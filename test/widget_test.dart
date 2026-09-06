import 'package:flutter_test/flutter_test.dart';
import 'package:ish_tissuemap_fusion/marin.dart';

void main() {
  testWidgets('application shell renders', (tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.byType(MyApp), findsOneWidget);
    expect(find.text('ISH TissueMap Fusion'), findsOneWidget);
  });
}
