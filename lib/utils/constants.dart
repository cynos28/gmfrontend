/// Constants for the Ganithamithura Learning App - Phase 1
library;

class AppConstants {
  // API Configuration - Using WiFi IP (no ADB needed)
  // Ensure phone and Mac are on same WiFi network
  static const String baseUrl = 'http://10.169.0.71:8000';
  
  
  // Activity Types
  static const String activityTypeTrace = 'trace';
  static const String activityTypeRead = 'read';
  static const String activityTypeSay = 'say';
  static const String activityTypeObjectDetection = 'object_detection';
  static const String activityTypeVideo = 'video';
  
  // Scoring Thresholds
  static const double traceSuccessThreshold = 0.70; // 70% coverage
  static const double speechRecognitionThreshold = 0.80; // 80% similarity
  
  // Test Configuration
  static const int beginnerTestActivityCount = 5;
  static const int activitiesPerNumber = 5;
  static const int testBucketSize = 6; // Show 5 out of 6
  
  // Level Configuration
  static const int totalLevels = 5;
  static const int level1MinNumber = 1;
  static const int level1MaxNumber = 10;
  
  // TODO: Phase 2 - Define levels 2-5 number ranges
  // static const int level2MinNumber = 11;
  // static const int level2MaxNumber = 20;
  
  // Timeouts
  static const int videoLoadTimeout = 30; // seconds
  static const int apiTimeout = 10; // seconds
  
  // UI Constants
  static const double buttonBorderRadius = 16.0;
  static const double cardElevation = 4.0;
  static const double standardPadding = 16.0;
  
  // Animation Durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 300);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 600);
  static const Duration longAnimationDuration = Duration(milliseconds: 1000);
}

class StorageKeys {
  static const String completedActivities = 'completed_activities';
  static const String testScores = 'test_scores';
  static const String currentLevel = 'current_level';
  static const String progressData = 'progress_data';
  static const String lastActivityDate = 'last_activity_date';
}

class NumberWords {
  static const Map<int, String> numberToWord = {
    1: 'one',
    2: 'two',
    3: 'three',
    4: 'four',
    5: 'five',
    6: 'six',
    7: 'seven',
    8: 'eight',
    9: 'nine',
    10: 'ten',
    // TODO: Phase 2 - Add numbers 11-100
  };
  
  static String getWord(int number) => numberToWord[number] ?? '';
  
  static int? getNumber(String word) {
    return numberToWord.entries
        .firstWhere(
          (entry) => entry.value.toLowerCase() == word.toLowerCase(),
          orElse: () => const MapEntry(0, ''),
        )
        .key;
  }
}

class AppColors {
  // Module Colors - Bright and Vibrant for Kids aged 6-10
  // Using bright, saturated colors that kids love!
  static const int measurementColor = 0xFFFFF3E0; // Bright orange background
  static const int measurementBorder = 0xFFFFE0B2; // Bright orange border
  static const int measurementIcon = 0xFFFF9500; // Bright orange icon
  static const int numberColor = 0xFFE8F4FF; // Bright blue background
  static const int numberBorder = 0xFFB3D7FF; // Bright blue border
  static const int numberIcon = 0xFF4285F4; // Bright blue icon
  static const int shapeColor = 0xFFE6F9EC; // Bright green background
  static const int shapeBorder = 0xFFB2F5D6; // Bright green border
  static const int shapeIcon = 0xFF34C759; // Bright green icon
  static const int symbolColor = 0xFFFCE4EC; // Bright pink background
  static const int symbolBorder = 0xFFF8BBD0; // Bright pink border
  static const int symbolIcon = 0xFFFF4081; // Bright pink icon
  
  // Text Colors
  static const int textBlack = 0xFF273444;
  static const int subText1 = 0xFF334156;
  static const int subText2 = 0xFF49596E;
  
  // Background Colors
  static const int white = 0xFFFFFFFF;
  static const int backgroundColor = 0xFFFAFBFF; // Very light blue-purple tint
  static const int splashBackground = 0xFFF6F7FF; // Light purple-blue for splash screen
  
  // Activity Card Colors - Updated for Kids-Friendly UI
  static const int timeCardBg = 0xFFE8EEFF; // Soft purple-blue
  static const int completedCardBg = 0xFFE8F8F0; // Soft green
  static const int progressBadgeBg = 0xFFFFEDE4; // Soft orange
  static const int progressBadgeText = 0xFFFF8C52; // Orange text
  
  // Navigation & UI
  static const int navActiveColor = 0xFF6B7FFF; // Primary accent
  static const int navInactiveColor = 0x7F49596E; // rgba(73,89,110,0.5)
  static const int dailyTipBg = 0xFF6B7FFF; // Primary accent
  
  // Border Colors
  static const int borderLight = 0xFFE8EEFF; // Very light purple-blue
  
  // Status Colors - Kids-Friendly
  static const int successColor = 0xFF2EB872; // Soft green
  static const int errorColor = 0xFFFF6B6B; // Soft red
  static const int warningColor = 0xFFFFC107; // Yellow
  static const int infoColor = 0xFF6B7FFF; // Primary accent
  
  // Star/Achievement Colors
  static const int starGold = 0xFFFFD700; // Gold
  static const int starBackground = 0xFFFFF9E6; // Very light yellow
  
  // Legacy colors for backward compatibility
  static const int primaryColor = 0xFF6B7FFF; // Primary accent
  static const int disabledColor = 0xFFBDBDBD; // Gray for disabled state
}
