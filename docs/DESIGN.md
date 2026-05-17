# Design System — Expense Intelligence App

## Visual Identity

**Mood**: Calm, premium, data-rich. Feels like Linear meets Apple Health.  
**Theme**: Dark-first. Light mode deferred to post-MVP.  
**Platform**: Flutter — iOS and Android optimized.

---

## Color Palette

### Base
| Token | Hex | Usage |
|---|---|---|
| `bg-primary` | `#0D0D0F` | Main background |
| `bg-surface` | `#161618` | Cards, sheets |
| `bg-elevated` | `#1E1E22` | Input fields, chips |
| `border` | `#2A2A2E` | Dividers, card borders |

### Accent — Mint
| Token | Hex | Usage |
|---|---|---|
| `accent` | `#00C896` | CTAs, progress, highlights |
| `accent-muted` | `#00C89620` | Accent backgrounds |
| `accent-dim` | `#00A87A` | Pressed states |

### Text
| Token | Hex | Usage |
|---|---|---|
| `text-primary` | `#F5F5F7` | Headlines, amounts |
| `text-secondary` | `#8E8E93` | Labels, metadata |
| `text-tertiary` | `#48484A` | Placeholders, disabled |

### Semantic
| Token | Hex | Usage |
|---|---|---|
| `error` | `#FF453A` | Destructive, over-budget |
| `warning` | `#FF9F0A` | Approaching limit |
| `success` | `#30D158` | Saved, completed |

### Category Colors
| Category | Color |
|---|---|
| Food | `#FF6B6B` |
| Transport | `#4ECDC4` |
| Shopping | `#FFE66D` |
| Bills | `#A8E6CF` |
| Entertainment | `#C77DFF` |
| Health | `#FF8B94` |
| Education | `#74B9FF` |
| Travel | `#FFEAA7` |
| Others | `#636E72` |

---

## Typography

**Font**: Inter (Google Fonts — available via `google_fonts` package)

| Style | Size | Weight | Usage |
|---|---|---|---|
| `display` | 32px | 700 | Amount on dashboard |
| `heading1` | 24px | 600 | Screen titles |
| `heading2` | 18px | 600 | Section headers |
| `body` | 15px | 400 | List items, descriptions |
| `label` | 13px | 500 | Chips, tags, category names |
| `caption` | 11px | 400 | Timestamps, metadata |
| `mono` | 16px | 500 | Currency numbers (use `Roboto Mono`) |

**Rule**: Currency amounts always use `mono`. All other text uses Inter.

---

## Spacing Scale

```
4, 8, 12, 16, 20, 24, 32, 40, 48, 64
```

Base unit: `4px`. Use multiples consistently.

---

## Border Radius

| Token | Value | Usage |
|---|---|---|
| `radius-sm` | 8px | Chips, badges |
| `radius-md` | 12px | Cards, inputs |
| `radius-lg` | 16px | Bottom sheets |
| `radius-xl` | 24px | FAB, modal cards |
| `radius-full` | 999px | Pills, avatars |

---

## Elevation / Shadow

No harsh shadows. Use border + subtle background shift only.

```dart
// Card style
BoxDecoration(
  color: Color(0xFF161618),
  borderRadius: BorderRadius.circular(12),
  border: Border.all(color: Color(0xFF2A2A2E), width: 1),
)
```

---

## Component Specs

### FAB — Quick Add
- Size: 56×56 (circular)
- Color: `accent`
- Icon: `+` (24px, white)
- Position: Bottom center, 24px above nav bar
- Shadow: none — use accent glow: `boxShadow: [BoxShadow(color: accent.withOpacity(0.3), blurRadius: 20)]`

### Cards
- Background: `bg-surface`
- Border: 1px `border`
- Radius: `radius-md` (12px)
- Padding: 16px
- No elevation

### Inputs
- Background: `bg-elevated`
- Border: 1px `border` (focused: 1px `accent`)
- Radius: `radius-md`
- Text: `text-primary`
- Placeholder: `text-tertiary`
- Height: 52px

### Bottom Sheet
- Background: `bg-surface`
- Top radius: `radius-lg` (16px)
- Handle: 4×36px, color `border`, centered, 12px from top
- Drag-dismissible: yes

### Category Chip
- Background: category color at 15% opacity
- Border: category color at 40% opacity
- Text: category color (full)
- Radius: `radius-sm`
- Padding: 6×12px

### Progress Bar / Budget Ring
- Track: `bg-elevated`
- Fill: `accent` (green if <80%, `warning` if 80–99%, `error` if ≥100%)
- Ring stroke: 6px
- Animation: 600ms ease-out on mount

---

## Navigation

**Bottom Navigation Bar**  
4 tabs: Home · Add (FAB center) · Analytics · Settings  
Active icon: `accent` color  
Inactive: `text-tertiary`  
Background: `bg-surface` with top border  
No labels — icons only (except Home which gets a dot indicator)

---

## Animation Principles

| Interaction | Duration | Curve |
|---|---|---|
| Screen transitions | 250ms | `easeInOutCubic` |
| Bottom sheet open | 300ms | `easeOutCubic` |
| Card tap feedback | 100ms | `easeIn` |
| Chart render | 600ms | `easeOutQuart` |
| FAB press | 80ms | `easeIn` |

Use `flutter_animate` package for declarative animations.

---

## Icons

Package: `lucide_icons` or `phosphor_flutter`  
Style: Outline (default), Filled (active state)  
Size: 20px in nav, 24px in content, 16px in chips

Category icons:
- Food: fork-knife
- Transport: car
- Shopping: shopping-bag
- Bills: receipt
- Entertainment: tv
- Health: heart
- Education: book
- Travel: plane
- Others: grid

---

## Screen Dimensions & Safe Areas

- Always use `SafeArea` widget
- Bottom padding: account for home indicator (iOS) — use `MediaQuery.of(context).padding.bottom`
- Horizontal page margin: 20px
- Content max-width: unbounded (full width mobile)

---

## Accessibility

- Minimum tap target: 44×44px
- Contrast ratio: ≥ 4.5:1 for body text
- Semantic labels on all icon buttons
- Support system font scaling (use `textScaleFactor` clamp: 0.85–1.2)
