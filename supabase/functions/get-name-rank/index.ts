import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

serve(async (req) => {
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_ANON_KEY') ?? ''
  )

  try {
    const { three_name } = await req.json()

    // 1. Find best score for these initials
    const { data: bestEntry } = await supabase
      .from('leaderboard')
      .select('game_score')
      .eq('three_name', three_name.toUpperCase())
      .order('game_score', { ascending: false })
      .limit(1)
      .single()

    if (!bestEntry) {
        return new Response(JSON.stringify({ rank: null, message: "No score found" }), {
            headers: { 'Content-Type': 'application/json' },
        })
    }

    // 2. Count how many people have a higher score
    const { count } = await supabase
      .from('leaderboard')
      .select('*', { count: 'exact', head: true })
      .gt('game_score', bestEntry.game_score)

    return new Response(JSON.stringify({ 
      three_name: three_name.toUpperCase(), 
      best_rank: (count || 0) + 1, 
      best_score: bestEntry.game_score 
    }), { headers: { 'Content-Type': 'application/json' } })

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), { status: 400 })
  }
})