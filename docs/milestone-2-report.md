# Milestone 2 — Supabase foundation and real authentication

**Status:** implementation complete, awaiting your review.
**Branch:** `arena/8128ca02-supreme-mall`
**Date:** 13 November 2026
**Depends on:** `docs/milestone-1-audit.md`

---

## 1. What you asked for

From the milestones brief, Milestone 2 is *"Supabase setup and real authentication"*: a
live database with least-privilege rules, real sign-up and sign-in for both customers
and businesses, and an app that no longer pretends to save things.

Everything below is that. No later-milestone features were pulled forward, and nothing
is stubbed: the flows hit the real project or they fail loudly.

---

## 2. What is live in Supabase

Project **supreme_mall** (`gfqpjdtbhsipquvdfkfn`), eu-central-1, Postgres 17.12,
ACTIVE_HEALTHY. Migration **`0001_foundation`** applied and recorded as version
`20261116114431` (confirmed via `list_migrations`; the "version: null" returned when it
was queued was just the queue response, not the apply result).

| Table | Rows | Policies | RLS |
| --- | --- | --- | --- |
| `departments` | 7 (3 active) | 1 | on |
| `profiles` | 0 | 2 | on |
| `businesses` | 0 | 4 | on |
| `business_departments` | 0 | 3 | on |
| `business_documents` | 0 | 3 | on |

13 policies in total, plus 6 functions (`is_admin`, `set_updated_at`,
`guard_business_update`, `guard_profile_update`, `handle_new_user`, plus Supabase's own
`rls_auto_enable`), 2 enums (`app_role`, `business_status`) and 5 triggers.

The deployed schema is committed for review as
[`supabase/migrations/0001_foundation.sql`](../supabase/migrations/0001_foundation.sql) —
a snapshot of what actually runs, including the seed data, trigger definitions and every
policy predicate.

### Department ids match the app

`shopping`, `food`, `fresh` are `is_active`; `rides`, `boda`, `errands`, `home` are
seeded but inactive — the same seven ids already used by `lib/models/department.dart`, so
the "soon" badges in the UI and the database agree.

---

## 3. Security model (and proof it works)

Rules, all enforced in the database rather than the client:

- **Credentials never touch our tables.** `profiles` has no password column; Supabase
  Auth owns the hash.
- **A user cannot change their own role.** A trigger rejects it.
- **A business owner cannot approve themselves.** Review fields (`status`,
  `reviewed_at`, `reviewed_by`, `rejection_reason`) are writable only by an admin, via a
  trigger; the insert policy also refuses any new row that is not `pending`.
- **Rows are private.** Owners see their own profile/business/documents; `departments`
  is the only table readable by anonymous users.
- **Fake signups are not possible from the client.** The role comes from sign-up
  metadata, and `handle_new_user` maps `account_type` to either `customer` or
  `business_owner` — nothing else.

I did not stop at "the tables exist". I created throwaway users, ran the app's exact
queries as those users, and deleted them afterwards. Results:

| Probe | Result |
| --- | --- |
| New auth user → profile row | `customer / Probe Customer / +254712000001` |
| Customer sees rows in `profiles` | 1 (own only) |
| Customer sees rows in `businesses` | 0 |
| Customer reads `departments` | 7 |
| Customer tries `role = 'admin'` | **blocked** — "Role is managed by Supreme Mall" |
| Owner creates a business | created, `status = pending` |
| Owner links a department | linked |
| Owner inserts a business with `status = 'approved'` | **blocked** — RLS violation |
| Owner inserts a business for a different `owner_id` | **blocked** — RLS violation |
| Owner sets own business to `approved` | **blocked** — "Only an administrator can change review fields" |
| Owner edits own business name | allowed — `Probe Cafe Renamed` |
| Owner reads its department link | `Supreme Food` |
| Second business account's role | `business_owner` |
| Second owner sees the first owner's business / documents | 0 / 0 |
| Anonymous reads `departments` / `profiles` / `businesses` / `business_documents` | 7 / 0 / 0 / 0 |
| Cleanup | 0 profiles, 0 businesses, 0 links left |

No test data was left in the project.

---

## 4. Auth configuration

| Setting | Value | Why |
| --- | --- | --- |
| Email provider | on | Email is the account identity |
| Phone provider | off | SMS costs money; phone is captured as data and verified later |
| Auto-confirm | **on** | No custom SMTP / no domain yet, per your direction |
| Redirect allow list | `com.suprememall.app://**`, `http://localhost:3000/**` | Ready for the deep link |
| Refresh token rotation | on | Standard hardening |
| Password floor | 6 (Supabase-side) | Client requires 8 + letter + number, so real users meet the stricter rule |

---

## 5. What changed in the app

### New

| File | Purpose |
| --- | --- |
| `lib/config/env.dart` | Reads `SUPABASE_URL` / `SUPABASE_ANON_KEY` from `--dart-define` |
| `lib/config/app_config.dart` | Review window, support address |
| `lib/services/supabase_bootstrap.dart` | Initialises Supabase once, exposes the shared `AuthService` |
| `lib/services/auth_service.dart` | Sign up (customer + business), sign in, sign out, reset, profile, own business |
| `lib/models/app_profile.dart` | `profiles` row (initials, first name, business flag) |
| `lib/models/business_application.dart` | `businesses` row + `BusinessStatus` enum |
| `lib/utils/auth_errors.dart` | Supabase error code → sentence a customer understands |
| `lib/screens/auth/auth_gate.dart` | Root: session decides welcome / dashboard / business status |
| `lib/screens/business/business_status_screen.dart` | Real pending/approved/rejected state, pull to refresh |
| `lib/screens/config_missing_screen.dart` | Explains a build with no credentials |
| `lib/widgets/error_banner.dart` | Inline form errors that stay on screen |
| `env.example.json`, `supabase/migrations/0001_foundation.sql` | Configuration shape + deployed schema |
| `test/auth_errors_test.dart`, `test/models_test.dart` | Unit tests for error mapping and models |

### Changed

- `lib/main.dart` — initialises Supabase, then `AuthGate`; a `home` override keeps the
  widget tests honest. No credentials in code.
- `lib/screens/auth/customer_signup_screen.dart` — real account creation; **email is now
  required** (it is the login identity), phone kept for M-Pesa and rider contact.
- `lib/screens/auth/business_signup_screen.dart` — creates the user, then the business
  row and its department link; handles the email-confirmation case honestly.
- `lib/screens/auth/sign_in_screen.dart` — real `signInWithPassword`, working password
  reset, inline errors; the customer/business toggle is gone because the role now comes
  from the database.
- `lib/screens/auth/signup_result_screen.dart` — no invented reference numbers; copy
  matches what the database actually did.
- `lib/screens/home/customer_home_screen.dart`, `tabs/home_tab.dart`, `tabs/profile_tab.dart`
  — identity is the signed-in person (greeting, initials, phone, account type); sign out
  ends the session.
- `.gitignore` — `env.json`, `*.env`, `.env`.
- `README.md` — run instructions, schema summary, honest limitations.

### Deleted

`lib/services/account_service.dart` — the simulated service and its DTOs. Its job is now
`AuthService`; leaving it would have created the duplicate service the brief forbids.

---

## 6. Risks from the audit, updated

| # | Risk | Status |
| --- | --- | --- |
| R1 | Customer sign-up email optional vs email-only auth | **Fixed** — email is required and validated |
| R2 | No auth gate | **Fixed** — `AuthGate` routes on the real session |
| R3 | No route table / deep links | Partly: the gate removes ad-hoc navigation; a route table is still not needed at this size |
| R4 | Simulated success paths | **Fixed** for auth — `AccountService` is gone |
| R5 | No `.env` convention | **Fixed** — `--dart-define-from-file`, git-ignored |
| R6 | Demo data imported by widgets | Open — deliberate; Milestone 3 replaces it with the catalogue |
| R7 | One-vs-many departments | **Fixed** — `business_departments` join table; the UI still asks for one, by design |
| R8 | Password policy mismatch | Improved — client enforces 8 + letter + number; the database floor stays 6 because the connector cannot change it |
| R9 | No double-submit guard | **Fixed** — every submit disables while `_submitting` |
| R10 | Accessibility | Open — labels still 8–10 px in places; scheduled with the design-token pass |
| R11 | No CI, no SDK here | Open — see §7 |
| R12 | Hardcoded profile identity | **Fixed** — real `profiles` row |
| R13 | DTOs inside the service file | **Fixed** — models are separate files |

---

## 7. What I could and could not verify

**Verified against the live project:** schema, policies, triggers, seed data, and the
behaviour of the rules in §3, all by querying and acting as real authenticated users.

**Not verified:** `flutter pub get`, `flutter format`, `flutter analyze` and
`flutter test`. There is no Flutter or Dart SDK in this sandbox and no route to install
one, so I did not run them and will not claim the code compiles. What I did instead:
balanced-delimiter checks across all 42 Dart files, a manual read of every changed file
against the existing widget APIs, and 12 widget/unit tests plus 11 new unit assertions
written to cover the new paths.

Please run this before merging:

```bash
cp env.example.json env.json     # paste URL + publishable key
flutter pub get
flutter analyze
flutter test
flutter run --dart-define-from-file=env.json
```

Then, on a device: sign up as a customer → dashboard greets you by name; sign out; sign
up as a business → "pending review" screen; sign in as each again → each lands in the
right place.

---

## 8. Decisions worth your attention

1. **Password reset is only half a loop today.** The app really calls Supabase, but the
   emailed link points at a redirect page that does not exist yet, and the built-in
   mailer only delivers to project members. The dialog says so and points to support.
   This closes when custom SMTP + a hosted reset page land pre-pilot.
2. **Customers cannot read `businesses` yet.** No public read policy exists until the
   catalogue needs one (Milestone 3). I would rather add it with the feature that uses
   it than ship an untested surface.
3. **Email confirmation stays off**, as instructed. When it returns, it should be the
   6-digit OTP you asked for — the client already branches to a "check your email" path
   if a session is not returned, so that change will not break the flow.
4. **One department per application.** The database supports many; the form asks for one
   so merchants choose their primary service. Multi-department can be added later
   without a migration.

---

## 9. Next

Milestone 3 — catalogue and storefronts: products, categories inside departments, images,
pricing, and the first customer-facing read policies. I have not started it, per your
rule that each milestone is reviewed before the next begins.
