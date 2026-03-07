import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ganithamithura/models/models.dart';
import 'package:ganithamithura/models/user.dart';
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

  // ==================== User Authentication ====================
  
  /// Save current user data
  Future<bool> saveCurrentUser(User user) async {
    try {
      final userJson = jsonEncode(user.toJson());
      return await prefs.setString(StorageKeys.currentUser, userJson);
    } catch (e) {
      throw Exception('Error saving user data: $e');
    }
  }
  
  /// Get current user data
  Future<User?> getCurrentUser() async {
    try {
      final userJson = prefs.getString(StorageKeys.currentUser);
      if (userJson == null) return null;
      
      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      return User.fromJson(userMap);
    } catch (e) {
      return null;
    }
  }
  
  /// Save authentication token
  Future<bool> saveAuthToken(String token) async {
    try {
      return await prefs.setString(StorageKeys.authToken, token);
    } catch (e) {
      throw Exception('Error saving auth token: $e');
    }
  }
  
  /// Get authentication token
  String? getAuthToken() {
    return prefs.getString(StorageKeys.authToken);
  }
  
  /// Clear user data (logout)
  Future<bool> clearUserData() async {
    try {
      await prefs.remove(StorageKeys.currentUser);
      await prefs.remove(StorageKeys.authToken);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final user = await getCurrentUser();
    return user != null;
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
      return completedActivities.firstWhere((p) => p.activityId == activityId);
    } catch (e) {
      return null;
    }
  }

  /// Save progress for a specific question within an activity
  Future<bool> saveQuestionProgress({
    required String activityId,
    required String questionId,
    required int score,
  }) async {
    // Get existing progress or create new
    var progress = await getActivityProgress(activityId);

    final now = DateTime.now();
    Map<String, QuestionProgress> questionProgressMap =
        progress?.questionProgress != null
        ? Map<String, QuestionProgress>.from(progress!.questionProgress!)
        : {};

    // Update or create question progress
    if (questionProgressMap.containsKey(questionId)) {
      questionProgressMap[questionId] = questionProgressMap[questionId]!
          .copyWithAttempt(score: score);
    } else {
      questionProgressMap[questionId] = QuestionProgress(
        questionId: questionId,
        attempts: 1,
        bestScore: score,
        lastAttemptAt: now,
        isCompleted: score >= 70,
      );
    }

    // Calculate total score
    final totalScore = questionProgressMap.values.fold(
      0,
      (sum, qp) => sum + qp.bestScore,
    );

    // Check if all questions are completed
    final allCompleted = questionProgressMap.values.every(
      (qp) => qp.isCompleted,
    );

    // Create updated progress
    final updatedProgress = Progress(
      activityId: activityId,
      score: totalScore,
      isCompleted: allCompleted,
      completedAt: allCompleted ? now : progress?.completedAt ?? now,
      attempts: (progress?.attempts ?? 0) + 1,
      questionProgress: questionProgressMap,
      resumeIndex: progress?.resumeIndex,
    );

    return await saveCompletedActivity(updatedProgress);
  }

  /// Update resume index for an activity (for session resumption)
  Future<bool> updateActivityResumeIndex(String activityId, int index) async {
    var progress = await getActivityProgress(activityId);

    if (progress == null) {
      progress = Progress(
        activityId: activityId,
        score: 0,
        isCompleted: false,
        completedAt: DateTime.now(),
        attempts: 0,
        resumeIndex: index,
      );
    } else {
      progress = Progress(
        activityId: progress.activityId,
        score: progress.score,
        isCompleted: progress.isCompleted,
        completedAt: progress.completedAt,
        attempts: progress.attempts,
        additionalData: progress.additionalData,
        questionProgress: progress.questionProgress,
        resumeIndex: index,
      );
    }

    return await saveCompletedActivity(progress);
  }

  // ==================== Test Scores ====================

  /// Save test result
  Future<bool> saveTestResult(TestResult testResult) async {
    final testScores = await getTestResults();
    testScores.add(testResult);

    final jsonList = testScores.map((t) => t.toJson()).toList();
    return await prefs.setString(StorageKeys.testScores, jsonEncode(jsonList));
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

  /// Unlock a specific level
  Future<bool> unlockLevel(int level) async {
    final currentLevel = getCurrentLevel();
    if (level > currentLevel) {
      return await setCurrentLevel(level);
    }
    return true;
  }

  /// Save level completion
  Future<bool> saveLevelCompletion(int level) async {
    final key = 'level_${level}_completed';
    return await prefs.setBool(key, true);
  }

  /// Check if level is completed
  Future<bool> isLevelCompleted(int level) async {
    final key = 'level_${level}_completed';
    return prefs.getBool(key) ?? false;
  }

  /// Save number completion for a level
  Future<bool> saveNumberCompletion(int level, int number) async {
    final key = 'level_${level}_number_${number}_completed';
    return await prefs.setBool(key, true);
  }

  /// Get completed numbers for a level - uses dynamic LevelConfig ranges
  Future<Map<int, bool>> getCompletedNumbers(int level) async {
    final Map<int, bool> completedNumbers = {};

    // Get level config for dynamic number ranges
    final config = AppConstants.getLevelConfig(level);

    for (int i = config.minNumber; i <= config.maxNumber; i++) {
      final key = 'level_${level}_number_${i}_completed';
      completedNumbers[i] = prefs.getBool(key) ?? false;
    }

    return completedNumbers;
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

  // ==================== Learning Session Tracking ====================

  /// Save current learning session position
  /// Call this when navigating to any activity
  Future<bool> saveLearningSession({
    required int level,
    required int number,
    required String activityType,
  }) async {
    // Check if we're starting a new number - if so, clear the lastCompletedActivityType
    final existingNumber = prefs.getInt(StorageKeys.currentLearningNumber);
    final existingLevel = prefs.getInt(StorageKeys.currentLearningLevel);

    bool success = true;
    success &= await prefs.setInt(StorageKeys.currentLearningLevel, level);
    success &= await prefs.setInt(StorageKeys.currentLearningNumber, number);
    success &= await prefs.setString(
      StorageKeys.currentActivityType,
      activityType,
    );
    success &= await prefs.setString(
      StorageKeys.lastActivityDate,
      DateTime.now().toIso8601String(),
    );

    // Clear lastCompletedActivityType if we're on a new number or new level
    // This prevents stale data from causing the wrong activity to be resumed
    if (existingNumber != number || existingLevel != level) {
      await prefs.remove(StorageKeys.lastCompletedActivityType);
    }

    return success;
  }

  /// Mark an activity type as completed for current session
  Future<bool> markActivityCompleted(String activityType) async {
    return await prefs.setString(
      StorageKeys.lastCompletedActivityType,
      activityType,
    );
  }

  /// Get the saved learning session
  /// Returns null if no session is saved
  LearningSession? getLearningSession() {
    final level = prefs.getInt(StorageKeys.currentLearningLevel);
    final number = prefs.getInt(StorageKeys.currentLearningNumber);
    final activityType = prefs.getString(StorageKeys.currentActivityType);
    final lastCompleted = prefs.getString(
      StorageKeys.lastCompletedActivityType,
    );

    if (level == null || number == null) {
      return null;
    }

    return LearningSession(
      level: level,
      number: number,
      currentActivityType: activityType,
      lastCompletedActivityType: lastCompleted,
    );
  }

  /// Clear the learning session (call when user completes a level or explicitly exits)
  Future<bool> clearLearningSession() async {
    bool success = true;
    success &= await prefs.remove(StorageKeys.currentLearningLevel);
    success &= await prefs.remove(StorageKeys.currentLearningNumber);
    success &= await prefs.remove(StorageKeys.currentActivityType);
    success &= await prefs.remove(StorageKeys.lastCompletedActivityType);
    return success;
  }

  /// Get the next activity type after a completed one
  /// Returns null if all activities are complete
  String? getNextActivityType(String completedActivityType) {
    const activityOrder = [
      AppConstants.activityTypeVideo,
      AppConstants.activityTypeTrace,
      'show', // Backend uses 'show' for object detection activity
      AppConstants.activityTypeSay,
      AppConstants.activityTypeRead,
    ];

    final currentIndex = activityOrder.indexOf(completedActivityType);
    if (currentIndex == -1 || currentIndex >= activityOrder.length - 1) {
      return null; // No next activity or not found
    }
    return activityOrder[currentIndex + 1];
  }
}

/// Learning Session Model - Tracks where user left off
class LearningSession {
  final int level;
  final int number;
  final String? currentActivityType;
  final String? lastCompletedActivityType;

  LearningSession({
    required this.level,
    required this.number,
    this.currentActivityType,
    this.lastCompletedActivityType,
  });

  /// Get the activity to resume from (skip completed activity)
  String? get resumeActivityType {
    if (lastCompletedActivityType == null) {
      return currentActivityType;
    }
    // If an activity was completed, start from the next one
    const activityOrder = [
      AppConstants.activityTypeVideo,
      AppConstants.activityTypeTrace,
      'show', // Backend uses 'show' for object detection activity
      AppConstants.activityTypeSay,
      AppConstants.activityTypeRead,
    ];
    final completedIndex = activityOrder.indexOf(lastCompletedActivityType!);
    if (completedIndex >= activityOrder.length - 1) {
      return null; // All activities for this number are complete
    }
    return activityOrder[completedIndex + 1];
  }

  @override
  String toString() =>
      'LearningSession(level: $level, number: $number, current: $currentActivityType, lastCompleted: $lastCompletedActivityType)';
}
