# Milestone 1 — Project audit & baseline

**Project:** Supreme Mall (Flutter + Supabase)
**Branch audited:** `arena/8128ca02-supreme-mall` @ `f49635d`
**Audit date:** 2026-11-14
**Supabase project:** `supreme_mall` · ref `gfqpjdtbhsipquvdfkfn` · region `eu-central-1` · **ACTIVE_HEALTHY**

---

## 0. Toolchain caveat (read first)

This audit was produced in a sandbox **without a Flutter/Dart SDK** (`flutter` and `dart` are not on
`PATH`, and the SDK cannot be installed here). Therefore the four commands required by Milestone 1 —
`flutter pub get`, `dart format .`, `flutter analyze`, `flutter test` — **have not been run**.

What *was* verified mechanically:

- Brace/bracket balance across all 29 library files and 2 test files.
- No use of removed/deprecated colour APIs (`withOpacity`, `withValues`) — colours are const literals.
- No stale references (e.g. `MyApp`, `_HomeBody`) left from refactors.
- No `BoxDecoration` mixing `color` and `gradient` (a runtime assertion that would crash a tab).

What must be run locally before Milestone 2 is considered signed off:

```bash
flutter pub get
dart format .
flutter analyze
flutter test
flutter run        # manual smoke test of the flows in §3
```

Recommendation: add a GitHub Actions workflow (`.github/workflows/ci.yml`) running
`flutter analyze` + `flutter test` on push, so this gap cannot recur.

---

## 1. Architecture at a glance

| Concern | Current state |
| --- | --- |
| Framework | Flutter, Material 3 (`useMaterial3: true`) |
| Dart SDK constraint | `^3.13.7` (`pubspec.yaml`) |
| Third-party dependencies | **None.** Only `cupertino_icons`, `flutter_lints`, `flutter_test` |
| Routing | Imperative `Navigator.push(MaterialPageRoute(...))`. No named routes, no route table, no deep links |
| State management | `setState` only. No provider/riverpod/bloc, no DI container |
| Persistence | None. No local DB, no secure storage, no session cache |
| Backend | None. `AccountService` fakes a 900 ms delay and an incrementing reference |
| Localisation | Hardcoded English strings |
| Code size | 4,957 lines of Dart across 29 `lib/` files + 2 test files |
| Analysis config | `package:flutter_lints/flutter.yaml`, platform folders excluded |

The layering is deliberately flat and is sound enough to grow on:

```
main.dart
  └─ WelcomeScreen
       ├─ CustomerSignupScreen ─┐
       ├─ BusinessSignupScreen ─┼─ SignupResultScreen ─→ CustomerHomeScreen (shell)
       └─ SignInScreen ─────────┘

CustomerHomeScreen  (IndexedStack + GlassBottomNav)
  ├─ HomeTab         (bento grid, demo merchants)
  ├─ CategoriesTab   (directory, demo merchants)
  ├─ OrdersTab       (demo orders, status ladder)
  └─ ProfileTab      (demo identity, sign out)
```

## 2. Folder structure

```
lib/
  main.dart                     26   app entry (SupremeMallApp → WelcomeScreen)
  models/
    department.dart             95   the seven departments, const list, openForApplications flag
    account_role.dart           13   customer | business
  data/
    demo_data.dart             170   sample merchants + orders (UI-only data)
  services/
    account_service.dart        94   AccountService + DTOs, 900 ms fake delay, TODO(supabase)
  screens/
    welcome_screen.dart        349   entry, two account paths, department pills
    auth/
      customer_signup_screen.dart   213
      business_signup_screen.dart   320
      signup_result_screen.dart     273
      sign_in_screen.dart           146
    home/
      customer_home_screen.dart      69   shell: IndexedStack + glass nav
      tabs/home_tab.dart            555   bento grid, active order card, merchants
      tabs/categories_tab.dart      338   search + filter chips + merchant rows
      tabs/orders_tab.dart          390   Active/Past, status ladder
      tabs/profile_tab.dart         247   identity, account rows, sign out
  theme/
    app_colors.dart              57   navy/ivory/gold/emerald/sky/charcoal + dark surfaces
    app_text.dart                80   type scale
    app_theme.dart               31   minimal ThemeData (colour scheme + scaffold only)
  utils/
    validators.dart              90   phone/email/password/name — pure functions, testable
    money.dart                   16   ksh(1240) → "KSh 1,240"
  widgets/
    app_button.dart             116   AppButton, AppTextLink
    dark_surface.dart           209   darkSurface(), DarkSectionLabel/Chip/SearchField/EmptyState
    form_fields.dart            364   text/phone/password fields, terms row, ChoicePill
    glass_bottom_nav.dart       219   BackdropFilter nav, badges, animated active tab
    role_option_card.dart       101
    signup_scaffold.dart        133
    supreme_logo.dart            67
    department_pill.dart         43
test/
  welcome_screen_test.dart       60   4 widget tests
  home_screen_test.dart          73   4 widget tests
design_preview/                     static HTML mocks for review (not part of the app)
docs/                                this audit + UI direction
```

## 3. Screens and navigation

| # | Screen | Route into it | Exits |
| --- | --- | --- | --- |
| 1 | `WelcomeScreen` | app entry (`home:`) | push → customer sign-up, business sign-up, sign-in |
| 2 | `CustomerSignupScreen` | from 1 | push → sign-in; `pushReplacement` → result |
| 3 | `BusinessSignupScreen` | from 1 | push → sign-in; `pushReplacement` → result |
| 4 | `SignupResultScreen` | after sign-up | customer: `pushReplacement` → dashboard; business: `popUntil first` |
| 5 | `SignInScreen` | from 1, 2, 3 | `maybePop`; submit shows a snackbar |
| 6 | `CustomerHomeScreen` (shell) | after customer sign-up only | Profile → sign out → `popUntil first` |

Navigation gaps that matter for Milestone 2:

1. **No auth gate.** `CustomerHomeScreen` is only reachable through the sign-up result screen, but any
   route change can land there unauthenticated. There is no session check anywhere.
2. **No deep links.** Supabase email confirmation and password recovery both redirect back to the app;
   with no route table and no `site_url`/redirect URI configured for a mobile scheme, those emails
   currently lead nowhere.
3. **No back-button handling** inside the shell: Android back exits the app instead of returning to Home.
4. **No splash/session-restore screen**, so a returning user always starts at `WelcomeScreen`.

## 4. Models, services, state

- **`SupremeDepartment`** — a `const` list of the seven departments with `id`, `name`, `tagline`,
  `icon`, `accent`, `openForApplications`. Used as UI configuration *and* as the business sign-up
  category picker. It has no database counterpart yet.
- **`AccountRole`** — two-value enum with `label`/`destination` helpers.
- **`CustomerSignupRequest` / `BusinessSignupRequest` / `AccountResult`** — DTOs declared inside
  `account_service.dart`. They are the right shape for a repository, but live in a service file.
- **`AccountService`** — abstract class + `_LocalAccountService` singleton. Both methods `debugPrint`,
  wait 900 ms, and return a fabricated reference (`SM-CUS-1001`). No failure path exists, so the UI has
  no error state to render.
- **State** — every screen is a `StatefulWidget` with local `setState` fields. There is no shared app
  state, no session object, and no cached profile.

## 5. Real vs simulated vs missing

| Capability | Status | Evidence |
| --- | --- | --- |
| Brand theme (palette, type scale, dark surfaces) | **Real** | `theme/*`, const colour literals |
| Welcome screen, account paths | **Real UI** | `welcome_screen.dart` |
| Customer sign-up form + validation | **Real validation, simulated persistence** | `validators.dart` runs; `AccountService` fakes |
| Business application form + validation | **Real validation, simulated persistence** | same; department picker drives nothing |
| Business approval status | **Simulated** | `SignupResultScreen.business` prints a pseudo-reference and "1–2 business days" |
| Sign in | **UI only** | `sign_in_screen.dart` validates then shows a snackbar |
| Password reset | **UI only** | snackbar: "Password reset by SMS will be enabled…" |
| Session restore / auth gate | **Missing** | no session code anywhere |
| Dashboard shell + glass nav | **Real UI** | `customer_home_screen.dart`, `glass_bottom_nav.dart` |
| Categories directory | **Simulated data** | `demo_data.dart` (6 merchants) rendered directly by the widget |
| Orders list + status ladder | **Simulated data** | `demo_data.dart` (3 orders) |
| Profile identity | **Simulated data** | hardcoded "Wanjiku Kamau / +254 712 ••• 678" |
| Sign out | **Real, but local only** | `popUntil(isFirst)`; no backend session to clear |
| Search / filters (Categories) | **Real logic over demo data** | in-memory filter in `categories_tab.dart` |
| Cart | **Deliberately missing** | `NavTab` has 4 values; documented in the enum |
| Storefronts (shopping/food/fresh) | **Missing** | merchant rows show a snackbar |
| Payments, commissions, admin | **Missing** | no code |
| Tests | **8 widget tests, never executed** | see §0 |

## 6. Dead or incomplete interactions

These are the places where the UI offers an affordance that does nothing. Rule 16 of the brief
("avoid placeholder buttons that appear functional") applies — each must be wired or explicitly labelled.

| # | Location | Affordance | Current behaviour |
| --- | --- | --- | --- |
| 1 | Home tab | notification bell | decorative; no handler |
| 2 | Home tab | "Track" chip on the active order | decorative `Container` |
| 3 | Orders tab | "Track order" | decorative `Container` |
| 4 | Orders tab | "Reorder" | decorative `Text` |
| 5 | Categories tab | merchant row | snackbar ("storefront opens in the next milestone") |
| 6 | Profile tab | 6 account/support rows | snackbar |
| 7 | Sign-in | submit, "Forgot password?" | snackbar |
| 8 | Welcome | "Terms of Service / Privacy Policy" | plain text, not tappable |
| 9 | All auth screens | submit | no error path — cannot fail, so no error UI |

## 7. Supabase baseline (verified against the live project)

**Project:** `supreme_mall`, ref `gfqpjdtbhsipquvdfkfn`, region `eu-central-1`, PostgreSQL 17.12,
status `ACTIVE_HEALTHY`, created 2026-11-16.

**Database:** `public` schema contains **0 tables** — clean slate, no legacy to migrate.

**Auth configuration as found:**

| Setting | Value | Consequence |
| --- | --- | --- |
| Email provider | enabled | accounts are email-based |
| Phone provider | **disabled** | phone+OTP cannot be used yet |
| `mailer_autoconfirm` | **false** | new users must confirm email before signing in |
| `password_min_length` | 6 | **weaker** than the client rule (8 + letter + number) |
| `site_url` | `http://localhost:3000` | not a mobile redirect target |
| Redirect allow list | empty | confirmation/recovery links cannot return to the app |
| Refresh token rotation | enabled | session handling must not reuse old tokens |
| Signups | enabled (`disable_signup=false`) | public sign-up works for both roles |

Secrets policy: the publishable/anon key is safe in the client **only** via `--dart-define`/env;
the service-role key must never enter the repo or the app bundle. `.gitignore` currently has **no**
`.env` entry, and there is no `--dart-define` convention — both need adding in Milestone 2.

## 8. Risks and issues

Ordered by what blocks Milestone 2.

| # | Severity | Issue | Why it matters |
| --- | --- | --- | --- |
| R1 | **Blocker** | Customer sign-up treats email as **optional** (`Validators.email(required: false)`) | Supabase email auth cannot create an account without it. Phone auth is disabled, so there is no fallback |
| R2 | **Blocker** | No auth gate or session restore | The dashboard is reachable without a session; RLS will reject every query and the UI will look broken |
| R3 | High | No route table or deep links | Email confirmation and password recovery are dead ends on mobile |
| R4 | High | Simulated success paths (`AccountService`, sign-in snackbar) | Violates rule 15; must be replaced with real results **and** error states |
| R5 | High | No secret-handling convention, no `.env` in `.gitignore` | Rule 8; an anon key committed by accident is hard to walk back |
| R6 | Medium | Demo data imported directly by widgets | Must move behind repositories before M3, or Supabase swap touches many files |
| R7 | Medium | Business picks **one** department in the UI | The target architecture says "one or more". Decide now: `businesses` + `business_departments` join, or a single `department_id` column you migrate later |
| R8 | Medium | Client password policy (8+, letter+number) vs server (6) | Server is the weaker boundary — raise it in M2 |
| R9 | Medium | No duplicate-submit protection | Double taps create two requests. Harmless for sign-up, fatal for orders in M4 |
| R10 | Medium | Accessibility: many bare `GestureDetector`s, 8–9 px labels | Thumb/sunlight legibility and screen readers; `GlassBottomNav` is the only `Semantics`-annotated widget |
| R11 | Medium | No CI, and no SDK in this sandbox | Analysis/test drift goes unnoticed between milestones |
| R12 | Low | Profile identity hardcoded | Must come from the session once auth lands |
| R13 | Low | `AccountService` DTOs live inside the service file | Move to `models/` when the repository layer is introduced |

## 9. Proposed Milestone 2 plan (for approval — no code changed yet)

Split into two reviewable halves so nothing lands unreviewed.

### 2A — Foundation and schema

**Files created**

```
lib/config/env.dart                 reads --dart-define, asserts non-empty at startup
lib/services/supabase_client.dart   Supabase.initialize (auth deep-link config)
lib/services/auth_service.dart      signUpCustomer / signUpBusiness / signIn / signOut / resetPassword / session stream
lib/repositories/profile_repository.dart
lib/repositories/business_repository.dart
supabase/migrations/0001_foundation.sql
supabase/README.md                  how to apply migrations, keys, redirect URLs
```

**Files modified**

```
pubspec.yaml                        + supabase_flutter, + flutter_secure_storage (session)
.gitignore                          + .env, *.env, /supabase/.env
lib/screens/auth/*.dart             real calls, loading/error states, email-confirmation screen
lib/services/account_service.dart   deleted once repositories replace it (documented in CHANGELOG note)
```

**Migration `0001_foundation.sql`** (one atomic migration, idempotent, applied via the Supabase connector)

- `departments` — `id text pk`, `name`, `short_name`, `sort_order`, `is_active bool`, seeded with the
  seven departments (Shopping/Food/Fresh active, the rest inactive).
- `profiles` — `id uuid pk references auth.users on delete cascade`, `full_name`, `phone`, `role text
  check in ('customer','business_owner','admin') default 'customer'`, `created_at`, `updated_at`.
- `businesses` — `id uuid pk`, `owner_id uuid references profiles`, `name`, `phone`, `email`, `area`,
  `status business_status default 'pending'`, `reviewed_at`, `reviewed_by`, `rejection_reason`,
  timestamps.
- `business_departments` — `(business_id, department_id)` composite pk → **supports one or more
  departments** (resolves R7 without a later migration).
- `business_documents` — metadata only (`doc_type`, `storage_path`, `uploaded_at`); no document
  contents in text columns, per the brief.
- Enums: `business_status`; helper `public.is_admin(uuid)` as `security definer`.
- Trigger `on auth.users insert` → create the `profiles` row (`security definer`) so a user can never
  exist without a profile, and cannot self-assign a role.
- `set_updated_at()` trigger on `profiles` and `businesses`.
- Indexes: `businesses(owner_id)`, `businesses(status)`, `business_departments(department_id)`.
- **RLS enabled on every table**, with policies:
  - `profiles`: select/update own row; role column not updatable by the client.
  - `businesses`: select/insert/update own (`owner_id = auth.uid()`); `status` may not be changed by
    the owner — enforced by a `BEFORE UPDATE` trigger, not just by hiding UI.
  - `business_departments`, `business_documents`: access only through business ownership.
  - `departments`: readable by any authenticated user where `is_active`.
  - Admin operations: later milestone, via `is_admin()`.
  - Customers can never approve a business: no policy permits it.

### 2B — Auth wiring

- `AuthGate` widget at the root: `Session? → WelcomeScreen | CustomerHomeScreen`.
- Real sign-up for both roles; business insert forced to `pending`; UI distinguishes
  "account created" from "business awaiting approval".
- Email confirmation screen ("check your inbox") since `mailer_autoconfirm` is false.
- Sign-in, sign-out (clears session), password reset email flow.
- Session restore on launch (Supabase persists; gate reads the restored session).
- Friendly mapping of Supabase error codes → inline field errors, never a silent failure.
- Tests: validators (unit), error-mapping (unit), `AuthGate` (widget), plus SQL RLS checks:
  two test users cannot read each other's rows; a business owner cannot set `status='approved'`.

### Configuration I will need from you

- Confirm the redirect scheme (e.g. `com.suprememall.app://login-callback`) — I will add it to the
  Supabase redirect allow list and to the Android/iOS manifests.
- If you want phone OTP later, an SMS provider (Twilio/TextLocal) must be configured; it is currently
  off, and Kenyan SMS costs money, so email auth first is cheaper.

## 10. Decisions needed before I start Milestone 2

1. **Email mandatory for customers?** Recommended: yes (email is the Supabase identity; keep phone for
   M-Pesa and rider contact). Alternative is enabling phone auth + an SMS provider.
2. **Email confirmation during development?** Currently required. Recommended: keep it ON in
   production, but you may want it OFF while testing on an emulator — one setting, your call.
3. **One department or several per business?** Recommended: several (join table now, no later migration).
4. **How is the first administrator created?** Recommended: a manual SQL update to one seeded account
   (`profiles.role='admin'`); no self-service admin sign-up, ever.
5. **Add `go_router` + `supabase_flutter`?** Both are justified: deep links for confirmation/reset, and
   the official client. Alternative is hand-rolled navigation (more code, more risk).
6. **Raise Supabase `password_min_length` to 8** and keep the client rule (letters + numbers)?

Once you approve these — and the Milestone 2 plan above — I will implement 2A first, report, and wait.

---

## Appendix — commands

```bash
# baseline (run locally; not possible in this sandbox)
flutter pub get
dart format .
flutter analyze
flutter test
flutter run

# after 2A/2B
flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```
