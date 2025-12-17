import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ganithamithura/services/local_storage/storage_service.dart';
import 'package:ganithamithura/models/unit_models.dart';

/// Service to track student progress for measurement units
class UnitProgressService {
  static final UnitProgressService _instance = UnitProgressService._();
  static UnitProgressService get instance => _instance;
  
  UnitProgressService._();
  
  final StorageService _storage = StorageService.instance;
  final String _baseUrl = 'http://10.0.2.2:8000/api/v1/progress';
  
  static const String _progressKey = 'unit_progress_data';
  
  // TODO: Replace with actual student ID from auth system
  String get _studentId => 'student_123'; // Temporary - get from login later
  
  /// Get progress for a specific unit
  Future<StudentUnitProgress?> getUnitProgress(String unitId) async {
    final allProgress = await _getAllProgress();
    return allProgress[unitId];
  }
  
  /// Get progress for a topic (aggregated from all units in that topic)
  Future<Map<String, dynamic>> getTopicProgress(String topic) async {
    final allProgress = await _getAllProgress();
    
    // Filter units by topic
    final topicUnits = allProgress.entries.where((entry) => 
      entry.key.toLowerCase().contains(topic.toLowerCase())
    );
    
    if (topicUnits.isEmpty) {
      return {
        'questionsAnswered': 0,
        'correctAnswers': 0,
        'accuracy': 0.0,
        'totalStars': 0,
      };
    }
    
    int totalQuestions = 0;
    int totalCorrect = 0;
    int totalStars = 0;
    
    for (final entry in topicUnits) {
      final progress = entry.value;
      totalQuestions += progress.questionsAnswered;
      totalCorrect += progress.correctAnswers;
      totalStars += progress.stars;
    }
    
    final accuracy = totalQuestions > 0 
        ? (totalCorrect / totalQuestions * 100) 
        : 0.0;
    
    return {
      'questionsAnswered': totalQuestions,
      'correctAnswers': totalCorrect,
      'accuracy': accuracy,
      'totalStars': totalStars,
    };
  }
  
  /// Record a question answer
  Future<void> recordAnswer({
    required String unitId,
    required bool isCorrect,
  }) async {
    // Extract topic and grade from unitId (e.g., "unit_length_1")
    final parts = unitId.split('_');
    final topic = parts.length > 1 ? parts[1] : 'Unknown';
    final grade = parts.length > 2 ? int.tryParse(parts[2]) ?? 1 : 1;
    
    // Sync with backend first
    try {
      await _syncAnswerToBackend(unitId, topic, grade, isCorrect);
    } catch (e) {
      print('⚠️ Backend sync failed, using local only: $e');
    }
    
    // Also update local storage as cache
    final allProgress = await _getAllProgress();
    
    // Get or create progress for this unit
    final currentProgress = allProgress[unitId] ?? StudentUnitProgress(
      unitId: unitId,
      questionsAnswered: 0,
      correctAnswers: 0,
      accuracy: 0.0,
      stars: 0,
    );
    
    // Update stats
    final newQuestionsAnswered = currentProgress.questionsAnswered + 1;
    final newCorrectAnswers = currentProgress.correctAnswers + (isCorrect ? 1 : 0);
    final newAccuracy = (newCorrectAnswers / newQuestionsAnswered * 100);
    
    // Calculate stars based on accuracy
    int stars = 0;
    if (newAccuracy >= 90) {
      stars = 3;
    } else if (newAccuracy >= 70) {
      stars = 2;
    } else if (newAccuracy >= 50) {
      stars = 1;
    }
    
    // Create updated progress
    final updatedProgress = StudentUnitProgress(
      unitId: unitId,
      questionsAnswered: newQuestionsAnswered,
      correctAnswers: newCorrectAnswers,
      accuracy: newAccuracy,
      stars: stars,
    );
    
    // Save to storage
    allProgress[unitId] = updatedProgress;
    await _saveAllProgress(allProgress);
  }
  
  /// Sync answer to backend
  Future<void> _syncAnswerToBackend(
    String unitId,
    String topic,
    int grade,
    bool isCorrect,
  ) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/record-answer'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'student_id': _studentId,
        'unit_id': unitId,
        'topic': topic,
        'grade': grade,
        'is_correct': isCorrect,
      }),
    );
    
    if (response.statusCode != 200) {
      throw Exception('Backend sync failed: ${response.body}');
    }
  }
  
  /// Load progress from backend
  Future<void> loadFromBackend() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/all/$_studentId'),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final units = data['units'] as List;
        
        // Update local cache with backend data
        final Map<String, StudentUnitProgress> progress = {};
        for (final unit in units) {
          final unitProgress = StudentUnitProgress(
            unitId: unit['unit_id'],
            questionsAnswered: unit['questions_answered'],
            correctAnswers: unit['correct_answers'],
            accuracy: (unit['accuracy'] as num).toDouble(),
            stars: unit['stars'],
          );
          progress[unit['unit_id']] = unitProgress;
        }
        
        await _saveAllProgress(progress);
        print('✅ Progress loaded from backend');
      }
    } catch (e) {
      print('⚠️ Failed to load from backend: $e');
    }
  }
  
  /// Get all progress data
  Future<Map<String, StudentUnitProgress>> _getAllProgress() async {
    final prefs = _storage.prefs;
    final jsonString = prefs.getString(_progressKey);
    
    if (jsonString == null) return {};
    
    final Map<String, dynamic> decoded = jsonDecode(jsonString);
    return decoded.map((key, value) => 
      MapEntry(key, StudentUnitProgress.fromJson(value))
    );
  }
  
  /// Save all progress data
  Future<void> _saveAllProgress(Map<String, StudentUnitProgress> progress) async {
    final prefs = _storage.prefs;
    final encoded = progress.map((key, value) => 
      MapEntry(key, value.toJson())
    );
    await prefs.setString(_progressKey, jsonEncode(encoded));
  }
  
  /// Get overall statistics
  Future<Map<String, dynamic>> getOverallStats() async {
    final allProgress = await _getAllProgress();
    
    if (allProgress.isEmpty) {
      return {
        'totalQuestions': 0,
        'totalCorrect': 0,
        'overallAccuracy': 0.0,
        'totalStars': 0,
        'unitsStarted': 0,
      };
    }
    
    int totalQuestions = 0;
    int totalCorrect = 0;
    int totalStars = 0;
    
    for (final progress in allProgress.values) {
      totalQuestions += progress.questionsAnswered;
      totalCorrect += progress.correctAnswers;
      totalStars += progress.stars;
    }
    
    final accuracy = totalQuestions > 0 
        ? (totalCorrect / totalQuestions * 100) 
        : 0.0;
    
    return {
      'totalQuestions': totalQuestions,
      'totalCorrect': totalCorrect,
      'overallAccuracy': accuracy,
      'totalStars': totalStars,
      'unitsStarted': allProgress.length,
    };
  }
  
  /// Clear all progress (for testing)
  Future<void> clearAllProgress() async {
    final prefs = _storage.prefs;
    await prefs.remove(_progressKey);
  }
  
  /// Clear progress for specific unit
  Future<void> clearUnitProgress(String unitId) async {
    final allProgress = await _getAllProgress();
    allProgress.remove(unitId);
    await _saveAllProgress(allProgress);
  }
}
