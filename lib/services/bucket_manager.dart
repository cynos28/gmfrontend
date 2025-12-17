import 'dart:math';
import 'package:ganithamithura/models/models.dart';
import 'package:ganithamithura/utils/constants.dart';

/// BucketManager - Manages activity buckets and random selection
class BucketManager {
  static BucketManager? _instance;
  final Random _random = Random();
  
  BucketManager._();
  
  static BucketManager get instance {
    _instance ??= BucketManager._();
    return _instance!;
  }
  
  // ==================== Activity Bucket Management ====================
  
  /// Get all activities for a specific number in Level 1
  /// Each number should have ~5 activities (video + trace + read + say + object_detection)
  List<Activity> getActivitiesForNumber(
    List<Activity> allActivities,
    int number,
  ) {
    return allActivities
        .where((activity) => activity.number == number)
        .toList();
  }
  
  /// Get learning sequence for a number (ordered activities)
  /// Order: Video -> Trace -> Read -> Say -> Object Detection
  List<Activity> getLearningSequenceForNumber(
    List<Activity> allActivities,
    int number,
  ) {
    final activities = getActivitiesForNumber(allActivities, number);
    
    // Sort by type priority
    activities.sort((a, b) {
      final priorityA = _getActivityTypePriority(a.type);
      final priorityB = _getActivityTypePriority(b.type);
      return priorityA.compareTo(priorityB);
    });
    
    return activities;
  }
  
  /// Get activity type priority for ordering
  int _getActivityTypePriority(String type) {
    switch (type) {
      case AppConstants.activityTypeVideo:
        return 1;
      case AppConstants.activityTypeTrace:
        return 2;
      case AppConstants.activityTypeRead:
        return 3;
      case AppConstants.activityTypeSay:
        return 4;
      case AppConstants.activityTypeObjectDetection:
        return 5;
      default:
        return 99;
    }
  }
  
  /// Get all Level 1 activities (numbers 1-10)
  List<Activity> getLevel1Activities(List<Activity> allActivities) {
    return allActivities
        .where((activity) => activity.level == 1)
        .toList();
  }
  
  // ==================== Test Bucket Management ====================
  
  /// Create test bucket for Level 1 (Beginner Test)
  /// Rules:
  /// - Pick activities from Level 1 only
  /// - Exclude video lessons
  /// - Include trace, read, say, and object_detection
  /// - Return 6 activities, but will show only 5
  List<Activity> createTestBucket(List<Activity> allActivities) {
    // Get Level 1 activities (exclude videos)
    final testableActivities = allActivities.where((activity) {
      return activity.level == 1 &&
          activity.type != AppConstants.activityTypeVideo;
    }).toList();
    
    if (testableActivities.isEmpty) {
      return [];
    }
    
    // Shuffle and pick
    testableActivities.shuffle(_random);
    
    final bucketSize = AppConstants.testBucketSize;
    final count = testableActivities.length < bucketSize
        ? testableActivities.length
        : bucketSize;
    
    return testableActivities.sublist(0, count);
  }
  
  /// Select random activities from test bucket
  /// Always select 5 from the bucket of 6
  List<Activity> selectRandomTestActivities(List<Activity> testBucket) {
    if (testBucket.length <= AppConstants.beginnerTestActivityCount) {
      return testBucket;
    }
    
    final shuffled = List<Activity>.from(testBucket);
    shuffled.shuffle(_random);
    
    return shuffled.sublist(0, AppConstants.beginnerTestActivityCount);
  }
  
  /// Get diverse test activities (ensures variety of activity types)
  List<Activity> getDiverseTestActivities(List<Activity> allActivities) {
    final level1Activities = getLevel1Activities(allActivities);
    
    // Group by activity type
    final byType = <String, List<Activity>>{};
    for (var activity in level1Activities) {
      if (activity.type == AppConstants.activityTypeVideo) continue;
      
      byType.putIfAbsent(activity.type, () => []);
      byType[activity.type]!.add(activity);
    }
    
    // Pick activities ensuring diversity
    final selected = <Activity>[];
    final types = byType.keys.toList()..shuffle(_random);
    
    // Try to get at least one of each type
    for (var type in types) {
      if (selected.length >= AppConstants.beginnerTestActivityCount) break;
      
      final activities = byType[type]!;
      if (activities.isNotEmpty) {
        activities.shuffle(_random);
        selected.add(activities.first);
      }
    }
    
    // Fill remaining slots if needed
    while (selected.length < AppConstants.beginnerTestActivityCount) {
      final allRemaining = level1Activities
          .where((a) => !selected.contains(a) && 
                       a.type != AppConstants.activityTypeVideo)
          .toList();
      
      if (allRemaining.isEmpty) break;
      
      allRemaining.shuffle(_random);
      selected.add(allRemaining.first);
    }
    
    // Final shuffle for random order
    selected.shuffle(_random);
    
    return selected;
  }
  
  // ==================== Practice Mode ====================
  
  /// Get random practice activities for a specific activity type
  List<Activity> getPracticeActivitiesByType(
    List<Activity> allActivities,
    String activityType, {
    int count = 5,
  }) {
    final activities = allActivities
        .where((activity) => 
            activity.level == 1 && 
            activity.type == activityType)
        .toList();
    
    activities.shuffle(_random);
    
    final selectedCount = activities.length < count ? activities.length : count;
    return activities.sublist(0, selectedCount);
  }
  
  /// Get next activity in learning sequence
  Activity? getNextActivity(
    List<Activity> learningSequence,
    Set<String> completedActivityIds,
  ) {
    for (var activity in learningSequence) {
      if (!completedActivityIds.contains(activity.id)) {
        return activity;
      }
    }
    return null; // All completed
  }
  
  /// Calculate progress for a number
  double getNumberProgress(
    List<Activity> numberActivities,
    Set<String> completedActivityIds,
  ) {
    if (numberActivities.isEmpty) return 0.0;
    
    final completedCount = numberActivities.where(
      (activity) => completedActivityIds.contains(activity.id),
    ).length;
    
    return completedCount / numberActivities.length;
  }
  
  /// Check if number is completed
  bool isNumberCompleted(
    List<Activity> numberActivities,
    Set<String> completedActivityIds,
  ) {
    if (numberActivities.isEmpty) return false;
    
    return numberActivities.every(
      (activity) => completedActivityIds.contains(activity.id),
    );
  }
  
  // ==================== Utility Methods ====================
  
  /// Shuffle activities (for random order)
  List<Activity> shuffleActivities(List<Activity> activities) {
    final shuffled = List<Activity>.from(activities);
    shuffled.shuffle(_random);
    return shuffled;
  }
  
  /// Filter activities by multiple criteria
  List<Activity> filterActivities(
    List<Activity> activities, {
    int? level,
    int? number,
    String? type,
    List<String>? excludeTypes,
  }) {
    return activities.where((activity) {
      if (level != null && activity.level != level) return false;
      if (number != null && activity.number != number) return false;
      if (type != null && activity.type != type) return false;
      if (excludeTypes != null && excludeTypes.contains(activity.type)) {
        return false;
      }
      return true;
    }).toList();
  }
}
