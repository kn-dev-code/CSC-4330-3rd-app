import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:planning_app/main.dart';

void main() {
  testWidgets('Homepage shows team planning content', (WidgetTester tester) async {
    await tester.pumpWidget(const PlanningApp());

    expect(find.text('Team Plan'), findsOneWidget);
    expect(find.textContaining('team'), findsWidgets);
    expect(find.text('Coming up'), findsOneWidget);
    expect(find.text('Sprint planning'), findsOneWidget);
    expect(find.text('Team'), findsOneWidget);
  });

  testWidgets('Can add a new plan', (WidgetTester tester) async {
    await tester.pumpWidget(const PlanningApp());

    // Tap on FloatingActionButton or Add Plan button
    await tester.tap(find.text('Add Plan'));
    await tester.pumpAndSettle();

    // Verify dialog appears
    expect(find.text('Add New Plan'), findsOneWidget);

    // Enter title
    await tester.enterText(
      find.byType(TextFormField).first,
      'Backend Refactoring',
    );

    // Tap Add Plan button in dialog
    await tester.tap(find.widgetWithText(FilledButton, 'Add Plan'));
    await tester.pumpAndSettle();

    // Verify new plan appears on list
    expect(find.text('Backend Refactoring'), findsOneWidget);
    expect(find.text('Plan "Backend Refactoring" added'), findsOneWidget);
  });

  testWidgets('Can remove a plan', (WidgetTester tester) async {
    await tester.pumpWidget(const PlanningApp());

    expect(find.text('Sprint planning'), findsOneWidget);

    // Tap remove button on Sprint planning item
    final removeButtons = find.byTooltip('Remove plan');
    await tester.tap(removeButtons.first);
    await tester.pumpAndSettle();

    // Verify item is removed and SnackBar is displayed
    expect(find.text('Sprint planning'), findsNothing);
    expect(find.text('Plan "Sprint planning" removed'), findsOneWidget);

    // Tap Undo
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    // Verify item is restored
    expect(find.text('Sprint planning'), findsOneWidget);
  });
}
