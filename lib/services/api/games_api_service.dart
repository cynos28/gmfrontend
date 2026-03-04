// API client for adaptive games via unit-rag-service (port 8000)
// Handles game parameter fetching, session evaluation, and IRT per-round updates.

import 'dart:convert';  
import 'package:http/http.dart' as http; 

class GamesApiService {
  static const List<String> _baseUrls = [
    'http://172.21.246.68:8000/adaptive-games', // WiFi – primary
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

  /// Fetch current game parameters for a domain (length / area / volume / weight).
  /// If [studentId] and [variant] are provided, IRT-adapted params are merged.
  /// Falls back to sensible defaults when offline.
  static Future<Map<String, dynamic>> getParameters(
    String domain, {
    String? studentId,
    String? variant,
  }) async {
    try {
      final base = await _getWorkingBaseUrl();
      final uri = Uri.parse('$base/parameters/$domain').replace(
        queryParameters: {
          if (studentId != null) 'student_id': studentId,
          if (variant != null) 'variant': variant,
        },
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        return json.decode(res.body) as Map<String, dynamic>;
      }
    } catch (e) {
      // ignore – fall through to default
    }
    return _defaultParams(domain);
  }

  /// Post a completed game session and receive the updated difficulty params.
  /// (Legacy — used by non-IRT variants like L-V1)
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

  // ─── IRT per-round endpoint (Build-a-Bridge L-V4) ────────────────────────

  /// Submit one round result to the IRT engine and receive updated θ,
  /// difficulty level, and next-round game parameters.
  static Future<Map<String, dynamic>> submitRoundResult({
    required String studentId,
    required String domain,
    required String variant,
    required bool correct,
    required int attempts,
    int hintsUsed = 0,
    double timeSeconds = 0.0,
    int starsEarned = 0,
  }) async {
    try {
      final base = await _getWorkingBaseUrl();
      final res = await http
          .post(
            Uri.parse('$base/round-result'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'student_id': studentId,
              'domain': domain,
              'variant': variant,
              'correct': correct,
              'attempts': attempts,
              'hints_used': hintsUsed,
              'time_seconds': timeSeconds,
              'stars_earned': starsEarned,
            }),
          )
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        return json.decode(res.body) as Map<String, dynamic>;
      }
    } catch (e) {
      // ignore – fall through to default
    }
    return {
      'theta': 0.0,
      'difficulty_level': 1,
      'p_expected': 0.5,
      'next_params': _defaultParamsForVariant(domain, variant),
      'rounds_played': 0,
    };
  }

  /// Fetch the full IRT session state for a student+variant.
  static Future<Map<String, dynamic>> getIRTState({
    required String studentId,
    String domain = 'length',
    String variant = 'L-V4',
  }) async {
    try {
      final base = await _getWorkingBaseUrl();
      final uri = Uri.parse('$base/irt-state/$studentId').replace(
        queryParameters: {'domain': domain, 'variant': variant},
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        return json.decode(res.body) as Map<String, dynamic>;
      }
    } catch (e) {
      // ignore
    }
    return {
      'student_id': studentId,
      'theta': 0.0,
      'difficulty_level': 1,
      'rounds_played': 0,
      'next_params': _defaultParamsForVariant(domain, variant),
    };
  }

  /// Get default params based on domain+variant.
  static Map<String, dynamic> _defaultParamsForVariant(String domain, String variant) {
    if (domain == 'area' && variant == 'A-V1') return _defaultAreaTileParams();
    if (domain == 'area' && variant == 'A-V2') return _defaultAreaArchitectParams();
    if (domain == 'volume' && variant == 'V-V1') return _defaultVolumeFillParams();
    if (domain == 'volume' && variant == 'V-V2') return _defaultVolumeCompareParams();
    if (domain == 'weight' && variant == 'W-W1') return _defaultWeightMatchParams();
    if (domain == 'weight' && variant == 'W-W2') return _defaultWeightEqualParams();
    return _defaultBridgeParams();
  }

  /// Fetch IRT analytics (θ trend, accuracy, etc.).
  static Future<Map<String, dynamic>> getIRTStats({
    required String studentId,
    String domain = 'length',
    String variant = 'L-V4',
  }) async {
    try {
      final base = await _getWorkingBaseUrl();
      final uri = Uri.parse('$base/irt-stats/$studentId').replace(
        queryParameters: {'domain': domain, 'variant': variant},
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        return json.decode(res.body) as Map<String, dynamic>;
      }
    } catch (e) {
      // ignore
    }
    return {
      'total_rounds': 0,
      'accuracy': 0.0,
      'theta_trend': <double>[],
      'difficulty_trend': <int>[],
    };
  }

  // ─── defaults ────────────────────────────────────────────────────────────

  static Map<String, dynamic> _defaultBridgeParams() => {
    'bridge_target_range': [12, 18],
    'plank_sizes': [3, 4, 5, 6, 7, 8],
    'plank_count': 7,
    'min_solution_planks': 2,
    'max_solution_planks': 4,
    'hints': 2,
  };

  static Map<String, dynamic> _defaultAreaTileParams() => {
    'min_rect_size': 2,
    'max_rect_size': 6,
    'grid_visible': true,
    'extra_grid_min': 1,
    'extra_grid_max': 3,
    'hints': 2,
  };

  static Map<String, dynamic> _defaultAreaArchitectParams() => {
    'room_rows_range': [4, 6],
    'room_cols_range': [5, 8],
    'target_width_range': [3, 6],
    'target_height_range': [3, 5],
    'level_types': ['formulaRectangle', 'mysterySide'],
    'hints': 2,
  };

  static Map<String, dynamic> _defaultVolumeFillParams() => {
    'capacity_ml': 500,
    'target_ml_options': [100, 150, 200, 250, 300],
    'tolerance_ml': 5,
    'normal_pour_step': 100,
    'fast_pour_step': 50,
    'fine_tune_step': 10,
    'hints': 3,
  };

  static Map<String, dynamic> _defaultVolumeCompareParams() => {
    'question_types': ['most', 'least', 'same'],
    'size_differences': [0.5, 0.7, 1.0],
    'container_types': ['cup1', 'glass1', 'jug1', 'jug2'],
    'option_count': 3,
    'hints': 2,
  };

  static Map<String, dynamic> _defaultWeightMatchParams() => {
    'available_weight_grams': [10, 50],
    'max_target_grams': 100,
    'max_pieces': 2,
    'hints': 3,
  };

  static Map<String, dynamic> _defaultWeightEqualParams() => {
    'available_weight_grams': [10, 50],
    'max_target_grams': 100,
    'max_pieces': 2,
    'hints': 3,
  };

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
          // V4 (Bridge) params — IRT level-3 defaults
          'bridge_target_range': [12, 18],
          'plank_sizes': [3, 4, 5, 6, 7, 8],
          'plank_count': 7,
          'min_solution_planks': 2,
          'max_solution_planks': 4,
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
      case 'volume':
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
