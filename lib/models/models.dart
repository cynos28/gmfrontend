import 'package:ganithamithura/utils/constants.dart';

/// Activity Model - Represents a learning activity
class Activity {
  final String id;
  final String type; // trace, read, say, object_detection, video, show
  final int number; // The number this activity teaches
  final String title;
  final String? description;
  final Map<String, dynamic>? metadata; // Activity-specific data
  final int level;
  final int order; // Order within the number sequence
  final List<ActivityQuestion>? questions; // Array of questions with difficulty

  Activity({
    required this.id,
    required this.type,
    required this.number,
    required this.title,
    this.description,
    this.metadata,
    required this.level,
    required this.order,
    this.questions,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    List<ActivityQuestion>? questionsList;
    if (json['questions'] != null) {
      questionsList = (json['questions'] as List)
          .map((q) => ActivityQuestion.fromJson(q))
          .toList();
    }

    return Activity(
      id: json['id'] as String,
      type: json['type'] as String,
      number: json['number'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      level: json['level'] as int,
      order: json['order'] as int,
      questions: questionsList,
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
      'questions': questions?.map((q) => q.toJson()).toList(),
    };
  }

  // Get questions by difficulty
  List<ActivityQuestion> getQuestionsByDifficulty(String difficulty) {
    if (questions == null) return [];
    return questions!.where((q) => q.difficulty == difficulty).toList();
  }

  // Get easy question for tutorial
  ActivityQuestion? getEasyQuestion() {
    if (questions == null || questions!.isEmpty) return null;
    try {
      return questions!.firstWhere((q) => q.difficulty == 'easy');
    } catch (e) {
      return questions!.first;
    }
  }

  // Get non-easy questions for progress test
  List<ActivityQuestion> getTestQuestions() {
    if (questions == null) return [];
    return questions!.where((q) => q.difficulty != 'easy').toList();
  }

  bool get isVideoLesson => type == AppConstants.activityTypeVideo;
  bool get isTraceActivity => type == AppConstants.activityTypeTrace;
  bool get isReadActivity => type == AppConstants.activityTypeRead;
  bool get isSayActivity => type == AppConstants.activityTypeSay;
  bool get isObjectDetection =>
      type == AppConstants.activityTypeObjectDetection || type == 'show';
}

/// Activity Question Model - Represents a single question within an activity
class ActivityQuestion {
  final String id;
  final String difficulty; // easy, medium, hard
  final int points;
  final String? question;
  final String? instruction;
  final dynamic correctAnswer;
  final List<String>? options;
  final String? image;
  final String? templateImage;
  final String? helpImage;
  final String? pronounce;
  final List<String>? alternatives;
  final int? maxObjects;
  final String? type; // For read activity

  ActivityQuestion({
    required this.id,
    required this.difficulty,
    required this.points,
    this.question,
    this.instruction,
    this.correctAnswer,
    this.options,
    this.image,
    this.templateImage,
    this.helpImage,
    this.pronounce,
    this.alternatives,
    this.maxObjects,
    this.type,
  });

  factory ActivityQuestion.fromJson(Map<String, dynamic> json) {
    return ActivityQuestion(
      id: json['id'] as String,
      difficulty: json['difficulty'] as String,
      points: json['points'] as int,
      question: json['question'] as String?,
      instruction: json['instruction'] as String?,
      correctAnswer: json['correct_answer'],
      options: json['options'] != null
          ? List<String>.from(json['options'])
          : null,
      image: json['image'] as String?,
      templateImage: json['template_image'] as String?,
      helpImage: json['help_image'] as String?,
      pronounce: json['pronounce'] as String?,
      alternatives: json['alternatives'] != null
          ? List<String>.from(json['alternatives'])
          : null,
      maxObjects: json['max_objects'] as int?,
      type: json['type'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'difficulty': difficulty,
      'points': points,
      'question': question,
      'instruction': instruction,
      'correct_answer': correctAnswer,
      'options': options,
      'image': image,
      'template_image': templateImage,
      'help_image': helpImage,
      'pronounce': pronounce,
      'alternatives': alternatives,
      'max_objects': maxObjects,
      'type': type,
    };
  }
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

  double get progress =>
      totalActivities > 0 ? completedActivities / totalActivities : 0.0;

  bool get isCompleted =>
      completedActivities == totalActivities && totalActivities > 0;

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

/// Question Progress Model - Tracks individual question attempts within an activity
class QuestionProgress {
  final String questionId;
  final int attempts;
  final int bestScore;
  final DateTime lastAttemptAt;
  final bool isCompleted;

  QuestionProgress({
    required this.questionId,
    this.attempts = 0,
    this.bestScore = 0,
    required this.lastAttemptAt,
    this.isCompleted = false,
  });

  factory QuestionProgress.fromJson(Map<String, dynamic> json) {
    return QuestionProgress(
      questionId: json['questionId'] as String,
      attempts: json['attempts'] as int? ?? 0,
      bestScore: json['bestScore'] as int? ?? 0,
      lastAttemptAt: DateTime.parse(json['lastAttemptAt'] as String),
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'attempts': attempts,
      'bestScore': bestScore,
      'lastAttemptAt': lastAttemptAt.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }

  /// Create updated copy with new attempt
  QuestionProgress copyWithAttempt({required int score}) {
    return QuestionProgress(
      questionId: questionId,
      attempts: attempts + 1,
      bestScore: score > bestScore ? score : bestScore,
      lastAttemptAt: DateTime.now(),
      isCompleted: isCompleted || score >= 70, // 70% threshold for completion
    );
  }
}

/// Progress Model - Tracks user's progress for an activity
class Progress {
  final String activityId;
  final int score;
  final bool isCompleted;
  final DateTime completedAt;
  final int attempts;
  final Map<String, dynamic>? additionalData;
  final Map<String, QuestionProgress>?
  questionProgress; // Question-level tracking
  final int? resumeIndex; // For session resumption

  Progress({
    required this.activityId,
    required this.score,
    required this.isCompleted,
    required this.completedAt,
    this.attempts = 1,
    this.additionalData,
    this.questionProgress,
    this.resumeIndex,
  });

  factory Progress.fromJson(Map<String, dynamic> json) {
    Map<String, QuestionProgress>? questionProgressMap;
    if (json['questionProgress'] != null) {
      questionProgressMap = (json['questionProgress'] as Map<String, dynamic>)
          .map((key, value) => MapEntry(key, QuestionProgress.fromJson(value)));
    }

    return Progress(
      activityId: json['activityId'] as String,
      score: json['score'] as int,
      isCompleted: json['isCompleted'] as bool,
      completedAt: DateTime.parse(json['completedAt'] as String),
      attempts: json['attempts'] as int? ?? 1,
      additionalData: json['additionalData'] as Map<String, dynamic>?,
      questionProgress: questionProgressMap,
      resumeIndex: json['resumeIndex'] as int?,
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
      'questionProgress': questionProgress?.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
      'resumeIndex': resumeIndex,
    };
  }

  /// Calculate total score from question progress
  int get totalQuestionScore {
    if (questionProgress == null || questionProgress!.isEmpty) return score;
    return questionProgress!.values.fold(0, (sum, qp) => sum + qp.bestScore);
  }

  /// Get completion percentage based on questions
  double get completionPercentage {
    if (questionProgress == null || questionProgress!.isEmpty) {
      return isCompleted ? 100.0 : 0.0;
    }
    final completed = questionProgress!.values
        .where((qp) => qp.isCompleted)
        .length;
    return (completed / questionProgress!.length) * 100;
  }
}

/// Test Result Model
class TestResult {
  final String testType; // 'beginner', 'intermediate', 'advanced', 'progress'
  final int totalQuestions;
  final int correctAnswers;
  final DateTime completedAt;
  final List<String> activityIds;
  final Map<String, bool> activityResults; // activityId -> wasCorrect
  final String? difficultyLevel; // For progress test: beginner/intermediate/advanced
  final List<int>? unlockedLevels; // Levels unlocked by this test

  TestResult({
    required this.testType,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.completedAt,
    required this.activityIds,
    required this.activityResults,
    this.difficultyLevel,
    this.unlockedLevels,
  });

  double get percentage =>
      totalQuestions > 0 ? (correctAnswers / totalQuestions) * 100 : 0.0;

  bool get isPassed => percentage >= 70.0;

  factory TestResult.fromJson(Map<String, dynamic> json) {
    return TestResult(
      testType: json['testType'] as String,
      totalQuestions: json['totalQuestions'] as int,
      correctAnswers: json['correctAnswers'] as int,
      completedAt: DateTime.parse(json['completedAt'] as String),
      activityIds: List<String>.from(json['activityIds'] as List),
      activityResults: Map<String, bool>.from(json['activityResults'] as Map),
      difficultyLevel: json['difficultyLevel'] as String?,
      unlockedLevels: json['unlockedLevels'] != null
          ? List<int>.from(json['unlockedLevels'] as List)
          : null,
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
      'difficultyLevel': difficultyLevel,
      'unlockedLevels': unlockedLevels,
    };
  }
}

/// Progress Test Question - Represents a single question in the progress placement test
class ProgressTestQuestion {
  final String id;
  final String type; // matching, drag_drop_order, drag_drop_count, image_counting, pattern_fill, trace, say, select
  final String difficulty;
  final int points;
  final String question;
  final String? instruction;
  
  // For select/MCQ type
  final List<String>? options;
  final String? correctAnswer;
  
  // For matching type
  final List<String>? leftItems;
  final List<String>? rightItems;
  final Map<String, String>? correctPairs;
  
  // For drag_drop_order type
  final List<String>? items;
  final List<String>? correctOrder;
  
  // For drag_drop_count type
  final int? availableCount;
  final int? correctCount;
  
  // For image_counting and object-based types
  final String? objectName;
  final String? objectEmoji;
  final String? objectImage;
  final int? objectCount;
  
  // For pattern_fill type
  final List<String>? sequence;
  final int? blankPosition;
  final List<String>? displaySequence;
  
  // For trace type
  final int? expectedNumber;
  final String? word;
  
  // For say type
  final List<String>? alternatives;

  ProgressTestQuestion({
    required this.id,
    required this.type,
    required this.difficulty,
    required this.points,
    required this.question,
    this.instruction,
    this.options,
    this.correctAnswer,
    this.leftItems,
    this.rightItems,
    this.correctPairs,
    this.items,
    this.correctOrder,
    this.availableCount,
    this.correctCount,
    this.objectName,
    this.objectEmoji,
    this.objectImage,
    this.objectCount,
    this.sequence,
    this.blankPosition,
    this.displaySequence,
    this.expectedNumber,
    this.word,
    this.alternatives,
  });

  factory ProgressTestQuestion.fromJson(Map<String, dynamic> json) {
    return ProgressTestQuestion(
      id: json['id'] as String,
      type: json['type'] as String,
      difficulty: json['difficulty'] as String,
      points: json['points'] as int,
      question: json['question'] as String,
      instruction: json['instruction'] as String?,
      options: json['options'] != null ? List<String>.from(json['options']) : null,
      correctAnswer: json['correct_answer'] as String?,
      leftItems: json['left_items'] != null ? List<String>.from(json['left_items']) : null,
      rightItems: json['right_items'] != null ? List<String>.from(json['right_items']) : null,
      correctPairs: json['correct_pairs'] != null ? Map<String, String>.from(json['correct_pairs']) : null,
      items: json['items'] != null ? List<String>.from(json['items']) : null,
      correctOrder: json['correct_order'] != null ? List<String>.from(json['correct_order']) : null,
      availableCount: json['available_count'] as int?,
      correctCount: json['correct_count'] as int?,
      objectName: json['object_name'] as String?,
      objectEmoji: json['object_emoji'] as String?,
      objectImage: json['object_image'] as String?,
      objectCount: json['object_count'] as int?,
      sequence: json['sequence'] != null ? List<String>.from(json['sequence']) : null,
      blankPosition: json['blank_position'] as int?,
      displaySequence: json['display_sequence'] != null ? List<String>.from(json['display_sequence']) : null,
      expectedNumber: json['expected_number'] as int?,
      word: json['word'] as String?,
      alternatives: json['alternatives'] != null ? List<String>.from(json['alternatives']) : null,
    );
  }
}

/// Progress Test Response from API
class ProgressTestResponse {
  final String testType;
  final int totalQuestions;
  final List<ProgressTestQuestion> questions;
  final Map<String, dynamic> scoring;
  final int? passingScore;
  final String? nextUnlock;

  ProgressTestResponse({
    required this.testType,
    required this.totalQuestions,
    required this.questions,
    required this.scoring,
    this.passingScore,
    this.nextUnlock,
  });

  factory ProgressTestResponse.fromJson(Map<String, dynamic> json) {
    final scoring = json['scoring'] as Map<String, dynamic>;
    return ProgressTestResponse(
      testType: json['test_type'] as String,
      totalQuestions: json['total_questions'] as int,
      questions: (json['questions'] as List)
          .map((q) => ProgressTestQuestion.fromJson(q))
          .toList(),
      scoring: scoring,
      passingScore: scoring['passing_score'] as int?,
      nextUnlock: scoring['next_unlock'] as String?,
    );
  }
}

/// Progress Test Evaluation Response
class ProgressTestEvaluation {
  final int score;
  final int total;
  final double percentage;
  final String difficultyLevel;
  final List<int> unlockedLevels;
  final String message;
  final String? testType;

  ProgressTestEvaluation({
    required this.score,
    required this.total,
    required this.percentage,
    required this.difficultyLevel,
    required this.unlockedLevels,
    required this.message,
    this.testType,
  });

  factory ProgressTestEvaluation.fromJson(Map<String, dynamic> json) {
    return ProgressTestEvaluation(
      score: json['score'] as int,
      total: json['total'] as int,
      percentage: (json['percentage'] as num).toDouble(),
      difficultyLevel: json['difficulty_level'] as String,
      unlockedLevels: List<int>.from(json['unlocked_levels'] as List),
      message: json['message'] as String,
      testType: json['test_type'] as String?,
    );
  }

  /// Whether this test result means the user passed and should unlock the next level
  bool get passed => unlockedLevels.length > 1 || difficultyLevel != 'beginner';
}
