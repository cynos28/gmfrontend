/// API client for contextual question generation
/// Uses RAG + GPT to generate personalized questions based on AR measurements
/// Automatically tries multiple URLs for compatibility

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/ar_measurement.dart';

class ContextualQuestionService {
  // Try URLs in order: localhost (adb reverse), then network IP
  static const List<String> _baseUrls = [
    'http://localhost:8000/api/v1/contextual',      // USB debugging (adb reverse)
    'http://192.168.8.145:8000/api/v1/contextual',  // WiFi network
  ];
  
  static Future<String> _getWorkingBaseUrl() async {
    for (final url in _baseUrls) {
      try {
        final healthUrl = url.replaceAll('/api/v1/contextual', '/health');
        final response = await http.get(Uri.parse(healthUrl))
            .timeout(const Duration(seconds: 2));
        if (response.statusCode == 200) {
          print('✅ Connected to RAG service: $url');
          return url;
        }
      } catch (e) {
        continue;
      }
    }
    print('⚠️ Using fallback URL: ${_baseUrls.first}');
    return _baseUrls.first;
  }
  
  /// Generate contextual questions based on AR measurement
  /// 
  /// Flow:
  /// 1. Receives MeasurementContext from measurement-service
  /// 2. Uses RAG to retrieve relevant curriculum chunks
  /// 3. Calls GPT-4o-mini to generate personalized questions
  /// 4. Returns questions referencing student's actual measurement
  Future<ContextualQuestionResponse> generateQuestions({
    required MeasurementContext measurementContext,
    required String studentId,
    required int grade,
    int numQuestions = 5,
  }) async {
    try {
      final request = ContextualQuestionRequest(
        studentId: studentId,
        grade: grade,
        numQuestions: numQuestions,
        measurementContext: measurementContext,
      );
      
      print('🔄 Generating contextual questions...');
      print('   Object: ${measurementContext.objectName}');
      print('   Measurement: ${measurementContext.measurementString}');
      print('   Topic: ${measurementContext.topicDisplay}');
      
      final baseUrl = await _getWorkingBaseUrl();
      final response = await http.post(
        Uri.parse('$baseUrl/generate-questions'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final result = ContextualQuestionResponse.fromJson(data);
        
        print('✅ Generated ${result.totalQuestions} contextual questions');
        if (result.questions.isNotEmpty) {
          print('   First question: ${result.questions.first.questionText}');
        }
        
        return result;
      } else {
        throw Exception(
          'Failed to generate questions: ${response.statusCode} - ${response.body}'
        );
      }
    } catch (e) {
      print('❌ Error generating contextual questions: $e');
      rethrow;
    }
  }
  
  /// Full flow: Process measurement → Generate questions
  /// 
  /// Convenience method that combines both services
  Future<ARMeasurement> createARMeasurementWithQuestions({
    required String objectName,
    required double value,
    required MeasurementUnit unit,
    required MeasurementType type,
    required String studentId,
    int grade = 1,
    int numQuestions = 5,
  }) async {
    // This will be implemented using the MeasurementApiService
    // For now, return a placeholder
    throw UnimplementedError(
      'Use MeasurementApiService + ContextualQuestionService separately'
    );
  }
  
  /// Get previously generated contextual questions for a student
  Future<List<ContextualQuestion>> getStudentQuestions({
    required String studentId,
    String? topic,
    int limit = 20,
  }) async {
    try {
      final queryParams = {
        'student_id': studentId,
        'limit': limit.toString(),
        if (topic != null) 'topic': topic,
      };
      
      final baseUrl = await _getWorkingBaseUrl();
      final uri = Uri.parse('$baseUrl/questions').replace(
        queryParameters: queryParams,
      );
      
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final questions = (data['questions'] as List)
            .map((q) => ContextualQuestion.fromJson(q))
            .toList();
        
        print('✅ Retrieved ${questions.length} contextual questions');
        return questions;
      } else {
        throw Exception(
          'Failed to get questions: ${response.statusCode} - ${response.body}'
        );
      }
    } catch (e) {
      print('❌ Error getting contextual questions: $e');
      return []; // Return empty list on error
    }
  }
  
  /// Check if RAG service is available
  Future<bool> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/health'),
      ).timeout(const Duration(seconds: 3));
      
      return response.statusCode == 200;
    } catch (e) {
      print('❌ RAG service not available: $e');
      return false;
    }
  }
}
