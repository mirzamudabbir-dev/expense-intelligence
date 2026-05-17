import 'package:flutter_riverpod/flutter_riverpod.dart';

final analyticsProvider =
    StateProvider<Map<String, dynamic>>((ref) => const {});
