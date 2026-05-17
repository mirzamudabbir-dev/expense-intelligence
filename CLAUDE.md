# CLAUDE.md — Spent

Master instructions. Read this first, every session, before any other file.

---

## What this project is

**Spent** is a mobile-first personal expense tracking app.

- **Frontend**: Flutter (iOS + Android)
- **Backend**: Python FastAPI (analytics aggregation only)
- **Database + Auth**: Supabase (Postgres + Realtime + Auth)
- **State management**: Riverpod
- **Navigation**: GoRouter

---

## What you are building

A dark-mode expense tracker that feels premium and fast. Users can add expenses in under 5 seconds, see spending patterns visually, and track against a monthly budget.

MVP only. No AI. No social features. No bank integrations. No crypto. No investment tracking.

---

## Non-negotiable rules

1. **Stack is fixed.** Flutter, Supabase, FastAPI. No substitutions, no additions to the core stack without explicit approval.
2. **No unapproved dependencies.** Before adding any package not in `app/CLAUDE.md` or `backend/CLAUDE.md`, stop and justify it. Weak justification → do not add.
3. **No hardcoded values.** Colors always from `AppColors.*`. Text styles always from `AppTextStyles.*`. Spacing always from the 4px scale (4, 8, 12, 16, 20, 24, 32, 40, 48, 64).
4. **No CRUD via FastAPI.** All expense and budget CRUD goes through the Supabase Flutter SDK directly. FastAPI handles analytics aggregation and budget status only.
5. **No AI features.** Do not suggest, stub, or scaffold anything AI-related.
6. **Flutter analyze must pass.** Zero issues before every commit. No ignoring warnings with `// ignore:` without approval.
7. **One step at a time.** Build exactly what the current step asks. Do not build ahead.
8. **Plan before building.** Every step: propose a plan, wait for approval, then build. Never start building without approval.

---

## File map

| File | Purpose |
|---|---|
| `CLAUDE.md` | This file. Master rules. Read every session. |
| `app/CLAUDE.md` | Flutter-specific instructions: folder structure, pubspec, patterns, platform notes. |
| `backend/CLAUDE.md` | FastAPI instructions: endpoints, auth middleware, Supabase RPC calls. |
| `docs/DESIGN.md` | Design system: colors, typography, spacing, component specs, animation timings. |
| `docs/SUPABASE.md` | Schema SQL, RLS policies, RPC functions, realtime setup. |
| `docs/PROGRESS.md` | Current step, last commit, blockers. Update after every commit. |
| `slices/slice_01_*.md` | Splash + Onboarding screen spec. |
| `slices/slice_02_*.md` | Auth screen spec. |
| `slices/slice_03_*.md` | Home / Dashboard screen spec. |
| `slices/slice_04_*.md` | Add Expense bottom sheet spec. |
| `slices/slice_05_*.md` | Transaction History screen spec. |
| `slices/slice_06_*.md` | Analytics screen spec. |
| `slices/slice_07_*.md` | Budget screen spec. |
| `slices/slice_08_*.md` | Settings screen spec. |

**Load slice files on demand.** Only read the slice for the screen you are currently building. Do not load all slices at once.

---

## Design principles (memorise these)

1. **Minimal but warm.** Clean layouts, large spacing, soft corners, no harsh shadows, no excessive gradients.
2. **Fast UX.** Every major action in 1–2 taps. Smooth animations. Expense entry under 5 seconds.
3. **Dark mode first.** Primary background `#0D0D0F`. Accent color mint `#00C896`. Never use neon or heavy gradients.

---

## Architecture rules

### Flutter
- Feature-first folder structure: `lib/features/<feature>/screens|widgets|providers|repositories|models/`
- Shared widgets in `lib/shared/widgets/` — never duplicate widget logic in feature folders
- Riverpod only for state — no `setState` in feature screens, no `ChangeNotifier`, no `BLoC`
- GoRouter only for navigation — no `Navigator.push`, no `MaterialPageRoute`
- Supabase SDK for all CRUD — no HTTP calls to FastAPI for expenses or budgets
- HTTP calls to FastAPI only from `features/analytics/repositories/` and reading budget status

### FastAPI
- Validates Supabase JWT on every request via `core/auth.py` dependency
- Uses service role Supabase client — never the anon key
- Calls Supabase RPCs for aggregations — no raw SQL strings in router files
- No CRUD endpoints — if tempted, stop and re-read this rule

### Supabase
- RLS enabled on all tables — never disable
- Service role key only in FastAPI backend — never in Flutter
- Anon key only in Flutter — never in backend
- Realtime enabled on `expenses` table only

---

## Environment variables

### Flutter (dart-define at build time)
```
SUPABASE_URL
SUPABASE_ANON_KEY
API_BASE_URL
```

### FastAPI (.env, never committed)
```
SUPABASE_URL
SUPABASE_SERVICE_ROLE_KEY
SUPABASE_JWT_SECRET
```

Never commit `.env`. Never hardcode these values. Never swap which key goes where.

---

## Commit format

```
step N: <verb> <thing>
```

Examples:
- `step 3: build shared widget library`
- `step 7: complete home screen`
- `step 9: deploy fastapi analytics endpoints`

One commit per step unless the step explicitly calls for multiple commits.

---

## Progress tracking

After every commit, update `docs/PROGRESS.md`:
- Mark the completed step with `[x]`
- Set `Current step` to the next step number
- Set `Latest commit` to the commit hash
- Note any blockers

---

## What done looks like

A step is done when:
1. `flutter analyze` returns zero issues (Flutter steps)
2. `uvicorn main:app` starts without error (backend steps)
3. The manual verification in the step prompt passes
4. `docs/PROGRESS.md` is updated
5. The commit is made with the correct message
