-- DIGITALGYYAN Admin Panel: run this entire script in Supabase SQL Editor.
-- First create your admin user in Supabase Dashboard > Authentication > Users.
-- Then copy that user's UUID and replace PASTE_ADMIN_USER_UUID below before running the final INSERT.
create extension if not exists pgcrypto;
create table if not exists public.dg_admins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);
create table if not exists public.dg_resources (
  id uuid primary key default gen_random_uuid(),
  title text not null check (char_length(title) between 1 and 140),
  description text not null default '' check (char_length(description) <= 500),
  section text not null,
  subject text not null default '',
  category text not null,
  file_path text not null unique,
  file_url text not null,
  file_type text not null,
  file_size bigint not null default 0 check (file_size >= 0 and file_size <= 68719476736),
  published boolean not null default false,
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now()
);
alter table public.dg_admins enable row level security;
alter table public.dg_resources enable row level security;
create or replace function public.dg_is_admin()
returns boolean language sql stable security definer set search_path = '' as $$
  select exists(select 1 from public.dg_admins a where a.user_id = (select auth.uid()));
$$;
revoke all on function public.dg_is_admin() from public;
grant execute on function public.dg_is_admin() to anon, authenticated;
-- Visitors can read only published resource metadata; only allowlisted admins can manage records.
drop policy if exists "Public read published resources" on public.dg_resources;
create policy "Public read published resources" on public.dg_resources for select to anon, authenticated using (published = true or public.dg_is_admin());
drop policy if exists "Admins insert resources" on public.dg_resources;
create policy "Admins insert resources" on public.dg_resources for insert to authenticated with check (public.dg_is_admin() and created_by = (select auth.uid()));
drop policy if exists "Admins update resources" on public.dg_resources;
create policy "Admins update resources" on public.dg_resources for update to authenticated using (public.dg_is_admin()) with check (public.dg_is_admin());
drop policy if exists "Admins delete resources" on public.dg_resources;
create policy "Admins delete resources" on public.dg_resources for delete to authenticated using (public.dg_is_admin());
grant select on public.dg_resources to anon, authenticated;
grant insert, update, delete on public.dg_resources to authenticated;
-- Admin table is not exposed to visitors. No client-side writes to this table are allowed.
grant select on public.dg_admins to authenticated;
drop policy if exists "Admin can read own allowlist row" on public.dg_admins;
create policy "Admin can read own allowlist row" on public.dg_admins for select to authenticated using (user_id = (select auth.uid()));
-- Create a public bucket so students can view/download published files. Upload/delete are admin-only.
-- 64 GiB configured ceiling: this does NOT override Supabase plan limits. Large files require a plan supporting the size and resumable TUS uploads.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('dg-resources', 'dg-resources', true, 68719476736,
  array['application/pdf','application/msword','application/vnd.openxmlformats-officedocument.wordprocessingml.document','application/vnd.ms-powerpoint','application/vnd.openxmlformats-officedocument.presentationml.presentation','image/png','image/jpeg','image/webp','image/gif','text/plain','application/octet-stream'])
on conflict (id) do update set public = true, file_size_limit = 68719476736;
drop policy if exists "Only admins upload DG resources" on storage.objects;
create policy "Only admins upload DG resources" on storage.objects for insert to authenticated with check (bucket_id = 'dg-resources' and public.dg_is_admin() and (storage.foldername(name))[1] = (select auth.uid())::text);
drop policy if exists "Only admins delete DG resources" on storage.objects;
create policy "Only admins delete DG resources" on storage.objects for delete to authenticated using (bucket_id = 'dg-resources' and public.dg_is_admin());
drop policy if exists "Only admins update DG resources" on storage.objects;
create policy "Only admins update DG resources" on storage.objects for update to authenticated using (bucket_id = 'dg-resources' and public.dg_is_admin()) with check (bucket_id = 'dg-resources' and public.dg_is_admin());
-- After creating the auth user, run this separately with the real UUID:
-- insert into public.dg_admins (user_id) values ('PASTE_ADMIN_USER_UUID');
