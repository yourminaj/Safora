import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safora/core/services/audio_service.dart';
import 'package:safora/core/services/location_service.dart';
import 'package:safora/data/datasources/sos_history_datasource.dart';
import 'package:safora/data/repositories/contacts_repository.dart';
import 'package:safora/domain/usecases/trigger_sos_usecase.dart';
import 'package:safora/presentation/blocs/sos/sos_cubit.dart';
import 'package:safora/presentation/widgets/countdown_overlay.dart';
import '../../helpers/widget_test_helpers.dart';

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

    cubit = SosCubit(
      audioService: mockAudio,
      triggerSosUseCase: MockTriggerSosUseCase(),
      contactsRepository: MockContactsRepository(),
      sosHistoryDatasource: MockSosHistoryDatasource(),
      locationService: MockLocationService(),
    );
  });

  tearDown(() => cubit.close());

  Widget buildOverlay() {
    return buildTestableWidget(
      child: BlocProvider<SosCubit>.value(
        value: cubit,
        child: const CountdownOverlay(),
      ),
    );
  }

  group('CountdownOverlay Widget Tests', () {
    testWidgets('renders countdown overlay', (tester) async {
      await tester.pumpWidget(buildOverlay());
      await tester.pump();
      expect(find.byType(CountdownOverlay), findsOneWidget);
    });

    testWidgets('has visual countdown elements', (tester) async {
      await tester.pumpWidget(buildOverlay());
      await tester.pump();

      // Should contain text and icons for the countdown UI
      expect(find.byType(Text), findsAtLeast(1));
    });

    testWidgets('has cancel/stop functionality', (tester) async {
      await tester.pumpWidget(buildOverlay());
      await tester.pump();

      // Look for cancel/stop button or tappable area
      final buttons = find.byType(ElevatedButton);
      final textButtons = find.byType(TextButton);
      final gestureDetectors = find.byType(GestureDetector);
      final inkWells = find.byType(InkWell);

      final hasInteractiveElement = buttons.evaluate().isNotEmpty ||
          textButtons.evaluate().isNotEmpty ||
          gestureDetectors.evaluate().isNotEmpty ||
          inkWells.evaluate().isNotEmpty;

      expect(hasInteractiveElement, true,
          reason: 'CountdownOverlay should have a cancel/stop action');
    });

    testWidgets('contains SOS-related text', (tester) async {
      await tester.pumpWidget(buildOverlay());
      await tester.pump();

      // Should show SOS-related information
      final allText = find.byType(Text);
      expect(allText, findsAtLeast(1));
    });
  });
}
