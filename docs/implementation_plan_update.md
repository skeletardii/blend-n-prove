\# Implementation Plan: Fusion Rush Supabase Integration (Arcade Hybrid)



This document outlines the architecture for "Fusion Rush", utilizing a hybrid approach: \*\*Arcade-Style Leaderboards\*\* (accessible to everyone, no login) and \*\*Authenticated Cloud Saves\*\* (requires login).



\## 1. Schema Strategy



We leverage the existing schema. No major migrations are needed, but we must apply specific RLS policies.



\### Tables

\* \*\*`public.profiles`\*\*: Linked to Auth. Used for Cloud Saves owner.

\* \*\*`public.saves`\*\*: Stores save slots (`jsonb`). Linked to `profiles.id`.

\* \*\*`public.settings`\*\*: Stores preferences (`jsonb`). Linked to `profiles.id`.

\* \*\*`public.stats`\*\*: Stores aggregation data (`jsonb`). Linked to `profiles.id`.

\* \*\*`public.leaderboard`\*\*: \*\*Arcade Table\*\*.

&nbsp;   \* `id` (BigInt/UUID): Unique entry ID.

&nbsp;   \* `three\_name` (Text): The 3-letter initials (e.g., "ABC").

&nbsp;   \* `game\_score` (Int): The score.

&nbsp;   \* `game\_time` (Interval): Time taken.

&nbsp;   \* `game\_level` (Int): Level reached.



\## 2. Security \& RLS Policies



\### A. Leaderboard (Arcade Mode)

\* \*\*Read:\*\* `ENABLE` for `anon` and `authenticated`. (Everyone can see scores).

\* \*\*Write:\*\* `DISABLE` for everyone.

&nbsp;   \* \*Reason:\* We do not want users inserting SQL directly.

&nbsp;   \* \*Solution:\* Submissions must go through the `submit-leaderboard-score` Edge Function, which uses the `service\_role` key to bypass RLS.



\### B. User Data (Saves/Profiles)

\* \*\*Read/Write:\*\* `ENABLE` only for `auth.uid() = user\_id`.

\* \*Result:\* Users can only touch their own save files.



\## 3. Edge Functions



These TypeScript functions (Deno) run on Supabase to handle secure logic.



\### Function 1: `submit-leaderboard-score`

\* \*\*Type:\*\* Public (Anonymous)

\* \*\*Purpose:\*\* Validates and inserts a score into the restricted leaderboard.

\* \*\*Input:\*\*

&nbsp;   ```json

&nbsp;   {

&nbsp;     "three\_name": "JOE",

&nbsp;     "score": 12500,

&nbsp;     "level": 5,

&nbsp;     "duration": 120.5

&nbsp;   }

&nbsp;   ```

\* \*\*Logic:\*\*

&nbsp;   1.  Validate `three\_name` is exactly 3 chars.

&nbsp;   2.  Validate `score` is within realistic bounds for the `level` (Anti-cheat).

&nbsp;   3.  Insert into `public.leaderboard` using Admin Client.

&nbsp;   4.  Calculate and return the specific rank of this new entry immediately.



\### Function 2: `get-name-rank`

\* \*\*Type:\*\* Public (Anonymous)

\* \*\*Purpose:\*\* specific retrieval of an arcade name's best performance.

\* \*\*Input:\*\* `{ "three\_name": "JOE" }`

\* \*\*Output:\*\*

&nbsp;   ```json

&nbsp;   {

&nbsp;     "best\_rank": 14,

&nbsp;     "best\_score": 12500,

&nbsp;     "total\_entries": 500

&nbsp;   }

&nbsp;   ```



\### Function 3: `ai-inference`

\* \*\*Type:\*\* Public or Authenticated (depending on strictness)

\* \*\*Purpose:\*\* Proxy for OpenAI/LLM calls to hide the API Key.

\* \*\*Input:\*\* `{ "prompt": "..." }`

\* \*\*Output:\*\* `{ "response": "..." }`



\### Function 4: `record-session-stats`

\* \*\*Type:\*\* Authenticated Only

\* \*\*Purpose:\*\* Aggregates telemetry (FPS, Load Times) for logged-in users.



\## 4. Database Helper Functions



To make the Edge Functions fast, we execute complex logic in SQL.



```sql

-- Helper: Get the rank of a specific score entry (for the "New High Score!" screen)

CREATE OR REPLACE FUNCTION public.get\_entry\_rank(p\_entry\_id bigint)

RETURNS bigint

LANGUAGE sql SECURITY DEFINER

AS $$

&nbsp; WITH ranked AS (

&nbsp;   SELECT id, rank() OVER (ORDER BY game\_score DESC) as r

&nbsp;   FROM public.leaderboard

&nbsp; )

&nbsp; SELECT r FROM ranked WHERE id = p\_entry\_id;

$$;

```

5\. Godot Client Architecture

We separate the "Arcade" logic from the "Auth" logic so players aren't forced to sign up.



SupabaseManager.gd (Core)

Manages the HTTP client.



Holds session\_token (if logged in).



Helper: call\_function(name, payload, require\_auth=false)



LeaderboardManager.gd (Arcade)

Does NOT require login.



submit\_score(initials, score) -> Calls submit-leaderboard-score function.



fetch\_top\_10() -> Calls REST API: GET /rest/v1/leaderboard?select=\*\&order=game\_score.desc\&limit=10.



AuthManager.gd (Cloud Saves)

login(email, password)



register(email, password)



upload\_save(slot\_id) -> POST to public.saves.



download\_save(slot\_id) -> GET from public.saves.

