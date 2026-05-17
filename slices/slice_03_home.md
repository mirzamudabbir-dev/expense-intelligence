# Slice 03 — Home / Dashboard

Route: `/home`

---

## Layout

No AppBar. Single `CustomScrollView` with `SliverList`. Horizontal margin: 20px throughout.

---

## Section 1 — Header (non-sticky, top of scroll)

- Left: initials circle (32px, `bg-elevated`, `accent` text, label size) + "Good morning, [first name]" (body, `text-secondary`), 8px gap between
- Right: bell `Icon` (24px, `text-secondary`)
- Padding: 20px horizontal, 16px top + safe area top

---

## Section 2 — Monthly Budget Card

Full-width `AppCard` (bg-surface, 1px border, radius-md 12px, padding 20px).

Contents (top to bottom):
- Label: "October 2025" — label size, `text-secondary`
- Amount: "₹24,500" — display size (32px, 700, mono), `text-primary`, 4px below label
- Subtext: "₹5,500 remaining of ₹30,000" — caption, `text-secondary`, 8px below amount
- 12px gap
- `BudgetProgressBar`: full width, height 6px, rounded-full
  - Fill: `accent` if < 80%, `warning` if 80–99%, `error` if ≥ 100%
  - Animate width from 0 on first render: 600ms easeOutQuart
- If no budget set: hide subtext and progress bar, show "Set a budget →" caption in `accent`

---

## Section 3 — Today Card

Full-width `AppCard`, padding 16px. Below monthly card, 12px gap.

- Row: left side "Today" (label, `text-secondary`) + right side amount "₹840" (heading2, mono, `text-primary`)
- Caption below: "3 transactions" (`text-secondary`, caption)

---

## Section 4 — Category Breakdown

- `SectionHeader`: title "This month", no action
- 8px gap
- Horizontal `SingleChildScrollView`, row of `CategoryChip` widgets
  - Each chip: category icon (16px) + name + " ₹X" amount
  - Chips ordered by spend descending
  - Scrolls horizontally, no snap

---

## Section 5 — Weekly Chart

- `SectionHeader`: title "This week", no action
- 8px gap
- `AppCard`, padding 16px
- `BarChart` via `fl_chart`, height 120px
  - 7 bars: Mon–Sun
  - Active day (today): `accent` fill; others: `bg-elevated`
  - No Y-axis labels, no grid lines
  - Show amount as tooltip on tap only
  - X-axis: 3-letter day names, caption size, `text-tertiary`

---

## Section 6 — Recent Transactions

- `SectionHeader`: title "Recent", action "See all" → `context.push('/history')`
- 8px gap
- Last 5 expenses as `TransactionTile` list
- 80px bottom padding (FAB clearance)

---

## FAB

- Position: `FloatingActionButton`, centered bottom, 24px above bottom nav
- Size: 56×56, circular, `accent` background
- Icon: `Plus`, 24px, white
- Box shadow: `BoxShadow(color: accent.withOpacity(0.3), blurRadius: 20, spreadRadius: 0)`
- onPressed: `showModalBottomSheet` → `AddExpenseSheet`

---

## Data

All from `ExpensesNotifier` (Supabase realtime stream).  
Budget from `BudgetNotifier` (Supabase query).  
Monthly total and today total: computed from expense list in provider.  
Weekly chart data: last 7 days grouped by date, computed locally.
