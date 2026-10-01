import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:expirybox/main.dart';

void main() {
  testWidgets('ExpiryBox starts with an empty item list', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const ExpiryBoxApp());
    await tester.pumpAndSettle();

    expect(find.text('ExpiryBox'), findsOneWidget);
    expect(find.text('Your box is empty'), findsOneWidget);
    expect(find.text('Add Item'), findsOneWidget);
  });
}