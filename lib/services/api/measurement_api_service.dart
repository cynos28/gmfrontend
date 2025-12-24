/// API client for measurement processing via unit-rag-service (port 8000)
/// Processes measurements and builds educational context
/// Automatically tries multiple URLs for compatibility

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/ar_measurement.dart';

class MeasurementApiService {
  // WiFi IP - works without ADB, just need same WiFi network
  static const List<String> _baseUrls = [
    'http://10.169.0.71:8000/api/v1/measurements',    // WiFi - Mac IP (PRIMARY)
    'http://localhost:8000/api/v1/measurements',      // ADB reverse fallback
    'http://10.0.2.2:8000/api/v1/measurements',       // Android Emulator fallback
  ];
  
  static Future<String> _getWorkingBaseUrl() async {
    for (final url in _baseUrls) {
      try {
        final healthUrl = url.replaceAll('/api/v1/measurements', '/health');
        final response = await http.get(Uri.parse(healthUrl))
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
        headers: {'Content-Type': 'application/json'},
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
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8001/health'),
      ).timeout(const Duration(seconds: 3));
      
      return response.statusCode == 200;
    } catch (e) {
      print('❌ measurement-service not available: $e');
      return false;
    }
  }
}
