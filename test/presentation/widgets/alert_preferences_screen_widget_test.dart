import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safora/core/constants/alert_types.dart';
import 'package:safora/core/services/alert_permission_gate.dart';
import 'package:safora/data/models/alert_preferences.dart';
import 'package:safora/l10n/app_localizations.dart';
import 'package:safora/presentation/blocs/alert_preferences/alert_preferences_cubit.dart';
import 'package:safora/presentation/screens/settings/alert_preferences_screen.dart';

class _MockAlertPreferences extends Mock implements AlertPreferences {}

class _MockAlertPermissionGate extends Mock implements AlertPermissionGate {}

void main() {
  late _MockAlertPreferences mockPrefs;
  late _MockAlertPermissionGate mockGate;
  late AlertPreferencesCubit cubit;

  setUpAll(() {
    registerFallbackValue(AlertType.earthquake);
    registerFallbackValue(AlertPriority.info);
    registerFallbackValue(AlertCategory.naturalDisaster);
  });

  setUp(() {
    mockPrefs = _MockAlertPreferences();
    mockGate = _MockAlertPermissionGate();

    // Stub AlertPreferences behavior.
    when(() => mockPrefs.isEnabled(any())).thenReturn(true);
    when(() => mockPrefs.minimumSeverity).thenReturn(AlertPriority.info);
    when(() => mockPrefs.shouldReceive(any())).thenReturn(true);
    when(() => mockPrefs.totalEnabled).thenReturn(AlertType.values.length);
    when(() => mockPrefs.totalAlerts).thenReturn(AlertType.values.length);
    when(() => mockPrefs.enabledAlerts).thenReturn(AlertType.values.toSet());
    when(() => mockPrefs.enabledCountByCategory()).thenReturn({});
    when(() => mockPrefs.groupedByCategory()).thenReturn({});
    when(() => mockPrefs.setEnabled(any(), any())).thenAnswer((_) async {});
    when(() => mockPrefs.enableCategory(any(), isUserPremium: any(named: 'isUserPremium'))).thenAnswer((_) async => 0);
    when(() => mockPrefs.disableCategory(any())).thenAnswer((_) async => 0);
    when(() => mockPrefs.enableAllFree()).thenAnswer((_) async => 0);
    when(() => mockPrefs.setMinimumSeverity(any())).thenAnswer((_) async {});

    cubit = AlertPreferencesCubit(
      alertPreferences: mockPrefs,
      permissionGate: mockGate,
    );
  });

  Widget buildTestWidget() {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: BlocProvider<AlertPreferencesCubit>.value(
        value: cubit,
        child: const Scaffold(body: AlertPreferencesScreen()),
      ),
    );
  }

  group('AlertPreferencesScreen Widget Tests', () {
    testWidgets('renders alert preferences screen', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(AlertPreferencesScreen), findsOneWidget);
    });

    testWidgets('displays Alert Preferences header text', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Alert Preferences'), findsOneWidget);
    });

    testWidgets('displays search bar with hint text', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Search 127 alert types...'), findsOneWidget);
    });

    testWidgets('renders Enable All Free chip', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Enable All Free'), findsOneWidget);
    });

    testWidgets('renders Minimum Severity section', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Minimum Severity'), findsOneWidget);
    });

    testWidgets('renders severity slider', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('renders search icon', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
    });
  });
}
