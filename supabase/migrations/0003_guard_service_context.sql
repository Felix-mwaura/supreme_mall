-- ============================================================================
-- Supreme Mall — migration 0003_guard_service_context
-- ============================================================================
-- Found while seeding the catalogue: the guard triggers from 0001 fired even
-- when there was no user at all (SQL console, migrations, service-role
-- maintenance). `auth.uid()` is NULL there and `is_admin(NULL)` is false, so a
-- deliberate administrative update was rejected with
--   "Only an administrator can change review fields".
--
-- Requests without a user context are already outside the surface RLS
-- protects, so they pass through. Authenticated users still hit every check —
-- the behaviour for real clients is unchanged, which the probe run confirms.
-- ============================================================================

create or replace function public.guard_business_update()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  if auth.uid() is null or public.is_admin(auth.uid()) then
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

create or replace function public.guard_profile_update()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  if auth.uid() is null or public.is_admin(auth.uid()) then
    return new;
  end if;
  if new.role is distinct from old.role then
    raise exception 'Role is managed by Supreme Mall' using errcode = '42501';
  end if;
  return new;
end
$$;

create or replace function public.guard_product_update()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  if auth.uid() is null or public.is_admin(auth.uid()) then
    return new;
  end if;
  if new.business_id <> old.business_id then
    raise exception 'A product cannot be moved to another business' using errcode = '42501';
  end if;
  return new;
end
$$;
