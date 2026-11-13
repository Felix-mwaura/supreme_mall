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
| Customer sign-up | `lib/screens/auth/customer_signup_screen.dart` | Name, M-Pesa phone, optional email, password, terms. Validated locally |
| Business sign-up | `lib/screens/auth/business_signup_screen.dart` | Business name, department/category picker, town/area, contact person, phone, email, password, documents checklist |
| Application result | `lib/screens/auth/signup_result_screen.dart` | Customer: account ready. Business: reference number + pending-verification timeline |
| Sign in | `lib/screens/auth/sign_in_screen.dart` | UI only — waits for the auth build |
| Customer shell | `lib/screens/home/customer_home_screen.dart` | Frosted glass nav over an `IndexedStack` of four tabs; each tab keeps its own scroll position |
| Home tab | `lib/screens/home/tabs/home_tab.dart` | "Bento" grid: hero Shopping + medium Food/Fresh + four "soon" tiles, active order card, nearby merchants |
| Categories tab | `lib/screens/home/tabs/categories_tab.dart` | Directory of businesses grouped by department, search + filter chips, "coming soon" block |
| Orders tab | `lib/screens/home/tabs/orders_tab.dart` | Active order with a Received → Preparing → On the way → Delivered ladder, plus history |
| Profile tab | `lib/screens/home/tabs/profile_tab.dart` | Identity card, account/support rows, working sign out |

Signing up as a customer now continues straight into the dashboard.

Design references are taken from the Developer Brief (sections 3–5) and the
Phase 1 Roadmap (sections 2.1, 2.2 and 7 for the commission/department structure).

### Design system
- Palette in `lib/theme/app_colors.dart`: Supreme Navy `#0B2D5B`, Ivory White `#F8FAFC`,
  Royal Gold `#D4A017`, Emerald `#27AE60`, Sky `#3498DB`, Charcoal `#4B5563`.
- Type scale in `lib/theme/app_text.dart`.
- `ThemeData` is intentionally minimal (`lib/theme/app_theme.dart`) so component styling
  lives in the reusable widgets and does not depend on version-specific theme classes.

### Project structure

```
lib/
  main.dart                     app entry (SupremeMallApp)
  models/
    department.dart             the seven service departments + Phase 1 flags
    account_role.dart           customer vs business
  data/
    demo_data.dart              sample merchants + orders (replaced by Supabase)
  services/
    account_service.dart        single seam for account creation (Supabase goes here)
  screens/
    welcome_screen.dart         entry screen (account paths)
    home/                       customer dashboard (Bento)
    auth/                       customer sign-up, business sign-up, result, sign in
  theme/                        colours, text styles, theme
  utils/validators.dart         phone / email / password / terms validation
  widgets/                      buttons, logo, role cards, form fields, scaffold
```

## Running it

```bash
flutter pub get
flutter run                      # device or emulator
flutter test                     # widget tests in test/welcome_screen_test.dart
flutter analyze
```

No third-party packages are used yet — the app depends only on the Flutter SDK.

## Design preview (no Flutter SDK needed)

`design_preview/index.html` is a static HTML mock of the three built screens for quick
client review. Serve it with any static file server:

```bash
cd design_preview && python3 -m http.server 3000
```

## Current limitations

- Nothing is persisted: `AccountService` resolves locally after a short delay. Both methods
  carry `TODO(supabase)` markers — planned tables are `profiles` (customers) and
  `businesses` (merchant applications, `status = 'pending'`).
- No OTP/SMS verification, no password reset, no merchant dashboard, no storefronts,
  no payments.
- **No cart tab.** It needs the orders database, so the shell ships with four tabs
  (Home, Categories, Orders, Profile) and the cart returns as the centre tab with
  the cart/checkout milestone.
- Categories and Orders render sample data from `lib/data/demo_data.dart`.
- Business documents are described in the UI but not yet uploaded.

## Suggested next steps

1. Connect Supabase auth + `profiles` / `businesses` tables (replacing `AccountService`).
2. SMS OTP verification on the Kenyan phone number captured at sign-up.
3. Storefronts: retail grid (Shopping), menu with option groups (hotel restaurants),
   produce by weight (Fresh) behind the four shared seams.
4. Cart tab + single checkout with one sub-order per business.
5. Merchant dashboard for Phase 1 departments.
