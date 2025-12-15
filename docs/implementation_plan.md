# Implementation Plan: Fusion Rush Supabase Integration

This document outlines the strategy for implementing User Accounts, Profiles, Cloud Saves, and Performance Stats using Supabase and Godot, leveraging the existing database schema.

## 1. Existing Schema Overview

Analysis of `db_schema.sql` confirms the following tables and RLS policies already exist:

*   **`public.profiles`**: `id` (UUID), `username` (Text).
    *   *RLS:* `user can manage own profile`.
*   **`public.stats`**: `id` (UUID), `user_id` (UUID), `data` (JSONB).
    *   *RLS:* `user can manage own stats`.
*   **`public.settings`**: `user_id` (UUID), `data` (JSONB).
    *   *RLS:* `user can manage own settings`.
*   **`public.saves`**: `id` (UUID), `user_id` (UUID), `slot` (Int), `data` (JSONB).
    *   *RLS:* `user can manage own saves`.

**Action:** We will build the Godot client to interact directly with these tables. No new SQL migrations are strictly necessary for the core structure, though we may add Edge Functions for optimization.

## 2. Cloud Saves Strategy

We will utilize the existing `public.saves` table instead of raw file storage. This simplifies the architecture by keeping all user data within the Postgres database.

*   **Data Format:** Godot dictionaries (save data) will be serialized to JSON and stored in the `data` column.
*   **Slots:** The `slot` integer column allows multiple save files per user.

## 3. Edge Functions Strategy

We will implement the following Supabase Edge Functions to secure sensitive logic and offload processing from the client.

### A. Function: `ai-inference`
*   **Purpose:** Securely interacts with OpenAI/LLM APIs.
*   **Why:** Prevents exposing API keys in the Godot client build.
*   **Input:** `{ "prompt": "...", "context": {...} }`
*   **Output:** `{ "response": "..." }`
*   **Client Usage:** `SupabaseManager.functions.invoke("ai-inference", payload)`

### B. Function: `record-session-stats`
*   **Purpose:** Validates and processes raw performance metrics before storage.
*   **Why:** Allows server-side validation of incoming stats (anti-cheat) and potential immediate aggregation (e.g., updating a "rolling average" column on the profile) without the client needing complex DB permissions.
*   **Input:** `{ "session_id": "...", "metrics": { "fps": 60, "load_time": 500, ... } }`
*   **Output:** `{ "success": true, "processed_at": "timestamp" }`

### C. Function: `get-profile-summary`
*   **Purpose:** Aggregates user data for the profile screen.
*   **Why:** Calculates "Average FPS", "Total Playtime", etc., on the server to save bandwidth and client CPU.
*   **Input:** `{ "user_id": "..." }` (Optional, defaults to current user)
*   **Output:** `{ "username": "...", "stats_summary": { "avg_fps": 58, "avg_load_time": 1.2 } }`

## 4. Godot Client Implementation

The current `SupabaseServiceImpl.gd` relies on `SUPABASE_ANON_KEY` for everything. We need to upgrade it to handle **User Sessions**.

### Architecture Changes

1.  **Refactor `SupabaseServiceImpl.gd` to `SupabaseManager`**:
    *   This singleton should hold the `session_token`.
    *   It should expose an `authenticated_request()` method that adds the `Authorization: Bearer {session_token}` header automatically.
    *   Add `call_edge_function(function_name: String, payload: Dictionary)` method.

2.  **New `AuthManager.gd`**:
    *   `sign_up(email, password)`
    *   `sign_in(email, password)`
    *   `sign_out()`
    *   Stores the received JWT token in `SupabaseManager`.

3.  **New `CloudSaveManager.gd`**:
    *   `upload_save(save_data: Dictionary, slot: int)`: UPSERTs into `public.saves`.
    *   `download_save(slot: int)`: SELECTs from `public.saves`.

4.  **New `StatsManager.gd`**:
    *   Collects metrics during gameplay.
    *   Uses `SupabaseManager.call_edge_function("record-session-stats", metrics)` to submit data.

5.  **New `AIManager.gd`**:
    *   Manages AI interactions.
    *   Uses `SupabaseManager.call_edge_function("ai-inference", prompt)` for secure AI calls.

### API Interaction Example (Godot)

**Authentication (Sign In):**
*   **Endpoint:** `POST /auth/v1/token?grant_type=password`
*   **Body:** `{"email": "...", "password": "..."}`
*   **Response:** JSON containing `access_token` and `user` object.

**Calling Edge Function (Authenticated):**
*   **Endpoint:** `POST /functions/v1/record-session-stats`
*   **Headers:**
    *   `apikey`: `SUPABASE_ANON_KEY`
    *   `Authorization`: `Bearer USER_ACCESS_TOKEN`
*   **Body:** JSON payload.

## 5. Next Steps

1.  **Create Manager Scripts:** Create `AuthManager.gd`, `CloudSaveManager.gd`, and `StatsManager.gd` in `src/managers/`.
2.  **Update SupabaseService:** Modify the existing service to support token-based authentication.
3.  **UI Integration:** Create Login/Register screens in the Godot UI.
