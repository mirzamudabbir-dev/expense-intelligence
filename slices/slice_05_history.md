# Slice 05 — Transaction History

Route: `/history`

---

## Layout

`Scaffold`, no default AppBar — custom header pinned at top.

---

## Header (pinned, not scrolling)

- Back button (chevron-left, `text-primary`) + title "Transactions" (heading2, `text-primary`)
- 12px below: full-width search `AppInput`
  - Leading icon: search (16px, `text-tertiary`)
  - Placeholder: "Search transactions"
  - onChanged: filter list in real time
- 12px below: horizontal `SingleChildScrollView` of filter chips
  - "All" + one chip per category + "This month" date chip
  - Selected chip: `accent-muted` bg + `accent` border + `accent` text
  - Unselected: `bg-elevated` + `border`
  - Padding: 20px horizontal, 4px vertical

---

## Transaction List

`ListView` below header.

**Group by date.** For each date group:
- Date header: formatted date string ("Today", "Yesterday", "Mon, 14 Oct") — label, `text-secondary`, padding 16px horizontal, 12px vertical
- List of `TransactionTile` for that date

**`TransactionTile`** (height ~64px):
- Leading: colored circle 40px diameter, `category color at 20% opacity` bg, category icon centered (20px, full category color)
- Title: note if non-empty, else category name — body, `text-primary`
- Subtitle: time (e.g. "2:30 PM") + " · " + payment method — caption, `text-secondary`
- Trailing: "₹1,200" — body, mono, `text-primary`, right-aligned
- Swipe left: reveals red delete button ("Delete", white text, `error` bg)
- Long press: show `ModalBottomSheet` with options: "Edit" + "Delete"

---

## Delete Flow

- Swipe-to-delete or "Delete" from long-press menu
- Immediately remove from list (optimistic)
- Show `SnackBar`: "Expense deleted" + "Undo" action (3s)
- Undo: re-insert expense
- If not undone: call `ExpensesNotifier.deleteExpense(id)`

---

## Edit Flow

- "Edit" from long-press → open `AddExpenseSheet` pre-filled with expense data
- Save → call `ExpensesNotifier.updateExpense(expense)`

---

## Empty State

Centered in list area:
- Icon: `Receipt`, 48px, `text-tertiary`
- Text: "No transactions yet" — body, `text-secondary`
- If filtered + empty: "No results for this filter" — body, `text-secondary`

---

## Data

Full expense list from `ExpensesNotifier`.  
Filter and search applied locally (no new API calls).  
Sort: date descending within each group.
