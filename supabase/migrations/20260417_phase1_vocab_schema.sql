-- Phase 1: Supabase setup only (no app integration)
-- Safe to run multiple times where possible.

create extension if not exists pgcrypto;

create table if not exists public.vocab (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  word text not null,
  meaning text not null,
  sentence text not null default '',
  created_at timestamptz not null default now()
);

create index if not exists idx_vocab_user_id on public.vocab(user_id);
create index if not exists idx_vocab_created_at on public.vocab(created_at desc);

alter table public.vocab enable row level security;

drop policy if exists "vocab_select_own" on public.vocab;
create policy "vocab_select_own"
on public.vocab
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "vocab_insert_own" on public.vocab;
create policy "vocab_insert_own"
on public.vocab
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "vocab_update_own" on public.vocab;
create policy "vocab_update_own"
on public.vocab
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "vocab_delete_own" on public.vocab;
create policy "vocab_delete_own"
on public.vocab
for delete
to authenticated
using (auth.uid() = user_id);
