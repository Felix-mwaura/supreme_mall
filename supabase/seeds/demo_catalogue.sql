-- ============================================================================
-- Demo catalogue (development only)
-- ============================================================================
-- Three approved businesses owned by the demo business account, with 17 real
-- product rows: two out of stock and one inactive, so every storefront state
-- can be seen without touching the data.
--
-- Prerequisite: the demo auth users exist (see the Milestone 2 report).
-- This file deliberately contains no credentials.
--
-- Remove with:
--   delete from auth.users where email like 'demo.%@suprememall.test';
-- which cascades to profiles → businesses → business_departments → products.
-- ============================================================================

-- The demo merchant account owns everything here.
update public.businesses
   set status = 'approved', reviewed_at = now(), rejection_reason = null
 where owner_id = '60000000-0000-4000-8000-000000000002';

insert into public.businesses (owner_id, name, contact_name, phone, email, area, status, reviewed_at)
select '60000000-0000-4000-8000-000000000002', v.name, v.contact, v.phone, v.email, v.area,
       'approved', now()
from (values
  ('Nyeri Fresh Mart', 'Wanjiku Njoroge', '+254720111333', 'freshmart@suprememall.test', 'Nyeri Town'),
  ('Karatina Greens',  'Joseph Kariuki',  '+254720111444', 'greens@suprememall.test',     'Karatina')
) as v(name, contact, phone, email, area)
where not exists (select 1 from public.businesses b where b.name = v.name);

insert into public.business_departments (business_id, department_id)
select b.id, d.department_id
from public.businesses b
join (values
  ('Nyeri Fresh Mart', 'shopping'),
  ('Karatina Greens',  'fresh'),
  ('Mama Ngina Cafe',  'food')
) as d(name, department_id) on d.name = b.name
where b.owner_id = '60000000-0000-4000-8000-000000000002'
on conflict do nothing;

insert into public.products
  (business_id, category_id, name, description, price_kes, compare_at_price, unit, stock_quantity, is_active)
select b.id, p.category_id, p.name, p.description, p.price, p.compare_at, p.unit, p.stock, p.active
from public.businesses b
join (values
  ('Nyeri Fresh Mart', 'groceries',  'Unga wa Dola 2kg',        'Maize flour, fortified. Mill date printed on the packet.', 199.00, null::numeric, null::text,  40, true),
  ('Nyeri Fresh Mart', 'groceries',  'Pishori rice 2kg',        'Aromatic Mwea pishori rice.',                              349.00, 399.00,       'pack',      26, true),
  ('Nyeri Fresh Mart', 'groceries',  'Cooking oil 1L',          'Refined vegetable oil.',                                   320.00, null::numeric, 'litre',      18, true),
  ('Nyeri Fresh Mart', 'household',  'Bar soap 800g',           'Multi-purpose washing soap.',                               210.00, null::numeric, null::text,  34, true),
  ('Nyeri Fresh Mart', 'beverages',  'Soda 500ml',              'Chilled, single bottle.',                                    70.00, null::numeric, null::text,   0, true),
  ('Nyeri Fresh Mart', 'toiletries', 'Toothpaste 100ml',        'Fluoride toothpaste.',                                      185.00, null::numeric, null::text,  12, false),
  ('Mama Ngina Cafe',  'breakfast',  'Full breakfast',          'Two eggs, sausage, chapati, tea or coffee.',                 450.00, null::numeric, null::text,  20, true),
  ('Mama Ngina Cafe',  'mains',      'Beef stew with rice',     'Slow-cooked beef, steamed rice, kachumbari.',                520.00, null::numeric, null::text,  15, true),
  ('Mama Ngina Cafe',  'mains',      'Chicken biryani',         'Spiced rice with quarter chicken.',                          650.00, 700.00,       null::text,   9, true),
  ('Mama Ngina Cafe',  'snacks',     'Mandazi (4 pieces)',      'Fried fresh each morning.',                                   80.00, null::numeric, null::text,  30, true),
  ('Mama Ngina Cafe',  'drinks',     'Passion juice 500ml',     'Freshly blended, no added sugar.',                           150.00, null::numeric, 'litre',      25, true),
  ('Karatina Greens',  'vegetables', 'Tomatoes',                'Farm-fresh, sold by weight.',                                120.00, null::numeric, 'kg',         50, true),
  ('Karatina Greens',  'vegetables', 'Sukuma wiki',             'One fresh bunch.',                                            40.00, null::numeric, 'bunch',      60, true),
  ('Karatina Greens',  'vegetables', 'Potatoes',                'Sorted, medium size.',                                        90.00, null::numeric, 'kg',         80, true),
  ('Karatina Greens',  'fruits',     'Bananas',                 'Ripe, sweet, sold by weight.',                               150.00, null::numeric, 'kg',         35, true),
  ('Karatina Greens',  'fruits',     'Avocado',                 'Single ripe fruit.',                                          30.00, null::numeric, 'piece',       0, true),
  ('Karatina Greens',  'cereals',    'Dry maize',               'Clean, graded, sold by weight.',                              90.00, null::numeric, 'kg',         45, true)
) as p(business_name, category_id, name, description, price, compare_at, unit, stock, active)
  on p.business_name = b.name
where b.owner_id = '60000000-0000-4000-8000-000000000002'
  and not exists (
    select 1 from public.products existing
    where existing.name = p.name and existing.business_id = b.id
  );
