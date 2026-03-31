import 'package:flutter_test/flutter_test.dart';
import 'package:safora/presentation/screens/home/home_screen.dart';
import 'package:safora/presentation/blocs/alerts/alerts_cubit.dart';
import 'package:safora/presentation/blocs/alerts/alerts_state.dart';
import 'package:safora/data/models/alert_event.dart';
import 'package:safora/core/constants/alert_types.dart';
import '../../../helpers/widget_test_helpers.dart';

class TestAlertsCubit extends AlertsCubit {
  TestAlertsCubit({
    required super.alertsRepository,
    required super.notificationService,
    required super.alertPreferences,
  });

  void emitState(AlertsState state) => emit(state);

  @override
  Future<void> loadAlerts() async {
    // No-op for testing to avoid setState during build
  }
}

void main() {
  late TestAlertsCubit testAlertsCubit;

  setUp(() {
    testAlertsCubit = TestAlertsCubit(
      alertsRepository: MockAlertsRepository(),
      notificationService: MockNotificationService(),
      alertPreferences: MockAlertPreferences(),
    );
  });

  tearDown(() {
    testAlertsCubit.close();
  });

  testWidgets('HomeScreen renders with localized title', (tester) async {
    await tester.pumpWidget(buildTestableWidget(
      child: const HomeScreen(),
      alertsCubit: testAlertsCubit,
    ));

    expect(find.text('Safora'), findsOneWidget);
  });

  testWidgets('HomeScreen BlocListener triggers on critical alerts', (tester) async {
    // Wait for initial render
    await tester.pumpWidget(buildTestableWidget(
      child: const HomeScreen(),
      alertsCubit: testAlertsCubit,
    ));
    await tester.pump();

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

    final loadedState = AlertsLoaded(alerts: [criticalAlert]);
    testAlertsCubit.emitState(loadedState);
    
    // Wait for the stream event and subsequent post frame callbacks / dialog animation
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    
    // Verify that the emergency overlay/dialog is shown
    expect(find.text('Major Earthquake'), findsWidgets);
  });
}
