import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ganithamithura/utils/constants.dart';

class SymbolService {
  static final SymbolService _instance = SymbolService._init();
  static SymbolService get instance => _instance;

  SymbolService._init();

  // URL for the symbol-service (running on port 8000)
  // Re-use emulator logic or constants. Since auth is 8001, symbol is usually 8000
  String get _baseUrl {
    if (AppConstants.baseUrl.contains('8001')) {
      return AppConstants.baseUrl.replaceAll('8001', '8000');
    }
    return 'http://10.0.2.2:8000'; // Default for android emulator
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

  Future<String> getCharacter(String userId) async {
    try {
      final url = Uri.parse('$_baseUrl/api/users/$userId/character');
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: AppConstants.apiTimeout));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['character_name'] ?? 'Cat';
      } else {
        return 'Cat'; // default fallback
      }
    } catch (e) {
      print('Error loading character: $e');
      return 'Cat'; // default fallback
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
}
