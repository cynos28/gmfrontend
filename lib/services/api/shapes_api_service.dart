import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:ganithamithura/models/shape_models.dart';
import 'package:ganithamithura/models/shape_model.dart';
import 'package:ganithamithura/utils/constants.dart';

/// Shapes API Service - Handles all shapes game backend API calls
class ShapesApiService {
  static ShapesApiService? _instance;
  final String baseUrl;
  
  ShapesApiService._({required this.baseUrl});
  
  static ShapesApiService get instance {
    _instance ??= ShapesApiService._(baseUrl: '${AppConstants.baseUrl}/shapes-patterns');
    return _instance!;
  }
  
  /// Helper method to create headers
  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }
  
  // ==================== Health Check ====================
  
  /// Check if the backend server is reachable
  Future<bool> checkBackendHealth() async {
    try {
      final url = Uri.parse('$baseUrl/');
      final response = await http.get(url).timeout(
        const Duration(seconds: 5),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  
  /// Get detailed backend status for debugging
  Future<Map<String, dynamic>> getBackendStatus() async {
    final status = {
      'baseUrl': baseUrl,
      'isReachable': false,
      'error': null,
    };
    
    try {
      final url = Uri.parse('$baseUrl/');
      final response = await http.get(url).timeout(
        const Duration(seconds: 5),
      );
      status['isReachable'] = response.statusCode == 200;
      status['statusCode'] = response.statusCode;
    } on SocketException catch (e) {
      status['error'] = 'Cannot connect to server: ${e.message}';
    } on TimeoutException {
      status['error'] = 'Connection timeout';
    } catch (e) {
      status['error'] = e.toString();
    }
    
    return status;
  }
  
  // ==================== Game Endpoints ====================
  
  /// GET /game/start - Start a new game and get game data
  /// 
  /// Returns game data based on the current level or game type.
  /// The response structure varies based on game type:
  /// - Shape matching games (level1, level3): Contains shapes and word_pool
  /// - Question games (level2, level4): Contains questions, answer_pool, correct_answers
  /// - Pattern games (level5, level6): Contains patterns and shape_pool
  Future<ShapeGame> startGame({String? gameId}) async {
    print('🔍 DEBUG - ShapesApiService baseUrl: $baseUrl');
    print('🔍 DEBUG - AppConstants.baseUrl: ${AppConstants.baseUrl}');
    
    try {
      final headers = _getHeaders();
      final uri = gameId != null 
          ? Uri.parse('$baseUrl/game/start?game_id=$gameId')
          : Uri.parse('$baseUrl/game/start');
      
      print('🔍 DEBUG - Full URI: $uri');
      
      final response = await http.get(
        uri,
        headers: headers,
      ).timeout(
        Duration(seconds: AppConstants.apiTimeout),
        onTimeout: () {
          throw TimeoutException(
            'Backend server not responding. Please ensure:\n'
            '1. Backend is running (start-gateway.ps1)\n'
            '2. MongoDB is running\n'
            '3. Using correct URL: $baseUrl'
          );
        },
      );
      
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return ShapeGame.fromJson(jsonData);
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required. Please login.');
      } else {
        throw Exception('Failed to start game: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception(
        'Cannot connect to backend server at $baseUrl\n'
        'Please ensure:\n'
        '1. Backend is running (start-gateway.ps1)\n'
        '2. MongoDB is running\n'
        '3. For Android emulator: using 10.0.2.2\n'
        '4. For physical device: using computer\'s IP address'
      );
    } on TimeoutException catch (e) {
      throw Exception(e.message ?? 'Connection timeout');
    } catch (e) {
      throw Exception('Error starting game: $e');
    }
  }
  
  /// POST /game/check-answers - Submit answers and get results
  /// 
  /// Submits user's answers for validation and receives score/results.
  /// Request body:
  /// {
  ///   "game_id": "level1",
  ///   "answers": {
  ///     "1": "Circle",
  ///     "2": "Square",
  ///     ...
  ///   }
  /// }
  /// 
  /// Response:
  /// {
  ///   "game_id": "level1",
  ///   "score": 80,
  ///   "total_questions": 4,
  ///   "correct_answers": 3,
  ///   "wrong_answers": 1,
  ///   "answer_results": {
  ///     "1": true,
  ///     "2": true,
  ///     "3": false,
  ///     "4": true
  ///   },
  ///   "is_passed": true
  /// }
  Future<GameResult> checkAnswers(GameAnswer gameAnswer) async {
    try {
      final headers = _getHeaders();
      final url = Uri.parse('$baseUrl/game/check-answers');
      
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(gameAnswer.toJson()),
      ).timeout(
        Duration(seconds: AppConstants.apiTimeout),
        onTimeout: () {
          throw TimeoutException('Backend server not responding');
        },
      );
      
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return GameResult.fromJson(jsonData);
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required. Please login.');
      } else if (response.statusCode == 400) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(jsonData['detail'] ?? 'Invalid request');
      } else {
        throw Exception('Failed to check answers: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Cannot connect to backend server at $baseUrl');
    } on TimeoutException catch (e) {
      throw Exception(e.message ?? 'Connection timeout');
    } catch (e) {
      throw Exception('Error checking answers: $e');
    }
  }
  
  // ==================== Convenience Methods ====================
  
  /// Start Level 1 - Match 2D Shapes with Names
  Future<ShapeMatchingGame> startLevel1() async {
    final game = await startGame(gameId: 'level1');
    return game as ShapeMatchingGame;
  }
  
  /// Start Level 2 - Shape Knowledge Quiz (2D)
  Future<QuestionRoundGame> startLevel2() async {
    final game = await startGame(gameId: 'level2');
    return game as QuestionRoundGame;
  }
  
  /// Start Level 3 - Match 3D Shapes with Names
  Future<ShapeMatchingGame> startLevel3() async {
    final game = await startGame(gameId: 'level3');
    return game as ShapeMatchingGame;
  }
  
  /// Start Level 4 - 3D Shape Knowledge Quiz
  Future<QuestionRoundGame> startLevel4() async {
    final game = await startGame(gameId: 'level4');
    return game as QuestionRoundGame;
  }
  
  /// Start Level 5 - Pattern Matching (2D Shapes)
  Future<PatternMatchingGame> startLevel5() async {
    final game = await startGame(gameId: 'level5');
    return game as PatternMatchingGame;
  }
  
  /// Start Level 6 - Pattern Matching (3D Shapes)
  Future<PatternMatchingGame> startLevel6() async {
    final game = await startGame(gameId: 'level6');
    return game as PatternMatchingGame;
  }
  
  /// GET /game/level-access - Get level access status
  /// 
  /// Returns information about which levels are locked/unlocked for the user.
  /// Response:
  /// {
  ///   "highest_passed_level": 5,
  ///   "available_levels": [1, 2, 3, 4, 5, 6],
  ///   "locked_levels": [7, 8],
  ///   "total_levels": 8,
  ///   "level_details": [
  ///     {
  ///       "level": 1,
  ///       "is_locked": false,
  ///       "is_passed": true,
  ///       "status": "pass",
  ///       "attempts": 3
  ///     },
  ///     ...
  ///   ]
  /// }
  Future<Map<String, dynamic>> getLevelAccessStatus() async {
    try {
      final headers = _getHeaders();
      final url = Uri.parse('$baseUrl/game/user-progress');
      
      final response = await http.get(
        url,
        headers: headers,
      ).timeout(
        Duration(seconds: AppConstants.apiTimeout),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        // Convert to expected format for compatibility
        final levels = data['levels'] as List<dynamic>;
        return {
          'highest_passed_level': data['highest_passed_level'],
          'locked_levels': levels
              .where((l) => l['is_locked'] == true)
              .map((l) => l['level'])
              .toList(),
          'level_details': levels,
        };
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required. Please login.');
      } else {
        throw Exception('Failed to get level access status: ${response.statusCode}');
      }
    } catch (e) {
      // Return default unlocked state instead of throwing
      // This allows the app to work in offline mode
      return {
        'highest_passed_level': 0,
        'locked_levels': <int>[],
        'level_details': List.generate(6, (index) => {
          'level': index + 1,
          'is_locked': false,
          'is_passed': false,
          'status': 'available',
          'attempts': 0,
        }),
      };
    }
  }
  
  // ==================== Mock Data (for offline development/testing) ====================
  
  /// Get mock data for testing without backend
  Future<ShapeGame> getMockGame(String gameId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    switch (gameId) {
      case 'level1':
        return ShapeMatchingGame(
          gameId: 'level1',
          level: 1,
          title: 'Match Shapes with Names',
          shapes: [
            ShapeData(id: '1', name: 'Circle', imageUrl: 'assets/images/2d_shapes/circle.png'),
            ShapeData(id: '2', name: 'Square', imageUrl: 'assets/images/2d_shapes/square.png'),
            ShapeData(id: '3', name: 'Triangle', imageUrl: 'assets/images/2d_shapes/triangle.png'),
          ],
          wordPool: ['Circle', 'Square', 'Triangle'],
        );
      case 'level2':
        return QuestionRoundGame(
          gameId: 'level2',
          level: 2,
          title: 'Shape Knowledge Quiz - Match the Correct Answer',
          questions: [
            ShapeQuestion(id: 'q1', question: 'Which shape has no sides and no corners?'),
            ShapeQuestion(id: 'q2', question: 'Which shape has four equal sides and four right angles?'),
            ShapeQuestion(id: 'q3', question: 'Which shape has three sides and three corners?'),
          ],
          answerPool: ['Circle', 'Square', 'Triangle', 'Rectangle', 'Oval'],
          correctAnswers: {'q1': 'Circle', 'q2': 'Square', 'q3': 'Triangle'},
        );
      default:
        throw Exception('Mock data not available for $gameId');
    }
  }
  
  // ==================== Shapes Learning Endpoints ====================
  
  /// GET /shapes/ - Get all shapes from database
  Future<List<ShapeModel>> getAllShapes() async {
    try {
      final url = Uri.parse('$baseUrl/shapes/');
      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Connection timeout'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => ShapeModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load shapes: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load shapes: $e');
    }
  }

  /// GET /shapes/type/{type} - Get shapes by type (2d or 3d)
  Future<List<ShapeModel>> getShapesByType(String type) async {
    try {
      final url = Uri.parse('$baseUrl/shapes/type/$type');
      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Connection timeout'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => ShapeModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load $type shapes: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load $type shapes: $e');
    }
  }

  /// GET /shapes/id/{id} - Get shape by ID
  Future<ShapeModel> getShapeById(String shapeId) async {
    try {
      final url = Uri.parse('$baseUrl/shapes/id/$shapeId');
      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Connection timeout'),
      );

      if (response.statusCode == 200) {
        return ShapeModel.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load shape: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load shape: $e');
    }
  }

  /// GET /shapes/name/{name} - Get shape by name
  Future<ShapeModel> getShapeByName(String shapeName) async {
    try {
      final url = Uri.parse('$baseUrl/shapes/name/$shapeName');
      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Connection timeout'),
      );

      if (response.statusCode == 200) {
        return ShapeModel.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load shape: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load shape: $e');
    }
  }
}
