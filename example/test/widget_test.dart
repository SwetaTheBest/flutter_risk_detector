import 'package:flutter_test/flutter_test.dart';

import 'package:example/main.dart';

void main() {
  testWidgets('shows the risk scenario launcher', (WidgetTester tester) async {
    await tester.pumpWidget(const RiskDetectorExampleApp());

    expect(find.textContaining('Risk Detector'), findsOneWidget);
    expect(find.textContaining('Overflow Detection'), findsOneWidget);
    expect(find.textContaining('Rebuild Storm + Jank'), findsOneWidget);
    expect(find.textContaining('Async Risks'), findsOneWidget);
    expect(find.textContaining('Memory Leaks'), findsOneWidget);
    expect(find.textContaining('Lint Issues'), findsOneWidget);
  });
}
