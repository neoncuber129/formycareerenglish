-- Deep Context: extend vocab row for context, SRS sync, and language_pair.
-- Historically `sentence` stored language_pair; real sentences (if any) move to original_sentence.

alter table public.vocab
  add column if not exists language_pair text;

alter table public.vocab
  add column if not exists original_sentence text not null default '';

alter table public.vocab
  add column if not exists context_paragraph text not null default '';

alter table public.vocab
  add column if not exists part_of_speech text not null default '';

alter table public.vocab
  add column if not exists phonetic text not null default '';

alter table public.vocab
  add column if not exists source_app text not null default '';

alter table public.vocab
  add column if not exists source_url text not null default '';

alter table public.vocab
  add column if not exists image_anchor text not null default '';

alter table public.vocab
  add column if not exists audio_url text not null default '';

alter table public.vocab
  add column if not exists tags text[] not null default array[]::text[];

alter table public.vocab
  add column if not exists next_review_at timestamptz;

alter table public.vocab
  add column if not exists interval_days integer not null default 1;

alter table public.vocab
  add column if not exists ease_factor double precision not null default 2.5;

alter table public.vocab
  add column if not exists review_count integer not null default 0;

-- Classify legacy `sentence`: language code vs free text (best-effort).
update public.vocab
set
  language_pair = case
    when trim(coalesce(sentence, '')) ~ '^[a-z]{2,3}(-[a-z]{2,3})?$'
      then trim(sentence)
    else coalesce(nullif(trim(language_pair), ''), 'en-vi')
  end,
  original_sentence = case
    when trim(coalesce(sentence, '')) ~ '^[a-z]{2,3}(-[a-z]{2,3})?$'
      then ''
    else trim(coalesce(sentence, ''))
  end;

update public.vocab
set language_pair = 'en-vi'
where language_pair is null or trim(language_pair) = '';

alter table public.vocab
  alter column language_pair set default 'en-vi';

alter table public.vocab
  alter column language_pair set not null;

-- Legacy `sentence` column: keep NOT NULL; mirror cloze sentence for readers that still select `sentence`.
update public.vocab
set sentence = coalesce(nullif(trim(original_sentence), ''), '')
where true;

update public.vocab
set next_review_at = coalesce(next_review_at, created_at)
where next_review_at is null;

alter table public.vocab
  alter column next_review_at set not null;

alter table public.vocab
  alter column next_review_at set default now();

create index if not exists idx_vocab_source_app on public.vocab(user_id, source_app);
