import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imn/main.dart';

void main() {
  testWidgets('App starts successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: ImnApp()));
    await tester.pump();
    // App should render without crashing
    expect(find.byType(ImnApp), findsOneWidget);
  });
}
