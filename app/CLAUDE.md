# claude.md — Flutter Frontend

You are building the Flutter frontend for "Spent" — a dark-mode expense tracking app.  
Stack: Flutter + Supabase (direct SDK, no FastAPI calls from Flutter except analytics).  
State management: Riverpod.  
Target: iOS and Android.

---

## Project Structure

```
lib/
├── main.dart
├── app.dart                        # MaterialApp, router, theme
├── core/
│   ├── theme/
│   │   ├── app_colors.dart
│   │   ├── app_text_styles.dart
│   │   └── app_theme.dart
│   ├── router/
│   │   └── app_router.dart         # GoRouter
│   ├── constants/
│   │   └── app_constants.dart
│   └── utils/
│       ├── currency_formatter.dart
│       └── date_formatter.dart
├── shared/
│   └── widgets/
│       ├── app_card.dart
│       ├── app_input.dart
│       ├── primary_button.dart
│       ├── category_chip.dart
│       ├── transaction_tile.dart
│       ├── amount_display.dart
│       ├── budget_progress_bar.dart
│       └── section_header.dart
├── features/
│   ├── auth/
│   │   ├── screens/
│   │   │   ├── splash_screen.dart
│   │   │   ├── onboarding_screen.dart
│   │   │   └── auth_screen.dart
│   │   ├── providers/
│   │   │   └── auth_provider.dart
│   │   └── repositories/
│   │       └── auth_repository.dart
│   ├── expenses/
│   │   ├── screens/
│   │   │   ├── home_screen.dart
│   │   │   └── history_screen.dart
│   │   ├── widgets/
│   │   │   └── add_expense_sheet.dart
│   │   ├── providers/
│   │   │   └── expenses_provider.dart
│   │   ├── repositories/
│   │   │   └── expenses_repository.dart
│   │   └── models/
│   │       └── expense.dart
│   ├── analytics/
│   │   ├── screens/
│   │   │   └── analytics_screen.dart
│   │   ├── providers/
│   │   │   └── analytics_provider.dart
│   │   └── repositories/
│   │       └── analytics_repository.dart
│   ├── budget/
│   │   ├── screens/
│   │   │   └── budget_screen.dart
│   │   ├── providers/
│   │   │   └── budget_provider.dart
│   │   └── repositories/
│   │       └── budget_repository.dart
│   └── settings/
│       └── screens/
│           └── settings_screen.dart
└── services/
    └── supabase_service.dart
```

---

## pubspec.yaml Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  supabase_flutter: ^2.5.0
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5
  go_router: ^13.2.0
  google_fonts: ^6.2.1
  fl_chart: ^0.68.0
  flutter_animate: ^4.5.0
  intl: ^0.19.0
  uuid: ^4.4.0
  shared_preferences: ^2.2.3

dev_dependencies:
  build_runner: ^2.4.10
  riverpod_generator: ^2.4.0
  custom_lint: ^0.6.4
  riverpod_lint: ^2.3.10
```

---

## Theme Setup

```dart
// core/theme/app_colors.dart
class AppColors {
  static const bgPrimary    = Color(0xFF0D0D0F);
  static const bgSurface    = Color(0xFF161618);
  static const bgElevated   = Color(0xFF1E1E22);
  static const border       = Color(0xFF2A2A2E);
  static const accent       = Color(0xFF00C896);
  static const accentMuted  = Color(0x2000C896);
  static const textPrimary  = Color(0xFFF5F5F7);
  static const textSecondary= Color(0xFF8E8E93);
  static const textTertiary = Color(0xFF48484A);
  static const error        = Color(0xFFFF453A);
  static const warning      = Color(0xFFFF9F0A);
  static const success      = Color(0xFF30D158);

  static const categoryColors = {
    'food':          Color(0xFFFF6B6B),
    'transport':     Color(0xFF4ECDC4),
    'shopping':      Color(0xFFFFE66D),
    'bills':         Color(0xFFA8E6CF),
    'entertainment': Color(0xFFC77DFF),
    'health':        Color(0xFFFF8B94),
    'education':     Color(0xFF74B9FF),
    'travel':        Color(0xFFFFEAA7),
    'others':        Color(0xFF636E72),
  };
}
```

```dart
// core/theme/app_theme.dart
ThemeData buildAppTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bgPrimary,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.accent,
      surface: AppColors.bgSurface,
      error: AppColors.error,
    ),
    fontFamily: GoogleFonts.inter().fontFamily,
    // NO default app bar, NO default dividers
    dividerColor: Colors.transparent,
    splashColor: Colors.transparent,
    highlightColor: AppColors.bgElevated,
  );
}
```

---

## Routing (GoRouter)

```dart
// core/router/app_router.dart
final router = GoRouter(
  initialLocation: '/splash',
  redirect: (context, state) {
    final isLoggedIn = supabase.auth.currentUser != null;
    final isAuthRoute = state.matchedLocation.startsWith('/auth') ||
        state.matchedLocation.startsWith('/onboarding') ||
        state.matchedLocation.startsWith('/splash');
    if (!isLoggedIn && !isAuthRoute) return '/auth';
    if (isLoggedIn && isAuthRoute) return '/home';
    return null;
  },
  routes: [
    GoRoute(path: '/splash',      builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/onboarding',  builder: (_, __) => const OnboardingScreen()),
    GoRoute(path: '/auth',        builder: (_, __) => const AuthScreen()),
    StatefulShellRoute.indexedStack(
      builder: (_, __, shell) => MainShell(shell: shell),
      branches: [
        StatefulShellBranch(routes: [GoRoute(path: '/home', builder: (_, __) => const HomeScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: '/analytics', builder: (_, __) => const AnalyticsScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen())]),
      ],
    ),
    GoRoute(path: '/history',  builder: (_, __) => const HistoryScreen()),
    GoRoute(path: '/budget',   builder: (_, __) => const BudgetScreen()),
  ],
);
```

---

## Data Models

```dart
// features/expenses/models/expense.dart
class Expense {
  final String id;
  final String userId;
  final double amount;
  final String category;    // lowercase: 'food', 'transport', etc.
  final String? note;
  final DateTime date;
  final String paymentMethod; // 'cash', 'upi', 'card'
  final DateTime createdAt;
}
```

```dart
// features/budget/models/budget.dart
class Budget {
  final String id;
  final String userId;
  final double monthlyLimit;
  final int month;  // 1-12
  final int year;
}
```

---

## Supabase Service

```dart
// services/supabase_service.dart
// Initialize once in main.dart
await Supabase.initialize(
  url: const String.fromEnvironment('SUPABASE_URL'),
  anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
);

SupabaseClient get supabase => Supabase.instance.client;
```

Pass env vars at build time:
```
flutter run --dart-define=SUPABASE_URL=xxx --dart-define=SUPABASE_ANON_KEY=xxx
```

---

## Key Provider Patterns

```dart
// Auth provider
@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  User? build() => supabase.auth.currentUser;

  Future<void> signIn(String email, String password) async {
    await supabase.auth.signInWithPassword(email: email, password: password);
    state = supabase.auth.currentUser;
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
    state = null;
  }
}
```

```dart
// Expenses provider — realtime
@riverpod
class ExpensesNotifier extends _$ExpensesNotifier {
  @override
  Future<List<Expense>> build() async {
    // Subscribe to realtime
    supabase.from('expenses')
      .stream(primaryKey: ['id'])
      .eq('user_id', supabase.auth.currentUser!.id)
      .listen((data) => state = AsyncData(data.map(Expense.fromJson).toList()));
    return [];
  }

  Future<void> addExpense(Expense expense) async {
    await supabase.from('expenses').insert(expense.toJson());
  }

  Future<void> deleteExpense(String id) async {
    await supabase.from('expenses').delete().eq('id', id);
  }
}
```

---

## Analytics Calls (FastAPI)

Analytics aggregation calls go to FastAPI, not Supabase directly:

```dart
// features/analytics/repositories/analytics_repository.dart
class AnalyticsRepository {
  final _base = const String.fromEnvironment('API_BASE_URL');

  Future<Map<String, dynamic>> getMonthlyAnalytics(int month, int year) async {
    final token = supabase.auth.currentSession!.accessToken;
    final res = await http.get(
      Uri.parse('$_base/analytics/monthly?month=$month&year=$year'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return jsonDecode(res.body);
  }
}
```

---

## Add Expense Sheet (Critical UX)

```dart
// Must open in < 200ms — use showModalBottomSheet with:
showModalBottomSheet(
  context: context,
  isScrollControlled: true,       // full height
  backgroundColor: Colors.transparent,
  useSafeArea: true,
  builder: (_) => const AddExpenseSheet(),
);
```

Auto-focus amount field on open:
```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _amountFocusNode.requestFocus();
  });
}
```

---

## Platform-Specific Notes

### iOS
- Use `CupertinoDatePicker` for date selection inside bottom sheet
- `SafeArea` always wraps content
- Haptic feedback on save: `HapticFeedback.mediumImpact()`

### Android
- Material date picker fallback
- Use `SystemUiOverlayStyle.dark` for status bar
- Edge-to-edge display: set in `MainActivity.kt`:
  ```kotlin
  WindowCompat.setDecorFitsSystemWindows(window, false)
  ```

---

## Build Commands

```bash
# Dev
flutter run --dart-define=SUPABASE_URL=xxx --dart-define=SUPABASE_ANON_KEY=xxx --dart-define=API_BASE_URL=xxx

# iOS Release
flutter build ipa --dart-define=...

# Android Release
flutter build appbundle --dart-define=...
```

---

## What NOT to Do

- Do NOT use `setState` in feature screens — use Riverpod
- Do NOT call FastAPI for CRUD — use Supabase SDK directly
- Do NOT use `Navigator.push` — use `context.go()` (GoRouter)
- Do NOT hardcode colors — always use `AppColors.*`
- Do NOT use default Material widgets unstyled — always override
- Do NOT add any AI, social, or investment features
