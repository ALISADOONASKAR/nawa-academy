-- Run this once in Supabase Dashboard > SQL Editor.
-- Creates a read-only role table. Only trusted SQL/dashboard administration
-- can assign or change roles; browser users cannot promote themselves.

create schema if not exists private;
revoke all on schema private from public;
grant usage on schema private to authenticated;

create table if not exists public.user_roles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  role text not null check (role in ('admin'))
);

alter table public.user_roles enable row level security;
revoke all on table public.user_roles from anon, authenticated;
grant select on table public.user_roles to authenticated;

create or replace function private.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.user_roles r
    where r.user_id = (select auth.uid()) and r.role = 'admin'
  );
$$;

revoke all on function private.is_admin() from public;
grant execute on function private.is_admin() to authenticated;

drop policy if exists "read own role or admin roles" on public.user_roles;
create policy "read own role or admin roles"
on public.user_roles
for select
to authenticated
using (user_id = (select auth.uid()) or (select private.is_admin()));

-- After nawacompany19@gmail.com has registered and confirmed the address,
-- run this separately to grant the owner account admin access:
-- insert into public.user_roles (user_id, role)
-- select id, 'admin' from auth.users
-- where lower(email) = lower('nawacompany19@gmail.com')
--   and email_confirmed_at is not null
-- on conflict (user_id) do update set role = excluded.role;

