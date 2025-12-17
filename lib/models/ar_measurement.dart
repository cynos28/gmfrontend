/// AR Measurement Models for contextual question generation
/// 
/// These models represent:
/// - AR measurement data captured from camera
/// - Measurement context processed by measurement-service
/// - Contextual questions generated based on AR measurements

import 'package:json_annotation/json_annotation.dart';

part 'ar_measurement.g.dart';

/// Types of measurements supported by AR
enum MeasurementType {
  @JsonValue('length')
  length,
  @JsonValue('capacity')
  capacity,
  @JsonValue('weight')
  weight,
  @JsonValue('area')
  area,
}

/// Units for different measurement types
enum MeasurementUnit {
  // Length units
  @JsonValue('mm')
  mm,
  @JsonValue('cm')
  cm,
  @JsonValue('m')
  m,
  @JsonValue('km')
  km,
  
  // Capacity units
  @JsonValue('ml')
  ml,
  @JsonValue('l')
  l,
  
  // Weight units
  @JsonValue('g')
  g,
  @JsonValue('kg')
  kg,
  
  // Area units
  @JsonValue('cm²')
  cm2,
  @JsonValue('m²')
  m2,
}

/// AR measurement request sent to measurement-service
@JsonSerializable()
class ARMeasurementRequest {
  @JsonKey(name: 'measurement_type')
  final MeasurementType measurementType;
  
  final double value;
  final MeasurementUnit unit;
  
  @JsonKey(name: 'object_name')
  final String objectName;
  
  @JsonKey(name: 'student_id')
  final String studentId;
  
  final int grade;
  
  ARMeasurementRequest({
    required this.measurementType,
    required this.value,
    required this.unit,
    required this.objectName,
    required this.studentId,
    required this.grade,
  });
  
  factory ARMeasurementRequest.fromJson(Map<String, dynamic> json) =>
      _$ARMeasurementRequestFromJson(json);
  
  Map<String, dynamic> toJson() => _$ARMeasurementRequestToJson(this);
}

/// Measurement context response from measurement-service
@JsonSerializable()
class MeasurementContext {
  @JsonKey(name: 'context_description')
  final String contextDescription;
  
  final String topic;
  
  @JsonKey(name: 'suggested_grade')
  final int suggestedGrade;
  
  @JsonKey(name: 'difficulty_hints')
  final List<String> difficultyHints;
  
  @JsonKey(name: 'personalized_prompt')
  final String personalizedPrompt;
  
  @JsonKey(name: 'object_name')
  final String objectName;
  
  final double value;
  final MeasurementUnit unit;
  
  @JsonKey(name: 'measurement_type')
  final MeasurementType measurementType;
  
  MeasurementContext({
    required this.contextDescription,
    required this.topic,
    required this.suggestedGrade,
    required this.difficultyHints,
    required this.personalizedPrompt,
    required this.objectName,
    required this.value,
    required this.unit,
    required this.measurementType,
  });
  
  factory MeasurementContext.fromJson(Map<String, dynamic> json) =>
      _$MeasurementContextFromJson(json);
  
  Map<String, dynamic> toJson() => _$MeasurementContextToJson(this);
  
  /// Human-readable measurement string
  String get measurementString => '$value${unit.name}';
  
  /// Display-friendly topic name
  String get topicDisplay {
    switch (measurementType) {
      case MeasurementType.length:
        return 'Length';
      case MeasurementType.capacity:
        return 'Capacity';
      case MeasurementType.weight:
        return 'Weight';
      case MeasurementType.area:
        return 'Area';
    }
  }
}

/// Request to generate contextual questions
@JsonSerializable()
class ContextualQuestionRequest {
  @JsonKey(name: 'student_id')
  final String studentId;
  
  final int grade;
  
  @JsonKey(name: 'num_questions')
  final int numQuestions;
  
  @JsonKey(name: 'measurement_context')
  final MeasurementContext measurementContext;
  
  ContextualQuestionRequest({
    required this.studentId,
    required this.grade,
    this.numQuestions = 5,
    required this.measurementContext,
  });
  
  factory ContextualQuestionRequest.fromJson(Map<String, dynamic> json) =>
      _$ContextualQuestionRequestFromJson(json);
  
  Map<String, dynamic> toJson() => _$ContextualQuestionRequestToJson(this);
}

/// Contextual question response
@JsonSerializable()
class ContextualQuestion {
  @JsonKey(name: 'question_id')
  final String questionId;
  
  @JsonKey(name: 'question_text')
  final String questionText;
  
  @JsonKey(name: 'question_type')
  final String questionType; // 'mcq', 'short_answer'
  
  final List<String>? options;
  
  @JsonKey(name: 'correct_answer')
  final String correctAnswer;
  
  final String? explanation;
  
  @JsonKey(name: 'difficulty_level')
  final int difficultyLevel;
  
  final List<String> hints;
  
  ContextualQuestion({
    required this.questionId,
    required this.questionText,
    required this.questionType,
    this.options,
    required this.correctAnswer,
    this.explanation,
    this.difficultyLevel = 3,
    this.hints = const [],
  });
  
  factory ContextualQuestion.fromJson(Map<String, dynamic> json) =>
      _$ContextualQuestionFromJson(json);
  
  Map<String, dynamic> toJson() => _$ContextualQuestionToJson(this);
  
  /// Check if answer is correct
  bool isCorrect(String answer) {
    return answer.trim().toLowerCase() == correctAnswer.trim().toLowerCase();
  }
}

/// Response from contextual question generation
@JsonSerializable()
class ContextualQuestionResponse {
  final bool success;
  
  @JsonKey(name: 'measurement_context')
  final Map<String, dynamic> measurementContextSummary;
  
  final List<ContextualQuestion> questions;
  
  @JsonKey(name: 'total_questions')
  final int totalQuestions;
  
  ContextualQuestionResponse({
    required this.success,
    required this.measurementContextSummary,
    required this.questions,
    required this.totalQuestions,
  });
  
  factory ContextualQuestionResponse.fromJson(Map<String, dynamic> json) =>
      _$ContextualQuestionResponseFromJson(json);
  
  Map<String, dynamic> toJson() => _$ContextualQuestionResponseToJson(this);
}

/// AR measurement session (for tracking multiple measurements)
class ARMeasurementSession {
  final String sessionId;
  final DateTime startTime;
  final String studentId;
  final MeasurementType type;
  final List<ARMeasurement> measurements;
  
  ARMeasurementSession({
    required this.sessionId,
    required this.startTime,
    required this.studentId,
    required this.type,
    this.measurements = const [],
  });
  
  /// Add a new measurement to the session
  ARMeasurementSession addMeasurement(ARMeasurement measurement) {
    return ARMeasurementSession(
      sessionId: sessionId,
      startTime: startTime,
      studentId: studentId,
      type: type,
      measurements: [...measurements, measurement],
    );
  }
  
  /// Get the latest measurement
  ARMeasurement? get latestMeasurement =>
      measurements.isNotEmpty ? measurements.last : null;
  
  /// Get session duration
  Duration get duration => DateTime.now().difference(startTime);
}

/// Individual AR measurement
class ARMeasurement {
  final String id;
  final DateTime timestamp;
  final double value;
  final MeasurementUnit unit;
  final String objectName;
  final MeasurementContext? context;
  final List<ContextualQuestion> questions;
  
  ARMeasurement({
    required this.id,
    required this.timestamp,
    required this.value,
    required this.unit,
    required this.objectName,
    this.context,
    this.questions = const [],
  });
  
  /// Create a measurement with context
  ARMeasurement withContext(MeasurementContext context) {
    return ARMeasurement(
      id: id,
      timestamp: timestamp,
      value: value,
      unit: unit,
      objectName: objectName,
      context: context,
      questions: questions,
    );
  }
  
  /// Create a measurement with questions
  ARMeasurement withQuestions(List<ContextualQuestion> questions) {
    return ARMeasurement(
      id: id,
      timestamp: timestamp,
      value: value,
      unit: unit,
      objectName: objectName,
      context: context,
      questions: questions,
    );
  }
  
  /// Human-readable measurement
  String get measurementString => '$value${unit.name}';
}

/// Helper extensions
extension MeasurementTypeExtension on MeasurementType {
  String get displayName {
    switch (this) {
      case MeasurementType.length:
        return 'Length';
      case MeasurementType.capacity:
        return 'Capacity';
      case MeasurementType.weight:
        return 'Weight';
      case MeasurementType.area:
        return 'Area';
    }
  }
  
  String get icon {
    switch (this) {
      case MeasurementType.length:
        return '📏';
      case MeasurementType.capacity:
        return '🥤';
      case MeasurementType.weight:
        return '⚖️';
      case MeasurementType.area:
        return '📐';
    }
  }
}

extension MeasurementUnitExtension on MeasurementUnit {
  String get displayName {
    switch (this) {
      case MeasurementUnit.mm:
        return 'Millimeters';
      case MeasurementUnit.cm:
        return 'Centimeters';
      case MeasurementUnit.m:
        return 'Meters';
      case MeasurementUnit.km:
        return 'Kilometers';
      case MeasurementUnit.ml:
        return 'Milliliters';
      case MeasurementUnit.l:
        return 'Liters';
      case MeasurementUnit.g:
        return 'Grams';
      case MeasurementUnit.kg:
        return 'Kilograms';
      case MeasurementUnit.cm2:
        return 'Square Centimeters';
      case MeasurementUnit.m2:
        return 'Square Meters';
    }
  }
}
