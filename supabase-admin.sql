-- حسابات المدارس + مدير النظام (يُشغَّل مرة واحدة بعد supabase.sql)
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text, school text,
  active boolean not null default false,
  is_admin boolean not null default false,
  created_at timestamptz not null default now());
alter table public.profiles enable row level security;

create or replace function public.is_admin() returns boolean language sql stable security definer set search_path = public as
$$ select coalesce((select is_admin from public.profiles where id = auth.uid()), false) $$;
create or replace function public.is_active() returns boolean language sql stable security definer set search_path = public as
$$ select coalesce((select active from public.profiles where id = auth.uid()), false) $$;

drop policy if exists "read profiles" on public.profiles;
create policy "read profiles" on public.profiles for select using (id = auth.uid() or public.is_admin());
drop policy if exists "admin updates" on public.profiles;
create policy "admin updates" on public.profiles for update using (public.is_admin()) with check (public.is_admin());

create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path = public as
$$ begin
  insert into public.profiles (id, email, school) values (new.id, new.email, new.raw_user_meta_data->>'school')
  on conflict (id) do nothing;
  return new;
end $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute function public.handle_new_user();

-- الحسابات الموجودة مسبقًا
insert into public.profiles (id, email) select id, email from auth.users on conflict (id) do nothing;

-- البيانات متاحة فقط للحساب المفعَّل
drop policy if exists "own rows" on public.app_data;
create policy "own rows" on public.app_data for all
  using (owner = auth.uid() and public.is_active())
  with check (owner = auth.uid() and public.is_active());

-- مدير النظام
update public.profiles set active = true, is_admin = true where email = 'k4044s@gmail.com';
