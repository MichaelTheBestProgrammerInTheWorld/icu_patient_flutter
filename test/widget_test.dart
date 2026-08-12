import 'package:flutter_test/flutter_test.dart';
import 'package:icu_patient_flutter/main.dart';

void main() {
  testWidgets('Dashboard loads and navigation works', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const IcuPatientApp());

    // Pump to trigger the minimal boot frame transition
    await tester.pump();

    // Verify that the dashboard title is shown.
    expect(find.text('ICU Vital Dashboard'), findsOneWidget);
    
    // Verify that the new ECG label is present.
    expect(find.text('ECG (Parsed in Long-Lived Isolate)'), findsOneWidget);

    // Verify button exists
    expect(find.text('VIEW FDA EVENTS'), findsOneWidget);

    // Tap the button to navigate
    await tester.tap(find.text('VIEW FDA EVENTS'));
    await tester.pumpAndSettle();

    // Verify we are on the FDA screen
    expect(find.text('FDA Event Log'), findsOneWidget);
  });
}
