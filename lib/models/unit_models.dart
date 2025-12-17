/// Models for Unit-based Learning System

class Unit {
  final String id;
  final String name;
  final String topic; // Length, Area, Capacity, Weight
  final int grade;
  final String? description;
  final String? iconName;

  Unit({
    required this.id,
    required this.name,
    required this.topic,
    required this.grade,
    this.description,
    this.iconName,
  });

  factory Unit.fromJson(Map<String, dynamic> json) {
    return Unit(
      id: json['id'] ?? json['unitId'] ?? '',
      name: json['name'] ?? '',
      topic: json['topic'] ?? '',
      grade: json['grade'] ?? 0,
      description: json['description'],
      iconName: json['iconName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'topic': topic,
      'grade': grade,
      'description': description,
      'iconName': iconName,
    };
  }
}

class StudentUnitProgress {
  final String unitId;
  final int questionsAnswered;
  final int correctAnswers;
  final double accuracy;
  final int stars;

  StudentUnitProgress({
    required this.unitId,
    required this.questionsAnswered,
    required this.correctAnswers,
    required this.accuracy,
    required this.stars,
  });

  factory StudentUnitProgress.fromJson(Map<String, dynamic> json) {
    return StudentUnitProgress(
      unitId: json['unitId'] ?? '',
      questionsAnswered: json['questionsAnswered'] ?? 0,
      correctAnswers: json['correctAnswers'] ?? 0,
      accuracy: (json['accuracy'] ?? 0).toDouble(),
      stars: json['stars'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'unitId': unitId,
      'questionsAnswered': questionsAnswered,
      'correctAnswers': correctAnswers,
      'accuracy': accuracy,
      'stars': stars,
    };
  }
}

class Question {
  final String questionId;
  final String questionText;
  final List<String> options;
  final int? correctIndex;
  final String difficulty; // easy, medium, hard
  final String explanation;

  Question({
    required this.questionId,
    required this.questionText,
    required this.options,
    this.correctIndex,
    required this.difficulty,
    required this.explanation,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      questionId: json['questionId'] ?? '',
      questionText: json['questionText'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      correctIndex: json['correctIndex'],
      difficulty: json['difficulty'] ?? 'easy',
      explanation: json['explanation'] ?? json['explanation_en'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'questionText': questionText,
      'options': options,
      'correctIndex': correctIndex,
      'difficulty': difficulty,
      'explanation': explanation,
    };
  }
}

class AnswerResponse {
  final bool isCorrect;
  final int correctIndex;
  final String explanation;

  AnswerResponse({
    required this.isCorrect,
    required this.correctIndex,
    required this.explanation,
  });

  factory AnswerResponse.fromJson(Map<String, dynamic> json) {
    return AnswerResponse(
      isCorrect: json['isCorrect'] ?? false,
      correctIndex: json['correctIndex'] ?? 0,
      explanation: json['explanation'] ?? json['explanation_en'] ?? '',
    );
  }
}

class ChatMessage {
  final String message;
  final bool isUser;
  final DateTime timestamp;
  final String? reply;

  ChatMessage({
    required this.message,
    required this.isUser,
    required this.timestamp,
    this.reply,
  });
}

class ChatResponse {
  final String reply;

  ChatResponse({
    required this.reply,
  });

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    return ChatResponse(
      reply: json['reply'] ?? json['reply_en'] ?? '',
    );
  }
}

// ========== RAG SERVICE MODELS ==========

class UploadDocumentResponse {
  final String id;
  final String title;
  final List<int> gradeLevels;
  final String? topic;
  final String status;
  final int questionsCount;

  UploadDocumentResponse({
    required this.id,
    required this.title,
    required this.gradeLevels,
    this.topic,
    required this.status,
    required this.questionsCount,
  });

  factory UploadDocumentResponse.fromJson(Map<String, dynamic> json) {
    return UploadDocumentResponse(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      gradeLevels: List<int>.from(json['grade_levels'] ?? []),
      topic: json['topic'],
      status: json['status'] ?? 'processing',
      questionsCount: json['questions_count'] ?? 0,
    );
  }
}

class GenerateQuestionsResponse {
  final String message;
  final int questionsGenerated;
  final List<RAGQuestion> questions;

  GenerateQuestionsResponse({
    required this.message,
    required this.questionsGenerated,
    required this.questions,
  });

  factory GenerateQuestionsResponse.fromJson(Map<String, dynamic> json) {
    final questionsList = json['questions'] as List<dynamic>? ?? [];
    return GenerateQuestionsResponse(
      message: json['message'] ?? '',
      questionsGenerated: json['questions_generated'] ?? 0,
      questions: questionsList.map((q) => RAGQuestion.fromJson(q)).toList(),
    );
  }
}

class DocumentInfo {
  final String id;
  final String title;
  final List<int> gradeLevels;
  final String? topic;
  final String? uploadedBy;
  final DateTime uploadedAt;
  final String status;
  final int questionsCount;

  DocumentInfo({
    required this.id,
    required this.title,
    required this.gradeLevels,
    this.topic,
    this.uploadedBy,
    required this.uploadedAt,
    required this.status,
    required this.questionsCount,
  });

  factory DocumentInfo.fromJson(Map<String, dynamic> json) {
    return DocumentInfo(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      gradeLevels: List<int>.from(json['grade_levels'] ?? []),
      topic: json['topic'],
      uploadedBy: json['uploaded_by'],
      uploadedAt: DateTime.parse(json['uploaded_at'] ?? DateTime.now().toIso8601String()),
      status: json['status'] ?? 'processing',
      questionsCount: json['questions_count'] ?? 0,
    );
  }
}

class RAGQuestion {
  final String id;
  final String? documentId;
  final String questionText;
  final String questionType; // mcq, short_answer, true_false
  final String correctAnswer;
  final List<String>? options;
  final int gradeLevel;
  final int difficultyLevel;
  final String? bloomLevel;
  final List<String> concepts;
  final String? explanation;
  final List<String> hints;

  RAGQuestion({
    required this.id,
    this.documentId,
    required this.questionText,
    required this.questionType,
    required this.correctAnswer,
    this.options,
    required this.gradeLevel,
    required this.difficultyLevel,
    this.bloomLevel,
    required this.concepts,
    this.explanation,
    required this.hints,
  });

  factory RAGQuestion.fromJson(Map<String, dynamic> json) {
    return RAGQuestion(
      id: json['id'] ?? '',
      documentId: json['document_id'],
      questionText: json['question_text'] ?? '',
      questionType: json['question_type'] ?? 'mcq',
      correctAnswer: json['correct_answer'] ?? '',
      options: json['options'] != null ? List<String>.from(json['options']) : null,
      gradeLevel: json['grade_level'] ?? 0,
      difficultyLevel: json['difficulty_level'] ?? 1,
      bloomLevel: json['bloom_level'],
      concepts: List<String>.from(json['concepts'] ?? []),
      explanation: json['explanation'],
      hints: List<String>.from(json['hints'] ?? []),
    );
  }
  
  // Convert to Question for compatibility
  Question toQuestion() {
    return Question(
      questionId: id,
      questionText: questionText,
      options: options ?? [],
      correctIndex: options?.indexOf(correctAnswer) ?? -1,
      difficulty: difficultyLevel <= 2 ? 'easy' : difficultyLevel <= 4 ? 'medium' : 'hard',
      explanation: explanation ?? '',
    );
  }
}

class AdaptiveFeedback {
  final bool isCorrect;
  final String correctAnswer;
  final String explanation;
  final double abilityScore;
  final int recommendedDifficulty;
  final List<String> strengthConcepts;
  final List<String> weakConcepts;

  AdaptiveFeedback({
    required this.isCorrect,
    required this.correctAnswer,
    required this.explanation,
    required this.abilityScore,
    required this.recommendedDifficulty,
    required this.strengthConcepts,
    required this.weakConcepts,
  });

  factory AdaptiveFeedback.fromJson(Map<String, dynamic> json) {
    return AdaptiveFeedback(
      isCorrect: json['is_correct'] ?? false,
      correctAnswer: json['correct_answer'] ?? '',
      explanation: json['explanation'] ?? '',
      abilityScore: (json['ability_score'] ?? 0.0).toDouble(),
      recommendedDifficulty: json['recommended_difficulty'] ?? 1,
      strengthConcepts: List<String>.from(json['strength_concepts'] ?? []),
      weakConcepts: List<String>.from(json['weak_concepts'] ?? []),
    );
  }
}

class StudentAnalytics {
  final String studentId;
  final double abilityScore;
  final int currentDifficulty;
  final int totalQuestions;
  final int correctAnswers;
  final double accuracy;
  final Map<String, dynamic> conceptsMastery;

  StudentAnalytics({
    required this.studentId,
    required this.abilityScore,
    required this.currentDifficulty,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.accuracy,
    required this.conceptsMastery,
  });

  factory StudentAnalytics.fromJson(Map<String, dynamic> json) {
    return StudentAnalytics(
      studentId: json['student_id'] ?? '',
      abilityScore: (json['ability_score'] ?? 0.0).toDouble(),
      currentDifficulty: json['current_difficulty'] ?? 1,
      totalQuestions: json['total_questions'] ?? 0,
      correctAnswers: json['correct_answers'] ?? 0,
      accuracy: (json['accuracy'] ?? 0.0).toDouble(),
      conceptsMastery: json['concepts_mastery'] ?? {},
    );
  }
}
