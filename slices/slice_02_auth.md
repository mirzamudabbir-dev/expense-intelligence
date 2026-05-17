# Slice 02 — Auth Screen

Route: `/auth`

---

## Layout

Background: `bg-primary`  
Single screen, toggles between Sign In and Sign Up mode.

**Top section** (centered, starts 80px from top + safe area):
- App name: "spent", Inter 700, 32px, `text-primary`
- Tagline: "Your money, clearly." body, `text-secondary`, 8px below

**Form section** (40px below tagline):
- Email input (`AppInput`)
- 12px gap
- Password input (`AppInput`, obscureText, eye icon toggle suffix)
- 12px gap — Sign Up mode only: Confirm Password input
- 24px gap
- Primary button: "Sign In" or "Create Account" (full-width, height 52px, `accent`)
- 24px gap
- Toggle text: center, `text-secondary`, body
  - Sign In mode: "Don't have an account? **Sign up**"
  - Sign Up mode: "Already have an account? **Sign in**"
  - Bold part: `accent` color, tappable

---

## Behavior

- Loading state: button shows `CircularProgressIndicator` (white, 18px), disabled
- Error: red `text-error` (#FF453A) caption text below the relevant field — not a toast
- On successful sign in → GoRouter redirect sends to `/home`
- On successful sign up → GoRouter redirect sends to `/home`
- Password field: eye icon toggles `obscureText`
- Keyboard: email type for email field, no autocorrect on password

---

## Validation (client-side)

- Email: must contain `@`
- Password: minimum 6 characters
- Confirm Password: must match Password
- Show errors only after first submit attempt
