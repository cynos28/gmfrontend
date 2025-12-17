import 'package:ganithamithura/utils/constants.dart';

/// Activity Model - Represents a learning activity
class Activity {
  final String id;
  final String type; // trace, read, say, object_detection, video
  final int number; // The number this activity teaches
  final String title;
  final String? description;
  final Map<String, dynamic>? metadata; // Activity-specific data
  final int level;
  final int order; // Order within the number sequence
  
  Activity({
    required this.id,
    required this.type,
    required this.number,
    required this.title,
    this.description,
    this.metadata,
    required this.level,
    required this.order,
  });
  
  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'] as String,
      type: json['type'] as String,
      number: json['number'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      level: json['level'] as int,
      order: json['order'] as int,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'number': number,
      'title': title,
      'description': description,
      'metadata': metadata,
      'level': level,
      'order': order,
    };
  }
  
  bool get isVideoLesson => type == AppConstants.activityTypeVideo;
  bool get isTraceActivity => type == AppConstants.activityTypeTrace;
  bool get isReadActivity => type == AppConstants.activityTypeRead;
  bool get isSayActivity => type == AppConstants.activityTypeSay;
  bool get isObjectDetection => type == AppConstants.activityTypeObjectDetection;
}

/// Level Model - Represents a learning level
class LearningLevel {
  final int levelNumber;
  final String title;
  final String description;
  final int minNumber;
  final int maxNumber;
  final bool isUnlocked;
  final int totalActivities;
  final int completedActivities;
  
  LearningLevel({
    required this.levelNumber,
    required this.title,
    required this.description,
    required this.minNumber,
    required this.maxNumber,
    required this.isUnlocked,
    this.totalActivities = 0,
    this.completedActivities = 0,
  });
  
  double get progress => totalActivities > 0 
      ? completedActivities / totalActivities 
      : 0.0;
  
  bool get isCompleted => completedActivities == totalActivities && totalActivities > 0;
  
  factory LearningLevel.fromJson(Map<String, dynamic> json) {
    return LearningLevel(
      levelNumber: json['levelNumber'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      minNumber: json['minNumber'] as int,
      maxNumber: json['maxNumber'] as int,
      isUnlocked: json['isUnlocked'] as bool,
      totalActivities: json['totalActivities'] as int? ?? 0,
      completedActivities: json['completedActivities'] as int? ?? 0,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'levelNumber': levelNumber,
      'title': title,
      'description': description,
      'minNumber': minNumber,
      'maxNumber': maxNumber,
      'isUnlocked': isUnlocked,
      'totalActivities': totalActivities,
      'completedActivities': completedActivities,
    };
  }
}

/// Progress Model - Tracks user's progress
class Progress {
  final String activityId;
  final int score;
  final bool isCompleted;
  final DateTime completedAt;
  final int attempts;
  final Map<String, dynamic>? additionalData;
  
  Progress({
    required this.activityId,
    required this.score,
    required this.isCompleted,
    required this.completedAt,
    this.attempts = 1,
    this.additionalData,
  });
  
  factory Progress.fromJson(Map<String, dynamic> json) {
    return Progress(
      activityId: json['activityId'] as String,
      score: json['score'] as int,
      isCompleted: json['isCompleted'] as bool,
      completedAt: DateTime.parse(json['completedAt'] as String),
      attempts: json['attempts'] as int? ?? 1,
      additionalData: json['additionalData'] as Map<String, dynamic>?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'activityId': activityId,
      'score': score,
      'isCompleted': isCompleted,
      'completedAt': completedAt.toIso8601String(),
      'attempts': attempts,
      'additionalData': additionalData,
    };
  }
}

/// Test Result Model
class TestResult {
  final String testType; // 'beginner', 'intermediate', 'advanced'
  final int totalQuestions;
  final int correctAnswers;
  final DateTime completedAt;
  final List<String> activityIds;
  final Map<String, bool> activityResults; // activityId -> wasCorrect
  
  TestResult({
    required this.testType,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.completedAt,
    required this.activityIds,
    required this.activityResults,
  });
  
  double get percentage => totalQuestions > 0 
      ? (correctAnswers / totalQuestions) * 100 
      : 0.0;
  
  bool get isPassed => percentage >= 70.0;
  
  factory TestResult.fromJson(Map<String, dynamic> json) {
    return TestResult(
      testType: json['testType'] as String,
      totalQuestions: json['totalQuestions'] as int,
      correctAnswers: json['correctAnswers'] as int,
      completedAt: DateTime.parse(json['completedAt'] as String),
      activityIds: List<String>.from(json['activityIds'] as List),
      activityResults: Map<String, bool>.from(json['activityResults'] as Map),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'testType': testType,
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'completedAt': completedAt.toIso8601String(),
      'activityIds': activityIds,
      'activityResults': activityResults,
    };
  }
}
