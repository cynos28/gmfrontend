import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Helper utilities for safe UI operations
class UIHelpers {
  /// Safely show a snackbar with a delay to ensure overlay is available
  static Future<void> showSafeSnackbar({
    required String title,
    required String message,
    required Color backgroundColor,
    Color colorText = Colors.white,
    Duration duration = const Duration(seconds: 2),
    int delayMilliseconds = 100,
  }) async {
    await Future.delayed(Duration(milliseconds: delayMilliseconds));
    
    // Check if Get context is available
    if (Get.context != null) {
      Get.snackbar(
        title,
        message,
        backgroundColor: backgroundColor,
        colorText: colorText,
        duration: duration,
      );
    }
  }

  /// Safely show a dialog with a delay to ensure overlay is available
  static Future<void> showSafeDialog({
    required Widget dialog,
    bool barrierDismissible = true,
    int delayMilliseconds = 100,
  }) async {
    await Future.delayed(Duration(milliseconds: delayMilliseconds));
    
    // Check if Get context is available
    if (Get.context != null) {
      Get.dialog(
        dialog,
        barrierDismissible: barrierDismissible,
      );
    }
  }

  /// Parse error messages and return user-friendly text
  static String getErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    // Network errors
    if (errorString.contains('socketexception') || 
        errorString.contains('network error') ||
        errorString.contains('no internet')) {
      return 'No internet connection. Please check your network settings.';
    }
    
    // Timeout errors
    if (errorString.contains('timeout') || 
        errorString.contains('timed out')) {
      return 'Request timed out. Please check your connection and try again.';
    }
    
    // Server errors
    if (errorString.contains('500') || 
        errorString.contains('internal server error')) {
      return 'Server error. Please try again later.';
    }
    
    if (errorString.contains('503') || 
        errorString.contains('service unavailable')) {
      return 'Service temporarily unavailable. Please try again later.';
    }
    
    // Client errors
    if (errorString.contains('404') || 
        errorString.contains('not found')) {
      return 'Resource not found. Please contact support.';
    }
    
    if (errorString.contains('400') || 
        errorString.contains('bad request')) {
      return 'Invalid request. Please try again.';
    }
    
    if (errorString.contains('401') || 
        errorString.contains('unauthorized')) {
      return 'Authentication required. Please log in again.';
    }
    
    if (errorString.contains('403') || 
        errorString.contains('forbidden')) {
      return 'Access denied. You do not have permission.';
    }
    
    // Data errors
    if (errorString.contains('formatexception') || 
        errorString.contains('json') ||
        errorString.contains('parse')) {
      return 'Invalid data received. Please try again.';
    }
    
    // Default
    return 'An unexpected error occurred. Please try again.';
  }
}
