import 'package:flutter/gestures.dart';
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

    // Scroll down in CustomScrollView to view the new plan
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
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

  testWidgets('Clicking tasks chip opens checklist with animations', (WidgetTester tester) async {
    await tester.pumpWidget(const PlanningApp());

    // Hovering alone does NOT toggle checklist
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);

    await gesture.moveTo(tester.getCenter(find.text('0/3 tasks')));
    await tester.pumpAndSettle();

    // Tapping the "0/3 tasks" button chip opens the checklist
    await tester.tap(find.text('0/3 tasks'));
    await tester.pumpAndSettle();

    expect(find.text('Roadmap deck'), findsOneWidget);
    expect(find.text('Sprint backlog'), findsOneWidget);
  });

  testWidgets('Checking off all tasks finishes the plan', (WidgetTester tester) async {
    await tester.pumpWidget(const PlanningApp());

    // Tap on tasks chip on Sprint planning (0/3 tasks) to open checklist
    await tester.tap(find.text('0/3 tasks'));
    await tester.pumpAndSettle();

    // Ensure visible & check off tasks
    await tester.ensureVisible(find.text('Roadmap deck'));
    await tester.tap(find.text('Roadmap deck'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Sprint backlog'));
    await tester.tap(find.text('Sprint backlog'));
    await tester.pumpAndSettle();

    expect(find.text('Finished'), findsNothing);

    await tester.ensureVisible(find.text('Team capacity sheet'));
    await tester.tap(find.text('Team capacity sheet'));
    await tester.pumpAndSettle();

    // Plan is finished!
    expect(find.text('Finished'), findsOneWidget);
    expect(find.text('🎉 Plan "Sprint planning" is finished!'), findsOneWidget);
  });

  testWidgets('Can drag and reorder plans', (WidgetTester tester) async {
    await tester.pumpWidget(const PlanningApp());

    final dragHandles = find.byIcon(Icons.drag_indicator_rounded);
    expect(dragHandles, findsNWidgets(3));

    // Drag the first drag handle down
    final firstHandle = dragHandles.first;
    final secondHandle = dragHandles.at(1);

    final gesture = await tester.startGesture(tester.getCenter(firstHandle));
    await tester.pump(const Duration(milliseconds: 300));
    await gesture.moveTo(tester.getCenter(secondHandle) + const Offset(0, 50));
    await tester.pumpAndSettle();
    await gesture.up();
    await tester.pumpAndSettle();

    // Verify plans are still rendered properly
    expect(find.text('Sprint planning'), findsOneWidget);
    expect(find.text('Design review'), findsOneWidget);
  });
}
