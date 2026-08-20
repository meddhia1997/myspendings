import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:myspendings/main.dart';

void main() {
  testWidgets('App boots and shows the transactions tab', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MySpendingsApp()));
    await tester.pump();

    expect(find.text('Transactions'), findsWidgets);
  });
}
