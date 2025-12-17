// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ar_measurement.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ARMeasurementRequest _$ARMeasurementRequestFromJson(
        Map<String, dynamic> json) =>
    ARMeasurementRequest(
      measurementType:
          $enumDecode(_$MeasurementTypeEnumMap, json['measurement_type']),
      value: (json['value'] as num).toDouble(),
      unit: $enumDecode(_$MeasurementUnitEnumMap, json['unit']),
      objectName: json['object_name'] as String,
      studentId: json['student_id'] as String,
      grade: (json['grade'] as num).toInt(),
    );

Map<String, dynamic> _$ARMeasurementRequestToJson(
        ARMeasurementRequest instance) =>
    <String, dynamic>{
      'measurement_type': _$MeasurementTypeEnumMap[instance.measurementType]!,
      'value': instance.value,
      'unit': _$MeasurementUnitEnumMap[instance.unit]!,
      'object_name': instance.objectName,
      'student_id': instance.studentId,
      'grade': instance.grade,
    };

const _$MeasurementTypeEnumMap = {
  MeasurementType.length: 'length',
  MeasurementType.capacity: 'capacity',
  MeasurementType.weight: 'weight',
  MeasurementType.area: 'area',
};

const _$MeasurementUnitEnumMap = {
  MeasurementUnit.mm: 'mm',
  MeasurementUnit.cm: 'cm',
  MeasurementUnit.m: 'm',
  MeasurementUnit.km: 'km',
  MeasurementUnit.ml: 'ml',
  MeasurementUnit.l: 'l',
  MeasurementUnit.g: 'g',
  MeasurementUnit.kg: 'kg',
  MeasurementUnit.cm2: 'cm²',
  MeasurementUnit.m2: 'm²',
};

MeasurementContext _$MeasurementContextFromJson(Map<String, dynamic> json) =>
    MeasurementContext(
      contextDescription: json['context_description'] as String,
      topic: json['topic'] as String,
      suggestedGrade: (json['suggested_grade'] as num).toInt(),
      difficultyHints: (json['difficulty_hints'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      personalizedPrompt: json['personalized_prompt'] as String,
      objectName: json['object_name'] as String,
      value: (json['value'] as num).toDouble(),
      unit: $enumDecode(_$MeasurementUnitEnumMap, json['unit']),
      measurementType:
          $enumDecode(_$MeasurementTypeEnumMap, json['measurement_type']),
    );

Map<String, dynamic> _$MeasurementContextToJson(MeasurementContext instance) =>
    <String, dynamic>{
      'context_description': instance.contextDescription,
      'topic': instance.topic,
      'suggested_grade': instance.suggestedGrade,
      'difficulty_hints': instance.difficultyHints,
      'personalized_prompt': instance.personalizedPrompt,
      'object_name': instance.objectName,
      'value': instance.value,
      'unit': _$MeasurementUnitEnumMap[instance.unit]!,
      'measurement_type': _$MeasurementTypeEnumMap[instance.measurementType]!,
    };

ContextualQuestionRequest _$ContextualQuestionRequestFromJson(
        Map<String, dynamic> json) =>
    ContextualQuestionRequest(
      studentId: json['student_id'] as String,
      grade: (json['grade'] as num).toInt(),
      numQuestions: (json['num_questions'] as num?)?.toInt() ?? 5,
      measurementContext: MeasurementContext.fromJson(
          json['measurement_context'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ContextualQuestionRequestToJson(
        ContextualQuestionRequest instance) =>
    <String, dynamic>{
      'student_id': instance.studentId,
      'grade': instance.grade,
      'num_questions': instance.numQuestions,
      'measurement_context': instance.measurementContext,
    };

ContextualQuestion _$ContextualQuestionFromJson(Map<String, dynamic> json) =>
    ContextualQuestion(
      questionId: json['question_id'] as String,
      questionText: json['question_text'] as String,
      questionType: json['question_type'] as String,
      options:
          (json['options'] as List<dynamic>?)?.map((e) => e as String).toList(),
      correctAnswer: json['correct_answer'] as String,
      explanation: json['explanation'] as String?,
      difficultyLevel: (json['difficulty_level'] as num?)?.toInt() ?? 3,
      hints:
          (json['hints'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
    );

Map<String, dynamic> _$ContextualQuestionToJson(ContextualQuestion instance) =>
    <String, dynamic>{
      'question_id': instance.questionId,
      'question_text': instance.questionText,
      'question_type': instance.questionType,
      'options': instance.options,
      'correct_answer': instance.correctAnswer,
      'explanation': instance.explanation,
      'difficulty_level': instance.difficultyLevel,
      'hints': instance.hints,
    };

ContextualQuestionResponse _$ContextualQuestionResponseFromJson(
        Map<String, dynamic> json) =>
    ContextualQuestionResponse(
      success: json['success'] as bool,
      measurementContextSummary:
          json['measurement_context'] as Map<String, dynamic>,
      questions: (json['questions'] as List<dynamic>)
          .map((e) => ContextualQuestion.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalQuestions: (json['total_questions'] as num).toInt(),
    );

Map<String, dynamic> _$ContextualQuestionResponseToJson(
        ContextualQuestionResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'measurement_context': instance.measurementContextSummary,
      'questions': instance.questions,
      'total_questions': instance.totalQuestions,
    };
