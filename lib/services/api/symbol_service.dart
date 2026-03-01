import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ganithamithura/utils/constants.dart';

class SymbolService {
  static final SymbolService _instance = SymbolService._init();
  static SymbolService get instance => _instance;

  SymbolService._init();

  String get _baseUrl {
    String? envUrl = dotenv.env['SYMBOL_BACKEND_URL'];
    if (envUrl != null && envUrl.isNotEmpty) {
      return envUrl;
    }
    return AppConstants.symbolBaseUrl;
  }

  Future<void> saveCharacter(String userId, String characterName) async {
    try {
      final url = Uri.parse('$_baseUrl/api/users/$userId/character');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'character_name': characterName}),
      ).timeout(const Duration(seconds: AppConstants.apiTimeout));

      if (response.statusCode != 200) {
        throw Exception('Failed to save character: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error saving character: $e');
    }
  }

  Future<String?> getCharacter(String userId) async {
    try {
      final url = Uri.parse('$_baseUrl/api/users/$userId/character');
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: AppConstants.apiTimeout));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['character_name'];
      } else {
        return null; // Explicitly returning null means they haven't chosen one
      }
    } catch (e) {
      print('Error loading character: $e');
      return null;
    }
  }

  Future<void> saveScore({
    required String userId,
    required String gameName,
    required int score,
    int level = 1,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/api/users/$userId/scores');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'game_name': gameName,
          'score': score,
          'level': level,
        }),
      ).timeout(const Duration(seconds: AppConstants.apiTimeout));

      if (response.statusCode != 200) {
        throw Exception('Failed to save score: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error saving score: $e');
    }
  }

  Future<List<dynamic>> getLeaderboard() async {
    try {
      final url = Uri.parse('$_baseUrl/api/game/leaderboard');
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: AppConstants.apiTimeout));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['leaderboard'] ?? [];
      } else {
        return [];
      }
    } catch (e) {
      print('Error parsing leaderboard: $e');
      return [];
    }
  }
}

