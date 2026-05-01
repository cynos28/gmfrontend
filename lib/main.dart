import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ganithamithura/utils/constants.dart';
import 'package:ganithamithura/services/local_storage/storage_service.dart';
import 'package:ganithamithura/services/api/unit_api_service.dart';
import 'package:ganithamithura/screens/home/home_screen.dart';
import 'package:ganithamithura/screens/symbol/symbol_home_screen.dart';
import 'package:ganithamithura/screens/splash/splash_screen.dart';
import 'package:ganithamithura/screens/measurements/ar_challenges/ar_measurement_screen.dart';
import 'package:ganithamithura/screens/measurements/ar_challenges/ar_questions_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
  // Initialize storage service
  StorageService.instance.init();

  // Register URL refresh listener — any service caches are cleared on each Gist pull
  AppConstants.registerUrlRefreshListener(UnitApiService.invalidateCache);

  // Load dynamic server URLs from GitHub Gist on startup
  await AppConstants.loadDynamicUrls();
  
  runApp(const GanithamithuraApp());
}

class GanithamithuraApp extends StatefulWidget {
  const GanithamithuraApp({super.key});

  @override
  State<GanithamithuraApp> createState() => _GanithamithuraAppState();
}

class _GanithamithuraAppState extends State<GanithamithuraApp> with WidgetsBindingObserver {
  Timer? _urlRefreshTimer;
  
  @override
  void initState() {
    super.initState();
    // Observe app lifecycle changes
    WidgetsBinding.instance.addObserver(this);
    
    // URL refresh timer disabled — using local URLs
    // _urlRefreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
    //   AppConstants.loadDynamicUrls();
    // });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _urlRefreshTimer?.cancel();
    super.dispose();
  }

  /// Called whenever the app lifecycle state changes.
  /// Refresh backend URLs when the app comes back to the foreground.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // URL refresh on resume disabled — using local URLs
     if (state == AppLifecycleState.resumed) {
       AppConstants.loadDynamicUrls();
     }
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Ganitha Mithura',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Color(AppColors.infoColor),
        scaffoldBackgroundColor: Color(AppColors.backgroundColor),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(AppColors.infoColor),
        ),
        textTheme: GoogleFonts.poppinsTextTheme(),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      getPages: [
        GetPage(
          name: '/home',
          page: () => const HomeScreen(),
        ),
        GetPage(
          name: '/symbol-home',
          page: () => const SymbolHomeScreen(),
        ),
        GetPage(
          name: '/ar-measurement',
          page: () => const ARMeasurementScreen(),
        ),
        GetPage(
          name: '/ar-questions',
          page: () => const ARQuestionsScreen(),
        ),
      ],
    );
  }
}
