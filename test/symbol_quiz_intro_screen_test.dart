import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ganithamithura/screens/symbol/quiz/symbol_quiz_intro_screen.dart';

void main() {
  testWidgets('SymbolQuizIntroScreen renders correctly', (WidgetTester tester) async {
    // Build the intro screen
    await tester.pumpWidget(const GetMaterialApp(
      home: SymbolQuizIntroScreen(),
    ));

    // Pump a frame to let everything settle
    await tester.pump();

    // Verify title
    expect(find.text('Symbol Hunter'), findsOneWidget);
    
    // Verify subtitle
    expect(find.text("Let's Learn Symbols Together !"), findsOneWidget);
    
    // Verify Page 1
    expect(find.text('Short and Friendly'), findsOneWidget);
    expect(find.text('NEXT'), findsOneWidget);

    // Tap Next -> Page 2
    await tester.tap(find.text('NEXT'));
    await tester.pump(); // Register tap
    await tester.pump(const Duration(milliseconds: 600)); // Wait for page transition

    // Verify Page 2
    expect(find.text('A path made just for You'), findsOneWidget);
    
    // Tap Next -> Page 3
    await tester.tap(find.text('NEXT'));
    await tester.pump(); // Register tap
    await tester.pump(const Duration(milliseconds: 600)); // Wait for page transition

    // Verify Page 3
    expect(find.text('Safe and Simple'), findsOneWidget);
    // Button text wraps, so finding exact match might be tricky. Checking for partial or specific part
    expect(find.textContaining('Start !'), findsOneWidget);
  });
}
