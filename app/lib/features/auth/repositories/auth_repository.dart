import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/supabase_service.dart';

class AuthRepository {
  const AuthRepository();

  Future<void> signIn(String email, String password) async {
    await supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUp(String email, String password) async {
    await supabase.auth.signUp(email: email, password: password);
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }
}

final authRepositoryProvider = Provider<AuthRepository>((_) => const AuthRepository());
