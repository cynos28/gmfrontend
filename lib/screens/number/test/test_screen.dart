import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Progress;
import 'package:ganithamithura/screens/number/test/progress_test_screen.dart';

/// TestScreen - DEPRECATED: Use ProgressTestScreen instead.
/// This screen now just redirects to the ProgressTestScreen hub.
class TestScreen extends StatelessWidget {
  final String testType;

  const TestScreen({super.key, required this.testType});

  @override
  Widget build(BuildContext context) {
    // Redirect to the new ProgressTestScreen hub
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.off(() => const ProgressTestScreen());
    });

    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
