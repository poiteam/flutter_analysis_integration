import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_analysis_integration/app/app.dart';

void main() {
  testWidgets('Analysis app renders start and stop controls', (tester) async {
    await tester.pumpWidget(const PoiAnalysisApp());
    await tester.pump();

    expect(find.text('Start'), findsOneWidget);
    expect(find.text('Stop'), findsOneWidget);
    expect(find.textContaining('Node IDs will appear here'), findsOneWidget);
  });
}
