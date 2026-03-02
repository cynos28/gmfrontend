import 'package:ganithamithura/services/api/io_config.dart';

class AppConfig {
  // Uses centralized IP from IoConfig
  static String get serverIp => IoConfig.symIp;
  static int get serverPort => IoConfig.symbolPort;
  
  static String get baseUrl => "http://$serverIp:$serverPort";
  static String get wsUrl => "ws://$serverIp:$serverPort";
}
