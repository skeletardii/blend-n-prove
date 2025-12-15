I understand you want the complete, finalized plan as a single Markdown file, including all explanations, database setup steps, and the Godot client-side code.

Here is the complete **`Fusion_Rush_Implementation_Plan_Complete.md`**. It includes everything: the Database logic, the Edge Function logic (TypeScript), and the Godot Client logic (GDScript).

-----

# Fusion Rush: Complete Supabase Integration Plan

This document outlines the full architecture for integrating "Fusion Rush" with Supabase. It uses a **Hybrid Architecture**:

1.  **Arcade Leaderboard:** Publicly accessible, no login required, secured via Edge Functions.
2.  **User Accounts:** Authenticated system for Cloud Saves and Settings.

## 1\. Database & Schema Strategy

We utilize the existing schema with specific security enhancements.

### Table Structure

  * **`public.leaderboard` (Arcade):**
      * `id` (BigInt): Unique entry ID.
      * `three_name` (Text): 3-letter initials (e.g., "ABC").
      * `game_score` (Int): Score.
      * `game_level` (Int): Level reached.
      * `game_time` (Interval): Time taken.
  * **`public.profiles` (Auth):** Linked to `auth.users`.
  * **`public.saves` (Auth):** Stores save data (`jsonb`), linked to `profiles`.
  * **`public.stats` (Auth):** Stores gameplay metrics (`jsonb`).

### SQL Setup Instructions

Run this SQL in your Supabase Dashboard -\> **SQL Editor** to configure security and helper functions.

```sql
-- 1. Enable Row Level Security (RLS) on Leaderboard
ALTER TABLE public.leaderboard ENABLE ROW LEVEL SECURITY;

-- 2. Allow PUBLIC READ access (Everyone can see scores)
DROP POLICY IF EXISTS "Leaderboard is public" ON public.leaderboard;
CREATE POLICY "Leaderboard is public" 
ON public.leaderboard FOR SELECT USING (true);

-- 3. BLOCK DIRECT WRITES
-- We intentionally do NOT create an INSERT/UPDATE policy.
-- This forces all score submissions to go through our secure Edge Function.

-- 4. Helper Function: Get Entry Rank
-- Used by the Edge Function to calculate rank immediately after insertion.
CREATE OR REPLACE FUNCTION public.get_entry_rank(p_entry_id bigint)
RETURNS bigint
LANGUAGE sql SECURITY DEFINER
AS $$
  WITH ranked AS (
    SELECT id, rank() OVER (ORDER BY game_score DESC) as r
    FROM public.leaderboard
  )
  SELECT r FROM ranked WHERE id = p_entry_id;
$$;
```

-----

## 2\. Edge Functions (Server-Side Logic)

These functions run on Supabase (Deno/TypeScript) to secure sensitive operations.

### Deployment Instructions

1.  Install Supabase CLI.
2.  Login: `supabase login`
3.  Create functions: `supabase functions new [name]`
4.  Deploy: `supabase functions deploy [name]`

### Function A: `submit-leaderboard-score`

**Purpose:** Validates arcade scores and inserts them bypassing RLS.

```typescript
// supabase/functions/submit-leaderboard-score/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

serve(async (req) => {
  // Use Service Role Key to bypass RLS
  const supabaseAdmin = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
  )

  try {
    const { three_name, score, level, duration } = await req.json()

    // 1. Validation
    if (!three_name || three_name.length !== 3) throw new Error("Initials must be 3 chars.")
    if (score > 1000000) throw new Error("Score unlikely.")

    // 2. Insert Score
    const { data, error } = await supabaseAdmin
      .from('leaderboard')
      .insert({ 
        three_name: three_name.toUpperCase(), 
        game_score: score, 
        game_level: level, 
        game_time: `${duration} seconds`
      })
      .select('id')
      .single()

    if (error) throw error

    // 3. Get Rank
    const { data: rank } = await supabaseAdmin.rpc('get_entry_rank', { p_entry_id: data.id })

    return new Response(JSON.stringify({ success: true, rank: rank }), { headers: { 'Content-Type': 'application/json' } })
  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), { status: 400 })
  }
})
```

### Function B: `get-name-rank`

**Purpose:** Finds the *best* rank for a specific set of initials.

```typescript
// supabase/functions/get-name-rank/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

serve(async (req) => {
  const supabase = createClient(Deno.env.get('SUPABASE_URL') ?? '', Deno.env.get('SUPABASE_ANON_KEY') ?? '')
  try {
    const { three_name } = await req.json()
    
    // Find best score for name
    const { data: best } = await supabase.from('leaderboard')
      .select('game_score').eq('three_name', three_name.toUpperCase())
      .order('game_score', { ascending: false }).limit(1).single()

    if (!best) return new Response(JSON.stringify({ rank: null }), { headers: { 'Content-Type': 'application/json' } })

    // Count players with higher scores
    const { count } = await supabase.from('leaderboard')
      .select('*', { count: 'exact', head: true }).gt('game_score', best.game_score)

    return new Response(JSON.stringify({ best_rank: (count || 0) + 1, best_score: best.game_score }), { headers: { 'Content-Type': 'application/json' } })
  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), { status: 400 })
  }
})
```

-----

## 3\. Godot Client Implementation (GDScript)

This architecture uses a central **Manager** script to handle all networking.

### Step 1: `SupabaseManager.gd`

Create this script and set it as an **Autoload** (Global) in Project Settings named `Supabase`.

```gdscript
extends Node

# --- CONFIGURATION ---
# Replace with your actual Project URL and Anon Key from Supabase Dashboard
const PROJECT_URL = "https://YOUR_PROJECT_ID.supabase.co"
const API_KEY = "YOUR_ANON_PUBLIC_KEY"

# --- SIGNALS ---
signal score_submitted(rank)
signal leaderboard_fetched(scores)
signal login_completed(user, error)

# --- STATE ---
var session_token = ""
var user_id = ""

# --- HELPER: HEADERS ---
func _get_headers(auth_token = null):
	var headers = ["Content-Type: application/json", "apikey: " + API_KEY]
	if auth_token:
		headers.append("Authorization: Bearer " + auth_token)
	else:
		headers.append("Authorization: Bearer " + API_KEY)
	return headers

# --- ARCADE LEADERBOARD ---

func submit_score_arcade(initials: String, score: int, level: int, duration: float):
	var url = PROJECT_URL + "/functions/v1/submit-leaderboard-score"
	var body = JSON.stringify({
		"three_name": initials,
		"score": score,
		"level": level,
		"duration": duration
	})
	
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(result, code, headers, body):
		var json = JSON.parse_string(body.get_string_from_utf8())
		if code == 200:
			emit_signal("score_submitted", json.rank)
			print("Score Submitted! Rank: ", json.rank)
		else:
			print("Error: ", json)
		http.queue_free()
	)
	http.request(url, _get_headers(), HTTPClient.METHOD_POST, body)

func fetch_leaderboard():
	# Standard REST API call (faster than Edge Function for reading)
	var url = PROJECT_URL + "/rest/v1/leaderboard?select=three_name,game_score,game_level&order=game_score.desc&limit=10"
	
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(result, code, headers, body):
		var json = JSON.parse_string(body.get_string_from_utf8())
		emit_signal("leaderboard_fetched", json)
		http.queue_free()
	)
	http.request(url, _get_headers(), HTTPClient.METHOD_GET)

# --- AUTHENTICATION (Cloud Saves) ---

func login(email, password):
	var url = PROJECT_URL + "/auth/v1/token?grant_type=password"
	var body = JSON.stringify({"email": email, "password": password})
	
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(result, code, headers, body):
		var json = JSON.parse_string(body.get_string_from_utf8())
		if code == 200:
			session_token = json.access_token
			user_id = json.user.id
			emit_signal("login_completed", json.user, null)
		else:
			emit_signal("login_completed", null, json.error_description if json.has("error_description") else "Login Failed")
		http.queue_free()
	)
	http.request(url, _get_headers(), HTTPClient.METHOD_POST, body)

func save_game_cloud(slot: int, data: Dictionary):
	if session_token == "": 
		print("Not logged in.")
		return

	var url = PROJECT_URL + "/rest/v1/saves"
	# Ideally use UPSERT (Prefer: resolution=merge-duplicates) header here
	var headers = _get_headers(session_token)
	
	var body = JSON.stringify({
		"user_id": user_id,
		"slot": slot,
		"data": data
	})
	
	var http = HTTPRequest.new()
	add_child(http)
	http.request(url, headers, HTTPClient.METHOD_POST, body)
```

### Step 2: Usage in GUI (Example)

Attach this script to your **Game Over** scene button.

```gdscript
extends Control

@onready var input_field = $InitialsInput

func _on_SubmitButton_pressed():
	var initials = input_field.text
	var score = GlobalGameManager.current_score
	
	# Call the Global Supabase Manager
	Supabase.submit_score_arcade(initials, score, 1, 120.0)
	
	# Listen for result
	await Supabase.score_submitted
	print("Rank received, transitioning to leaderboard...")
```

-----

### Manual Instructions & Checklist

1.  **[ ] CLI Setup:** Ensure you have run `supabase link` and `supabase functions deploy` successfully.
2.  **[ ] Secrets:** Don't forget to run `supabase secrets set OPENAI_API_KEY=...` if you implement the AI function.
3.  **[ ] Godot Config:** In `SupabaseManager.gd`, you **must** manually replace `PROJECT_URL` and `API_KEY` with your actual credentials from the Supabase Dashboard (Settings -\> API).
4.  **[ ] Autoload:** You **must** add `SupabaseManager.gd` to the **Autoload** list in Project Settings for the global `Supabase` variable to work.