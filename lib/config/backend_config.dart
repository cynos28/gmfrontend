/// Backend Configuration
/// Update this file when your WiFi network changes
/// 
/// To find your Mac's IP address:
/// 1. Open Terminal
/// 2. Run: ifconfig | grep "inet " | grep -v 127.0.0.1
/// 3. Copy the IP address (e.g., 172.21.246.68)
/// 4. Update CURRENT_WIFI_IP below

class BackendConfig {
  /// Update this when your WiFi network changes
  static const String CURRENT_WIFI_IP = '172.21.246.68';
  
  /// All possible backend URLs (tried in order)
  static List<String> get backendUrls => [
    'http://localhost:8000',           // ADB reverse (PRIMARY - fastest)
    'http://10.0.2.2:8000',            // Android Emulator
    'http://$CURRENT_WIFI_IP:8000',    // WiFi (update IP above when network changes)
    'http://192.168.1.100:8000',       // Common router IP pattern
    'http://10.0.0.100:8000',          // Alternative private IP range
  ];
  
  /// Instructions for first-time setup
  static const String setupInstructions = '''
  🔧 Setup Instructions:
  
  Option 1: ADB Reverse (Recommended - No IP needed!)
  ────────────────────────────────────────────────
  1. Connect device via USB
  2. Run: adb reverse tcp:8000 tcp:8000
  3. App will connect to localhost:8000
  
  Option 2: WiFi Connection (When ADB not available)
  ────────────────────────────────────────────────
  1. Ensure device and Mac are on same WiFi network
  2. Find Mac IP: ifconfig | grep "inet " | grep -v 127.0.0.1
  3. Update CURRENT_WIFI_IP in lib/config/backend_config.dart
  4. Restart the app
  
  ⚠️ If connection fails after network change:
  Simply update CURRENT_WIFI_IP and hot reload!
  ''';
}
