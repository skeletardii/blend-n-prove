# Implementation Plan: Fusion Rush Supabase Integration (Arcade Hybrid)

This document outlines the architecture for "Fusion Rush", utilizing a hybrid approach: **Arcade-Style Leaderboards** (accessible to everyone, no login) and **Authenticated Cloud Saves** (requires login).

## 1. Schema Strategy

We leverage the existing schema. No major migrations are needed, but we must apply specific RLS policies.

### Tables

*   **`public.profiles`**: Linked to Auth. Used for Cloud Saves owner.
*   **`public.saves`**: Stores save slots (`jsonb`). Linked to `profiles.id`.
*   **`public.settings`**: Stores preferences (`jsonb`). Linked to `profiles.id`.
*   **`public.stats`**: Stores aggregation data (`jsonb`). Linked to `profiles.id`.
*   **`public.leaderboard`**: **Arcade Table**.
    *   `id` (BigInt/UUID): Unique entry ID.
    *   `three_name` (Text): The 3-letter initials (e.g., "ABC").
    *   `game_score` (Int): The score.
    *   `game_time` (Interval): Time taken.
    *   `game_level` (Int): Level reached.

## 2. Security & RLS Policies

### A. Leaderboard (Arcade Mode)
*   **Read:** `ENABLE` for `anon` and `authenticated`. (Everyone can see scores).
*   **Write:** `DISABLE` for everyone.
    *   *Reason:* We do not want users inserting SQL directly.
    *   *Solution:* Submissions must go through the `submit-leaderboard-score` Edge Function, which uses the `service_role` key to bypass RLS.

### B. User Data (Saves/Profiles)
*   **Read/Write:** `ENABLE` only for `auth.uid() = user_id`.
    *   *Result:* Users can only touch their own save files.

## 3. Edge Functions

These TypeScript functions (Deno) run on Supabase to handle secure logic.

### Function 1: `submit-leaderboard-score`
*   **Type:** Public (Anonymous)
*   **Purpose:** Validates and inserts a score into the restricted leaderboard.
*   **Input:**
    ```json
    {
      "three_name": "JOE",
      "score": 12500,
      "level": 5,
      "duration": 120.5
    }
    ```
*   **Logic:**
    1.  Validate `three_name` is exactly 3 chars.
    2.  Validate `score` is within realistic bounds for the `level` (Anti-cheat).
    3.  Insert into `public.leaderboard` using Admin Client.
    4.  Calculate and return the specific rank of this new entry immediately.

### Function 2: `get-name-rank`
*   **Type:** Public (Anonymous)
*   **Purpose:** specific retrieval of an arcade name's best performance.
*   **Input:** `{ "three_name": "JOE" }`
*   **Output:**
    ```json
    {
      "best_rank": 14,
      "best_score": 12500,
      "total_entries": 500
    }
    ```

### Function 3: `ai-inference`
*   **Type:** Public or Authenticated (depending on strictness)
*   **Purpose:** Proxy for OpenAI/LLM calls to hide the API Key.
*   **Input:** `{ "prompt": "..." }`
*   **Output:** `{ "response": "..." }`

### Function 4: `record-session-stats`
*   **Type:** Authenticated Only
*   **Purpose:** Aggregates telemetry (FPS, Load Times) for logged-in users.

## 4. Database Helper Functions

To make the Edge Functions fast, we execute complex logic in SQL.

```sql
-- Helper: Get the rank of a specific score entry (for the "New High Score!" screen)
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

## 5. Godot Client Architecture

We separate the "Arcade" logic from the "Auth" logic so players aren't forced to sign up.

*   **`SupabaseManager.gd` (Core)**
    *   Manages the HTTP client.
    *   Holds `session_token` (if logged in).
    *   Helper: `call_function(name, payload, require_auth=false)`

*   **`LeaderboardManager.gd` (Arcade)**
    *   Does NOT require login.
    *   `submit_score(initials, score)` -> Calls `submit-leaderboard-score` function.
    *   `fetch_top_10()` -> Calls REST API: `GET /rest/v1/leaderboard?select=*&order=game_score.desc&limit=10`.

*   **`AuthManager.gd` (Cloud Saves)**
    *   `login(email, password)`
    *   `register(email, password)`
    *   `upload_save(slot_id)` -> POST to `public.saves`.
    *   `download_save(slot_id)` -> GET from `public.saves`.