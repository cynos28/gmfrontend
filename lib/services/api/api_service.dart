import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ganithamithura/models/models.dart';
import 'package:ganithamithura/utils/constants.dart';

/// ApiService - Handles all backend API calls
class ApiService {
  static ApiService? _instance;
  final String baseUrl;
  
  ApiService._({required this.baseUrl});
  
  static ApiService get instance {
    _instance ??= ApiService._(baseUrl: AppConstants.baseUrl);
    return _instance!;
  }
  
  /// Helper method to create headers
  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }
  
  // ==================== Activity Endpoints ====================
  
  /// GET /levels/{level}/activities - Fetch activities for a level
  Future<List<Activity>> getActivitiesForLevel(int level) async {
    try {
      final url = Uri.parse('$baseUrl/levels/$level/activities');
      final response = await http.get(
        url,
        headers: _getHeaders(),
      ).timeout(
        Duration(seconds: AppConstants.apiTimeout),
      );
      
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final activitiesList = jsonData['activities'] as List;
        return activitiesList
            .map((json) => Activity.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to load activities: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching activities: $e');
    }
  }
  
  /// POST /activity/score - Submit activity score
  Future<Map<String, dynamic>> submitActivityScore({
    required String activityId,
    required int score,
    required bool isCompleted,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/activity/score');
      final body = {
        'activity_id': activityId,
        'score': score,
        'is_completed': isCompleted,
        'completed_at': DateTime.now().toIso8601String(),
        'additional_data': additionalData,
      };
      
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode(body),
      ).timeout(
        Duration(seconds: AppConstants.apiTimeout),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to submit score: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error submitting score: $e');
    }
  }
  
  // ==================== Test Endpoints ====================
  
  /// GET /test/beginner - Get beginner test activities (5 random)
  Future<List<Activity>> getBeginnerTestActivities() async {
    try {
      final url = Uri.parse('$baseUrl/test/beginner');
      final response = await http.get(
        url,
        headers: _getHeaders(),
      ).timeout(
        Duration(seconds: AppConstants.apiTimeout),
      );
      
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final activitiesList = jsonData['activities'] as List;
        return activitiesList
            .map((json) => Activity.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to load test activities: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching test activities: $e');
    }
  }
  
  /// TODO: Phase 2 - Add intermediate and advanced test endpoints
  // Future<List<Activity>> getIntermediateTestActivities() async { }
  // Future<List<Activity>> getAdvancedTestActivities() async { }
  
  // ==================== Progress Endpoints ====================
  
  /// TODO: Phase 2 - Add progress sync endpoints
  // Future<void> syncProgress(List<Progress> progressList) async { }
  // Future<Map<String, dynamic>> getUserProgress() async { }
  
  // ==================== Utility Methods ====================
  
  /// Health check endpoint
  Future<bool> healthCheck() async {
    try {
      final url = Uri.parse('$baseUrl/health');
      final response = await http.get(url).timeout(
        const Duration(seconds: 5),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  
  /// Get activities by number
  Future<List<Activity>> getActivitiesForNumber(int level, int number) async {
    try {
      final allActivities = await getActivitiesForLevel(level);
      return allActivities.where((a) => a.number == number).toList();
    } catch (e) {
      throw Exception('Error fetching activities for number: $e');
    }
  }
}
