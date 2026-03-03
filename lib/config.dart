class AppConfig {
  // Replace with your computer's local IP address
  static const String serverIp = "192.168.8.143"; 
  static const int serverPort = 8000;
  
  static String get baseUrl => "http://$serverIp:$serverPort";
  static String get wsUrl => "ws://$serverIp:$serverPort";
}
