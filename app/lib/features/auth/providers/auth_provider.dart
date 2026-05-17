import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/supabase_service.dart';
import '../repositories/auth_repository.dart';

final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  return supabase.auth.onAuthStateChange;
});

class AuthNotifier extends Notifier<User?> {
  @override
  User? build() {
    ref.listen(authStateChangesProvider, (_, next) {
      state = next.valueOrNull?.session?.user;
    });
    return supabase.auth.currentUser;
  }

  Future<void> signIn(String email, String password) async {
    await ref.read(authRepositoryProvider).signIn(email, password);
  }

  Future<void> signUp(String email, String password) async {
    await ref.read(authRepositoryProvider).signUp(email, password);
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
  }
}

final authNotifierProvider =
    NotifierProvider<AuthNotifier, User?>(() => AuthNotifier());
