-- DIGITALGYYAN Dynamic CMS migration
-- Run once in Supabase SQL Editor AFTER the existing SUPABASE-SETUP.sql has been applied.
-- This adds an unlimited-depth parent/child structure for sections, subjects, parts, chapters,
-- folders and categories. It does not delete or rewrite existing resource rows.

create table if not exists public.dg_content_nodes (
  id uuid primary key default gen_random_uuid(),
  parent_id uuid null references public.dg_content_nodes(id) on delete set null,
  node_type text not null check (node_type in ('section','class','subject','part','chapter','folder','category')),
  name text not null check (char_length(name) between 1 and 140),
  icon text not null default '📁',
  color text not null default '#2563eb',
  sort_order integer not null default 0,
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists dg_content_nodes_parent_idx on public.dg_content_nodes(parent_id);
create index if not exists dg_content_nodes_type_idx on public.dg_content_nodes(node_type);
alter table public.dg_content_nodes enable row level security;
drop policy if exists "Public can read content structure" on public.dg_content_nodes;
create policy "Public can read content structure" on public.dg_content_nodes for select to anon, authenticated using (true);
drop policy if exists "Admins create content structure" on public.dg_content_nodes;
create policy "Admins create content structure" on public.dg_content_nodes for insert to authenticated with check (public.dg_is_admin() and created_by = (select auth.uid()));
drop policy if exists "Admins update content structure" on public.dg_content_nodes;
create policy "Admins update content structure" on public.dg_content_nodes for update to authenticated using (public.dg_is_admin()) with check (public.dg_is_admin());
drop policy if exists "Admins delete content structure" on public.dg_content_nodes;
create policy "Admins delete content structure" on public.dg_content_nodes for delete to authenticated using (public.dg_is_admin());
grant select on public.dg_content_nodes to anon, authenticated;
grant insert, update, delete on public.dg_content_nodes to authenticated;

alter table public.dg_resources add column if not exists node_id uuid null references public.dg_content_nodes(id) on delete set null;
create index if not exists dg_resources_node_id_idx on public.dg_resources(node_id);

-- Optional HTML support for future web-based resources. If needed, add HTML MIME type to bucket allowlist
-- through Supabase Dashboard > Storage > dg-resources > Settings. Do not upload executable HTML from untrusted sources.
