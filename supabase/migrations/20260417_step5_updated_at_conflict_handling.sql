-- Step 5: Conflict handling support with updated_at (last-write-wins)

alter table public.vocab
  add column if not exists updated_at timestamptz not null default now();

update public.vocab
set updated_at = created_at
where updated_at is null;

create index if not exists idx_vocab_updated_at on public.vocab(updated_at desc);
