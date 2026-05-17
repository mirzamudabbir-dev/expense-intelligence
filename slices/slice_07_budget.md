# Slice 07 — Budget Screen

Route: `/budget`  
Access: Settings → "Monthly Budget" or tapping budget card on Home

---

## Layout

`Scaffold`, custom back-header (if pushed), `SingleChildScrollView`, 20px horizontal margin.

---

## Header

- Back button + title "Budget" — heading2, `text-primary`
- 24px top + safe area

---

## Section 1 — Budget Ring Card

Full-width `AppCard`, padding 24px, centered contents.

**If budget is set:**
- `CustomPaint` or `fl_chart` `PieChart` (donut style):
  - Outer radius ~80px, stroke width ~12px, hole ~68px
  - Filled arc: budget status color (`accent` / `warning` / `error`)
  - Remaining arc: `bg-elevated`
  - Center text: "₹X\nremaining" — amount in heading1 mono `text-primary`, label "remaining" in caption `text-secondary`
  - Animate arc from 0 on mount: 700ms easeOutQuart
- Below ring (16px gap):
  - "₹X spent of ₹Y" — body, `text-secondary`
  - "X% used" — label, status color
- Edit button: icon-only pencil button top-right of card

**If no budget set:**
- Icon: `Target`, 48px, `text-tertiary`
- Text: "No budget set" — body, `text-secondary`
- 16px gap
- "Set Budget" button: full-width, `accent`, height 52px

---

## Section 2 — Set / Edit Budget (Bottom Sheet)

Opened by "Set Budget" button or pencil icon.

Sheet contents:
- Title: "Set Monthly Budget" — heading2, centered
- 24px gap
- Label: "Monthly limit" — label, `text-secondary`
- Amount input: large, mono, 40px font, `text-primary`, numeric keyboard, "₹" prefix
  - Pre-filled with current limit if editing
- 24px gap
- "Save Budget" button: full-width, `accent`, height 52px
  - Writes to Supabase `budgets` table directly (not FastAPI)
  - Uses current month + year
  - UPSERT (insert or update on conflict user_id + month + year)

---

## Budget Status Colors

| Usage | Color |
|---|---|
| < 80% spent | `accent` (#00C896) |
| 80–99% spent | `warning` (#FF9F0A) |
| ≥ 100% spent | `error` (#FF453A) |

---

## Data

Budget record from Supabase `budgets` table (direct query).  
Monthly spent total from `ExpensesNotifier` (computed locally).  
No FastAPI call needed for this screen.
