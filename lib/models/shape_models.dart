/// Shape Models for Shapes Service Integration
library;

import 'dart:convert';

/// Shape data model
class ShapeData {
  final String id;
  final String name;
  final String imageUrl;

  ShapeData({
    required this.id,
    required this.name,
    required this.imageUrl,
  });

  factory ShapeData.fromJson(Map<String, dynamic> json) {
    return ShapeData(
      id: json['id'] as String? ?? '', // Default to empty string if id is missing
      name: json['name'] as String,
      imageUrl: json['image_url'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image_url': imageUrl,
    };
  }
}

/// Question model for quiz-type games
class ShapeQuestion {
  final String id;
  final String question;

  ShapeQuestion({
    required this.id,
    required this.question,
  });

  factory ShapeQuestion.fromJson(Map<String, dynamic> json) {
    return ShapeQuestion(
      id: json['id'] as String,
      question: json['question'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
    };
  }
}

/// Pattern data model for pattern matching games
class PatternData {
  final String id;
  final List<ShapeData?> sequence;
  final List<ShapeData> options;
  final ShapeData correctAnswer;

  PatternData({
    required this.id,
    required this.sequence,
    required this.options,
    required this.correctAnswer,
  });

  factory PatternData.fromJson(Map<String, dynamic> json) {
    return PatternData(
      id: json['id'] as String,
      sequence: (json['sequence'] as List)
          .map((item) {
            if (item == null) return null;
            return ShapeData.fromJson(item as Map<String, dynamic>);
          })
          .toList(),
      options: (json['options'] as List)
          .map((item) => ShapeData.fromJson(item as Map<String, dynamic>))
          .toList(),
      correctAnswer: ShapeData.fromJson(json['correct_answer'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sequence': sequence.map((item) => item?.toJson()).toList(),
      'options': options.map((item) => item.toJson()).toList(),
      'correct_answer': correctAnswer.toJson(),
    };
  }
}

/// Base game model
class ShapeGame {
  final String gameId;
  final int level;
  final String title;
  final String? type;

  ShapeGame({
    required this.gameId,
    required this.level,
    required this.title,
    this.type,
  });

  factory ShapeGame.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    
    if (type == 'question_round') {
      return QuestionRoundGame.fromJson(json);
    } else if (type == 'pattern_matching') {
      return PatternMatchingGame.fromJson(json);
    } else {
      // Default: shape matching game
      return ShapeMatchingGame.fromJson(json);
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'game_id': gameId,
      'level': level,
      'title': title,
      if (type != null) 'type': type,
    };
  }
}

/// Shape matching game (Level 1, 3)
class ShapeMatchingGame extends ShapeGame {
  final List<ShapeData> shapes;
  final List<String> wordPool;

  ShapeMatchingGame({
    required super.gameId,
    required super.level,
    required super.title,
    required this.shapes,
    required this.wordPool,
  }) : super(type: null);

  factory ShapeMatchingGame.fromJson(Map<String, dynamic> json) {
    return ShapeMatchingGame(
      gameId: json['game_id'] as String,
      level: json['level'] as int,
      title: json['title'] as String,
      shapes: (json['shapes'] as List)
          .map((item) => ShapeData.fromJson(item))
          .toList(),
      wordPool: (json['word_pool'] as List)
          .map((item) => item as String)
          .toList(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'shapes': shapes.map((item) => item.toJson()).toList(),
      'word_pool': wordPool,
    };
  }
}

/// Question round game (Level 2, 4)
class QuestionRoundGame extends ShapeGame {
  final List<ShapeQuestion> questions;
  final List<String> answerPool;
  final Map<String, String> correctAnswers;

  QuestionRoundGame({
    required super.gameId,
    required super.level,
    required super.title,
    required this.questions,
    required this.answerPool,
    required this.correctAnswers,
  }) : super(type: 'question_round');

  factory QuestionRoundGame.fromJson(Map<String, dynamic> json) {
    return QuestionRoundGame(
      gameId: json['game_id'] as String,
      level: json['level'] as int,
      title: json['title'] as String,
      questions: (json['questions'] as List)
          .map((item) => ShapeQuestion.fromJson(item))
          .toList(),
      answerPool: (json['answer_pool'] as List)
          .map((item) => item as String)
          .toList(),
      correctAnswers: Map<String, String>.from(json['correct_answers']),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'questions': questions.map((item) => item.toJson()).toList(),
      'answer_pool': answerPool,
      'correct_answers': correctAnswers,
    };
  }
}

/// Pattern matching game (Level 5, 6)
class PatternMatchingGame extends ShapeGame {
  final List<PatternData> patterns;
  final List<ShapeData> shapePool;

  PatternMatchingGame({
    required super.gameId,
    required super.level,
    required super.title,
    required this.patterns,
    required this.shapePool,
  }) : super(type: 'pattern_matching');

  factory PatternMatchingGame.fromJson(Map<String, dynamic> json) {
    return PatternMatchingGame(
      gameId: json['game_id'] as String,
      level: json['level'] as int,
      title: json['title'] as String,
      patterns: (json['patterns'] as List)
          .map((item) => PatternData.fromJson(item))
          .toList(),
      shapePool: (json['shape_pool'] as List)
          .map((item) => ShapeData.fromJson(item))
          .toList(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'patterns': patterns.map((item) => item.toJson()).toList(),
      'shape_pool': shapePool.map((item) => item.toJson()).toList(),
    };
  }
}

/// Game answer request model
class GameAnswer {
  final String gameId;
  final Map<String, String> answers;

  GameAnswer({
    required this.gameId,
    required this.answers,
  });

  Map<String, dynamic> toJson() {
    // Convert game_id to level number (e.g., "level1" -> 1)
    final levelNum = int.tryParse(gameId.replaceAll('level', '')) ?? 1;
    
    // Convert answers map to list of objects
    final answersList = answers.entries.map((entry) => {
      'question_id': entry.key,
      'answer': entry.value,
    }).toList();
    
    return {
      'level': levelNum,
      'answers': answersList,
    };
  }
}

/// Game result model
class GameResult {
  final String gameId;
  final int score;
  final int totalQuestions;
  final int correctAnswers;
  final int wrongAnswers;
  final Map<String, bool> answerResults;
  final bool isPassed;

  GameResult({
    required this.gameId,
    required this.score,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.answerResults,
    required this.isPassed,
  });

  factory GameResult.fromJson(Map<String, dynamic> json) {
    // Backend returns: {score, total_questions, status, results}
    final results = json['results'] as List<dynamic>? ?? [];
    final totalQuestions = json['total_questions'] as int? ?? results.length;
    final score = json['score'] as int? ?? 0;
    final status = json['status'] as String? ?? 'fail';
    
    // Convert results list to answer_results map
    final answerResults = <String, bool>{};
    for (var result in results) {
      final questionId = result['question_id'] as String;
      final isCorrect = result['is_correct'] as bool;
      answerResults[questionId] = isCorrect;
    }
    
    return GameResult(
      gameId: json['game_id'] as String? ?? 'level1',
      score: score,
      totalQuestions: totalQuestions,
      correctAnswers: score,
      wrongAnswers: totalQuestions - score,
      answerResults: answerResults,
      isPassed: status == 'pass',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'game_id': gameId,
      'score': score,
      'total_questions': totalQuestions,
      'correct_answers': correctAnswers,
      'wrong_answers': wrongAnswers,
      'answer_results': answerResults,
      'is_passed': isPassed,
    };
  }

  int get stars {
    if (correctAnswers == totalQuestions) return 3;
    if (correctAnswers >= (totalQuestions * 0.7)) return 2;
    if (correctAnswers >= (totalQuestions * 0.5)) return 1;
    return 0;
  }
}
