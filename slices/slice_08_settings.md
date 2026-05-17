# Slice 08 — Settings Screen

Route: `/settings` (tab 3 in MainShell)

---

## Layout

`Scaffold`, no AppBar — custom title. `ListView`, 20px horizontal margin.

---

## Header

- Title: "Settings" — heading1, `text-primary`, 20px top + safe area, 24px bottom

---

## List Sections

Use `AppCard` per section group. 12px gap between groups.

---

### Group 1 — Account

Card, divider between rows.

**Row: Email**
- Leading: user icon (20px, `text-secondary`)
- Title: "Account" (body, `text-primary`)
- Subtitle: user's email (caption, `text-secondary`)
- No trailing, not tappable

---

### Group 2 — Preferences

**Row: Monthly Budget**
- Leading: target icon
- Title: "Monthly Budget"
- Trailing: current limit ("₹30,000") in caption `text-secondary` + chevron-right
- onTap: `context.push('/budget')`

**Row: Currency**
- Leading: currency icon
- Title: "Currency"
- Trailing: "₹ INR" caption + (no chevron — not tappable for MVP)

---

### Group 3 — App

**Row: Notifications**
- Leading: bell icon
- Title: "Notifications"
- Trailing: `Switch` (non-functional for MVP, defaults off)

---

### Group 4 — About

**Row: Version**
- Leading: info icon
- Title: "Version"
- Trailing: "1.0.0" caption, `text-secondary`
- Use `package_info_plus` to get real version string

---

## Sign Out Button

Below all groups, 24px gap.

Full-width `OutlinedButton`:
- Border: `error` (#FF453A)
- Text: "Sign Out", `error` color, body weight 500
- Height: 52px, radius-md
- onPressed: `AuthNotifier.signOut()` → GoRouter redirects to `/auth`
- Confirm before signing out: simple `showDialog` with "Sign out?" + Cancel / Sign Out buttons

---

## Row Spec (reusable pattern)

```
Height: 52px minimum
Padding: 16px horizontal
Leading icon: 20px, text-secondary, 12px right margin
Title: body, text-primary
Trailing: caption text + optional chevron (16px, text-tertiary)
Divider: 1px border between rows within same card
```
