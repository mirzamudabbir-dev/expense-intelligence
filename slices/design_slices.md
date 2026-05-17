# Design Slices — Screen-by-Screen UI Specs

Each slice = one screen. Implement in order. No slice depends on a later one.

---

## SLICE 1 — Splash + Onboarding

**Route**: `/splash` → `/onboarding` → `/auth`

### Splash
- Full screen `bg-primary`
- App logo centered (text: "spent" in Inter 700, 36px, `text-primary`)
- Subtle fade-in animation, 400ms
- Auto-navigate after 1.5s

### Onboarding (3 slides — PageView)
Slide layout:
- Top 60%: Illustration area (use simple SVG/Lottie icons, no heavy assets)
- Bottom 40%: Title (heading1) + subtitle (body, `text-secondary`)
- Bottom: Page dots + "Continue" button + "Skip" text link

Slide content:
1. **Track instantly** — "Add expenses in under 5 seconds."
2. **See your patterns** — "Beautiful charts that make sense of your spending."
3. **Stay on budget** — "Set limits. Know where you stand."

"Continue" button: Full-width, `accent` background, white text, radius-xl, height 52px.

---

## SLICE 2 — Auth Screen

**Route**: `/auth`

### Layout
- Background: `bg-primary`
- Top: App name "spent" (heading1, centered, 48px from top)
- Tagline: "Your money, clearly." (`text-secondary`, body)
- 40px gap
- Email input
- Password input
- 16px gap
- Primary button: "Sign In" / "Create Account"
- 24px gap
- Toggle text: "Don't have an account? Sign up" (tap switches mode)

### Behavior
- Single screen toggles between Sign In and Sign Up
- Sign Up adds "Confirm Password" field
- Show/hide password toggle (eye icon)
- Loading state on button: spinner replaces text
- Error: red text below field, not toast

---

## SLICE 3 — Dashboard (Home)

**Route**: `/home`

### Layout — Scroll view, no AppBar (custom header)

**Header Section** (non-scrollable overlay or top of scroll)
- Left: Avatar/initials circle (32px) + "Good morning, [name]"
- Right: Bell icon (notifications — non-functional MVP)
- Padding: 20px horizontal, 16px top (+ safe area)

**Monthly Card** (full-width card, `bg-surface`)
- Label: "October spending" (`text-secondary`, label)
- Amount: "₹24,500" (`display`, `text-primary`)
- Subtext: "₹5,500 remaining of ₹30,000 budget" (`text-secondary`, caption)
- Progress bar below (full width within card, 6px height, rounded)
- Padding: 20px

**Today's Card** (same row as... actually full-width, below monthly)
- Smaller card
- "Today" label
- Amount: "₹840"
- X transactions count

**Category Breakdown** (horizontal scroll row)
- Section title: "This month" (heading2)
- Horizontally scrollable category chips with amount
- Each chip: icon + category name + amount
- Tap → filter transaction list (MVP: navigate to history with filter)

**Weekly Chart**
- Section title: "This week"
- Simple bar chart (7 bars, Mon–Sun)
- Active day bar: `accent`, others: `bg-elevated`
- Y-axis: none. Amounts as tooltip on tap only.
- Height: 120px
- Use `fl_chart` package

**Recent Transactions**
- Section title: "Recent" + "See all" link (right-aligned, `accent`, label)
- Last 5 transactions as `TransactionTile`
- Each tile: category icon (colored) + title/note + date + amount
- Amount: right-aligned, `text-primary`, mono font

**Bottom FAB padding**: 80px at list bottom so FAB doesn't cover last item.

---

## SLICE 4 — Quick Add Expense (Bottom Sheet)

**Trigger**: FAB tap

### Layout — Modal bottom sheet, 90% screen height
- Handle bar at top
- Title: "Add Expense" (heading2, centered)
- 24px gap

**Amount Field** (hero element)
- Large centered number input
- Font: 40px, mono, `text-primary`
- Prefix: "₹" (same size, `text-secondary`)
- Keyboard: numeric (auto-opens)
- Cursor blinks in `accent`

**Below amount — row of inputs (card-style grouped)**
- Category selector (dropdown/sheet): shows icon + name
- Note field: text input, placeholder "What was this for?"
- Date: defaults to today, tap to change (DatePicker)
- Payment method: Cash / UPI / Card (3 chips, select one)

**Save Button**
- Full-width, `accent`, "Save Expense"
- Disabled until amount > 0
- On save: sheet dismisses + brief success haptic + transaction appears in list

### Category Selector (nested bottom sheet)
- Grid: 3 columns, 9 categories
- Each cell: icon (32px) + label below
- Selected: `accent-muted` background + `accent` border
- Dismiss on select

---

## SLICE 5 — Transaction History

**Route**: `/history`

### Header
- Back button (if navigated) or title "Transactions"
- Search bar (always visible, not collapsed)
- Filter row below search: horizontal chips for categories + "This month" date chip

### List
- Grouped by date: date header (label, `text-secondary`) + list of transactions
- Each `TransactionTile`:
  - Leading: colored circle with category icon (40px)
  - Title: note (or category name if no note)
  - Subtitle: time + payment method
  - Trailing: amount (mono, `text-primary`)
  - Long press → context menu (Edit / Delete)

### Empty State
- Centered icon + "No transactions yet"
- "Add your first expense" button

### Delete
- Swipe left to reveal red delete button (iOS style)
- Confirmation: simple snackbar with "Undo" action

---

## SLICE 6 — Analytics

**Route**: `/analytics`

### Layout — Scroll view

**Period Selector**
- 3 chips: Week / Month / Year
- Defaults to Month

**Summary Row** (3 equal cards in a row)
- Total Spent
- Daily Average  
- Top Category

**Monthly Comparison Chart**
- Bar chart: last 6 months
- Current month: `accent`, others: `bg-elevated`
- X-axis: month name abbreviations
- Height: 180px

**Category Breakdown** (full section)
- Title: "Spending by Category"
- List of categories with:
  - Color dot + name
  - Progress bar (relative to total)
  - Amount + percentage
- Sorted by highest spend

**Spending Trend**
- Line chart: daily spending for selected period
- Color: `accent`
- Fill below line: `accent` at 10% opacity
- Height: 160px

---

## SLICE 7 — Budget Screen

**Route**: `/budget` (accessible from Settings or Dashboard card tap)

### Layout

**Monthly Budget Card** (full-width)
- Big ring/donut chart: center shows "₹X remaining"
- Below ring: "₹X spent of ₹Y budget"
- Ring color follows budget status (accent/warning/error)

**Set Budget** button (if no budget set)
- Opens bottom sheet with amount input

**Per-Category Budgets** (optional MVP+ — skip if time)

**Edit Budget**
- Tap pencil icon on card → inline edit or bottom sheet

---

## SLICE 8 — Settings

**Route**: `/settings`

Simple list screen:

- **Account**: Email display, Sign Out
- **Budget**: "Set Monthly Budget" → budget screen
- **Currency**: INR default (single option MVP)
- **Notifications**: toggle (non-functional MVP)
- **App Version**: x.x.x

Destructive: "Sign Out" in `error` color, at bottom.

---

## Component Library (Reusable)

### `TransactionTile`
```
Props: transaction, onTap, onDelete
```

### `AmountDisplay`
```
Props: amount, currency, size (sm/md/lg)
```

### `CategoryChip`
```
Props: category, selected, onTap
```

### `BudgetProgressBar`
```
Props: spent, total, showLabel
```

### `SectionHeader`
```
Props: title, actionLabel, onAction
```

### `AppCard`
```
Props: child, padding
(wraps with bg-surface + border + radius-md)
```

### `PrimaryButton`
```
Props: label, onPressed, isLoading, isDisabled
```

### `AppInput`
```
Props: label, hint, controller, keyboardType, suffix
```
