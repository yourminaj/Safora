import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safora/core/services/notification_service.dart';
import 'package:safora/data/datasources/reminders_local_datasource.dart';
import 'package:safora/data/models/medicine_reminder.dart';
import 'package:safora/data/repositories/reminders_repository.dart';
import 'package:safora/presentation/blocs/reminders/reminders_cubit.dart';
import 'package:safora/presentation/blocs/reminders/reminders_state.dart';

class MockRemindersRepository extends Mock implements RemindersRepository {}

class MockNotificationService extends Mock implements NotificationService {}

void main() {
  setUpAll(() {
    registerFallbackValue(const MedicineReminder(
      name: 'dummy',
      dosage: 'dummy',
      timeOfDay: '00:00',
    ));
  });
  late RemindersCubit cubit;
  late MockRemindersRepository mockRepo;
  late MockNotificationService mockNotificationService;

  setUp(() {
    mockRepo = MockRemindersRepository();
    mockNotificationService = MockNotificationService();
    cubit = RemindersCubit(
      repository: mockRepo,
      notificationService: mockNotificationService,
    );
  });

  tearDown(() {
    cubit.close();
  });

  group('RemindersCubit — Initial State', () {
    test('initial state is RemindersInitial', () {
      expect(cubit.state, const RemindersInitial());
    });
  });

  group('RemindersCubit — loadReminders', () {
    final reminders = [
      const MedicineReminder(
        id: 'r1',
        name: 'Aspirin',
        dosage: '100mg',
        timeOfDay: '08:00',
        isActive: true,
      ),
      const MedicineReminder(
        id: 'r2',
        name: 'Metformin',
        dosage: '500mg',
        timeOfDay: '09:00',
        isActive: false,
      ),
    ];

    test('emits RemindersLoading then RemindersLoaded on success', () async {
      when(() => mockRepo.getAll()).thenReturn(reminders);

      final states = <RemindersState>[];
      final sub = cubit.stream.listen(states.add);

      cubit.loadReminders();
      await Future<void>.delayed(Duration.zero);

      expect(states, hasLength(2));
      expect(states[0], isA<RemindersLoading>());
      expect(states[1], isA<RemindersLoaded>());
      expect((states[1] as RemindersLoaded).activeCount, 1);

      await sub.cancel();
    });

    test('emits RemindersLoaded with empty list', () async {
      when(() => mockRepo.getAll()).thenReturn([]);

      final states = <RemindersState>[];
      final sub = cubit.stream.listen(states.add);

      cubit.loadReminders();
      await Future<void>.delayed(Duration.zero);

      expect(states.last, isA<RemindersLoaded>());
      expect((states.last as RemindersLoaded).activeCount, 0);

      await sub.cancel();
    });

    test('emits RemindersError on exception', () async {
      when(() => mockRepo.getAll()).thenThrow(Exception('DB error'));

      final states = <RemindersState>[];
      final sub = cubit.stream.listen(states.add);

      cubit.loadReminders();
      await Future<void>.delayed(Duration.zero);

      expect(states.last, isA<RemindersError>());

      await sub.cancel();
    });
  });

  group('RemindersCubit — addReminder', () {
    test('adds reminder and reloads list', () async {
      when(() => mockRepo.add(any())).thenAnswer((_) async => 'new-id');
      when(() => mockRepo.getAll()).thenReturn([]);
      when(() => mockNotificationService.showDisasterAlert(
            title: any(named: 'title'),
            body: any(named: 'body'),
          )).thenAnswer((_) async {});

      final states = <RemindersState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.addReminder(
        name: 'Vitamin D',
        dosage: '1000 IU',
        timeOfDay: '10:00',
      );
      await Future<void>.delayed(Duration.zero);

      verify(() => mockRepo.add(any())).called(1);
      expect(states.last, isA<RemindersLoaded>());

      await sub.cancel();
    });

    test('emits ReminderLimitReached when limit is hit', () async {
      when(() => mockRepo.add(any())).thenThrow(
        ReminderLimitException('Maximum 20 reminders reached'),
      );

      final states = <RemindersState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.addReminder(
        name: 'Extra',
        dosage: '1',
        timeOfDay: '12:00',
      );
      await Future<void>.delayed(Duration.zero);

      expect(states.last, isA<ReminderLimitReached>());

      await sub.cancel();
    });
  });

  group('RemindersCubit — deleteReminder', () {
    test('deletes and reloads list', () async {
      when(() => mockRepo.delete('r1')).thenAnswer((_) async {});
      when(() => mockRepo.getAll()).thenReturn([]);
      when(() => mockNotificationService.cancelNotification(any()))
          .thenAnswer((_) async {});

      final states = <RemindersState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.deleteReminder('r1');
      await Future<void>.delayed(Duration.zero);

      expect(states.last, isA<RemindersLoaded>());

      await sub.cancel();
    });
  });

  group('RemindersCubit — toggleReminder', () {
    test('toggles and reloads list', () async {
      when(() => mockRepo.toggleActive('r1')).thenAnswer((_) async {});
      when(() => mockRepo.getAll()).thenReturn([]);

      final states = <RemindersState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.toggleReminder('r1');
      await Future<void>.delayed(Duration.zero);

      expect(states.last, isA<RemindersLoaded>());

      await sub.cancel();
    });
  });
}
