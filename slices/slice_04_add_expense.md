# Slice 04 — Add Expense Bottom Sheet

Trigger: FAB on Home screen  
Widget: `AddExpenseSheet` — modal bottom sheet

---

## Sheet Setup

```dart
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  useSafeArea: true,
  builder: (_) => const AddExpenseSheet(),
);
```

Background: `bg-surface` (#161618)  
Top corners: radius-lg (16px)  
Handle: 4×36px, color `border`, centered, 12px from top

---

## Layout (top to bottom, padding 20px horizontal)

**Handle bar** — centered, 12px top margin

**Title** — "Add Expense", heading2, centered, 20px below handle

**Amount Field** (hero element) — 24px below title
- Row: "₹" prefix (40px, mono, `text-secondary`) + number input
- Input: 40px font, mono, `text-primary`, no border/background — raw text field
- Keyboard: `TextInputType.numberWithOptions(decimal: true)` — auto-opens on sheet open
- Cursor color: `accent`
- Placeholder: "0" in `text-tertiary`
- Auto-focus on sheet open:
  ```dart
  WidgetsBinding.instance.addPostFrameCallback((_) => _amountFocus.requestFocus());
  ```

**Field Group** — `AppCard` containing stacked rows, 24px below amount

Row 1 — Category:
- Leading: category icon (20px, category color) + category name (body, `text-primary`)
- Trailing: chevron-right icon (`text-tertiary`)
- onTap: open `CategorySelectorSheet` (see below)

Divider: 1px `border`

Row 2 — Note:
- `TextField`, no decoration, placeholder "What was this for?", body, `text-secondary`
- No trailing icon

Divider: 1px `border`

Row 3 — Date:
- Leading: calendar icon + formatted date ("Today" if today, else "Mon, 14 Oct")
- Trailing: chevron-right
- onTap: `showDatePicker` (iOS: `CupertinoDatePicker`, Android: material DatePicker)

Divider: 1px `border`

Row 4 — Payment Method:
- Label: "Paid with" (caption, `text-secondary`)
- 8px gap
- Row of 3 chips: Cash / UPI / Card
  - Selected: `accent-muted` bg + `accent` border + `accent` text
  - Unselected: `bg-elevated` bg + `border` border + `text-secondary` text
  - Height: 32px, radius-sm, padding 8×16px

**Save Button** — 20px below field group, full-width
- Label: "Save Expense"
- Disabled (opacity 0.4) if amount == 0
- onPressed: call `ExpensesNotifier.addExpense()` → dismiss sheet → `HapticFeedback.mediumImpact()`

---

## Category Selector (nested bottom sheet)

`showModalBottomSheet` from within `AddExpenseSheet`.

- Title: "Category", heading2, centered
- Grid: `GridView`, 3 columns, padding 20px
- Each cell (height 88px):
  - Icon (32px, category color) centered
  - Category name (label, `text-secondary`) below, 4px gap
  - Selected: `accent-muted` bg + `accent` border (1px), radius-md
  - onTap: set selected category → auto-dismiss sheet
- Default selected: "Others"

---

## Default State

- Amount: empty
- Category: "Others"
- Note: empty
- Date: today
- Payment: "Cash"
