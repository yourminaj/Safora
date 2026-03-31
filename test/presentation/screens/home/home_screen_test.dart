import 'dart:async';
import 'package:flutter_test/flutter_test.dart';

import 'package:mocktail/mocktail.dart';
import 'package:safora/presentation/screens/home/home_screen.dart';
import 'package:safora/presentation/blocs/alerts/alerts_cubit.dart';
import 'package:safora/presentation/blocs/alerts/alerts_state.dart';
import 'package:safora/data/models/alert_event.dart';
import 'package:safora/core/constants/alert_types.dart';
import '../../../helpers/widget_test_helpers.dart';

class MockAlertsCubit extends Mock implements AlertsCubit {}




void main() {
  late MockAlertsCubit mockAlertsCubit;

  setUp(() {
    mockAlertsCubit = MockAlertsCubit();
    // Default state
    when(() => mockAlertsCubit.state).thenReturn(const AlertsInitial());
    when(() => mockAlertsCubit.stream).thenAnswer((_) => const Stream.empty());
  });

  testWidgets('HomeScreen renders with localized title', (tester) async {
    await tester.pumpWidget(buildTestableWidget(
      child: const HomeScreen(),
      alertsCubit: mockAlertsCubit,
    ));

    expect(find.text('Safora'), findsOneWidget);
  });

  testWidgets('HomeScreen BlocListener triggers on critical alerts', (tester) async {
    // Create a stream controller to emit states
    final states = StreamController<AlertsState>();
    when(() => mockAlertsCubit.stream).thenAnswer((_) => states.stream);
    when(() => mockAlertsCubit.state).thenReturn(const AlertsInitial());

    await tester.pumpWidget(buildTestableWidget(
      child: const HomeScreen(),
      alertsCubit: mockAlertsCubit,
    ));

    // Emit a state with a critical alert
    final criticalAlert = AlertEvent(
      id: '1',
      type: AlertType.earthquake,
      title: 'Major Earthquake',
      latitude: 0,
      longitude: 0,
      timestamp: DateTime.now(),
      confidenceLevel: 1.0,
      distanceKm: 0.5,
    );

    states.add(AlertsLoaded(alerts: [criticalAlert]));
    
    // Pump to trigger listener
    await tester.pump();
    
    // Verify that the emergency overlay/dialog is shown (triggered by _checkForCriticalAlerts)
    // _checkForCriticalAlerts shows a full-screen critical alert overlay or similar.
    // In our implementation, it might show a specific UI element.
    expect(find.text('Major Earthquake'), findsWidgets);
    
    await states.close();
  });
}
