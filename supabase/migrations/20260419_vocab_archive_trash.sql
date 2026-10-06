-- Archive flag + soft delete (recycle bin).

alter table public.vocab
  add column if not exists is_archived boolean not null default false;

alter table public.vocab
  add column if not exists deleted_at timestamptz null;

create index if not exists idx_vocab_user_deleted
  on public.vocab(user_id, deleted_at desc nulls last);
