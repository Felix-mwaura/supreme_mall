# Supreme Mall — storefront, merchant dashboard and money model

**A decision record, not code.** Nothing in this document has been implemented.
Read it, cross things out, tell me what you disagree with — then it becomes the
spec the next milestones are built from.

| | |
| --- | --- |
| Status | **Proposed** — awaiting your review |
| Branch | `arena/070a7d25-supreme-mall` (Milestone 3 open in PR #6, unverified build) |
| Scope | How businesses list, how customers browse, how money is split |
| Not in scope | Booking-based services (rides, boda, errands), admin tooling, payments automation |

---

## 1. Where the app actually is today

Stated plainly, because the proposals below build on it:

- **Customers** browse real Supabase data: a department storefront (all approved
  merchants in Shopping / Food / Fresh), a merchant directory, product pages,
  search, and a saved delivery area. Cart and checkout do not exist.
- **Merchant data model** is complete: a business owns products, belongs to one or
  more departments, and RLS lets it read and write only its own rows. A guard
  trigger stops a product being moved to another business.
- **Merchants have no UI.** The only way to add a product today is a SQL insert.
  After sign-up a business owner sees a status screen and nothing else.
- **No order tables, no payment integration, no commission rules, no payouts.**
- The Milestone 3 build has **not been compiled** — there is no Flutter SDK in the
  environment it was written in. `flutter analyze && flutter test` still needs to
  run before anything is treated as working.

---

## 2. Decisions

### D1 — One merchant dashboard for every business type

A supermarket, a café and a greengrocer do the same job: list an item, set a price,
say whether it is available, publish. That is **one UI**, with a handful of fields
that change per department.

Encoded once as a profile, not as three screens:

| | Shopping | Food | Fresh |
| --- | --- | --- | --- |
| Item noun | item | dish | produce |
| Allowed units | pack, piece, litre, dozen | *(none — see Q1)* | kg, g, bunch, crate |
| Unit required | no | n/a | **yes** — a price without a unit is meaningless |
| Stock model | counted (12 left) | switch (available today) | counted, in kg |
| Price label | Price | Price | Price per unit |
| Categories | Groceries, Household, Beverages, Toiletries (+ aisles, see §3) | Breakfast, Mains, Snacks, Drinks | Vegetables, Fruits, Cereals |
| Accent / glyph | Sky | Gold | Emerald |

Screens: **Store home** (status + counts), **Products** (list, search, filter),
**Product form** (the one form), **Store settings**. Profile drives labels, which
fields appear, and validation copy.

**Rejected:** a dashboard per business type (triples the code and the bugs, drifts
within two milestones); a `business_type` column (the department already says it).

### D2 — Only three departments sell listings

Shopping, Food and Fresh are catalogues. Rides, Boda, Errands and Home services are
**bookings** — availability, coverage, fares. They get their own surface in Phase 2
and are excluded from the merchant dashboard until then.

**Rejected:** forcing services into `products`. It produces "Boda ride — KES 150 —
12 in stock", which is nonsense and would be hard to undo.

### D3 — A shop is public when approved **and** it has at least one active product

This is your gate, and it removes empty storefronts from browse entirely. A merchant
builds their catalogue while under review; the shop opens the moment approval and
the first active listing coincide.

Implementation choice:

- **Preferred:** a database policy — `businesses_select_approved` also requires
  `exists (active product)`. One definition for every consumer, forever.
- **Fallback:** an `!inner` embed in the merchants query. Same result, but only for
  queries that remember to write it.

Needs a small, separately justified migration. The existing index
`products_business_idx (business_id, is_active)` makes the check cheap.

**Consequence to accept:** a merchant who deactivates every product disappears from
browse until they list again. Correct behaviour — but the merchant must be told in
plain words: *"Approved. Add your first item to open your shop."*

### D4 — Customers browse a diversified feed; each shop still owns its items

**Model chosen: B — multi-merchant basket, per-shop fulfilment.**

- The home surface is a cross-merchant feed, organised by department then category.
- Every card names its merchant and area; tapping one opens the merchant's shop
  page (today's `StorefrontScreen` with `merchant:`).
- The cart groups items by shop. One payment, but **one sub-order per shop**, each
  with its own status.
- Nothing built in M3 is wasted: the department storefront *is* the feed, and the
  shop page becomes the detail view.

| Model | What it is | Verdict |
| --- | --- | --- |
| A | Platform owns demand, assigns a merchant to each item ("black box") | **Rejected for launch** — needs dispatch, comparable price/stock truth, and merchants who accept being invisible |
| B | Multi-merchant basket, sub-orders per shop | **Chosen** |
| C | One shop per checkout (what exists) | Kept *underneath* B as the fulfilment unit |

### D5 — An account may run several stores

Data already allows it; the demo merchant owns three. UI adapts so the common case
costs nothing:

- One store → no switcher, straight into that store.
- Two or more → a compact switcher in the header, and the product form always names
  the store being edited (the worst bug here is listing into the wrong shop).
- **Cap: 3 stores during the pilot**, so one account cannot become a wholesale
  listing farm.
- Each store keeps its own departments. A café that also sells packaged goods is
  legitimately `food` + `shopping`.

### D6 — Product photos are uploaded by merchants, after approval

- Supabase Storage bucket (e.g. `product-images`), **write scoped to the owning
  business**, public read for customers.
- Limits: max ~2 MB, image MIME types only, client-side downscale and EXIF strip
  before upload (a 12 MP phone photo will make the storefront crawl).
- Placeholder art stays as the fallback: most merchants will photograph some items
  and not others.
- **The uncomfortable part:** no system can vet image *content*. RLS stops a
  merchant touching another store's images, but not uploading something offensive.
  The human approval gate is the only check, and it happens once.

**Decision needed (Q3):** do photo changes after approval re-enter a light review,
or do we trust approved merchants?

### D7 — Money: record it precisely now, automate collection later

This is the one place I recommend deliberately slowing down.

The vision — commission split between business and platform, with a cash-out — is
right. But **collecting customer money first and paying merchants later** makes the
platform a payment intermediary: float, reconciliation, payout delays, regulatory
exposure, and merchants who do not trust you yet will not hand over their revenue.

**Phase 1 (pilot):**

- Customer pays **on delivery** — cash, or M-Pesa to that merchant's own till.
- Each merchant delivers its own sub-order (their own boda). No platform fleet, no
  float, no gateway integration, no licence.
- The platform **computes commission per order line at the moment of ordering** and
  invoices weekly from a ledger.

**Phase 2 (when volume justifies it):** the platform collects one M-Pesa STK push
per order and pays merchants out net of commission. The schema below is built so
this is *additive*, not a rewrite.

Non-negotiables regardless of phase:

1. **Snapshots.** Every order line freezes `unit_price`, `commission_rate` and
   `commission_amount` at order time. A rate change tomorrow must never rewrite
   yesterday's order.
2. **Server-side arithmetic.** Commission and net are computed in the database (or
   an edge function). The client never sends money values it could forge.
3. **A ledger from the first order**, not a spreadsheet later. Its states are
   `accrued → invoiced → settled`, and it *is* the merchant's cash-out screen.

### D8 — Freshness: refetch now, realtime later

- Refetch the catalogue when the app resumes and when the customer switches into a
  catalogue screen; pull-to-refresh already exists.
- One shared "catalogue changed" notifier so every screen stays in step.
- **Realtime only after the merchant dashboard exists** — until merchants can edit
  listings, there is nothing to stream. When it does: one shared channel, debounced
  events, reconnect with backoff, and a slow fallback poll, because sockets die
  silently and "live" must never mean "frozen".
- Not verifiable from this environment at all (no network to Supabase), so it ships
  only when you can test it on a device.

---

## 3. Supporting decisions

**Categories are curated, never free-text.** Merchants pick from a list per
department. Adding aisles for a supermarket (Bakery, Dairy & eggs, Meat & fish,
Frozen, Cleaning, Baby, Stationery…) is a data insert — no migration, no code
change. Unused aisles ship `is_active = false`.

**Category selection is two-level:** department first, then category. `products` has
only `category_id` and the department is derived from it, so a store in two
departments must choose which department it is listing into — otherwise a
supermarket files tomatoes under Groceries and they never appear in Fresh.

**Pack sizes are products, not variants.** "Pishori rice 2 kg" and "5 kg" are two
rows with different prices. No variants, barcodes, batches or expiry — that is
inventory software, not a storefront.

**Duplicate products in the feed.** Ten shops sell Unga wa Dola. Options: group and
show *"from KSh 199 · 3 shops"*; show only the cheapest offer per product; or keep
all and sort by area. **Decision needed (Q4).** This single choice decides whether
the feed reads like a marketplace or a price list.

**Delivery fee is per sub-order** (per shop), shown before payment. Honest, and it
discourages absurd cross-town baskets without building batching logic. In the pilot
the fee passes to the delivering merchant/rider; the platform's revenue is
commission only.

---

## 4. Data model (proposal — each needs its own justified migration)

```
commission_rules  (department_id, rate_bps, effective_from, is_active)

orders            (id, customer_id, delivery_area, status,
                   goods_total, delivery_total, total, placed_at, paid_at)

order_items       (id, order_id, sub_order_id, product_id, business_id,
                   quantity, unit,
                   unit_price_snapshot,      -- never re-derived
                   commission_rate_bps_snapshot,
                   commission_amount)

sub_orders        (id, order_id, business_id, status,
                   goods_total, commission_total, net_to_business,
                   delivery_fee, fulfilment ('merchant_delivery' | 'platform_rider'))

payouts           (id, business_id, period_start, period_end,
                   gross, commission, net, status ('accrued'|'invoiced'|'settled'), settled_at)
```

Notes:

- `sub_order_id` on the line, so per-shop fulfilment and per-shop commission are
  always in agreement.
- Statuses are per **sub-order** as well as per order: Shop A can be packed while
  Shop B is still cooking. Tracking UI follows that.
- `orders.delivery_area` is copied from the profile at order time — the customer may
  change their area later, and history must not move with it.
- No stock reservation table yet. Checkout validates stock server-side and rejects
  what has gone; reservation is a later refinement, and pretending otherwise would
  create phantom holds.

---

## 5. Worked example — one order, three shops

Rates used here are illustrative: Shopping 10 %, Fresh 12 %, Food 15 %.

Customer basket: 2 × Unga (Nyeri Fresh Mart, 199 each), 1 kg tomatoes (Karatina
Greens, 120/kg), 1 chicken biryani (Mama Ngina Cafe, 650).

| Sub-order | Goods | Commission | Net to business | Delivery fee (rider) |
| --- | --- | --- | --- | --- |
| Nyeri Fresh Mart | 398.00 | 39.80 (10 %) | 358.20 | 100.00 |
| Karatina Greens | 120.00 | 14.40 (12 %) | 105.60 | 80.00 |
| Mama Ngina Cafe | 650.00 | 97.50 (15 %) | 552.50 | 70.00 |
| **Total** | **1 168.00** | **151.70** | **1 016.30** | **250.00** |

- Customer pays **KSh 1 418** on delivery (goods + delivery).
- Platform revenue for this order: **KSh 151.70**, accrued to the ledger the moment
  the order is placed — not when it is delivered.
- Each merchant sees one number in the dashboard: *"KSh 358.20 due to you this week
  (order #SM-1043)"* — plus what was deducted and why.
- If the Shopping rate changes to 8 % next month, this order still reads 39.80.
  That is the entire point of the snapshots.

---

## 6. Order of work

1. **Verify Milestone 3** — `flutter analyze && flutter test` on PR #6. Nothing
   below starts first.
2. **Feed + refetch** (small, no money): home becomes the department feed, duplicate
   grouping, refetch on resume, area-aware "near you".
3. **Merchant dashboard** (medium, no money): products, one profile-driven form,
   stock, photos, the "approved — add your first item" state.
4. **Multi-shop cart, orders and ledger** (large): grouped cart, sub-orders,
   commission snapshots, merchant statement view, per-shop tracking.
5. **Later:** automated M-Pesa collection and payouts, realtime, admin review queue,
   push notifications, services.

Steps 2 and 3 carry no financial risk and can ship before a shilling moves.

---

## 7. Open questions

| # | Question | My recommendation |
| --- | --- | --- |
| Q1 | Does Food get `plate` / `serving` units, or stay unit-less? | Extend the unit list — small migration, and a café otherwise cannot state what the price buys |
| Q2 | Who collects the money in the pilot: merchant on delivery, or platform? | Merchant on delivery now; platform collection when volume and Daraja justify it |
| Q3 | Do photo changes after approval re-enter review? | Light re-review for the first photo on a listing; trust after that |
| Q4 | How does the feed handle the same product in several shops? | Group: *"from KSh 199 · 3 shops"* |
| Q5 | Is the pilot's first supermarket Shopping only, or Shopping + Fresh? | Whatever it stocks — the model already supports both |
| Q6 | Confirmed cap of 3 stores per account? | Yes, for the pilot |

---

## 8. Risks

| Risk | Why it matters | Mitigation |
| --- | --- | --- |
| Cross-merchant checkout is the biggest piece of work in the product | It touches cart, orders, money and delivery at once | Ship steps 2–3 first; design step 4 before writing it |
| Commission collected manually can leak revenue | Weekly invoicing depends on you chasing merchants | Ledger from order one; a merchant with an unpaid invoice is visible |
| Under-priced delivery on multi-shop baskets | Fee per shop annoys customers; one fee per trip loses money | Start per sub-order, transparently |
| Merchant photo quality | Poor photos make the feed look cheap | Downscale client-side, give photo guidance, keep placeholder art |
| Unverified build | Milestone 3 has never been compiled | Do not build on it until `analyze` and `test` pass |
| Realtime cannot be tested here | Silent socket failures look like frozen data | Fallback poll, and only ship when testable on device |

---

## 9. Sign-off checklist

- [ ] D1–D8 accepted (or corrected)
- [ ] Q1–Q6 answered
- [ ] Milestone 3 verified locally (`flutter analyze && flutter test`)
- [ ] Data model in §4 reviewed — each table needs a migration you approve separately
