import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:ganithamithura/models/unit_models.dart';

/// API Service for Unit-based Learning
/// Base URL should be configured in production
class UnitApiService {
  // Using WiFi IP - works on any device without ADB setup
  // Make sure phone and Mac are on same WiFi network
  static const String baseUrl = 'http://192.168.1.18:8000/api';
  static const String ragBaseUrl = 'http://192.168.1.18:8000'; // RAG Service
  
  // Singleton pattern
  static final UnitApiService _instance = UnitApiService._internal();
  factory UnitApiService() => _instance;
  UnitApiService._internal();
  
  // Current student ID (should be set on login/app start)
  String? _currentStudentId;
  
  void setStudentId(String studentId) {
    _currentStudentId = studentId;
  }
  
  String get studentId => _currentStudentId ?? 'student_default';
  
  /// GET /api/units?grade=3
  /// Fetch all units for a specific grade
  Future<List<Unit>> getUnits(int grade) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/units?grade=$grade'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Unit.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load units: ${response.statusCode}');
      }
    } catch (e) {
      // Return mock data for MVP if API fails
      return _getMockUnits(grade);
    }
  }
  
  /// POST /api/chat
  /// Send chat message and get AI response
  Future<ChatResponse> sendChatMessage({
    required String unitId,
    required String message,
    List<Map<String, dynamic>>? conversationHistory,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$ragBaseUrl/chat'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'studentId': studentId,
          'unitId': unitId,
          'message': message,
          'conversationHistory': conversationHistory ?? [],
        }),
      ).timeout(const Duration(seconds: 20));
      
      if (response.statusCode == 200) {
        return ChatResponse.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to send message: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Chat error: $e');
      throw Exception('Failed to get AI response');
    }
  }
  
  /// GET /api/chat/history/{studentId}/{unitId}
  /// Load chat history from database (multi-device sync)
  Future<List<ChatMessage>> loadChatHistory({
    required String unitId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$ragBaseUrl/chat/history/$studentId/$unitId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final messages = data['messages'] as List<dynamic>? ?? [];
        return messages.map((msg) => ChatMessage.fromJson(msg)).toList();
      } else {
        debugPrint('Failed to load chat history: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error loading chat history: $e');
      return [];
    }
  }
  
  /// DELETE /api/chat/history/{studentId}/{unitId}
  /// Clear chat history from database
  Future<void> clearChatHistory({
    required String unitId,
  }) async {
    try {
      await http.delete(
        Uri.parse('$ragBaseUrl/chat/history/$studentId/$unitId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('Error clearing chat history: $e');
    }
  }
  
  // ========== RAG SERVICE ENDPOINTS ==========
  
  /// POST /upload/document
  /// Upload a document for a specific unit and grade
  Future<UploadDocumentResponse> uploadDocument({
    required File file,
    required List<int> gradeLevels,
    required String topic,
    String? teacherId,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$ragBaseUrl/upload/document'),
      );
      
      // Add file
      request.files.add(
        await http.MultipartFile.fromPath('file', file.path),
      );
      
      // Add form fields
      request.fields['grade_levels'] = gradeLevels.join(',');
      request.fields['topic'] = topic;
      if (teacherId != null) {
        request.fields['uploaded_by'] = teacherId;
      }
      
      final streamedResponse = await request.send()
          .timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        return UploadDocumentResponse.fromJson(json.decode(response.body));
      } else {
        throw Exception('Upload failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Document upload error: $e');
    }
  }
  
  /// POST /questions/generate/{documentId}
  /// Generate questions from uploaded document
  Future<GenerateQuestionsResponse> generateQuestions({
    required String documentId,
    required int gradeLevel,
    int numQuestions = 10,
    List<int>? difficultyLevels,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$ragBaseUrl/questions/generate/$documentId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'num_questions': numQuestions,
          'grade_level': gradeLevel,
          if (difficultyLevels != null) 'difficulty_levels': difficultyLevels,
        }),
      ).timeout(const Duration(seconds: 60));
      
      if (response.statusCode == 200) {
        return GenerateQuestionsResponse.fromJson(json.decode(response.body));
      } else {
        throw Exception('Question generation failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Generate questions error: $e');
    }
  }
  
  /// GET /documents
  /// Get all uploaded documents (for teacher dashboard)
  Future<List<DocumentInfo>> getDocuments({
    String? topic,
    int? gradeLevel,
  }) async {
    try {
      var uri = '$ragBaseUrl/documents';
      final queryParams = <String>[];
      if (topic != null) queryParams.add('topic=$topic');
      if (gradeLevel != null) queryParams.add('grade_level=$gradeLevel');
      if (queryParams.isNotEmpty) {
        uri += '?${queryParams.join('&')}';
      }
      
      final response = await http.get(
        Uri.parse(uri),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => DocumentInfo.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch documents: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Get documents error: $e');
    }
  }
  
  /// GET /documents/{documentId}
  /// Get document details
  Future<DocumentInfo> getDocumentDetails(String documentId) async {
    try {
      final response = await http.get(
        Uri.parse('$ragBaseUrl/documents/$documentId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return DocumentInfo.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to fetch document: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Get document details error: $e');
    }
  }
  
  /// GET /questions/
  /// Get questions by filters
  Future<List<RAGQuestion>> getRAGQuestions({
    String? documentId,
    int? gradeLevel,
    int? difficultyLevel,
    int skip = 0,
    int limit = 50,
  }) async {
    try {
      final queryParams = <String>[
        'skip=$skip',
        'limit=$limit',
      ];
      if (documentId != null) queryParams.add('document_id=$documentId');
      if (gradeLevel != null) queryParams.add('grade_level=$gradeLevel');
      if (difficultyLevel != null) queryParams.add('difficulty_level=$difficultyLevel');
      
      final response = await http.get(
        Uri.parse('$ragBaseUrl/questions/?${queryParams.join('&')}'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => RAGQuestion.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch questions: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Get RAG questions error: $e');
    }
  }
  
  /// POST /adaptive/submit-answer
  /// Submit answer with adaptive feedback
  Future<AdaptiveFeedback> submitAdaptiveAnswer({
    required String questionId,
    required String unitId,
    required String answer,
    int? timeTaken,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$ragBaseUrl/api/v1/adaptive/submit-answer'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'student_id': studentId,
          'question_id': questionId,
          'unit_id': unitId,
          'answer': answer,
          if (timeTaken != null) 'time_taken': timeTaken,
        }),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return AdaptiveFeedback.fromJson(json.decode(response.body));
      } else {
        throw Exception('Submit answer failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Submit adaptive answer error: $e');
    }
  }
  
  /// GET /api/v1/adaptive/next-question
  /// Get next adaptive question based on student ability
  Future<RAGQuestion> getAdaptiveQuestion({
    required String unitId,
    int? currentDifficulty,
    int? gradeLevel,
  }) async {
    try {
      final queryParams = [
        'student_id=$studentId',
        'unit_id=$unitId',
      ];
      if (currentDifficulty != null) {
        queryParams.add('current_difficulty=$currentDifficulty');
      }
      if (gradeLevel != null) {
        queryParams.add('grade_level=$gradeLevel');
      }
      
      final response = await http.get(
        Uri.parse('$ragBaseUrl/api/v1/adaptive/next-question?${queryParams.join('&')}'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return RAGQuestion.fromJson(json.decode(response.body));
      } else {
        throw Exception('Get adaptive question failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Get adaptive question error: $e');
    }
  }
  
  /// GET /api/v1/adaptive/analytics/{studentId}
  /// Get student analytics and ability metrics
  Future<StudentAnalytics> getStudentAnalytics({String? unitId}) async {
    try {
      var uri = '$ragBaseUrl/api/v1/adaptive/analytics/$studentId';
      if (unitId != null) {
        uri += '?unit_id=$unitId';
      }
      
      final response = await http.get(
        Uri.parse(uri),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return StudentAnalytics.fromJson(json.decode(response.body));
      } else {
        throw Exception('Get analytics failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Get student analytics error: $e');
    }
  }
  
  // ========== MOCK DATA FOR MVP ==========
  
  List<Unit> _getMockUnits(int grade) {
    return [
      Unit(
        id: 'unit_length_$grade',
        name: 'Length – cm and m',
        topic: 'Length',
        grade: grade,
        description: 'Learn to measure length using centimeters and meters',
        iconName: 'straighten',
      ),
      Unit(
        id: 'unit_area_$grade',
        name: 'Area – cm² and m²',
        topic: 'Area',
        grade: grade,
        description: 'Understand how to calculate area of shapes',
        iconName: 'crop_square',
      ),
      Unit(
        id: 'unit_capacity_$grade',
        name: 'Capacity – ml and l',
        topic: 'Capacity',
        grade: grade,
        description: 'Learn about volume and capacity measurements',
        iconName: 'local_drink',
      ),
      Unit(
        id: 'unit_weight_$grade',
        name: 'Weight – g and kg',
        topic: 'Weight',
        grade: grade,
        description: 'Understand weight measurements in grams and kilograms',
        iconName: 'fitness_center',
      ),
    ];
  }
  
  StudentUnitProgress _getMockProgress(String unitId) {
    return StudentUnitProgress(
      unitId: unitId,
      questionsAnswered: 12,
      correctAnswers: 9,
      accuracy: 75.0,
      stars: 3,
    );
  }
  
  Question _getMockQuestion(String unitId) {
    final questions = [
      Question(
        questionId: 'q1_${DateTime.now().millisecondsSinceEpoch}',
        questionText: 'How many centimeters are in 1 meter?',
        options: ['10 cm', '100 cm', '1000 cm', '50 cm'],
        correctIndex: 1,
        difficulty: 'easy',
        explanation: '1 meter equals 100 centimeters. Remember: 1m = 100cm',
      ),
      Question(
        questionId: 'q2_${DateTime.now().millisecondsSinceEpoch}',
        questionText: 'If a pencil is 15 cm long, how many mm is that?',
        options: ['150 mm', '15 mm', '1500 mm', '1.5 mm'],
        correctIndex: 0,
        difficulty: 'medium',
        explanation: '1 cm = 10 mm, so 15 cm = 15 × 10 = 150 mm',
      ),
      Question(
        questionId: 'q3_${DateTime.now().millisecondsSinceEpoch}',
        questionText: 'Which is longer: 2 meters or 150 centimeters?',
        options: ['2 meters', '150 centimeters', 'They are equal', 'Cannot compare'],
        correctIndex: 0,
        difficulty: 'easy',
        explanation: '2 meters = 200 cm, which is longer than 150 cm',
      ),
    ];
    
    return questions[DateTime.now().second % questions.length];
  }
  
  AnswerResponse _getMockAnswerResponse(int selectedIndex) {
    final isCorrect = selectedIndex == 1; // Mock: option B is correct
    return AnswerResponse(
      isCorrect: isCorrect,
      correctIndex: 1,
      explanation: isCorrect 
          ? 'Great job! That\'s correct!' 
          : '1 meter equals 100 centimeters. Remember: 1m = 100cm',
    );
  }
  
  ChatResponse _getMockChatResponse(String message) {
    return ChatResponse(
      reply: 'Great question! In measurement, we use different units for different sizes. '
             'For example, we use centimeters (cm) for small things like pencils, '
             'and meters (m) for bigger things like the height of a door. '
             'Remember: 100 cm = 1 m. Would you like to practice some questions?',
    );
  }
}
