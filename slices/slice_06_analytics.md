# Slice 06 — Analytics Screen

Route: `/analytics` (tab 2 in MainShell)

---

## Layout

`Scaffold`, no AppBar. `SingleChildScrollView`, horizontal margin 20px.

---

## Header

- Title: "Analytics" — heading1, `text-primary`, 20px top + safe area
- 16px gap
- Period selector: 3 chips in a row — "Week" / "Month" / "Year"
  - Selected: `accent-muted` + `accent` border + `accent` text
  - Unselected: `bg-elevated` + `border` + `text-secondary`
  - onTap: update provider, reload data

---

## Section 1 — Summary Row

3 equal-width `AppCard`s in a `Row` (use `Expanded`), 8px gap between.

Each card (padding 12px, centered):
- Value: heading2, mono, `text-primary`
- Label: caption, `text-secondary`, 4px below value

Cards:
1. Total Spent — "₹24,500"
2. Daily Avg — "₹816"
3. Top Category — category name (label size, category color)

---

## Section 2 — Monthly Comparison Chart

- `SectionHeader`: "Last 6 Months", no action
- 8px gap
- `AppCard`, padding 16px
- `BarChart` via `fl_chart`, height 180px
  - 6 bars: oldest → current month
  - Current month bar: `accent` fill; others: `bg-elevated`
  - No Y-axis. X-axis: 3-letter month abbreviation, caption, `text-tertiary`
  - Bar width: proportional, corner radius 4px (top only)
  - Tooltip on tap: show "₹X" in `bg-elevated` card

---

## Section 3 — Category Breakdown

- `SectionHeader`: "By Category", no action
- 8px gap
- List of categories with spend (sorted descending, only show categories with > 0 spend)

Each row (16px vertical padding, no card — just list):
- Leading: colored dot (10px circle, category color)
- Category name: body, `text-primary`, 8px after dot
- Trailing: "₹X" (body, mono, `text-primary`) + " · X%" (caption, `text-secondary`)
- Full-width progress bar below the row text: height 4px, track `bg-elevated`, fill = category color, width = percentage of total
- 8px gap between rows

---

## Section 4 — Daily Spending Trend

- `SectionHeader`: "Daily Trend", no action
- 8px gap
- `AppCard`, padding 16px
- `LineChart` via `fl_chart`, height 160px
  - Line color: `accent`
  - Fill below line: `accent` at 10% opacity (`AreaChartData`)
  - No Y-axis labels. X-axis: day abbreviation or date, caption, `text-tertiary`
  - Dot: 4px circle, `accent`, only on data points
  - Tooltip on tap: "₹X"

---

## Data Source

Call FastAPI: `GET /analytics/monthly?month=X&year=Y` (or weekly/yearly based on period selector).

Show `CircularProgressIndicator` (centered, `accent` color) while loading.  
Show "Could not load data. Tap to retry." on error.

16px bottom padding at end of scroll.
