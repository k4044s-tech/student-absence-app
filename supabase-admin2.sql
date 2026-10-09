-- مدة الاشتراك + حذف الحساب + إعادة تعيين كلمة المرور (يُشغَّل مرة واحدة بعد supabase-admin.sql)
alter table public.profiles add column if not exists expires_at timestamptz;

create or replace function public.is_active() returns boolean language sql stable security definer set search_path = public as
$$ select coalesce((select is_admin or (active and (expires_at is null or expires_at > now())) from public.profiles where id = auth.uid()), false) $$;

create or replace function public.admin_delete_user(uid uuid) returns void language plpgsql security definer set search_path = public, auth as
$$ begin
  if not public.is_admin() then raise exception 'not allowed'; end if;
  if uid = auth.uid() then raise exception 'cannot delete yourself'; end if;
  delete from auth.users where id = uid;
end $$;

create or replace function public.admin_set_password(uid uuid, pw text) returns void language plpgsql security definer set search_path = public, auth, extensions as
$$ begin
  if not public.is_admin() then raise exception 'not allowed'; end if;
  if length(coalesce(pw, '')) < 6 then raise exception 'password too short'; end if;
  update auth.users set encrypted_password = extensions.crypt(pw, extensions.gen_salt('bf')), updated_at = now() where id = uid;
end $$;

revoke all on function public.admin_delete_user(uuid) from public, anon;
revoke all on function public.admin_set_password(uuid, text) from public, anon;
grant execute on function public.admin_delete_user(uuid) to authenticated;
grant execute on function public.admin_set_password(uuid, text) to authenticated;
