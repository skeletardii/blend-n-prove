import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

serve(async (req) => {
  // 1. Setup Admin Client (Bypasses security rules to write the score)
  const supabaseAdmin = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
  )

  try {
    const { three_name, score, level, duration } = await req.json()

    // 2. Validation Checks
    if (!three_name || three_name.length !== 3) {
      throw new Error("Initials must be exactly 3 characters.")
    }
    if (score > 1000000) { throw new Error("Score unlikely.") }

    // 3. Insert Score into Database
    const { data: insertedData, error: insertError } = await supabaseAdmin
      .from('leaderboard')
      .insert({ 
        three_name: three_name.toUpperCase(), 
        game_score: score, 
        game_level: level,
        game_time: `${duration} seconds` 
      })
      .select('id')
      .single()

    if (insertError) throw insertError

    // 4. Get the Rank instantly
    const { data: rank } = await supabaseAdmin.rpc('get_entry_rank', { p_entry_id: insertedData.id })

    return new Response(JSON.stringify({ success: true, rank: rank, id: insertedData.id }), {
      headers: { 'Content-Type': 'application/json' },
    })

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), { status: 400 })
  }
})