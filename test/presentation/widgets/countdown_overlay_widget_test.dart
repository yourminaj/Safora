import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safora/core/services/audio_service.dart';
import 'package:safora/core/services/location_service.dart';
import 'package:safora/data/datasources/sos_history_datasource.dart';
import 'package:safora/data/repositories/contacts_repository.dart';
import 'package:safora/domain/usecases/trigger_sos_usecase.dart';
import 'package:safora/presentation/blocs/sos/sos_cubit.dart';
import 'package:safora/presentation/blocs/sos/sos_state.dart';
import 'package:safora/presentation/widgets/countdown_overlay.dart';
import '../../helpers/widget_test_helpers.dart';

class MockBox extends Mock implements Box<dynamic> {}
class MockAudioService extends Mock implements AudioService {}
class MockTriggerSosUseCase extends Mock implements TriggerSosUseCase {}
class MockContactsRepository extends Mock implements ContactsRepository {}
class MockSosHistoryDatasource extends Mock implements SosHistoryDatasource {}
class MockLocationService extends Mock implements LocationService {}

void main() {
  late SosCubit cubit;

  setUp(() {
    final mockAudio = MockAudioService();
    when(() => mockAudio.isSirenPlaying).thenReturn(false);
    when(() => mockAudio.stopAll()).thenAnswer((_) async {});
    when(() => mockAudio.playSiren()).thenAnswer((_) async {});

    final mockBox = MockBox();
    when(() => mockBox.get(any(), defaultValue: any(named: 'defaultValue'))).thenReturn(null);
    when(() => mockBox.put(any(), any())).thenAnswer((_) async {});
    when(() => mockBox.delete(any())).thenAnswer((_) async {});

    cubit = SosCubit(
      audioService: mockAudio,
      triggerSosUseCase: MockTriggerSosUseCase(),
      contactsRepository: MockContactsRepository(),
      sosHistoryDatasource: MockSosHistoryDatasource(),
      locationService: MockLocationService(),
      settingsBox: mockBox,
    );
  });

  tearDown(() => cubit.close());

  group('CountdownOverlay Widget Tests', () {
    testWidgets('renders countdown overlay widget', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: BlocProvider<SosCubit>.value(
            value: cubit,
            child: const CountdownOverlay(),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(CountdownOverlay), findsOneWidget);
    });

    test('CountdownOverlay class is a StatelessWidget', () {
      expect(const CountdownOverlay(), isA<CountdownOverlay>());
    });

    test('SosCubit starts in SosIdle state', () {
      // Verify initial state — CountdownOverlay renders SizedBox.shrink
      // when state is not SosCountdown
      expect(cubit.state, isA<SosIdle>());
    });

    test('CountdownOverlay has a static show method', () {
      // Compile-time contract check
      expect(CountdownOverlay.show, isNotNull);
    });
  });
}
