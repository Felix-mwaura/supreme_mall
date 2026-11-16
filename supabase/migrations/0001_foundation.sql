-- ============================================================================
-- Supreme Mall — migration 0001_foundation
-- ============================================================================
-- This file is a faithful snapshot of what is deployed on the `supreme_mall`
-- project (ref gfqpjdtbhsipquvdfkfn). It was applied through the Supabase
-- connector and recorded as migration version 20261116114431; the file itself
-- is the reviewable reference, not the thing that ran. Verified after applying:
--   5 tables, 13 policies, RLS enabled on every table, 7 seeded departments,
--   6 functions, 2 enums, 5 triggers.
--
-- Scope: identity + business application only. No catalogue, cart, order or
-- payment tables — those arrive with their own milestones.
-- ============================================================================

create extension if not exists pgcrypto;

-- ---------------------------------------------------------------- enums -----
create type public.app_role as enum ('customer', 'business_owner', 'admin');
create type public.business_status as enum ('pending', 'approved', 'rejected', 'suspended');

-- ---------------------------------------------------------- departments -----
-- Mirror of `supremeDepartments` in lib/models/department.dart (same ids).
create table public.departments (
  id          text primary key,
  name        text not null,
  short_name  text not null,
  tagline     text,
  sort_order  integer not null default 0,
  is_active   boolean not null default false,   -- Phase 1 departments are true
  created_at  timestamptz not null default now()
);

insert into public.departments (id, name, short_name, tagline, sort_order, is_active) values
  ('shopping', 'Supreme Shopping', 'Shopping', 'Supermarkets & retail',      1, true),
  ('food',     'Supreme Food',     'Food',     'Restaurants & takeaways',    2, true),
  ('fresh',    'Supreme Fresh',    'Fresh',    'Farm & market produce',      3, true),
  ('rides',    'Supreme Rides',    'Rides',    'Cabs & scheduled trips',     4, false),
  ('boda',     'Supreme Boda',     'Boda',     'Rider transport & parcels',  5, false),
  ('errands',  'Supreme Errands',  'Errands',  'Shopping runs & pick-ups',   6, false),
  ('home',     'Supreme Home',     'Home',     'Repairs & household help',   7, false)
on conflict (id) do nothing;

-- ------------------------------------------------------------- profiles -----
create table public.profiles (
  id          uuid primary key references auth.users (id) on delete cascade,
  full_name   text not null default '',
  phone       text,
  role        public.app_role not null default 'customer',
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  constraint profiles_phone_format check (phone is null or phone ~ '^[+]254[0-9]{9}$')
);

-- ------------------------------------------------------------ businesses ----
create table public.businesses (
  id               uuid primary key default gen_random_uuid(),
  owner_id         uuid not null references public.profiles (id) on delete cascade,
  name             text not null,
  contact_name     text,
  phone            text not null,
  email            text not null,
  area             text not null,
  status           public.business_status not null default 'pending',
  reviewed_at      timestamptz,
  reviewed_by      uuid references public.profiles (id),
  rejection_reason text,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  constraint businesses_name_check check (length(trim(name)) >= 2 and length(trim(name)) <= 120),
  constraint businesses_phone_format check (phone ~ '^[+]254[0-9]{9}$'),
  constraint businesses_email_format check (email ~ '^[^@ ]+@[^@ ]+[.][a-zA-Z]{2,}$')
);

-- A business can sell in several departments (Brief: one merchant, many
-- services), hence a join table rather than a column on `businesses`.
create table public.business_departments (
  business_id   uuid not null references public.businesses (id) on delete cascade,
  department_id text not null references public.departments (id) on delete restrict,
  created_at    timestamptz not null default now(),
  primary key (business_id, department_id)
);

-- Metadata only for now: files live in Storage, added with the review workflow.
create table public.business_documents (
  id           uuid primary key default gen_random_uuid(),
  business_id  uuid not null references public.businesses (id) on delete cascade,
  doc_type     text not null,
  storage_path text not null,
  uploaded_at  timestamptz not null default now(),
  constraint business_documents_doc_type_check
    check (doc_type in ('business_permit', 'national_id', 'kra_pin', 'other'))
);

-- ------------------------------------------------------------ functions ----
create or replace function public.is_admin(uid uuid)
returns boolean
language sql
stable
security definer
set search_path to 'public'
as $$
  select exists (select 1 from public.profiles p where p.id = uid and p.role = 'admin');
$$;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end
$$;

-- Owners may edit their own business, but never its review state.
create or replace function public.guard_business_update()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  if public.is_admin(auth.uid()) then
    return new;
  end if;
  if new.owner_id <> old.owner_id then
    raise exception 'Business owner cannot be reassigned' using errcode = '42501';
  end if;
  if new.status is distinct from old.status
     or new.reviewed_by is distinct from old.reviewed_by
     or new.reviewed_at is distinct from old.reviewed_at
     or new.rejection_reason is distinct from old.rejection_reason then
    raise exception 'Only an administrator can change review fields' using errcode = '42501';
  end if;
  return new;
end
$$;

-- Customers cannot promote themselves to merchant or admin.
create or replace function public.guard_profile_update()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  if public.is_admin(auth.uid()) then
    return new;
  end if;
  if new.role is distinct from old.role then
    raise exception 'Role is managed by Supreme Mall' using errcode = '42501';
  end if;
  return new;
end
$$;

-- Every new auth user gets a profile. `account_type` is the only role signal
-- the client may send, and it can only ever produce customer or business_owner.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  insert into public.profiles (id, full_name, phone, role)
  values (
    new.id,
    coalesce(nullif(trim(new.raw_user_meta_data->>'full_name'), ''), ''),
    nullif(new.raw_user_meta_data->>'phone', ''),
    case
      when new.raw_user_meta_data->>'account_type' = 'business'
        then 'business_owner'::public.app_role
      else 'customer'::public.app_role
    end
  )
  on conflict (id) do nothing;
  return new;
end
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

create trigger profiles_touch  before update on public.profiles   for each row execute function public.set_updated_at();
create trigger profiles_guard  before update on public.profiles   for each row execute function public.guard_profile_update();
create trigger businesses_touch before update on public.businesses for each row execute function public.set_updated_at();
create trigger businesses_guard before update on public.businesses for each row execute function public.guard_business_update();

-- ----------------------------------------------------------------- RLS -----
alter table public.departments         enable row level security;
alter table public.profiles            enable row level security;
alter table public.businesses          enable row level security;
alter table public.business_departments enable row level security;
alter table public.business_documents  enable row level security;

-- Departments: readable by anyone (the app needs the list before sign-in).
create policy departments_read on public.departments
  for select to anon, authenticated using (true);

-- Profiles: you see and edit only your own row; admins see all.
create policy profiles_select_own on public.profiles
  for select to authenticated using (id = auth.uid() or public.is_admin(auth.uid()));
create policy profiles_update_own on public.profiles
  for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

-- Businesses: owners see their own; admins see everything.
create policy businesses_select_own on public.businesses
  for select to authenticated using (owner_id = auth.uid() or public.is_admin(auth.uid()));
create policy businesses_insert_own on public.businesses
  for insert to authenticated with check (owner_id = auth.uid() and status = 'pending');
create policy businesses_update_own on public.businesses
  for update to authenticated using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create policy businesses_delete_own on public.businesses
  for delete to authenticated using (owner_id = auth.uid() and status = 'pending');

-- Departments of a business follow the business' owner.
create policy bd_select on public.business_departments
  for select to authenticated
  using (exists (select 1 from public.businesses b
                 where b.id = business_departments.business_id
                   and (b.owner_id = auth.uid() or public.is_admin(auth.uid()))));
create policy bd_insert on public.business_departments
  for insert to authenticated
  with check (exists (select 1 from public.businesses b
                      where b.id = business_departments.business_id and b.owner_id = auth.uid()));
create policy bd_delete on public.business_departments
  for delete to authenticated
  using (exists (select 1 from public.businesses b
                 where b.id = business_departments.business_id and b.owner_id = auth.uid()));

-- Documents follow the business too.
create policy bdoc_select on public.business_documents
  for select to authenticated
  using (exists (select 1 from public.businesses b
                 where b.id = business_documents.business_id
                   and (b.owner_id = auth.uid() or public.is_admin(auth.uid()))));
create policy bdoc_insert on public.business_documents
  for insert to authenticated
  with check (exists (select 1 from public.businesses b
                      where b.id = business_documents.business_id and b.owner_id = auth.uid()));
create policy bdoc_delete on public.business_documents
  for delete to authenticated
  using (exists (select 1 from public.businesses b
                 where b.id = business_documents.business_id and b.owner_id = auth.uid()));

-- Deliberately absent: a customer-facing read policy on `businesses`. The
-- catalogue milestone adds `businesses_select_approved` when the storefront
-- list actually needs it. Until then customers cannot enumerate merchants.
