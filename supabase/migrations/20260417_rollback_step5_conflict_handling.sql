-- Rollback Step 5 conflict-handling changes.
-- Use with caution in non-production environments only.

drop trigger if exists trg_vocab_set_updated_at on public.vocab;
drop function if exists public.set_vocab_updated_at();

drop index if exists idx_vocab_updated_at;

alter table public.vocab
  drop column if exists updated_at;
