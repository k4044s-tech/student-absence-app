-- اسم المستخدم (يُشغَّل مرة واحدة بعد supabase-admin2.sql)
alter table public.profiles add column if not exists username text unique;

create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path = public as
$$ begin
  insert into public.profiles (id, email, school, username)
  values (new.id, new.email, new.raw_user_meta_data->>'school', lower(new.raw_user_meta_data->>'username'))
  on conflict (id) do nothing;
  return new;
end $$;
