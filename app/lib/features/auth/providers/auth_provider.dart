import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/supabase_service.dart';

final authProvider = StateProvider<User?>((ref) => supabase.auth.currentUser);
