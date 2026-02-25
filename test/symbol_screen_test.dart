import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ganithamithura/screens/symbol/symbol_home_screen.dart';
import 'package:ganithamithura/utils/constants.dart';

void main() {
  testWidgets('SymbolHomeScreen renders correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const GetMaterialApp(
      home: SymbolHomeScreen(),
    ));

    // Allow animations to settle (optional, or just pump a frame)
    await tester.pump(const Duration(milliseconds: 500));

    // Verify that the title is present
    // Verify that the title is present
    expect(find.text('Hello, Marion'), findsOneWidget);
    
    // Verify subheading
    expect(find.text('Progress 10%'), findsOneWidget);

    // Verify that the action cards/categories are present
    expect(find.text('Lessons'), findsWidgets);
    expect(find.text('Games'), findsWidgets);
    
    // Verify icons on Home Screen
    expect(find.byIcon(Icons.menu_book_rounded), findsWidgets);
    expect(find.byIcon(Icons.games_rounded), findsWidgets);

    // Tap on 'Lessons' card and verify navigation
    // 'Lessons' appears in Categories and the Big Card. The Card is likely the last one found or we search by specific text hierarchy.
    // simpler: The big card has subtitle "Fun learning lessons..."
    await tester.tap(find.text('Lessons').last); 
    await tester.pump(); // Register tap
    await tester.pump(const Duration(seconds: 1)); // Wait for navigation

    // Verify we are on the Intro Screen
    expect(find.text('Symbol Hunter'), findsOneWidget);
    expect(find.text('Only 3 - 4 minutes.'), findsOneWidget);
    expect(find.text('NEXT'), findsOneWidget);
  });
}
