-- Step 5 hardening: keep updated_at accurate on every row update.

create or replace function public.set_vocab_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_vocab_set_updated_at on public.vocab;
create trigger trg_vocab_set_updated_at
before update on public.vocab
for each row
execute function public.set_vocab_updated_at();
