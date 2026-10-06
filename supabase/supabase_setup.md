# Supabase Setup (Phase 1)

This phase only prepares backend schema and access policies.  
No application integration is required yet.

## 1) Create project
- Create a Supabase project from the dashboard.
- Keep your project URL and anon key for later phases.

## 2) Run SQL migration
- Open SQL Editor in Supabase.
- Run:
  - `supabase/migrations/20260417_phase1_vocab_schema.sql`
  - `supabase/migrations/20260417_step5_updated_at_conflict_handling.sql`
  - `supabase/migrations/20260417_step5_updated_at_trigger.sql`

## 3) Verify table and policies
- Confirm table `public.vocab` exists with columns:
  - `id uuid`
  - `user_id uuid`
  - `word text`
  - `meaning text`
  - `sentence text`
  - `created_at timestamptz`
  - `updated_at timestamptz`
- Confirm RLS is enabled on `public.vocab`.
- Confirm policies exist:
  - `vocab_select_own`
  - `vocab_insert_own`
  - `vocab_update_own`
  - `vocab_delete_own`

## 4) Sanity checks
- Insert should fail when unauthenticated.
- Authenticated user should only see own rows.

## Notes for next phases
- App-side fields stay unchanged (`sourceText`, `translatedText`, `languagePair`).
- Later phases use an adapter:
  - `sourceText -> word`
  - `translatedText -> meaning`
  - `languagePair -> sentence`
- Conflict handling uses `updated_at` with last-write-wins.
- `updated_at` is auto-maintained by DB trigger on `UPDATE`.
