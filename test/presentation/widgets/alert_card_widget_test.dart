import 'package:flutter_test/flutter_test.dart';
import 'package:safora/data/models/alert_event.dart';
import 'package:safora/core/constants/alert_types.dart';
import 'package:safora/presentation/widgets/alert_card.dart';
import '../../helpers/widget_test_helpers.dart';

void main() {
  group('AlertCard Widget Tests', () {
    final testAlert = AlertEvent(
      id: 'a1',
      type: AlertType.earthquake,
      title: '5.2 Earthquake',
      latitude: 23.8,
      longitude: 90.4,
      timestamp: DateTime(2026, 3, 24, 12, 0),
    );

    testWidgets('renders alert card', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: AlertCard(alert: testAlert)),
      );
      // Use pump with duration instead of pumpAndSettle for animated widgets.
      await tester.pump(const Duration(seconds: 2));
      expect(find.byType(AlertCard), findsOneWidget);
    });

    testWidgets('displays alert title', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: AlertCard(alert: testAlert)),
      );
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('5.2 Earthquake'), findsOneWidget);
    });

    testWidgets('onTap callback is triggered', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        buildTestableWidget(
          child: AlertCard(
            alert: testAlert,
            onTap: () => tapped = true,
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 2));

      await tester.tap(find.byType(AlertCard));
      expect(tapped, true);
    });
  });
}
