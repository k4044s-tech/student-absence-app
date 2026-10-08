-- متابعة غياب الطلاب — جدول البيانات في Supabase
-- شغّل هذا الملف مرة واحدة: Supabase ← SQL Editor ← New query ← الصق ← Run

create table if not exists public.app_data (
  owner      uuid        not null default auth.uid() references auth.users(id) on delete cascade,
  kind       text        not null,   -- cfg | days | roster | actions | refs | noorm
  key        text        not null,   -- تاريخ اليوم للرصد، أو main
  data       jsonb       not null,
  updated_at timestamptz not null default now(),
  primary key (owner, kind, key)
);

alter table public.app_data enable row level security;
alter table public.app_data replica identity full;

drop policy if exists "own rows" on public.app_data;
create policy "own rows" on public.app_data
  for all using (owner = auth.uid()) with check (owner = auth.uid());

-- المزامنة الفورية بين الأجهزة
do $$ begin
  alter publication supabase_realtime add table public.app_data;
exception when duplicate_object then null; end $$;
