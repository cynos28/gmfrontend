import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ganithamithura/screens/symbol/gaming/level_selection_screen.dart';
import 'package:ganithamithura/screens/symbol/gaming/widgets/level_island_widget.dart';

void main() {
  setUp(() {
    Get.testMode = true;
  });

  testWidgets('LevelSelectionScreen renders correctly', (WidgetTester tester) async {
    // Provide a large screen size to avoid overflow in scrollable areas if needed, 
    // though SingleChildScrollView handles it.
    tester.view.physicalSize = const Size(1080, 4000); // Increased height to fit all items
    tester.view.devicePixelRatio = 3.0;

    await tester.pumpWidget(const GetMaterialApp(home: LevelSelectionScreen()));
    // Pump for animations
    await tester.pump(const Duration(seconds: 2));

    // Verify Header Elements (Brown Back button, Score Pill)
    expect(find.byIcon(Icons.home_outlined), findsOneWidget); // Changed to outlined
    expect(find.text('2755'), findsOneWidget); // Mock score

    // Verify Banner Image
    // Verify Banner Content
    expect(find.text('Unlock your level'), findsOneWidget);
    expect(find.text('Play'), findsOneWidget);
    
    // Verify Banner Image exists
    expect(find.byType(Image), findsWidgets); // Should find background and banner starburst

    // Verify Level Islands
    // We expect 7 LevelIslandWidgets again
    expect(find.byType(LevelIslandWidget), findsNWidgets(7));
    
    // Verify Level Numbers (1, 2, 3) - Enabled
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);

    // Verify Locked State (Levels 4-7 are locked)
    // Locked levels should show LOCK ICON instead of numbers now
    expect(find.text('4'), findsNothing);
    expect(find.text('5'), findsNothing);
    expect(find.text('6'), findsNothing);
    expect(find.text('7'), findsNothing);

    // Should find 4 lock icons (for levels 4, 5, 6, 7)
    expect(find.byIcon(Icons.lock), findsNWidgets(4));
    
    // Level 1 is unlocked
    final level1Finder = find.widgetWithText(LevelIslandWidget, '1');
    final level1Widget = tester.widget<LevelIslandWidget>(level1Finder);
    expect(level1Widget.isLocked, isFalse);
    
    // Clean up
    addTearDown(tester.view.resetPhysicalSize);
  });
}
