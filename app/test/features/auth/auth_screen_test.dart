import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:spent/core/theme/app_theme.dart';
import 'package:spent/features/auth/providers/auth_provider.dart';
import 'package:spent/features/auth/screens/auth_screen.dart';

// Fake that succeeds silently — no Supabase calls.
// signUp returns false = email confirmation required (the default Supabase behaviour).
class _PassNotifier extends AuthNotifier {
  @override
  User? build() => null;

  @override
  Future<void> signIn(String email, String password) async {}

  @override
  Future<bool> signUp(String email, String password) async => false;
}

// Fake that always throws an AuthException with a given message.
class _FailNotifier extends AuthNotifier {
  final String msg;
  _FailNotifier(this.msg);

  @override
  User? build() => null;

  @override
  Future<void> signIn(String email, String password) async =>
      throw AuthException(msg);

  @override
  Future<bool> signUp(String email, String password) async =>
      throw AuthException(msg);
}

Widget _wrap(AuthNotifier Function() factory) => ProviderScope(
      overrides: [authNotifierProvider.overrideWith(factory)],
      child: MaterialApp(theme: buildAppTheme(), home: const AuthScreen()),
    );

void main() {
  // ─── Form validation ──────────────────────────────────────────────────────

  group('AuthScreen – form validation', () {
    testWidgets('rejects email without @', (tester) async {
      await tester.pumpWidget(_wrap(_PassNotifier.new));

      await tester.enterText(find.byType(TextField).at(0), 'notanemail');
      await tester.enterText(find.byType(TextField).at(1), 'password123');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(find.text('Enter a valid email address'), findsOneWidget);
    });

    testWidgets('rejects password shorter than 6 characters', (tester) async {
      await tester.pumpWidget(_wrap(_PassNotifier.new));

      await tester.enterText(find.byType(TextField).at(0), 'user@test.com');
      await tester.enterText(find.byType(TextField).at(1), '123');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(find.text('Password must be at least 6 characters'), findsOneWidget);
    });

    testWidgets('rejects mismatched confirm password in sign-up mode', (tester) async {
      await tester.pumpWidget(_wrap(_PassNotifier.new));

      await tester.tap(find.text('Sign up'));
      await tester.pump();

      await tester.enterText(find.byType(TextField).at(0), 'user@test.com');
      await tester.enterText(find.byType(TextField).at(1), 'securepass');
      await tester.enterText(find.byType(TextField).at(2), 'different123');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('clears errors after toggling mode', (tester) async {
      await tester.pumpWidget(_wrap(_PassNotifier.new));

      // Trigger email error in sign-in mode
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      expect(find.text('Enter a valid email address'), findsOneWidget);

      // Toggle to sign-up — errors should clear
      await tester.tap(find.text('Sign up'));
      await tester.pump();
      expect(find.text('Enter a valid email address'), findsNothing);
    });
  });

  // ─── Mode toggle ─────────────────────────────────────────────────────────

  group('AuthScreen – mode toggle', () {
    testWidgets('starts in sign-in mode with 2 text fields', (tester) async {
      await tester.pumpWidget(_wrap(_PassNotifier.new));

      expect(find.text('Sign In'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2));
    });

    testWidgets('toggles to sign-up showing confirm field and Create Account button',
        (tester) async {
      await tester.pumpWidget(_wrap(_PassNotifier.new));

      await tester.tap(find.text('Sign up'));
      await tester.pump();

      expect(find.text('Create Account'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(3));
    });

    testWidgets('toggles back to sign-in removing confirm field', (tester) async {
      await tester.pumpWidget(_wrap(_PassNotifier.new));

      await tester.tap(find.text('Sign up'));
      await tester.pump();
      await tester.tap(find.text('Sign in'));
      await tester.pump();

      expect(find.text('Sign In'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2));
    });
  });

  // ─── Sign-in flow ─────────────────────────────────────────────────────────

  group('AuthScreen – sign-in flow', () {
    testWidgets('accepts valid credentials without error', (tester) async {
      await tester.pumpWidget(_wrap(_PassNotifier.new));

      await tester.enterText(find.byType(TextField).at(0), 'user@test.com');
      await tester.enterText(find.byType(TextField).at(1), 'securepass');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Something went wrong. Try again.'), findsNothing);
      expect(find.text('Enter a valid email address'), findsNothing);
    });

    testWidgets('shows AuthException message on sign-in failure', (tester) async {
      await tester.pumpWidget(_wrap(() => _FailNotifier('Invalid login credentials')));

      await tester.enterText(find.byType(TextField).at(0), 'user@test.com');
      await tester.enterText(find.byType(TextField).at(1), 'wrongpass');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump(); // loading state
      await tester.pump(); // future resolves

      expect(find.text('Invalid login credentials'), findsOneWidget);
    });

    testWidgets('shows generic error on unexpected exception', (tester) async {
      // Notifier that throws a non-AuthException
      final provider = authNotifierProvider.overrideWith(() {
        return _GenericFailNotifier();
      });
      await tester.pumpWidget(ProviderScope(
        overrides: [provider],
        child: MaterialApp(theme: buildAppTheme(), home: const AuthScreen()),
      ));

      await tester.enterText(find.byType(TextField).at(0), 'user@test.com');
      await tester.enterText(find.byType(TextField).at(1), 'password123');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      await tester.pump();

      expect(find.text('Something went wrong. Try again.'), findsOneWidget);
    });
  });

  // ─── Register flow ────────────────────────────────────────────────────────

  group('AuthScreen – register flow', () {
    testWidgets('shows confirmation screen when email verification is required',
        (tester) async {
      await tester.pumpWidget(_wrap(_PassNotifier.new));

      await tester.tap(find.text('Sign up'));
      await tester.pump();

      await tester.enterText(find.byType(TextField).at(0), 'new@test.com');
      await tester.enterText(find.byType(TextField).at(1), 'securepass');
      await tester.enterText(find.byType(TextField).at(2), 'securepass');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Check your inbox'), findsOneWidget);
      expect(find.text('Back to Sign In'), findsOneWidget);
      expect(find.text('Something went wrong. Try again.'), findsNothing);
    });

    testWidgets('Back to Sign In button returns to sign-in form', (tester) async {
      await tester.pumpWidget(_wrap(_PassNotifier.new));

      await tester.tap(find.text('Sign up'));
      await tester.pump();
      await tester.enterText(find.byType(TextField).at(0), 'new@test.com');
      await tester.enterText(find.byType(TextField).at(1), 'securepass');
      await tester.enterText(find.byType(TextField).at(2), 'securepass');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Back to Sign In'));
      await tester.pump();

      expect(find.text('Sign In'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2));
    });

    testWidgets('shows AuthException message on register failure', (tester) async {
      await tester.pumpWidget(_wrap(() => _FailNotifier('User already registered')));

      await tester.tap(find.text('Sign up'));
      await tester.pump();

      await tester.enterText(find.byType(TextField).at(0), 'taken@test.com');
      await tester.enterText(find.byType(TextField).at(1), 'securepass');
      await tester.enterText(find.byType(TextField).at(2), 'securepass');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      await tester.pump();

      expect(find.text('User already registered'), findsOneWidget);
    });
  });
}

class _GenericFailNotifier extends AuthNotifier {
  @override
  User? build() => null;

  @override
  Future<void> signIn(String email, String password) async =>
      throw Exception('network error');

  @override
  Future<bool> signUp(String email, String password) async =>
      throw Exception('network error');
}
