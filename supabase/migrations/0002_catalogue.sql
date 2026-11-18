-- ============================================================================
-- Supreme Mall — migration 0002_catalogue
-- ============================================================================
-- Deployed on `supreme_mall` (ref gfqpjdtbhsipquvdfkfn) through the Supabase
-- connector. This file mirrors what is live; it is the reviewable reference,
-- not the artefact that ran.
--
-- Adds: product_categories (per department), products (owned by one business),
-- profiles.delivery_area, and the read policies that let customers browse
-- approved merchants without exposing pending ones.
-- ============================================================================

create table public.product_categories (
  id            text primary key,
  department_id text not null references public.departments (id) on delete cascade,
  name          text not null,
  sort_order    integer not null default 0,
  is_active     boolean not null default true,
  created_at    timestamptz not null default now(),
  constraint product_categories_name_check check (length(btrim(name)) between 2 and 60)
);
create index product_categories_department_idx
  on public.product_categories (department_id, sort_order);

create table public.products (
  id               uuid primary key default gen_random_uuid(),
  business_id      uuid not null references public.businesses (id) on delete cascade,
  category_id      text not null references public.product_categories (id) on delete restrict,
  name             text not null,
  description      text,
  price_kes        numeric(12,2) not null,
  compare_at_price numeric(12,2),
  unit             text,
  stock_quantity   integer not null default 0,
  is_active        boolean not null default true,
  image_url        text,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  constraint products_name_check check (length(btrim(name)) between 2 and 120),
  constraint products_price_check check (price_kes > 0),
  -- A "was" price is only meaningful if it is genuinely higher.
  constraint products_compare_price_check
    check (compare_at_price is null or compare_at_price > price_kes),
  constraint products_stock_check check (stock_quantity >= 0),
  constraint products_unit_check
    check (unit is null or unit in ('kg','g','bunch','crate','piece','litre','pack','dozen'))
);
create index products_business_idx on public.products (business_id, is_active);
create index products_category_idx on public.products (category_id, is_active);

create trigger products_touch
  before update on public.products
  for each row execute function public.set_updated_at();

-- A product belongs to the business that created it, permanently.
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

create trigger products_guard
  before update on public.products
  for each row execute function public.guard_product_update();

-- Where the customer shops. Persisted on the profile so it survives reinstalls
-- and is available to checkout later.
alter table public.profiles add column delivery_area text;

-- ------------------------------------------------------------------ RLS -----
alter table public.product_categories enable row level security;
alter table public.products enable row level security;

create policy product_categories_read on public.product_categories
  for select to anon, authenticated using (true);

-- Browsing surface: active listings of approved businesses only.
create policy products_select_approved on public.products
  for select to anon, authenticated
  using (
    is_active
    and exists (
      select 1 from public.businesses b
      where b.id = products.business_id and b.status = 'approved'
    )
  );

-- Merchants manage their own catalogue whatever their approval state.
create policy products_select_own on public.products
  for select to authenticated
  using (exists (select 1 from public.businesses b
                 where b.id = products.business_id and b.owner_id = auth.uid()));
create policy products_insert_own on public.products
  for insert to authenticated
  with check (exists (select 1 from public.businesses b
                      where b.id = products.business_id and b.owner_id = auth.uid()));
create policy products_update_own on public.products
  for update to authenticated
  using (exists (select 1 from public.businesses b
                 where b.id = products.business_id and b.owner_id = auth.uid()))
  with check (exists (select 1 from public.businesses b
                      where b.id = products.business_id and b.owner_id = auth.uid()));
create policy products_delete_own on public.products
  for delete to authenticated
  using (exists (select 1 from public.businesses b
                 where b.id = products.business_id and b.owner_id = auth.uid()));

-- Approved merchants become visible so storefront headers, the directory and
-- the product page can name them.
create policy businesses_select_approved on public.businesses
  for select to anon, authenticated using (status = 'approved');

create policy bd_select_approved on public.business_departments
  for select to anon, authenticated
  using (exists (select 1 from public.businesses b
                 where b.id = business_departments.business_id and b.status = 'approved'));

-- --------------------------------------------------------------- taxonomy ---
insert into public.product_categories (id, department_id, name, sort_order) values
  ('groceries',   'shopping', 'Groceries',   1),
  ('household',   'shopping', 'Household',   2),
  ('beverages',   'shopping', 'Beverages',   3),
  ('toiletries',  'shopping', 'Toiletries',  4),
  ('breakfast',   'food',     'Breakfast',   1),
  ('mains',       'food',     'Mains',       2),
  ('snacks',      'food',     'Snacks',      3),
  ('drinks',      'food',     'Drinks',      4),
  ('vegetables',  'fresh',    'Vegetables',  1),
  ('fruits',      'fresh',    'Fruits',      2),
  ('cereals',     'fresh',    'Cereals',     3)
on conflict (id) do nothing;
