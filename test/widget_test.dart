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
}
