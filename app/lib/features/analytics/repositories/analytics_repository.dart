import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../services/supabase_service.dart';
import '../models/analytics_data.dart';

class AnalyticsRepository {
  const AnalyticsRepository();

  static const _base = String.fromEnvironment('API_BASE_URL');

  Future<AnalyticsData> getMonthlyAnalytics(int month, int year) async {
    final token = supabase.auth.currentSession?.accessToken;
    if (token == null) throw Exception('Not authenticated');

    final uri = Uri.parse('$_base/analytics/monthly')
        .replace(queryParameters: {'month': '$month', 'year': '$year'});

    final res = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode != 200) {
      throw Exception('Analytics request failed: ${res.statusCode}');
    }

    return AnalyticsData.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }
}
