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
    expect(find.text('Symbol World'), findsOneWidget);
    
    // Verify subheading
    expect(find.text('Let\'s Play with Symbols!'), findsOneWidget);

    // Verify buttons are present
    expect(find.text('Symbol Stories'), findsOneWidget);
    expect(find.text('Symbol Quiz'), findsOneWidget);
    
    // Verify icons
    expect(find.byIcon(Icons.menu_book), findsOneWidget);
    expect(find.byIcon(Icons.psychology), findsOneWidget);
  });
}
