/// Constants for the Ganithamithura Learning App - Phase 1
library;

import 'dart:convert';
import 'package:http/http.dart' as http;

class AppConstants {
  // API Configuration
  static String authBaseUrl = 'http://192.168.8.167:8001';
  static String symbolBaseUrl = 'http://192.168.8.167:8000';
  static String measurementBaseUrl = 'http://192.168.8.167:8002'; // New API
  static String shapeBaseUrl = 'http://192.168.8.167:8003/shapes-patterns';
  static String numBaseUrl = 'http://192.168.8.167:8004';

  static String get baseUrl => authBaseUrl;
  
  /// Optional callback invoked whenever URLs are successfully refreshed.
  /// Services can register here to invalidate their internal caches.
  static void Function()? _onUrlsRefreshed;
  static void registerUrlRefreshListener(void Function() listener) {
    _onUrlsRefreshed = listener;
  }
  
  static const String _gistApiUrl = "https://api.github.com/gists/a03d59a6c3a4e84f0688591151f6fd30";
  
  static Future<void> loadDynamicUrls() async {
    int retryCount = 0;
    const int maxRetries = 3;
    
    while (retryCount < maxRetries) {
      try {
        print("📡 Attempting to fetch backend URLs (Attempt ${retryCount + 1})...");
        
        // Use the Gist API directly instead of the raw file to avoid GitHub's CDN caching
        final response = await http.get(
          Uri.parse("$_gistApiUrl?t=${DateTime.now().millisecondsSinceEpoch}"),
          headers: {
            'Cache-Control': 'no-cache, no-store, must-revalidate',
            'Pragma': 'no-cache',
            'Expires': '0',
            'Accept': 'application/vnd.github.v3+json',
          },
        ).timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          final gistData = json.decode(response.body);
          final fileData = gistData['files']['ganithamithura_urls.json'];
          
          if (fileData != null && fileData['content'] != null) {
            final data = json.decode(fileData['content']);
            
            symbolBaseUrl = data['symbol_api'] ?? symbolBaseUrl;
            authBaseUrl = data['auth_api'] ?? authBaseUrl;
            measurementBaseUrl = data['measurement_api'] ?? measurementBaseUrl;
            numBaseUrl = data['number_api'] ?? numBaseUrl;
            
            if (data['shape_api'] != null) {
              shapeBaseUrl = "${data['shape_api']}/shapes-patterns";
            }
            
            // Notify any registered listeners that URLs changed
            _onUrlsRefreshed?.call();
            
            print("✅ Backend URLs Successfully Loaded!");
            print("   Auth:        $authBaseUrl");
            print("   Symbol:      $symbolBaseUrl");
            print("   Measurement: $measurementBaseUrl");
            return; // Exit on success
          }
        }
        
        print("⚠️ Failed to load from Gist (Status: ${response.statusCode})");
      } catch (e) {
        print("⚠️ Gist fetch error: $e");
      }
      
      retryCount++;
      if (retryCount < maxRetries) {
        print("🔄 Retrying in ${retryCount * 2} seconds...");
        await Future.delayed(Duration(seconds: retryCount * 2));
      }
    }
    
    print("❌ Failed to fetch backend URLs after $maxRetries attempts. Using fallback addresses.");
    print("   Fallback Auth: $authBaseUrl");
  }

  // Activity Types
  static const String activityTypeTrace = 'trace';
  static const String activityTypeRead = 'read';
  static const String activityTypeSay = 'say';
  static const String activityTypeObjectDetection = 'object_detection';
  static const String activityTypeVideo = 'video';

  // Scoring Thresholds
  static const double traceSuccessThreshold = 0.30; // 70% coverage
  static const double speechRecognitionThreshold = 0.80; // 80% similarity

  // Test Configuration
  static const int beginnerTestActivityCount = 5;
  static const int activitiesPerNumber = 5;
  static const int testBucketSize = 6; // Show 5 out of 6

  // Level Configuration
  static const int totalLevels = 5;
  static const int level1MinNumber = 1;
  static const int level1MaxNumber = 10;

  // Static level configurations for all 5 levels
  static final Map<int, LevelConfig> levelConfigs = {
    1: LevelConfig(
      level: 1,
      minNumber: 1,
      maxNumber: 10,
      hasTrace: true,
      hasShow: true,
      hasVideo: true,
    ),
    2: LevelConfig(
      level: 2,
      minNumber: 11,
      maxNumber: 20,
      hasTrace: true,
      hasShow: true,
      hasVideo: true,
    ),
    3: LevelConfig(
      level: 3,
      minNumber: 21,
      maxNumber: 50,
      hasTrace: false,
      hasShow: true,
      hasVideo: false,
    ),
    4: LevelConfig(
      level: 4,
      minNumber: 51,
      maxNumber: 100,
      hasTrace: false,
      hasShow: true,
      hasVideo: false,
    ),
    5: LevelConfig(
      level: 5,
      minNumber: 101,
      maxNumber: 1000,
      hasTrace: false,
      hasShow: false,
      hasVideo: false,
    ),
  };

  /// Get config for a specific level, returns level 1 config if not found
  static LevelConfig getLevelConfig(int level) {
    return levelConfigs[level] ?? levelConfigs[1]!;
  }

  // Timeouts
  static const int videoLoadTimeout = 30; // seconds
  // Common headers for API requests
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'ngrok-skip-browser-warning': 'true',
  };

  static const int apiTimeout = 30; // seconds

  // UI Constants
  static const double buttonBorderRadius = 16.0;
  static const double cardElevation = 4.0;
  static const double standardPadding = 16.0;

  // Animation Durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 300);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 600);
  static const Duration longAnimationDuration = Duration(milliseconds: 1000);
}

/// Level configuration defining number ranges and activity availability
class LevelConfig {
  final int level;
  final int minNumber;
  final int maxNumber;
  final bool hasTrace; // Whether trace activity is available
  final bool hasShow; // Whether show (object detection) activity is available
  final bool hasVideo; // Whether video lessons are available

  const LevelConfig({
    required this.level,
    required this.minNumber,
    required this.maxNumber,
    this.hasTrace = true,
    this.hasShow = true,
    this.hasVideo = true,
  });

  /// Total numbers in this level
  int get numberCount => maxNumber - minNumber + 1;

  /// Get list of activities available for this level
  List<String> get availableActivities {
    final activities = <String>[];
    if (hasVideo) activities.add(AppConstants.activityTypeVideo);
    if (hasTrace) activities.add(AppConstants.activityTypeTrace);
    if (hasShow) activities.add(AppConstants.activityTypeObjectDetection);
    activities.add(AppConstants.activityTypeSay);
    activities.add(AppConstants.activityTypeRead);
    return activities;
  }

  /// Check if a number is in this level's range
  bool containsNumber(int number) => number >= minNumber && number <= maxNumber;
}

class StorageKeys {
  static const String completedActivities = 'completed_activities';
  static const String testScores = 'test_scores';
  static const String currentLevel = 'current_level';
  static const String progressData = 'progress_data';
  static const String lastActivityDate = 'last_activity_date';
  static const String hasSeenOnboarding = 'has_seen_onboarding';
  static const String currentUser = 'current_user';
  static const String authToken = 'auth_token';

  // Learning session tracking
  static const String currentLearningLevel = 'current_learning_level';
  static const String currentLearningNumber = 'current_learning_number';
  static const String currentActivityType = 'current_activity_type';
  static const String lastCompletedActivityType =
      'last_completed_activity_type';
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
    11: 'eleven',
    12: 'twelve',
    13: 'thirteen',
    14: 'fourteen',
    15: 'fifteen',
    16: 'sixteen',
    17: 'seventeen',
    18: 'eighteen',
    19: 'nineteen',
    20: 'twenty',
    21: 'twenty-one',
    22: 'twenty-two',
    23: 'twenty-three',
    24: 'twenty-four',
    25: 'twenty-five',
    26: 'twenty-six',
    27: 'twenty-seven',
    28: 'twenty-eight',
    29: 'twenty-nine',
    30: 'thirty',
    31: 'thirty-one',
    32: 'thirty-two',
    33: 'thirty-three',
    34: 'thirty-four',
    35: 'thirty-five',
    36: 'thirty-six',
    37: 'thirty-seven',
    38: 'thirty-eight',
    39: 'thirty-nine',
    40: 'forty',
    41: 'forty-one',
    42: 'forty-two',
    43: 'forty-three',
    44: 'forty-four',
    45: 'forty-five',
    46: 'forty-six',
    47: 'forty-seven',
    48: 'forty-eight',
    49: 'forty-nine',
    50: 'fifty',
    51: 'fifty-one',
    52: 'fifty-two',
    53: 'fifty-three',
    54: 'fifty-four',
    55: 'fifty-five',
    56: 'fifty-six',
    57: 'fifty-seven',
    58: 'fifty-eight',
    59: 'fifty-nine',
    60: 'sixty',
    61: 'sixty-one',
    62: 'sixty-two',
    63: 'sixty-three',
    64: 'sixty-four',
    65: 'sixty-five',
    66: 'sixty-six',
    67: 'sixty-seven',
    68: 'sixty-eight',
    69: 'sixty-nine',
    70: 'seventy',
    71: 'seventy-one',
    72: 'seventy-two',
    73: 'seventy-three',
    74: 'seventy-four',
    75: 'seventy-five',
    76: 'seventy-six',
    77: 'seventy-seven',
    78: 'seventy-eight',
    79: 'seventy-nine',
    80: 'eighty',
    81: 'eighty-one',
    82: 'eighty-two',
    83: 'eighty-three',
    84: 'eighty-four',
    85: 'eighty-five',
    86: 'eighty-six',
    87: 'eighty-seven',
    88: 'eighty-eight',
    89: 'eighty-nine',
    90: 'ninety',
    91: 'ninety-one',
    92: 'ninety-two',
    93: 'ninety-three',
    94: 'ninety-four',
    95: 'ninety-five',
    96: 'ninety-six',
    97: 'ninety-seven',
    98: 'ninety-eight',
    99: 'ninety-nine',
    100: 'one hundred',
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
  static const int numberColor = 0xFFB3D7FF; // Bright blue background
  static const int numberBorder = 0xFFE8F4FF; // Bright blue border
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
  static const int splashBackground =
      0xFFF6F7FF; // Light purple-blue for splash screen

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
