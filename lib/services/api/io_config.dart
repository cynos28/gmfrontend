/// Centralized network configuration
/// Change the IP address here and it will be used across all services.
/// 
/// To find your Mac's IP:
///   ifconfig | grep "inet " | grep -v 127.0.0.1
///
/// Make sure your phone and Mac are on the same WiFi network.
class IoConfig {
  // ============================================
  // CHANGE THIS IP WHEN YOUR NETWORK CHANGES
  // ============================================
  static const String symIp = '192.168.8.143';

  // Port configuration
  static const int authPort = 8001;
  static const int symbolPort = 8000;

  // Derived base URLs
  static String get authBaseUrl => 'http://$symIp:$authPort';
  static String get symbolBaseUrl => 'http://$symIp:$symbolPort';

  // WebSocket URLs
  static String get wsUrl => 'ws://$symIp:$symbolPort';
}
