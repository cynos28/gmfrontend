/// AR Learning Service - Coordinates measurement processing and question generation
/// 
/// This service orchestrates the full learning flow:
/// 1. Student enters measurement details
/// 2. Measurement sent to unit-rag-service for context building
/// 3. Context used by RAG service for personalized question generation
/// 4. Questions displayed to student with their actual measurement

import 'package:uuid/uuid.dart';
import '../models/ar_measurement.dart';
import 'api/measurement_api_service.dart';
import 'api/contextual_question_service.dart';

class ARLearningService {
  final MeasurementApiService _measurementApi = MeasurementApiService();
  final ContextualQuestionService _questionApi = ContextualQuestionService();
  final Uuid _uuid = const Uuid();
  
  // Active AR sessions
  final Map<String, ARMeasurementSession> _activeSessions = {};
  
  /// Start a new AR measurement session
  ARMeasurementSession startSession({
    required String studentId,
    required MeasurementType type,
  }) {
    final session = ARMeasurementSession(
      sessionId: _uuid.v4(),
      startTime: DateTime.now(),
      studentId: studentId,
      type: type,
    );
    
    _activeSessions[session.sessionId] = session;
    print('📱 Started AR session: ${type.displayName} (${session.sessionId})');
    
    return session;
  }
  
  /// Process an AR measurement and generate contextual questions
  /// 
  /// This is the main method that orchestrates the entire flow
  Future<ARMeasurement> processARMeasurement({
    required String sessionId,
    required double value,
    required MeasurementUnit unit,
    required String objectName,
    required String studentId,
    int grade = 1,
    int numQuestions = 5,
  }) async {
    final session = _activeSessions[sessionId];
    if (session == null) {
      throw Exception('Session not found: $sessionId');
    }
    
    // Create initial measurement object
    final measurement = ARMeasurement(
      id: _uuid.v4(),
      timestamp: DateTime.now(),
      value: value,
      unit: unit,
      objectName: objectName,
    );
    
    try {
      // Step 1: Process measurement to get educational context
      print('📏 Step 1: Processing measurement...');
      final context = await _measurementApi.processMeasurement(
        measurementType: session.type,
        value: value,
        unit: unit,
        objectName: objectName,
        studentId: studentId,
        grade: grade,
      );
      
      final measurementWithContext = measurement.withContext(context);
      
      // Step 2: Generate personalized questions using RAG + GPT
      print('🤖 Step 2: Generating contextual questions...');
      final response = await _questionApi.generateQuestions(
        measurementContext: context,
        studentId: studentId,
        grade: grade,
        numQuestions: numQuestions,
      );
      
      final finalMeasurement = measurementWithContext.withQuestions(
        response.questions,
      );
      
      // Update session
      _activeSessions[sessionId] = session.addMeasurement(finalMeasurement);
      
      print('✅ AR measurement processed successfully!');
      print('   Object: $objectName');
      print('   Measurement: $value${unit.name}');
      print('   Questions generated: ${response.questions.length}');
      
      return finalMeasurement;
      
    } catch (e) {
      print('❌ Error processing AR measurement: $e');
      rethrow;
    }
  }
  
  /// Quick test flow without AR camera (for development)
  Future<ARMeasurement> quickTest({
    required MeasurementType type,
    required String objectName,
    required double value,
    required MeasurementUnit unit,
    String studentId = 'student_123',
    int grade = 1,
  }) async {
    final session = startSession(studentId: studentId, type: type);
    
    return processARMeasurement(
      sessionId: session.sessionId,
      value: value,
      unit: unit,
      objectName: objectName,
      studentId: studentId,
      grade: grade,
    );
  }
  
  /// Get measurements from a session
  List<ARMeasurement> getSessionMeasurements(String sessionId) {
    final session = _activeSessions[sessionId];
    return session?.measurements ?? [];
  }
  
  /// End a session
  void endSession(String sessionId) {
    _activeSessions.remove(sessionId);
    print('🛑 Ended AR session: $sessionId');
  }
  
  /// Get all active sessions for a student
  List<ARMeasurementSession> getStudentSessions(String studentId) {
    return _activeSessions.values
        .where((s) => s.studentId == studentId)
        .toList();
  }
  
  /// Check if both services are available
  Future<Map<String, bool>> checkServicesHealth() async {
    final measurementHealth = await _measurementApi.checkHealth();
    final ragHealth = await _questionApi.checkHealth();
    
    return {
      'measurement-service': measurementHealth,
      'rag-service': ragHealth,
      'all_healthy': measurementHealth && ragHealth,
    };
  }
}
