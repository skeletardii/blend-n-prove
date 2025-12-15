-- The error "duplicate key value violates unique constraint" indicates that the
-- primary key sequence (public.leaderboard_id_seq) is out of sync with the actual
-- IDs in the table. This often happens after bulk inserts or restores.

-- Run this SQL in your Supabase Dashboard -> SQL Editor to fix it:

SELECT setval('public.leaderboard_id_seq', COALESCE((SELECT MAX(id) FROM public.leaderboard), 0) + 1, false);
