# Release Hardening Checklist

## 1) Database migrations
- Run in order:
  - `supabase/migrations/20260417_phase1_vocab_schema.sql`
  - `supabase/migrations/20260417_step5_updated_at_conflict_handling.sql`
  - `supabase/migrations/20260417_step5_updated_at_trigger.sql`
- Verify `public.vocab` has:
  - `id`, `user_id`, `word`, `meaning`, `sentence`, `created_at`, `updated_at`
- Verify RLS policies exist and are enabled.

## 2) Runtime safety checks
- Start app offline:
  - save vocab succeeds locally
  - UI updates immediately
- Restore network:
  - pending vocab is pushed
  - pull merges remote updates
- Confirm app does not crash when Supabase is unavailable.

## 3) Conflict and integrity checks
- Same vocab `id` edited on two clients:
  - latest `updated_at` wins after sync cycle
- No duplicate rows for same `id` after repeated retries.
- New writes always use UUID ids.

## 4) Logging checks
- Confirm logs are emitted for:
  - OCR
  - save action
  - sync stages
  - errors
- Export logs using `LoggerService.exportRecentLogsToJson()`.

## 5) Test gate
- Must pass before release:
  - `flutter analyze` (mobile + desktop)
  - `flutter test` (mobile + desktop + shared package)
  - `flutter test integration_test -d windows` (mobile)
- Optional one-command gate:
  - PowerShell: `scripts/quality_gate.ps1`
  - Bash: `scripts/quality_gate.sh`

## 6) Rollback script
- For Step 5 conflict-handling rollback only:
  - `supabase/migrations/20260417_rollback_step5_conflict_handling.sql`
- Run rollback only if required by incident response.
