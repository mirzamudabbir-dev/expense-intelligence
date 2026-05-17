# Claude Code build playbook — Spent (Expense Tracking App)

Operator's manual. One prompt per step. Copy-paste verbatim, review the result, commit, move on.

## Table of contents

1. [One-time repo setup](#one-time-repo-setup)
2. [Priming (every session)](#priming-every-session)
3. [The single-prompt pattern](#the-single-prompt-pattern)
4. [Step 1 — Scaffolding](#step-1--scaffolding)
5. [Step 2 — Supabase schema + RLS](#step-2--supabase-schema--rls)
6. [Step 3 — Theme + shared components](#step-3--theme--shared-components)
7. [Step 4 — Auth screens](#step-4--auth-screens)
8. [Step 5 — Expense model + repository](#step-5--expense-model--repository)
9. [Step 6 — Add Expense sheet](#step-6--add-expense-sheet)
10. [Step 7 — Home screen](#step-7--home-screen)
11. [Step 8 — Transaction history](#step-8--transaction-history)
12. [Step 9 — FastAPI backend](#step-9--fastapi-backend)
13. [Step 10 — Analytics screen](#step-10--analytics-screen)
14. [Step 11 — Budget screen](#step-11--budget-screen)
15. [Step 12 — Settings screen](#step-12--settings-screen)
16. [Step 13 — Polish pass](#step-13--polish-pass)
17. [Step 14 — E2E smoke test](#step-14--e2e-smoke-test)
18. [Recovery prompts](#recovery-prompts)
19. [Context management](#context-management)
20. [Pre-commit checklist](#pre-commit-checklist)

---

## One-time repo setup

```bash
mkdir spent && cd spent
git init
mkdir -p app backend docs slices

# Drop in the files you already have
mv ~/Downloads/CLAUDE.md            ./CLAUDE.md
mv ~/Downloads/claude_flutter.md    ./app/CLAUDE.md
mv ~/Downloads/claude_fastapi.md    ./backend/CLAUDE.md
mv ~/Downloads/claude_supabase.md   ./docs/SUPABASE.md
mv ~/Downloads/design.md            ./docs/DESIGN.md
mv ~/Downloads/slice_0*.md          ./slices/

cat > .gitignore <<'EOF'
.dart_tool/
build/
*.g.dart
*.freezed.dart
.flutter-plugins
.flutter-plugins-dependencies
.packages
pubspec.lock
__pycache__/
*.pyc
.venv/
.env
.env.local
*.log
EOF

cat > docs/PROGRESS.md <<'EOF'
# Build Progress

Latest commit: (none)
Current step: 1
Blockers: none

## Steps
- [ ] 1. Scaffolding
- [ ] 2. Supabase schema + RLS
- [ ] 3. Theme + shared components
- [ ] 4. Auth screens
- [ ] 5. Expense model + repository
- [ ] 6. Add Expense sheet
- [ ] 7. Home screen
- [ ] 8. Transaction history
- [ ] 9. FastAPI backend
- [ ] 10. Analytics screen
- [ ] 11. Budget screen
- [ ] 12. Settings screen
- [ ] 13. Polish pass
- [ ] 14. E2E smoke test
EOF

git add . && git commit -m "Initial scaffold: design doc, claude instructions, slices, progress tracker"
claude
```

---

## Priming (every session)

First message of every session:

> Read `CLAUDE.md` and `@docs/PROGRESS.md`. Tell me current step, last commit, and the 3 design principles in one line each. No code yet.

If first session ever, replace with:

> Read `CLAUDE.md` and `@docs/DESIGN.md`. Give me one-line summaries of each major section, then list deliverables for step 1. Flag any ambiguities. No code yet.

Review the summary. Correct misreads before continuing. **Catches 80% of bad implementations.**

---

## The single-prompt pattern

Every step uses one prompt that asks Claude to: plan → wait for approval → build → run checks → commit → update progress.

Between steps, run `/clear` and re-prime. Mid-step, run `/compact` if context exceeds ~70%.

---

## Step 1 — Scaffolding

**Goal:** Flutter project created, folder structure matching `app/CLAUDE.md`, all pubspec deps installed, app runs on iOS and Android with a blank dark screen. FastAPI skeleton in `backend/`.

> Step 1 per `@app/CLAUDE.md` (folder structure, pubspec, theme setup) and `@docs/DESIGN.md` (colors, typography).
>
> Plan, then wait for approval. Then build.
>
> Scope:
> - Flutter: `flutter create spent --org com.spent --platforms ios,android`. Apply the exact folder structure from `app/CLAUDE.md`. Add all pubspec.yaml dependencies as listed. Create `AppColors`, `AppTextStyles`, `AppTheme` in `core/theme/`. Set up `main.dart` with `Supabase.initialize` using dart-define env vars and `MaterialApp` using `buildAppTheme()`.
> - Router: GoRouter with all routes from `app/CLAUDE.md`. All screens are stubs (empty `Scaffold` with title text) except splash.
> - Backend: `backend/` with `main.py` (`GET /health` → `{"status":"ok"}`), `requirements.txt`, empty `core/` and `routers/` folders.
>
> No business logic. No Supabase calls yet.
>
> Verify: `flutter analyze` clean, `flutter run` launches on simulator showing dark background (#0D0D0F). `cd backend && uvicorn main:app` starts without error. Update `@docs/PROGRESS.md`. Commit `step 1: complete`.

---

## Step 2 — Supabase schema + RLS

**Goal:** all tables created in Supabase, RLS policies active, realtime enabled on expenses, RPCs deployed.

> Step 2 per `@docs/SUPABASE.md`.
>
> Plan, then wait. Cover:
> 1. SQL execution order: categories → expenses → budgets → updated_at trigger → RLS policies → RPCs.
> 2. Confirm `SECURITY DEFINER` on all RPCs so FastAPI service role can call them.
> 3. Confirm `supabase_realtime` publication includes `expenses` table.
>
> Build order: produce the complete schema SQL as one block I can paste into the Supabase SQL editor. Then produce the four RPC functions (`get_monthly_total`, `get_category_breakdown`, `get_daily_trend`, `get_monthly_comparison`) as a second block.
>
> Verify: paste and run both blocks in Supabase SQL editor. Confirm `categories` has 9 rows. Test RLS by querying `expenses` as anon role — expect 0 rows returned. Enable realtime on `expenses` in Supabase Dashboard → Database → Replication. Update progress. Commit `step 2: complete`.

---

## Step 3 — Theme + shared components

**Goal:** every shared widget in `lib/shared/widgets/` built, themed, and pixel-correct to `@docs/DESIGN.md`.

> Step 3 per `@docs/DESIGN.md` (component specs, spacing scale, color tokens).
>
> Plan, then wait. Cover:
> 1. `AppCard` is the base decoration — all card-like widgets use its `BoxDecoration` (bg-surface, 1px border, radius-md). No shadows.
> 2. `BudgetProgressBar` color logic: `accent` if < 80%, `warning` if 80–99%, `error` if ≥ 100%. Animate width on first render: 600ms easeOutQuart.
> 3. `CategoryChip` reads color from `AppColors.categoryColors[categoryId]`. Background at 15% opacity, border at 40%.
>
> Build: `AppCard`, `AppInput`, `PrimaryButton`, `CategoryChip`, `TransactionTile`, `AmountDisplay`, `BudgetProgressBar`, `SectionHeader`. Each widget uses only `AppColors.*` and `AppTextStyles.*`. No hardcoded hex values anywhere.
>
> Verify: `flutter analyze` clean. Render each widget in a `WidgetTest` — confirm no overflow, no theme fallback warnings. Update progress. Commit `step 3: complete`.

---

## Step 4 — Auth screens

**Goal:** working sign-up, sign-in, splash, and onboarding. GoRouter redirect sends users to correct screen based on auth state.

> Step 4 per `@slices/slice_01_splash_onboarding.md`, `@slices/slice_02_auth.md`, and `@app/CLAUDE.md` (auth provider pattern).
>
> Plan, then wait. Cover:
> 1. `AuthNotifier` listens to `supabase.auth.onAuthStateChange` stream to keep state current.
> 2. GoRouter `redirect`: logged-in user hitting `/auth` or `/onboarding` → `/home`. Logged-out user hitting `/home` → `/auth`.
> 3. Onboarding shown only on first install — persist a `bool` flag in `shared_preferences`.
>
> Build order: `AuthRepository` + `AuthNotifier` → `SplashScreen` (fade-in, auto-navigate after 1.5s) → `OnboardingScreen` (PageView, 3 slides per slice spec, skip/continue) → `AuthScreen` (toggle sign-in/sign-up, client validation, loading state on button, error below field — not toast).
>
> Verify: `flutter analyze` clean. Manual test: cold launch → onboarding → sign up → lands on `/home` stub. Sign out → `/auth`. Second cold launch skips onboarding. Wrong password → error text below field. Update progress. Commit `step 4: complete`.

---

## Step 5 — Expense model + repository

**Goal:** `Expense` model, `ExpensesRepository`, `ExpensesNotifier` with live Supabase realtime stream, add + delete working.

> Step 5 per `@app/CLAUDE.md` (expense model, Riverpod patterns, realtime provider).
>
> Plan, then wait. Cover:
> 1. `Expense.fromJson` — confirm `category` in Dart maps to `category_id` column in Supabase.
> 2. Realtime stream: `.stream(primaryKey: ['id']).eq('user_id', currentUserId)` — emits full updated list on any change.
> 3. Delete strategy: optimistic (remove from local `AsyncData` immediately, call Supabase after) or stream-driven (wait for stream). State your choice and why.
>
> Build order: `Expense` model with `fromJson`/`toJson` → `ExpensesRepository` (addExpense, updateExpense, deleteExpense, stream getter) → `ExpensesNotifier` (`AsyncNotifier`, stream subscription in `build()`).
>
> No UI changes this step.
>
> Verify: `flutter analyze` clean. Integration test: `addExpense` → stream emits list with 1 item. `deleteExpense` → stream emits empty list. Update progress. Commit `step 5: complete`.

---

## Step 6 — Add Expense sheet

**Goal:** `AddExpenseSheet` bottom sheet opens from FAB, full UX per slice spec, saves to Supabase in realtime.

> Step 6 per `@slices/slice_04_add_expense.md` and `@docs/DESIGN.md`.
>
> Plan, then wait. Cover:
> 1. Amount field auto-focus: `WidgetsBinding.instance.addPostFrameCallback((_) => _amountFocus.requestFocus())`.
> 2. Category selector: nested `showModalBottomSheet`, `GridView` 3 columns, 9 categories, auto-dismiss on select. Default selection: "Others".
> 3. Date picker: `CupertinoDatePicker` on iOS, Material `showDatePicker` on Android. Detect via `Platform.isIOS`.
> 4. Save button disabled when `amount <= 0`.
>
> Build: `AddExpenseSheet` (amount field, field group card with category/note/date/payment chips) + `CategorySelectorSheet` (nested). On save: `ExpensesNotifier.addExpense()` → `Navigator.pop()` → `HapticFeedback.mediumImpact()`.
>
> Verify: `flutter analyze` clean. Manual test on iOS and Android: sheet opens, keyboard focuses amount, category grid shows 9 items, tapping a category dismisses nested sheet and updates chip, save writes row to Supabase. Update progress. Commit `step 6: complete`.

---

## Step 7 — Home screen

**Goal:** fully functional home screen with monthly card, today card, category chips, weekly chart, recent transactions list, and FAB.

> Step 7 per `@slices/slice_03_home.md` and `@docs/DESIGN.md`.
>
> Plan, then wait. Cover:
> 1. Monthly total and today total computed from `ExpensesNotifier` list in a derived provider — not a Supabase call.
> 2. Weekly chart: group expenses by `date` for last 7 days, fill missing days with 0.0. 7 bars, Mon–Sun, today's bar in `accent`, others in `bg-elevated`.
> 3. Budget card: if `BudgetNotifier` returns null for current month/year, show "Set a budget →" caption in `accent` instead of progress bar.
>
> Build: `HomeScreen` as `CustomScrollView` + `SliverList`. `BudgetNotifier` queries Supabase `budgets` directly. FAB: bottom-center, `accent`, glow shadow, opens `AddExpenseSheet`. "See all" navigates to `/history`. Bottom padding 80px.
>
> Verify: `flutter analyze` clean. Manual test: add 3 expenses → totals update without refresh. Set a budget → progress bar appears. Weekly bar chart renders without error. Update progress. Commit `step 7: complete`.

---

## Step 8 — Transaction history

**Goal:** `/history` with date-grouped list, live search, category filter chips, swipe-to-delete with undo, long-press edit.

> Step 8 per `@slices/slice_05_history.md` and `@docs/DESIGN.md`.
>
> Plan, then wait. Cover:
> 1. Grouping: client-side, sort by date desc, group by `expense.date` (date only, no time). Date headers: "Today", "Yesterday", then "Mon, 14 Oct" format.
> 2. Search: filters on `note` and category name, case-insensitive, no new Supabase call.
> 3. Delete: optimistic removal from displayed list → `ScaffoldMessenger` SnackBar with "Undo" (3s). If undone: re-insert to list. If not undone: call `ExpensesNotifier.deleteExpense(id)`.
>
> Build: `HistoryScreen` with pinned custom header (back button + title + search bar + filter chips), grouped `ListView`, `TransactionTile` with `Dismissible` for swipe-to-delete, `GestureDetector` long-press opening a modal bottom sheet with Edit / Delete options. Edit opens `AddExpenseSheet` pre-filled.
>
> Verify: `flutter analyze` clean. Manual test: 5 expenses across 2 dates → grouped correctly. Search "coffee" → filters live. Swipe delete → undo → expense reappears. Long-press edit → sheet pre-filled → save → list updates. Update progress. Commit `step 8: complete`.

---

## Step 9 — FastAPI backend

**Goal:** FastAPI deployed, JWT auth validates Supabase tokens, `/analytics/monthly` and `/budget/status` return correct aggregated data via Supabase RPCs.

> Step 9 per `@backend/CLAUDE.md`.
>
> Plan, then wait. Cover:
> 1. JWT validation uses `SUPABASE_JWT_SECRET` (from Supabase Dashboard → Settings → API). Decode with `audience="authenticated"`, extract `sub` as `user_id`.
> 2. All RPC calls use the service role client — bypasses RLS so FastAPI can aggregate across the user's rows.
> 3. `GET /budget/status`: if no budget row for month/year, return `{"limit": null, "spent": X, "remaining": null, "percentage": null}`.
>
> Build order: `core/config.py` (pydantic-settings) → `core/auth.py` (JWT dep) → `core/database.py` (service role Supabase client) → `schemas/analytics.py` (Pydantic response models) → `routers/analytics.py` (`GET /analytics/monthly`) → `routers/budget.py` (`GET /budget/status`) → register routers in `main.py`.
>
> Verify: `uvicorn main:app` starts. `GET /health` → `{"status":"ok"}`. Sign into app, copy JWT, `curl /analytics/monthly?month=X&year=Y -H "Authorization: Bearer <token>"` → correct totals. Deploy to Railway or Render, note the public URL. Update progress. Commit `step 9: complete`.

---

## Step 10 — Analytics screen

**Goal:** analytics screen with period selector, 3 summary cards, monthly bar chart, category breakdown list, daily line chart — all driven by FastAPI.

> Step 10 per `@slices/slice_06_analytics.md` and `@docs/DESIGN.md`.
>
> Plan, then wait. Cover:
> 1. `AnalyticsRepository`: HTTP GET with `Authorization: Bearer ${supabase.auth.currentSession!.accessToken}`. Use `dart-define` `API_BASE_URL`.
> 2. Period selector state (Week / Month / Year) drives which `month`/`year` params are sent. Month is default.
> 3. Loading state: centered `CircularProgressIndicator`, color `accent`. Error state: centered text "Could not load data. Tap to retry." wired to provider refresh.
>
> Build: `AnalyticsNotifier` (Riverpod `AsyncNotifier`, calls `AnalyticsRepository`) → `AnalyticsScreen` with period chips, 3 summary `AppCard`s in a row, `BarChart` (monthly comparison, 6 bars), category breakdown list (color dot + name + progress bar + amount + %), `LineChart` (daily trend, filled). All charts `fl_chart`.
>
> Verify: `flutter analyze` clean. Manual test: 5+ expenses added → charts render with real data. Switching period chips re-fetches. No data case shows empty state. Update progress. Commit `step 10: complete`.

---

## Step 11 — Budget screen

**Goal:** budget donut ring showing spend vs limit with correct colors, set/edit budget bottom sheet writing to Supabase.

> Step 11 per `@slices/slice_07_budget.md` and `@docs/DESIGN.md`.
>
> Plan, then wait. Cover:
> 1. Donut ring: `fl_chart` `PieChart`, `sectionsSpace: 0`, `centerSpaceRadius` sized to create a hole. Two sections: spent (status color) + remaining (`bg-elevated`). Animate `sections` from 0 on mount via `fl_chart` `swapAnimationDuration: 700ms`.
> 2. Ring color thresholds: same as `BudgetProgressBar` — accent / warning / error.
> 3. Set/edit budget: UPSERT to Supabase `budgets` table with `ignoreDuplicates: false` and `onConflict: 'user_id,month,year'`. Immediately update `BudgetNotifier` state after save.
>
> Build: `BudgetNotifier` (direct Supabase query + upsert) → `BudgetScreen` with donut ring card (status color + center text + spent/limit label) + pencil edit icon → set/edit bottom sheet (amount input, "Save Budget" button).
>
> Verify: `flutter analyze` clean. Manual test: set ₹10,000 → ring renders. Add expenses to ₹8,500 → ring at 85%, warning orange. Edit to ₹7,000 → ring turns error red. Update progress. Commit `step 11: complete`.

---

## Step 12 — Settings screen

**Goal:** settings screen with account info, budget navigation, currency label, notifications toggle, app version, sign-out with confirmation dialog.

> Step 12 per `@slices/slice_08_settings.md` and `@docs/DESIGN.md`.
>
> Plan, then wait. Cover:
> 1. Version string: `PackageInfo.fromPlatform()` from `package_info_plus`, loaded in provider or `initState`.
> 2. Sign out: `showDialog` → "Sign out?" → Cancel / Sign Out. Sign Out calls `AuthNotifier.signOut()`. GoRouter redirect handles navigation to `/auth`.
> 3. Notifications `Switch`: non-functional, `initialValue: false`, `onChanged: (_) {}`. No wiring needed.
>
> Build: `SettingsScreen` as `ListView` with 4 `AppCard` section groups per slice spec. Sign out `OutlinedButton` in `error` color below groups.
>
> Verify: `flutter analyze` clean. Manual test: version shows correctly (not "0.0.0"). Budget row navigates to `/budget`. Sign out → dialog appears → confirm → lands on `/auth`. Update progress. Commit `step 12: complete`.

---

## Step 13 — Polish pass

**Goal:** animations, haptics, empty states, safe area audit, keyboard avoidance — no new features.

> Step 13 per `@docs/DESIGN.md` (animation principles, safe area rules, accessibility).
>
> Plan, then wait. Cover:
> 1. `flutter_animate`: `.fadeIn().slideY(begin: 0.05)` on list items in `HomeScreen` recent transactions and `HistoryScreen` transaction tiles. Duration 250ms, delay staggered `index * 30ms`.
> 2. `fl_chart` animations: set `swapAnimationDuration: const Duration(milliseconds: 600)` and `swapAnimationCurve: Curves.easeOutQuart` on all charts.
> 3. Safe area: audit every screen for `SafeArea` or `SliverSafeArea`. Every scrollable ends with `SizedBox(height: 80)` to clear FAB.
> 4. Keyboard occlusion: `AddExpenseSheet` — `Scaffold(resizeToAvoidBottomInset: true)`. Test on iPhone SE simulator (smallest viewport).
> 5. Empty states: `HistoryScreen` (no transactions, no filter results), `AnalyticsScreen` (no data for period).
>
> No new features. No new routes. Polish only.
>
> Verify: `flutter analyze` clean. Manual test on iPhone SE and large Android simulator: no overflow, no keyboard occlusion on amount field, list animations play on scroll, charts animate on screen enter. Update progress. Commit `step 13: complete`.

---

## Step 14 — E2E smoke test

**Goal:** all critical flows work end-to-end on a physical or simulated device. Demo-ready.

> Step 14. Read `@docs/PROGRESS.md` and `@docs/DESIGN.md`. No code yet.
>
> Produce a flow checklist organized by user action:
>
> 1. New user: cold launch → onboarding (3 slides) → sign up → home screen shows ₹0 and no budget bar.
> 2. Add expense: FAB → amount → category (change from default) → note → save → appears on home in realtime, today card increments.
> 3. Volume: add 10 expenses across 5 categories → home category chips ordered by spend, weekly bars show data, recent list shows last 5.
> 4. History: navigate → all 10 expenses grouped by date. Search by note → filters live. Category chip → filters by category. Swipe delete → undo → expense restored.
> 5. Analytics: all charts render with real data. Period selector switches data.
> 6. Budget: set ₹5,000 → home shows progress bar. Spend past ₹4,000 → bar turns warning. Spend past ₹5,000 → bar turns error.
> 7. Settings: correct email shown, version shown. Sign out → confirmation → `/auth`.
> 8. Sign back in → all 10 expenses still present, budget preserved.
>
> Walk each flow on device. For each broken flow, append one line to `docs/BUGS.md`.
>
> Then send follow-ups for individual bugs, one per session:
>
> > Read `@docs/BUGS.md` line N. Reproduce the issue, plan the fix, build, verify, commit.

---

## Recovery prompts

**Tests fail and you can't see why:**

> Stop. Show: failing test name, full output, your hypothesis, minimum diff to isolate. No fix code yet.

**Off-spec implementation:**

> Stop. You're building outside the slice file or `@docs/DESIGN.md`. `git reset --hard HEAD~1`. Re-read the relevant slice and re-plan.

**Wrong colors or spacing:**

> Compare current implementation of `[widget]` against `@docs/DESIGN.md` component specs. List: in spec but missing in code, in code but not in spec. No changes yet.

**Supabase query returning wrong data:**

> Stop. Show the exact query, the raw Supabase response, and which section of `@docs/SUPABASE.md` it should follow. No fix yet.

**Riverpod state not updating UI:**

> Stop. Show the provider type, how state is mutated, and where the widget reads it. Confirm widget is `ConsumerWidget` or uses `ref.watch`. No fix yet.

**Dependency added without asking:**

> You added `[package]` without asking. Justify: what it does, what breaks without it, whether a Flutter built-in exists. Weak justification → remove it.

---

## Context management

**Signs to clear:** slower responses, forgetting rules from `CLAUDE.md`, re-reading files already in context, recommending packages already in pubspec.

**Before clearing:**

> Summarize: last commit hash, current step, files changed this session, open TODOs, any blockers. I'll save this and re-prime.

Then `/clear` and re-prime.

**Avoiding bloat:** one step per session where possible. Steps 7 and 13 may need splitting if context grows — split at a natural commit boundary. Don't paste Flutter error logs — point Claude to the terminal. Don't ask Claude to explain code it just wrote — re-emits into context.

**`/compact` vs `/clear`:** `/compact` mid-step when context >70%. `/clear` between steps or when the same mistake recurs twice.

---

## Pre-commit checklist

Send before approving any commit:

> Before commit, confirm: `flutter analyze` returns no issues. Commit message follows `step N: <verb> <thing>`. No `.env`, secrets, generated build artifacts, or `pubspec.lock` in diff. Change matches the slice file and `@docs/DESIGN.md` — not assumption. Show `git diff --stat` and the commit message before running `git commit`.
