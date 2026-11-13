# Supreme Mall — UI direction (research + recommendation)

Prepared before any further coding. Sources: Dribbble "ecommerce mobile app ui" collection,
reference shots pulled from Dribbble/Pinterest, and 2026 UI trend write-ups.

Live visual comparison: `design_preview/style_options.html` (three directions side by side).

---

## 1. What the references actually do

### Pattern A — Grocery / marketplace app screens (light, single brand colour)
The dominant ecommerce-mobile pattern on Dribbble right now:

- **Bottom navigation with 4–5 tabs**: Shop · Cart · Favourites · Profile · More
- **Location + search pinned at the top**, search as a full-width rounded field
- **Category circles** or compact chips, not a giant banner carousel
- **Product cards**: image, name, *unit price*, discount chip, quantity stepper inline
- **Sticky cart summary bar** at the bottom of listing screens ("Subtotal … Check out")
- Checkout as a *single scrollable page* with the total pinned — no multi-step wizard

### Pattern B — Super-app service grid
- Services as a **bento grid of large tiles**, each tile one job, sized by importance
- **Location selector** ("Nyeri Town ▾") in the header of every service screen
- **Active request card** at the top with a status chip ("Pending", "On the way")
- Icon-in-rounded-square on every tile — the shape carries the visual rhythm

### Pattern C — 2026 trend layer
- **Bento grids are mainstream**, not experimental — hierarchy through tile size [1](https://www.sanjaydey.com/ux-ui-design-trends-2026-biggest/)
- **Bottom-anchored navigation** replaces top tabs for consumer apps; 48dp minimum targets [1](https://www.sanjaydey.com/ux-ui-design-trends-2026-biggest/)
- **Semantic colour tokens** (colour by *role*, not hex) rather than hard-coded values [4](https://spunk.pics/blog/ui-design-trends-2026)
- **Responsible glassmorphism**: depth to show hierarchy, never as wallpaper [2](https://mediaplus.com.sg/ui-trends/)
- **Variable fonts** instead of 4+ static weights
- Baymard's benchmark: 71% of mobile commerce apps rate mediocre or worse [1](https://www.sanjaydey.com/ux-ui-design-trends-2026-biggest/) — the bar is low, so execution beats novelty

---

## 2. Three directions for Supreme Mall

### A · Civic Trust — flat, structured, bank-like
Navy header, ivory body, hairline borders, no shadows, 11px radii, gold as a thin status
rule only. Reads official and reliable.

- **Best for:** M-Pesa money movement, dispute/support flows, admin-adjacent screens
- **Weak for:** consumer warmth; can feel like a government portal

### B · Warm Marketplace — editorial, photographic
Cream surface, 18–20px radii, soft warm shadows, gold hero CTAs, big promo card per department.

- **Best for:** Supreme Food and Supreme Fresh — it sells the produce
- **Weak for:** image-led layouts are heavy on data and don't suit Rides/Errands/Home

### C · Dark Bento — super-app, glass, colour-coded
Deep navy canvas, bento tiles, coloured icon chips, gold live-accents, floating nav.

- **Best for:** showing seven departments at once; modern, matches Grab/Gojek mental model
- **Weak for:** sunlight legibility, low-end LCDs, and data-light users

---

## 3. Recommendation — "Brand chrome, light content" (A + C hybrid)

1. **Navy is chrome, not canvas.** Navy header/hero, navy bottom nav, navy primary buttons.
   The working surface stays **Ivory `#F8FAFC`** — sunlight legibility, faster render on 2G/3G,
   and the ivory/navy contrast is the brand's strongest visual signature.
2. **Bento service grid** (from C): 1 hero tile + 3 medium Phase 1 tiles + 4 small "soon" tiles.
   All seven departments visible on a 5-inch screen without a cluttered 7-up grid.
   `grid_column: span 2` for hero, so it collapses to a single column gracefully.
3. **Department accents used as identity, not decoration.** Shopping = navy, Food = gold,
   Fresh = emerald, Rides = sky. Accent appears on the icon chip and the status pill only.
   This lets users navigate by colour after a week of use.
4. **Gold is scarce.** Primary CTA and "live/now" states only. If everything is gold, nothing is.
5. **Tokens before screens.** Extend `app_colors.dart` into semantic tokens
   (`surface`, `surfaceRaised`, `border`, `inkPrimary`, `inkMuted`, `accentLive`) so dark mode
   is a token swap later rather than a redesign.

### Component spec to implement

| Element | Decision |
| --- | --- |
| Bottom nav | 5 tabs: Home · Orders · Cart · Alert · Account. 56dp tall, 24dp icons, badge on Cart |
| Header | Sticky: location pill (`Nyeri Town ▾`) + notification bell, then full-width search |
| Service grid | 2-column bento, 12dp gutters, 16dp radius tiles, 40×40 icon chip |
| Product card | Image 1:1 (cached, skeleton placeholder), name 2 lines max, **unit chip** (`kg`/`bunch`/`crate`/`piece` — required by Brief §4.3), price bold, add button |
| Quantity | Inline − / + stepper, 40dp targets, optimistic local state |
| Cart | Sticky bottom bar with subtotal + item count; opens full-screen cart sheet |
| Status | Pill with dot: Received · Preparing · Ready · On the way · Delivered |
| Money | Always `KSh 1,240` format, right-aligned, tabular figures |
| Type | One variable font family, 3 weights (Regular 400 / SemiBold 600 / ExtraBold 800). Recommend **Plus Jakarta Sans** or **Manrope**; fallback Roboto |
| Radii | 16dp cards, 12dp inputs, 14dp buttons, 100dp pills |
| Elevation | One soft shadow (`0 10px 26px rgba(11,45,91,.08)`); no stacked shadows |
| Motion | 140–200ms ease-out for state change; no decorative animation on listing screens |
| Loading | Skeleton shimmer, never a blank screen or a spinner over content |
| Errors | Inline under the field; never a toast for something the user must fix |

### Deliberately avoided
- Neumorphism and heavy glassmorphism walls
- Emoji as product/UI icons (they render differently per Android OEM)
- Full dark-mode default at launch (design the tokens now, ship it in Phase 2)
- Carousels as the primary navigation for services — they hide 5 of 7 departments
- Multi-step checkout wizards — single scrollable checkout with pinned total

---

## 4. Suggested build order after the choice

1. Customer home / service hub (the bento grid above) — reuses the existing theme
2. Supreme Food storefront + menu item (simplest full loop, per earlier recommendation)
3. Cart + single-page checkout with itemised totals (Roadmap §7.2 requires the breakdown)
4. Order status timeline
5. Replicate 2–4 for Shopping and Fresh
6. Merchant dashboard (web, per brief §6)
