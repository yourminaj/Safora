import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safora/core/constants/alert_types.dart';
import 'package:safora/data/datasources/alerts_local_datasource.dart';
import 'package:safora/data/models/alert_event.dart';

class MockBox extends Mock implements Box {}

void main() {
  late MockBox mockBox;
  late AlertsLocalDataSource datasource;

  setUp(() {
    mockBox = MockBox();
    datasource = AlertsLocalDataSource(mockBox);
  });

  group('AlertsLocalDataSource', () {
    final now = DateTime(2026, 3, 24, 14, 30);
    final alert = AlertEvent(
      id: 'alert1',
      type: AlertType.earthquake,
      title: 'Quake',
      latitude: 23.8,
      longitude: 90.4,
      timestamp: now,
    );

    test('count returns box length', () {
      when(() => mockBox.length).thenReturn(3);
      expect(datasource.count, 3);
    });

    test('exists returns true for existing key', () {
      when(() => mockBox.containsKey('alert1')).thenReturn(true);
      expect(datasource.exists('alert1'), true);
    });

    test('exists returns false for missing key', () {
      when(() => mockBox.containsKey('missing')).thenReturn(false);
      expect(datasource.exists('missing'), false);
    });

    test('save stores alert as JSON', () async {
      when(() => mockBox.put(any(), any())).thenAnswer((_) async {});
      when(() => mockBox.length).thenReturn(1);
      await datasource.save(alert);
      verify(() => mockBox.put('alert1', any())).called(1);
    });

    test('getAll returns empty for empty box', () {
      when(() => mockBox.keys).thenReturn([]);
      expect(datasource.getAll(), isEmpty);
    });

    test('getAll returns alerts sorted newest first', () {
      final older = AlertEvent(
        type: AlertType.flood,
        title: 'Flood',
        latitude: 1,
        longitude: 2,
        timestamp: DateTime(2026, 1, 1),
      );
      when(() => mockBox.keys).thenReturn(['a1', 'a2']);
      when(() => mockBox.get('a1')).thenReturn(jsonEncode(older.toMap()));
      when(() => mockBox.get('a2')).thenReturn(jsonEncode(alert.toMap()));
      final results = datasource.getAll();
      expect(results.length, 2);
      expect(results.first.timestamp.isAfter(results.last.timestamp), true);
    });

    test('getAll skips corrupt entries', () {
      when(() => mockBox.keys).thenReturn(['good', 'bad']);
      when(() => mockBox.get('good')).thenReturn(jsonEncode(alert.toMap()));
      when(() => mockBox.get('bad')).thenReturn('not-valid-json{{{');
      final results = datasource.getAll();
      expect(results.length, 1);
    });

    test('getRecent returns limited results', () {
      when(() => mockBox.keys).thenReturn(['a1', 'a2', 'a3']);
      for (var i = 0; i < 3; i++) {
        final a = AlertEvent(
          type: AlertType.earthquake,
          title: 'Q$i',
          latitude: 1,
          longitude: 2,
          timestamp: now.subtract(Duration(days: i)),
        );
        when(() => mockBox.get('a${i + 1}'))
            .thenReturn(jsonEncode(a.toMap()));
      }
      final recent = datasource.getRecent(limit: 2);
      expect(recent.length, 2);
    });

    test('clear clears the box', () async {
      when(() => mockBox.clear()).thenAnswer((_) async => 0);
      await datasource.clear();
      verify(() => mockBox.clear()).called(1);
    });
  });
}
