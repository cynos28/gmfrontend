import 'package:ganithamithura/utils/constants.dart';

class AppConfig {
  static String get baseUrl => AppConstants.symbolBaseUrl;
  
  static String get wsUrl {
    // Replace http/https with ws/wss based on the public URL
    if (AppConstants.symbolBaseUrl.startsWith("https://")) {
      return AppConstants.symbolBaseUrl.replaceFirst("https://", "wss://");
    } else {
      return AppConstants.symbolBaseUrl.replaceFirst("http://", "ws://");
    }
  }
}
