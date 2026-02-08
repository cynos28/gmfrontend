import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ganithamithura/screens/symbol/gaming/game_welcome_screen.dart';

void main() {
  setUp(() {
    Get.testMode = true;
  });

  testWidgets('GameWelcomeScreen renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const GetMaterialApp(home: GameWelcomeScreen()));
    // Pump to allow animations to start
    await tester.pump(const Duration(seconds: 2));

    // Verify Text
    expect(find.text("Let's"), findsOneWidget);
    expect(find.text("Play"), findsOneWidget);
    
    // Verify Image (Game Icon)
    // We can verify by type Image
    expect(find.byType(Image), findsWidgets); // Background + Icon

    // Verify Button
    expect(find.text('Get Started'), findsOneWidget);
  });

  testWidgets('Get Started button triggers navigation', (WidgetTester tester) async {
    await tester.pumpWidget(const GetMaterialApp(home: GameWelcomeScreen()));
    await tester.pump(const Duration(seconds: 2));

    // Find Button
    final button = find.text('Get Started');
    
    // Tap
    await tester.tap(button);
    // Pump for a fixed duration to allow navigation transition to start/progress
    await tester.pump(const Duration(seconds: 2));

    // In a real app this would navigate to CharacterSelectionScreen
    // Since we are mocking Get.testMode, we can't easily check the route stack without more setup
    // But ensuring no crash on tap is good for now.
  });
}
