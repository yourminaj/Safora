import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safora/data/datasources/sos_history_datasource.dart';
import 'package:safora/data/models/sos_history_entry.dart';
import 'package:safora/presentation/screens/settings/sos_history_screen.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/widget_test_helpers.dart';
import 'package:safora/core/services/premium_manager.dart';

class MockPremiumManager extends Mock implements PremiumManager {}

class _FakeBox extends Fake implements Box {
  final List<Map<String, dynamic>> _items = [];

  @override
  int get length => _items.length;

  @override
  Future<int> add(dynamic value) async {
    _items.add(Map<String, dynamic>.from(value as Map));
    return _items.length - 1;
  }

  @override
  dynamic getAt(int index) => _items[index];

  @override
  Future<int> clear() async {
    final count = _items.length;
    _items.clear();
    return count;
  }

  @override
  Future<void> deleteAt(int index) async => _items.removeAt(index);
}

void main() {
  late _FakeBox fakeBox;
  late SosHistoryDatasource datasource;
  late MockPremiumManager premiumManager;

  setUp(() {
    fakeBox = _FakeBox();
    datasource = SosHistoryDatasource(fakeBox);
    premiumManager = MockPremiumManager();
    when(() => premiumManager.historyRetentionDays).thenReturn(30);
    
    final getIt = GetIt.instance;
    if (!getIt.isRegistered<SosHistoryDatasource>()) {
      getIt.registerSingleton<SosHistoryDatasource>(datasource);
    }
    if (!getIt.isRegistered<PremiumManager>()) {
      getIt.registerSingleton<PremiumManager>(premiumManager);
    }
  });

  tearDown(() {
    final getIt = GetIt.instance;
    if (getIt.isRegistered<SosHistoryDatasource>()) {
      getIt.unregister<SosHistoryDatasource>();
    }
    if (getIt.isRegistered<PremiumManager>()) {
      getIt.unregister<PremiumManager>();
    }
  });

  Widget buildScreen() {
    return buildTestableWidget(child: const SosHistoryScreen());
  }

  group('SosHistoryScreen Widget Tests', () {
    testWidgets('renders SOS History screen', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      expect(find.byType(SosHistoryScreen), findsOneWidget);
    });

    testWidgets('shows empty state when no history', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.history_rounded), findsOneWidget);
    });

    testWidgets('shows entries when history exists', (tester) async {
      await datasource.add(SosHistoryEntry(
        timestamp: DateTime(2026, 3, 24, 14, 30),
        contactsNotified: 3,
        smsSentCount: 2,
        wasCancelled: false,
        triggerSource: SosTriggerSource.manual,
      ));
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.touch_app_rounded), findsOneWidget);
    });

    testWidgets('shows cancelled badge for cancelled entries', (tester) async {
      await datasource.add(SosHistoryEntry(
        timestamp: DateTime(2026, 3, 24, 14, 30),
        contactsNotified: 2,
        smsSentCount: 0,
        wasCancelled: true,
        triggerSource: SosTriggerSource.shake,
      ));
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.vibration_rounded), findsOneWidget);
    });

    testWidgets('shows clear button when entries exist', (tester) async {
      await datasource.add(SosHistoryEntry(
        timestamp: DateTime(2026, 3, 24, 14, 30),
        contactsNotified: 1,
        smsSentCount: 1,
        wasCancelled: false,
        triggerSource: SosTriggerSource.manual,
      ));
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
    });

    testWidgets('does not show clear button when empty', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.delete_outline_rounded), findsNothing);
    });
  });
}
