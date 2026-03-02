// API client for adaptive games via unit-rag-service (port 8000)
// Handles game parameter fetching and session evaluation.

import 'dart:convert';  
import 'package:http/http.dart' as http; 

class GamesApiService {
  static const List<String> _baseUrls = [
    'http://10.169.0.71:8000/adaptive-games', // WiFi – primary
    'http://localhost:8000/adaptive-games', // ADB reverse
    'http://10.0.2.2:8000/adaptive-games', // Android emulator
  ];

  // ─── internal helpers ────────────────────────────────────────────────────

  static Future<String> _getWorkingBaseUrl() async {
    for (final url in _baseUrls) {
      try {
        final healthUrl = url.replaceAll('/adaptive-games', '/health');
        final res = await http
            .get(Uri.parse(healthUrl))
            .timeout(const Duration(seconds: 2));
        if (res.statusCode == 200) return url;
      } catch (_) {}
    }
    return _baseUrls.first;
  }

  // ─── public API ──────────────────────────────────────────────────────────

  /// Fetch current game parameters for a domain (length / area / capacity / weight).
  /// Falls back to sensible defaults when offline.
  static Future<Map<String, dynamic>> getParameters(String domain) async {
    try {
      final base = await _getWorkingBaseUrl();
      final res = await http
          .get(Uri.parse('$base/parameters/$domain'))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        return json.decode(res.body) as Map<String, dynamic>;
      }
    } catch (e) {
      // ignore – fall through to default
    }
    return _defaultParams(domain);
  }

  /// Post a completed game session and receive the updated difficulty params.
  static Future<Map<String, dynamic>> evaluateSession({
    required String userId,
    required String domain,
    required int attempts,
    required double time,
    required double targetTime,
    required int hints,
  }) async {
    try {
      final base = await _getWorkingBaseUrl();
      final res = await http
          .post(
            Uri.parse('$base/evaluate'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'user_id': userId,
              'domain': domain,
              'attempts': attempts,
              'time': time,
              'target_time': targetTime,
              'hints': hints,
            }),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        return json.decode(res.body) as Map<String, dynamic>;
      }
    } catch (e) {
      // ignore – fall through to default
    }
    return {'diagnosis': 'maintain', 'new_params': {}};
  }

  // ─── defaults ────────────────────────────────────────────────────────────

  static Map<String, dynamic> _defaultParams(String domain) {
    switch (domain) {
      case 'length':
        return {
          'current_variant': 'L-V1',
          'hints': 2,
          // V1 (Ruler Explorer) params
          'object_size_range': [5, 15],
          'choice_spread': 3,
          // V2 (Compare) params
          'min_size_difference': 3,
          // V3 (Calculate & Win) params
          'allow_decimals': false,
          'value_range_mm': [30, 150],
          'value_range_m': [0.05, 0.25],
          // V4 (Bridge) params
          'bridge_target_range': [10, 18],
          'plank_sizes': [3, 4, 5, 6, 7, 8, 9],
          'plank_count': 7,
        };
      case 'area':
        return {
          'current_variant': 'A-V1',
          'hints': 2,
          // V1 (Tile Rectangle) params
          'max_rect_size': 6,
          'min_rect_size': 2,
          'grid_visible': true,
          // V2 (Tile Irregular Shape) params
          'shape_complexity': 1,
          // V3 (Build Target Area) params
          'target_area_range': [8, 20],
          'require_two_solutions': false,
          // V4 (Composite Area) params
          'max_parts': 2,
        };
      case 'capacity':
        return {
          'current_variant': 'C-V1',
          'target_volume': 200,
          'pour_step': 50,
          'show_ghost_line': true,
          'ingredients': 1,
        };
      case 'weight':
        return {
          'current_variant': 'W-V1',
          'target_weight': 300,
          'tolerance': 0.15,
          'show_labels': true,
          'object_variety': 2,
        };
      default:
        return {'current_variant': '${domain[0].toUpperCase()}-V1'};
    }
  }
}
