/// API client for measurement processing via unit-rag-service (port 8000)
/// Processes measurements and builds educational context
/// Automatically tries multiple URLs for compatibility

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/ar_measurement.dart';
import '../../utils/constants.dart';

class MeasurementApiService {
  // Use dynamically loaded URL from AppConstants
  static List<String> get _baseUrls => [
    '${AppConstants.measurementBaseUrl}/api/v1/measurements',
    'http://localhost:8002/api/v1/measurements',
    'http://10.0.2.2:8002/api/v1/measurements',
  ];
  
  static Map<String, String> get _headers => {
    ...AppConstants.headers,
    'Content-Type': 'application/json',
  };
  
  static Future<String> _getWorkingBaseUrl() async {
    for (final url in _baseUrls) {
      try {
        final healthUrl = url.replaceAll('/api/v1/measurements', '/health');
        final response = await http.get(Uri.parse(healthUrl), headers: AppConstants.headers)
            .timeout(const Duration(seconds: 2));
        if (response.statusCode == 200) {
          print('✅ Connected to measurement service: $url');
          return url;
        }
      } catch (e) {
        continue;
      }
    }
    print('⚠️ Using fallback URL: ${_baseUrls.first}');
    return _baseUrls.first;
  }
  
  /// Process an AR measurement and get educational context
  /// 
  /// Takes raw AR measurement data and returns structured context
  /// including suggested grade, difficulty hints, and personalized prompts
  Future<MeasurementContext> processMeasurement({
    required MeasurementType measurementType,
    required double value,
    required MeasurementUnit unit,
    required String objectName,
    required String studentId,
    required int grade,
  }) async {
    try {
      final request = ARMeasurementRequest(
        measurementType: measurementType,
        value: value,
        unit: unit,
        objectName: objectName,
        studentId: studentId,
        grade: grade,
      );
      
      print('🔄 Processing AR measurement: ${request.toJson()}');
      
      final baseUrl = await _getWorkingBaseUrl();
      final response = await http.post(
        Uri.parse('$baseUrl/process'),
        headers: _headers,
        body: jsonEncode(request.toJson()),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final context = MeasurementContext.fromJson(data);
        
        print('✅ Measurement context built: ${context.topicDisplay}');
        print('   Suggested grade: ${context.suggestedGrade}');
        print('   Prompt: ${context.personalizedPrompt}');
        
        return context;
      } else {
        throw Exception(
          'Failed to process measurement: ${response.statusCode} - ${response.body}'
        );
      }
    } catch (e) {
      print('❌ Error processing measurement: $e');
      rethrow;
    }
  }
  
  /// Quick measurement context for testing (without AR)
  Future<MeasurementContext> quickMeasurement({
    required String objectName,
    required double value,
    required MeasurementUnit unit,
    required MeasurementType type,
    int grade = 1,
  }) async {
    return processMeasurement(
      measurementType: type,
      value: value,
      unit: unit,
      objectName: objectName,
      studentId: 'student_123', // TODO: Get from auth service
      grade: grade,
    );
  }
  
  /// Check if measurement-service is available
  Future<bool> checkHealth() async {
    try {
      final baseUrl = await _getWorkingBaseUrl();
      final healthUrl = baseUrl.replaceAll('/api/v1/measurements', '/health');
      final response = await http.get(
        Uri.parse(healthUrl),
        headers: AppConstants.headers,
      ).timeout(const Duration(seconds: 3));
      
      return response.statusCode == 200;
    } catch (e) {
      print('❌ measurement-service not available: $e');
      return false;
    }
  }
}
