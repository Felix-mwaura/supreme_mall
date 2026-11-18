# Milestone 3 — Customer experience and storefronts

**Status:** implementation complete, awaiting review.
**Branch:** `arena/070a7d25-supreme-mall`
**Database:** `supreme_mall` (`gfqpjdtbhsipquvdfkfn`) — migrations `0002_catalogue`, `0003_guard_service_context`

---

## 1. What this milestone covers

From the milestone brief (M3): department navigation, location selection, search with
loading/empty/error states, a Shopping storefront first, product cards, product detail
pages, an architecture that lets Food and Fresh follow without duplicating Shopping, real
Supabase data instead of hardcoded samples, and correct handling of unavailable listings.

| Brief item | Where it lives |
| --- | --- |
| Department navigation | Home bento tiles open their storefront; Categories tab filters by department |
| Location selection, persisted | `profiles.delivery_area` + `showAreaPicker`; the Home chip shows and changes it |
| Search with real states | `StorefrontScreen` (320 ms debounce) and the merchant directory |
| Shopping storefront first | `StorefrontScreen` — same widget reused by Food and Fresh |
| Categories and product cards | `product_categories` table, `ProductCard` |
| Product detail pages | `ProductDetailScreen`: image, merchant, price, unit, availability, description |
| Reusable for Food/Fresh | One storefront + one card; departments differ by data (categories, units, accent, glyph) |
| Real data from Supabase | `CatalogueRepository`; no catalogue data in `demo_data.dart` any more |
| Unavailable/inactive listings | RLS hides inactive rows; out-of-stock is shown, not hidden |

**Explicitly not in this milestone:** cart, quantity selector, checkout, payment,
favourites. The brief puts cart and checkout in M4, and the design brief forbids fake
controls — so the product page has **no Add to Cart button**. It ends with an honest line
saying checkout is not open yet. That is the one place I deliberately did not follow the
reference design, and it is the first thing M4 will replace.

---

## 2. Database

### Tables

| Table | Purpose |
| --- | --- |
| `product_categories` | Groceries, Household, Beverages, Toiletries (Shopping); Breakfast, Mains, Snacks, Drinks (Food); Vegetables, Fruits, Cereals (Fresh) — 11 seeded |
| `products` | 17 columns worth of listing: name, description, `price_kes`, `compare_at_price`, `unit`, `stock_quantity`, `is_active`, `image_url`, business, category |
| `profiles.delivery_area` | Where the customer shops; nullable until they choose |

Constraints that are actually load-bearing: `price_kes > 0`; `compare_at_price is null or
compare_at_price > price_kes` (so a "was" price cannot be invented by accident);
`stock_quantity >= 0`; `unit` limited to kg/g/bunch/crate/piece/litre/pack/dozen (the
units the documents name for Fresh).

### Policies (least privilege)

| Who | Can do |
| --- | --- |
| Anyone (anon) | Read active products **only** of approved businesses; read categories; read approved merchants |
| Signed-in customer | Same as anon, plus their own profile |
| Merchant | Full CRUD on their own products whatever their approval state; still cannot move a product to another business (trigger) |
| Admin | Everything, via `is_admin()` |

### Verified by acting as real users

Created throwaway users, queried as them, deleted them afterwards.

| Probe | Result |
| --- | --- |
| Anonymous sees products | 16 of 17 — inactive product hidden, out-of-stock still visible |
| Anonymous sees approved businesses | 3 |
| Anonymous sees a **pending** business and its products | 0 / 0 |
| Signed-in customer sees the pending business | 0 |
| Pending merchant sees own products | 2 of their own, plus the 16 public |
| Merchant moves a product to another business | **blocked** — "A product cannot be moved to another business" |
| Anonymous reads `profiles` | 0 rows |
| Seeded taxonomy | 11 categories |
| Cleanup | 17 products, 3 businesses left — no residue |

### Migration `0003` fixed a real defect found during seeding

The guards from `0001` also fired when there was **no user at all** (`auth.uid()` is NULL,
`is_admin(NULL)` is false). Result: a legitimate administrative update — including the
very first approval — was rejected with "Only an administrator can change review fields".
That would have blocked M6 admin approval through SQL or a service-role job. Requests
without a user context now pass; authenticated users hit exactly the same checks as
before, which the probes above re-confirm.

---

## 3. App

### New

| File | Purpose |
| --- | --- |
| `lib/models/catalogue.dart` | `ProductCategory`, `CatalogueProduct`, `MerchantSummary`; tolerates PostgREST returning `numeric` as a number *or* a string |
| `lib/repositories/catalogue_repository.dart` | The only place that queries the catalogue: by department, merchant, category, search term |
| `lib/screens/catalogue/storefront_screen.dart` | One storefront for every department |
| `lib/screens/catalogue/product_detail_screen.dart` | Product page |
| `lib/widgets/product_card.dart` | `ProductCard` + `ProductCardSkeleton` |
| `lib/widgets/catalogue_image.dart` | Image with fade-in, loading and failure fallback |
| `lib/widgets/area_picker_sheet.dart` | Area selection sheet + `serviceAreas` |
| `test/catalogue_test.dart`, `test/storefront_test.dart` | Model rules and storefront states |

### Changed

- `lib/screens/home/tabs/home_tab.dart` — live tiles open their storefront; "Near you"
  now lists real approved merchants; the area chip shows and edits the saved area.
- `lib/screens/home/tabs/categories_tab.dart` — rewritten as a real merchant directory
  (grouped by department, searchable, filterable) that opens the shared storefront.
- `lib/screens/home/customer_home_screen.dart` — owns the chosen area, saves it to the
  profile, and reverts the UI if the save fails rather than claiming success.
- `lib/models/app_profile.dart`, `lib/services/auth_service.dart` — `deliveryArea` and
  `updateDeliveryArea`.
- `lib/services/supabase_bootstrap.dart` — exposes the shared client to the repository.
- `lib/data/demo_data.dart` — merchant demo data **deleted** (dead code once the
  directory went to Supabase). Sample *orders* remain until M4.

### Design decisions worth your review

1. **Dark canvas kept.** Your accepted direction is Option C · Dark Bento, and the design
   brief says the source files are authoritative. The reference's cream-and-yellow palette
   is not used; department accents (Sky, Gold, Emerald) identify departments, gold stays
   the action colour.
2. **One storefront, three departments.** Shopping, Food and Fresh differ by data —
   categories, units, accent, glyph — not by screen. Adding a department is a row in
   `departments` plus categories, not a new page.
3. **No photography yet.** Merchants cannot upload images (that needs the merchant
   dashboard and a Storage bucket), so listings render a department-tinted placeholder
   with the category glyph. `image_url` is already read, with fade-in and a broken-image
   fallback, so real photos work the day uploads exist.
4. **Grid sizing is responsive**: `SliverGridDelegateWithMaxCrossAxisExtent(190)` with a
   fixed tile *height* (300 dp) instead of an aspect ratio. The card's photo is always
   square, so proportions match across listings; the explicit height is what stops the
   column overflowing on a 320 dp phone once the customer raises their text size
   (card text is clamped at 130 %, which the tile is measured for).
5. **Search debounced at 320 ms** (merchant directory 220 ms) to avoid a query per
   keystroke on a slow connection.
6. **Touch targets are 48 dp**, including the area chip and the category chips: the pill
   keeps its compact look and gains an invisible padded hit area, because a 34 dp chip
   fails the accessibility bar in the brief.
7. **The Home search bar is a doorway, not a second search engine.** It was an inert
   text field you could type into with no effect — the decorative control the brief
   forbids. It now opens the merchant directory, where search actually filters live
   data; the Categories chip bar and storefront search do the real work.
8. **One remaining sample block on Home**: the "Order #SM-1042" card is still
   `demo_data`. Orders are Milestone 4, and the card is not tappable, so it cannot
   mislead anyone into thinking tracking works.

---

## 4. Verification

**Not run:** `flutter analyze`, `flutter test`, `flutter run` — there is still no Flutter or
Dart SDK in this sandbox, so I will not claim the build is green.

Run here, across 51 Dart files:

| Check | Result |
| --- | --- |
| Import resolution (226 directives) | 0 broken |
| Undefined project symbols | none |
| Duplicate top-level names | none |
| Delimiter balance | 51/51 files |
| Database behaviour | 13 probes as real users (above) |

One bug that only appeared because of a static read: pruning `DemoMerchant` left its
`demoMerchants` list and `merchantsFor()` behind, referencing a deleted class. Fixed.

### How to see it

```bash
flutter run --dart-define-from-file=env.json
```

Sign in as `demo.customer@suprememall.test` / `Supreme123`, then:

1. Home → tap **Supreme Shopping** → 6 listings, "Groceries/Household/Beverages/Toiletries"
   chips, Pishori rice showing `-13%` off a real previous price.
2. Search "soap" → one result; search "zzz" → "Nothing matches".
3. Soda 500ml → "OUT OF STOCK" badge on the card and out-of-stock on the detail page.
4. Supreme Fresh → units shown as "per kg", "per bunch", "each".
5. Categories tab → three approved merchants grouped by department, tap one → that
   merchant's listings.
6. Tap the area chip → pick Karatina → reopen the app → still Karatina.

Toothpaste stays invisible everywhere: it is `is_active = false`, so it never leaves the
database.

---

## 5. Risks and what remains

| Item | Status |
| --- | --- |
| R6 (demo data imported by widgets) | **Closed for catalogue** — merchants/products come from Supabase. Orders still demo until M4. |
| Merchant photo uploads | Open — needs Storage + merchant dashboard (M5) |
| Favourites | Not built; needs an agreed MVP scope and a `favourites` table |
| Pagination | Repository accepts `limit`/`offset` (page size 40) but the UI loads one page; a "load more" belongs with real volume |
| Ratings/reviews | No data model yet, so nothing is shown — no invented stars |
| Image sizing | No `cached_network_image`; the built-in loader plus sized boxes is enough until uploads exist |
| CLI verification | Still none here; please run `flutter analyze` + `flutter test` (expect 37 tests) |

---

## 6. Next

M4 — cart, checkout and order management: real cart state, quantity rules, delivery fees
calculated server-side, order creation only after validation, order history replacing the
sample rows, and the Add to Cart action this milestone deliberately left out.
