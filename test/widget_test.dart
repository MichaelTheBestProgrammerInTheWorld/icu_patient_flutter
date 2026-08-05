import 'package:flutter_test/flutter_test.dart';
import 'package:icu_patient_flutter/main.dart';

void main() {
  testWidgets('Dashboard loads and shows title', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const IcuPatientApp());

    // Verify that the dashboard title is shown.
    expect(find.text('ICU Vital Dashboard'), findsOneWidget);
    
    // Verify that the ECG label is present.
    expect(find.text('ECG (Simulated via Coinbase BTC-USD)'), findsOneWidget);

    // Drain pending timers from WebSocket connection attempt
    await tester.pumpAndSettle();
  });
}
