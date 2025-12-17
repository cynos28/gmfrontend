import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ganithamithura/models/models.dart';
import 'package:ganithamithura/utils/constants.dart';

/// StorageService - Handles all local storage operations
class StorageService {
  static StorageService? _instance;
  SharedPreferences? _prefs;
  
  StorageService._();
  
  static StorageService get instance {
    _instance ??= StorageService._();
    return _instance!;
  }
  
  /// Initialize storage service
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }
  
  SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('StorageService not initialized. Call init() first.');
    }
    return _prefs!;
  }
  
  // ==================== Completed Activities ====================
  
  /// Save completed activity
  Future<bool> saveCompletedActivity(Progress progress) async {
    final completedActivities = await getCompletedActivities();
    
    // Update or add progress
    final index = completedActivities.indexWhere(
      (p) => p.activityId == progress.activityId,
    );
    
    if (index >= 0) {
      completedActivities[index] = progress;
    } else {
      completedActivities.add(progress);
    }
    
    final jsonList = completedActivities.map((p) => p.toJson()).toList();
    return await prefs.setString(
      StorageKeys.completedActivities,
      jsonEncode(jsonList),
    );
  }
  
  /// Get all completed activities
  Future<List<Progress>> getCompletedActivities() async {
    final jsonString = prefs.getString(StorageKeys.completedActivities);
    if (jsonString == null) return [];
    
    final jsonList = jsonDecode(jsonString) as List;
    return jsonList.map((json) => Progress.fromJson(json)).toList();
  }
  
  /// Check if activity is completed
  Future<bool> isActivityCompleted(String activityId) async {
    final completedActivities = await getCompletedActivities();
    return completedActivities.any(
      (p) => p.activityId == activityId && p.isCompleted,
    );
  }
  
  /// Get progress for specific activity
  Future<Progress?> getActivityProgress(String activityId) async {
    final completedActivities = await getCompletedActivities();
    try {
      return completedActivities.firstWhere(
        (p) => p.activityId == activityId,
      );
    } catch (e) {
      return null;
    }
  }
  
  // ==================== Test Scores ====================
  
  /// Save test result
  Future<bool> saveTestResult(TestResult testResult) async {
    final testScores = await getTestResults();
    testScores.add(testResult);
    
    final jsonList = testScores.map((t) => t.toJson()).toList();
    return await prefs.setString(
      StorageKeys.testScores,
      jsonEncode(jsonList),
    );
  }
  
  /// Get all test results
  Future<List<TestResult>> getTestResults() async {
    final jsonString = prefs.getString(StorageKeys.testScores);
    if (jsonString == null) return [];
    
    final jsonList = jsonDecode(jsonString) as List;
    return jsonList.map((json) => TestResult.fromJson(json)).toList();
  }
  
  /// Get test results by type
  Future<List<TestResult>> getTestResultsByType(String testType) async {
    final allResults = await getTestResults();
    return allResults.where((t) => t.testType == testType).toList();
  }
  
  /// Get best test score for a type
  Future<TestResult?> getBestTestScore(String testType) async {
    final results = await getTestResultsByType(testType);
    if (results.isEmpty) return null;
    
    results.sort((a, b) => b.percentage.compareTo(a.percentage));
    return results.first;
  }
  
  // ==================== Level Progress ====================
  
  /// Set current level
  Future<bool> setCurrentLevel(int level) async {
    return await prefs.setInt(StorageKeys.currentLevel, level);
  }
  
  /// Get current level (default is 1)
  int getCurrentLevel() {
    return prefs.getInt(StorageKeys.currentLevel) ?? 1;
  }
  
  /// Check if level is unlocked
  Future<bool> isLevelUnlocked(int level) async {
    if (level == 1) return true; // Level 1 always unlocked
    
    final currentLevel = getCurrentLevel();
    return level <= currentLevel;
  }
  
  // ==================== Progress Data ====================
  
  /// Save progress data (generic key-value storage)
  Future<bool> saveProgressData(String key, dynamic value) async {
    final progressData = await getProgressData();
    progressData[key] = value;
    
    return await prefs.setString(
      StorageKeys.progressData,
      jsonEncode(progressData),
    );
  }
  
  /// Get all progress data
  Future<Map<String, dynamic>> getProgressData() async {
    final jsonString = prefs.getString(StorageKeys.progressData);
    if (jsonString == null) return {};
    
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }
  
  /// Get specific progress data
  Future<dynamic> getProgressValue(String key) async {
    final progressData = await getProgressData();
    return progressData[key];
  }
  
  // ==================== Statistics ====================
  
  /// Get total completed activities count
  Future<int> getTotalCompletedActivities() async {
    final completed = await getCompletedActivities();
    return completed.where((p) => p.isCompleted).length;
  }
  
  /// Get completion rate for a level
  Future<double> getLevelCompletionRate(int level) async {
    // TODO: Phase 2 - Implement actual level activity tracking
    // For now, return 0
    return 0.0;
  }
  
  /// Get total tests taken
  Future<int> getTotalTestsTaken() async {
    final results = await getTestResults();
    return results.length;
  }
  
  /// Get average test score
  Future<double> getAverageTestScore() async {
    final results = await getTestResults();
    if (results.isEmpty) return 0.0;
    
    final totalPercentage = results.fold<double>(
      0.0,
      (sum, result) => sum + result.percentage,
    );
    
    return totalPercentage / results.length;
  }
  
  // ==================== Last Activity Date ====================
  
  /// Update last activity date
  Future<bool> updateLastActivityDate() async {
    return await prefs.setString(
      StorageKeys.lastActivityDate,
      DateTime.now().toIso8601String(),
    );
  }
  
  /// Get last activity date
  DateTime? getLastActivityDate() {
    final dateString = prefs.getString(StorageKeys.lastActivityDate);
    if (dateString == null) return null;
    
    return DateTime.parse(dateString);
  }
  
  // ==================== Utility Methods ====================
  
  /// Clear all data (for testing/debugging)
  Future<bool> clearAllData() async {
    return await prefs.clear();
  }
  
  /// Clear specific data
  Future<bool> clearCompletedActivities() async {
    return await prefs.remove(StorageKeys.completedActivities);
  }
  
  Future<bool> clearTestScores() async {
    return await prefs.remove(StorageKeys.testScores);
  }
  
  Future<bool> clearProgressData() async {
    return await prefs.remove(StorageKeys.progressData);
  }
}
