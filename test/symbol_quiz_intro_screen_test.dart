import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ganithamithura/screens/symbol/quiz/symbol_quiz_intro_screen.dart';

import 'package:flutter/services.dart';

void main() {
  setUpAll(() {
    const MethodChannel channel = MethodChannel('flutter_tts');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return null;
    });
  });

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
    // Tap Start Button
    await tester.tap(find.textContaining('Start !'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // Wait for nav

    // Verify Options Screen
    expect(find.text('Practice Questions'), findsOneWidget);
    
    // Tap Practice Questions -> Level Screen
    await tester.tap(find.text('Practice Questions'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Verify Level Selection Screen
    expect(find.text('Level 01'), findsOneWidget);

    // Tap Level 01 -> Learning Screen
    await tester.tap(find.text('Level 01'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); 

    // Verify Learning Screen
    expect(find.text('Symbol Learning'), findsOneWidget); // AppBar title
    expect(find.text('Connecting to Tutor...'), findsOneWidget); // Initial state
  });
}
