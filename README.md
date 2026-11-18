# Supreme Mall

**One app. Multiple services. Endless solutions.**
A Flutter app for Supreme Solutions Ltd — an integrated marketplace and service-booking
platform launching in Nyeri, Kenya.

---

## What is built so far

**Milestone 1 — Home screen and account paths (customer + business sign-up).**

| Screen | File | Notes |
| --- | --- | --- |
| Home | `lib/screens/welcome_screen.dart` | Brand hero, the seven department pills (Phase 1 live / later-phase "soon"), and the two account paths: **Sign up as a customer** and **Sign up as a business** |
| Customer shell | `lib/screens/home/customer_home_screen.dart` | Frosted glass nav over an `IndexedStack` of four tabs; each tab keeps its own scroll position |
| Home tab | `lib/screens/home/tabs/home_tab.dart` | "Bento" grid: hero Shopping + medium Food/Fresh + four "soon" tiles, active order card, nearby merchants |
| Categories tab | `lib/screens/home/tabs/categories_tab.dart` | Directory of businesses grouped by department, search + filter chips, "coming soon" block |
| Orders tab | `lib/screens/home/tabs/orders_tab.dart` | Active order with a Received → Preparing → On the way → Delivered ladder, plus history |
| Profile tab | `lib/screens/home/tabs/profile_tab.dart` | Real identity from `profiles`, account/support rows, working sign out |

**Milestone 2 — Supabase foundation and real authentication.**

| Screen | File | Notes |
| --- | --- | --- |
| Auth gate | `lib/screens/auth/auth_gate.dart` | Root widget. No session → welcome screen; customer → dashboard; business owner → business status |
| Customer sign-up | `lib/screens/auth/customer_signup_screen.dart` | Creates a Supabase user (email + password), profile row via trigger; email is required now |
| Business sign-up | `lib/screens/auth/business_signup_screen.dart` | Creates the user, then the `businesses` row (`status = 'pending'`) and its `business_departments` link |
| Sign in | `lib/screens/auth/sign_in_screen.dart` | Real `signInWithPassword`, password reset by email, inline error mapping |
| Business status | `lib/screens/business/business_status_screen.dart` | Reads its real status; can pull to refresh. Approval is not possible from the app |
| Config error | `lib/screens/config_missing_screen.dart` | Explains a build made without Supabase credentials, instead of failing later |
| Application result | `lib/screens/auth/signup_result_screen.dart` | Post-submission confirmation for both account types |

**Milestone 3 — customer storefronts (Shopping first, Food and Fresh reuse it).**

| Screen | File | Notes |
| --- | --- | --- |
| Storefront | `lib/screens/catalogue/storefront_screen.dart` | One widget per department: branded header, area, rounded search (320 ms debounce), category chips, responsive grid, pull to refresh, loading / empty / error states |
| Product detail | `lib/screens/catalogue/product_detail_screen.dart` | Photo, merchant, price with real previous price, unit, availability, description. No cart action — that is Milestone 4 |
| Merchant directory | `lib/screens/home/tabs/categories_tab.dart` | Rewritten: real approved merchants grouped by department, search, department chips, "coming later" departments kept visibly separate |
| Home "Near you" | `lib/screens/home/tabs/home_tab.dart` | Live merchants split by department; tiles open their storefront; area chip edits the saved area |

Catalogue reads live in `lib/repositories/catalogue_repository.dart`; nothing in the
catalogue UI touches `demo_data.dart` any more (only sample orders do, until Milestone 4).
Full detail: [`docs/milestone-3-report.md`](docs/milestone-3-report.md).

Data access lives in `lib/services/auth_service.dart` (auth + profile + own business),
with typed errors surface-mapped by `lib/utils/auth_errors.dart`.

Design references are taken from the Developer Brief (sections 3–5) and the
Phase 1 Roadmap (sections 2.1, 2.2 and 7 for the commission/department structure).

### Database (Supabase)

Project **supreme_mall**, ref `gfqpjdtbhsipquvdfkfn`, eu-central-1, Postgres 17.
The deployed schema is reproduced for review in `supabase/migrations/`
(`0001_foundation`, `0002_catalogue`, `0003_guard_service_context`).

- Tables: `departments` (7 seeded, ids mirroring `lib/models/department.dart`),
  `profiles`, `businesses`, `business_departments` (many-to-many), `business_documents`,
  `product_categories` (11 seeded across Shopping/Food/Fresh) and `products`.
- A new `auth.users` row creates its `profiles` row automatically; `account_type`
  metadata can only produce `customer` or `business_owner`.
- RLS is on for every table. Owners see only their own profile/business/documents;
  `guard_*` triggers stop a user changing their own `role` or a business's review
  fields — those are administrator-only (`is_admin()`).
- Customers can read approved businesses and their **active** products only; pending
  merchants and inactive listings never leave the database. A merchant has full control
  of their own products but cannot move one to another business.
- Passwords never touch our tables: Supabase Auth owns credentials.
- Local demo catalogue: [`supabase/seeds/demo_catalogue.sql`](supabase/seeds/demo_catalogue.sql)
  (three stores, 17 products, two out of stock and one inactive, so every state is visible).

### Design system
- Palette in `lib/theme/app_colors.dart`: Supreme Navy `#0B2D5B`, Ivory White `#F8FAFC`,
  Royal Gold `#D4A017`, Emerald `#27AE60`, Sky `#3498DB`, Charcoal `#4B5563`.
- Type scale in `lib/theme/app_text.dart`.
- `ThemeData` is intentionally minimal (`lib/theme/app_theme.dart`) so component styling
  lives in the reusable widgets and does not depend on version-specific theme classes.

### Project structure

```
lib/
  main.dart                     app entry: Supabase init, then AuthGate
  config/
    env.dart                    SUPABASE_URL / SUPABASE_ANON_KEY from --dart-define
    app_config.dart             review window, support address
  models/
    department.dart             the seven service departments + Phase 1 flags
    account_role.dart           customer vs business
    app_profile.dart            profiles row (+ delivery_area)
    catalogue.dart              product, category and merchant summary
    business_application.dart   businesses row + status enum
  data/
    demo_data.dart              sample orders only (catalogue is live)
  repositories/
    catalogue_repository.dart   the only catalogue queries (department/merchant/search)
  services/
    supabase_bootstrap.dart     initialises Supabase once, exposes client + AuthService
    auth_service.dart           sign up / sign in / sign out / reset / load profile
  screens/
    welcome_screen.dart         entry screen (account paths)
    home/                       customer dashboard (Bento)
    catalogue/                  storefront + product detail (shared by all departments)
    business/                   business status while awaiting approval
    auth/                       sign-up, sign-in, result, auth gate
  theme/                        colours, text styles, theme
  utils/
    validators.dart             phone / email / password / terms validation
    auth_errors.dart            Supabase error → human message
    money.dart                  KSh formatting
  widgets/                      buttons, logo, nav, cards, form fields, banners
supabase/migrations/            deployed schema, for review
supabase/seeds/                 local demo catalogue
test/                           widget + unit tests
```

## Running it

The Supabase URL and **publishable** key are injected at build time so no
credentials are committed:

```bash
cp env.example.json env.json      # then paste your project values
flutter pub get
flutter run --dart-define-from-file=env.json
flutter test
flutter analyze
```

`env.json` is git-ignored. Never put the service-role key in it — the client only
needs the publishable key, and RLS enforces the rest.

Without `env.json` the app opens a configuration screen explaining what is missing
instead of throwing network errors at the first tap.

### Troubleshooting: "Supabase credentials" screen

These values are compiled into the app. If the screen appears, the build never
received them — restarting or hot-reloading will not help.

| What the screen says | Cause | Fix |
| --- | --- | --- |
| No credentials in this build | the flag was never passed | start from a terminal with `--dart-define-from-file=env.json`, or use the committed `.vscode/launch.json` (F5) |
| The anon key is missing | `SUPABASE_ANON_KEY` spelt differently or absent in `env.json` | names are case-sensitive: `SUPABASE_URL`, `SUPABASE_ANON_KEY` |
| The project URL is missing | `SUPABASE_URL` spelt differently or absent | same |
| All present, still failing | an old build is installed | `flutter clean && flutter run --dart-define-from-file=env.json` |

Android Studio and VS Code **Run buttons do not pass extra arguments**: add
`--dart-define-from-file=env.json` under *Additional arguments* in your run
configuration, or use the included launch file. `env.json` must sit in the
project root, next to `pubspec.yaml`.

## Design preview (no Flutter SDK needed)

`design_preview/index.html` is a static HTML mock of the built screens for quick
client review. Serve it with any static file server:

```bash
cd design_preview && python3 -m http.server 3000
```

## Current limitations

- **Email confirmation is off** (Supabase auto-confirm) because no custom SMTP or
  domain exists yet. Sign-up therefore produces an active session immediately.
  Pre-pilot this becomes a 6-digit OTP typed into the app — not a magic link.
- Password reset sends a Supabase email and needs the project's redirect allow list;
  with the built-in mailer it only reaches project members until custom SMTP exists.
- The password floor in Supabase Auth is 6 characters; the client requires 8 with a
  letter and a number. The stricter client rule is what real users meet.
- Business documents are collected as metadata columns; the upload + review workflow
  arrives with the admin milestone.
- Merchants cannot upload product photos yet (needs the merchant dashboard and a
  Storage bucket), so listings show a department-tinted placeholder. `image_url` is
  already read, with fade-in and a broken-image fallback.
- Orders still render sample data from `lib/data/demo_data.dart`.
- No ratings or reviews: there is no data model for them, so none are displayed.
- The storefront loads a single page of 40 listings; the repository is paginated
  (`limit`/`offset`) and "load more" arrives with real volume.
- **No cart tab.** It needs the orders database, so the shell ships with four tabs
  (Home, Categories, Orders, Profile) and the cart returns as the centre tab with
  the cart/checkout milestone.

## Suggested next steps

1. Milestone 4 — cart, checkout and orders: real cart state, server-validated totals,
   one sub-order per business, order history replacing the sample rows.
2. Merchant dashboard: product CRUD and photo uploads.
3. Customer address book + delivery zones per town.
4. Favourites, once the MVP scope is agreed and a table exists.
5. Pre-pilot: custom SMTP + OTP email confirmation, then pilot launch.
