import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ganithamithura/models/user.dart';
import 'package:ganithamithura/services/local_storage/storage_service.dart';
import 'package:ganithamithura/utils/constants.dart';

/// Authentication Service - Handles user authentication with MongoDB backend
class AuthService {
  static AuthService? _instance;
  final String baseUrl;
  
  AuthService._({required this.baseUrl});
  
  static AuthService get instance {
    _instance ??= AuthService._(
      baseUrl: dotenv.env['AUTH_BACKEND_URL'] ?? AppConstants.authBaseUrl,
    );
    return _instance!;
  }
  
  /// Helper method to create headers
  Map<String, String> _getHeaders({String? token}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }
  
  // ==================== Sign Up ====================
  
  /// POST /api/auth/signup - Register a new user
  Future<AuthResponse> signUp({
    required String name,
    required String email,
    required String password,
    required int grade,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/auth/signup');
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'grade': grade,
        }),
      ).timeout(
        Duration(seconds: AppConstants.apiTimeout),
      );
      
      final jsonData = jsonDecode(response.body);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final authResponse = AuthResponse.fromJson(jsonData);
        
        // Save user data and token locally
        if (authResponse.user != null) {
          await _saveUserData(authResponse.user!, authResponse.token);
        }
        
        return authResponse;
      } else {
        return AuthResponse(
          success: false,
          message: jsonData['message'] ?? 'Sign up failed',
        );
      }
    } catch (e) {
      return AuthResponse(
        success: false,
        message: 'Error during sign up: $e',
      );
    }
  }
  
  // ==================== Sign In ====================
  
  /// POST /api/auth/signin - Login existing user
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/auth/signin');
      print('🔐 AUTH DEBUG: Attempting sign in to: $url');
      print('🔐 AUTH DEBUG: baseUrl=$baseUrl');
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(
        Duration(seconds: AppConstants.apiTimeout),
      );
      
      print('🔐 AUTH DEBUG: Response status=${response.statusCode}');
      print('🔐 AUTH DEBUG: Response body=${response.body}');
      
      final jsonData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(jsonData);
        
        // Save user data and token locally
        if (authResponse.user != null) {
          await _saveUserData(authResponse.user!, authResponse.token);
        }
        
        return authResponse;
      } else {
        return AuthResponse(
          success: false,
          message: jsonData['message'] ?? 'Sign in failed',
        );
      }
    } catch (e) {
      print('🔐 AUTH DEBUG: Exception during sign in: $e');
      return AuthResponse(
        success: false,
        message: 'Error during sign in: $e',
      );
    }
  }
  
  // ==================== Forgot Password ====================
  
  /// POST /api/auth/forgot-password - Request password reset
  Future<AuthResponse> forgotPassword({required String email}) async {
    try {
      final url = Uri.parse('$baseUrl/api/auth/forgot-password');
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode({
          'email': email,
        }),
      ).timeout(
        Duration(seconds: AppConstants.apiTimeout),
      );
      
      final jsonData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return AuthResponse(
          success: true,
          message: jsonData['message'] ?? 'Password reset email sent',
        );
      } else {
        return AuthResponse(
          success: false,
          message: jsonData['message'] ?? 'Failed to send reset email',
        );
      }
    } catch (e) {
      return AuthResponse(
        success: false,
        message: 'Error sending reset email: $e',
      );
    }
  }
  
  // ==================== Sign Out ====================
  
  /// Sign out user - Clear local data
  Future<void> signOut() async {
    try {
      await StorageService.instance.clearUserData();
    } catch (e) {
      throw Exception('Error during sign out: $e');
    }
  }
  
  // ==================== Get Current User ====================
  
  /// Get currently logged in user from local storage
  Future<User?> getCurrentUser() async {
    try {
      return await StorageService.instance.getCurrentUser();
    } catch (e) {
      return null;
    }
  }
  
  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    try {
      final user = await getCurrentUser();
      return user != null;
    } catch (e) {
      return false;
    }
  }
  
  // ==================== Private Helper Methods ====================
  
  /// Save user data and token to local storage
  Future<void> _saveUserData(User user, String? token) async {
    await StorageService.instance.saveCurrentUser(user);
    if (token != null) {
      await StorageService.instance.saveAuthToken(token);
    }
  }
}
