# Slice 01 — Splash + Onboarding

Routes: `/splash` → `/onboarding` → `/auth`

---

## Splash Screen

- Full screen `bg-primary` (#0D0D0F)
- Center: text "spent", Inter 700, 36px, `text-primary`
- Fade-in animation 400ms on mount
- Auto-navigate to `/onboarding` after 1.5s (or `/home` if already logged in)

---

## Onboarding Screen

Widget: `PageView`, 3 slides.

**Slide layout:**
- Top 60%: illustration area — use a large centered `Icon` from lucide/phosphor, 96px, `accent` color. No heavy assets.
- Bottom 40%:
  - Title: heading1 (24px, 600), `text-primary`
  - Subtitle: body (15px, 400), `text-secondary`, 8px below title
  - 32px gap
  - Page dots (3 dots, active = `accent`, inactive = `border`)
  - 16px gap
  - "Continue" button: full-width, height 52px, `accent` bg, white text, radius-xl (24px)
  - 12px gap
  - "Skip" text link: center, `text-secondary`, label size

**Slide content:**
1. Icon: `Zap` — Title: "Track instantly" — Subtitle: "Add expenses in under 5 seconds."
2. Icon: `BarChart2` — Title: "See your patterns" — Subtitle: "Beautiful charts that make sense of your spending."
3. Icon: `Target` — Title: "Stay on budget" — Subtitle: "Set limits. Know where you stand."

**Behavior:**
- "Continue" on slide 3 → navigate to `/auth`
- "Skip" → navigate to `/auth`
- Slide transition: 300ms, easeOutCubic
