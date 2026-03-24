import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safora/data/datasources/sos_history_datasource.dart';
import 'package:safora/data/models/sos_history_entry.dart';

class MockBox extends Mock implements Box {}

void main() {
  late MockBox mockBox;
  late SosHistoryDatasource datasource;

  setUp(() {
    mockBox = MockBox();
    datasource = SosHistoryDatasource(mockBox);
  });

  group('SosHistoryDatasource', () {
    final now = DateTime(2026, 3, 24, 12, 0);
    final entry = SosHistoryEntry(
      timestamp: now,
      contactsNotified: 2,
      smsSentCount: 1,
      wasCancelled: false,
    );

    test('count returns box length', () {
      when(() => mockBox.length).thenReturn(5);
      expect(datasource.count, 5);
    });

    test('add stores entry to box', () async {
      when(() => mockBox.add(any())).thenAnswer((_) async => 0);
      when(() => mockBox.length).thenReturn(1);
      await datasource.add(entry);
      verify(() => mockBox.add(any())).called(1);
    });

    test('add trims old entries when over maxEntries', () async {
      when(() => mockBox.add(any())).thenAnswer((_) async => 0);
      when(() => mockBox.length).thenReturn(SosHistoryDatasource.maxEntries + 1);
      when(() => mockBox.deleteAt(0)).thenAnswer((_) async {});
      await datasource.add(entry);
      verify(() => mockBox.deleteAt(0)).called(1);
    });

    test('getAll returns empty for empty box', () {
      when(() => mockBox.length).thenReturn(0);
      expect(datasource.getAll(), isEmpty);
    });

    test('getAll returns entries sorted newest first', () {
      final older = SosHistoryEntry(
        timestamp: DateTime(2026, 1, 1),
        contactsNotified: 1,
        smsSentCount: 1,
        wasCancelled: false,
      );
      final newer = SosHistoryEntry(
        timestamp: DateTime(2026, 3, 24),
        contactsNotified: 2,
        smsSentCount: 2,
        wasCancelled: true,
      );
      when(() => mockBox.length).thenReturn(2);
      when(() => mockBox.getAt(0)).thenReturn(older.toMap());
      when(() => mockBox.getAt(1)).thenReturn(newer.toMap());
      final results = datasource.getAll();
      expect(results.length, 2);
      expect(results.first.timestamp.isAfter(results.last.timestamp), true);
    });

    test('getRecent returns limited results', () {
      when(() => mockBox.length).thenReturn(3);
      for (var i = 0; i < 3; i++) {
        when(() => mockBox.getAt(i)).thenReturn(SosHistoryEntry(
          timestamp: now.subtract(Duration(days: i)),
          contactsNotified: 1,
          smsSentCount: 1,
          wasCancelled: false,
        ).toMap());
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
