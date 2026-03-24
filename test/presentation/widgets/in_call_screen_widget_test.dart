import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safora/core/services/audio_service.dart';
import 'package:safora/injection.dart';
import 'package:safora/presentation/screens/decoycall/in_call_screen.dart';
import '../../helpers/widget_test_helpers.dart';

class MockAudioService extends Mock implements AudioService {}

void main() {
  late MockAudioService mockAudio;

  setUp(() {
    getIt.reset();
    mockAudio = MockAudioService();
    when(() => mockAudio.isRingtonePlaying).thenReturn(false);
    when(() => mockAudio.isSirenPlaying).thenReturn(false);
    when(() => mockAudio.stopRingtone()).thenAnswer((_) async {});
    when(() => mockAudio.stopAll()).thenAnswer((_) async {});
    when(() => mockAudio.playRingtone()).thenAnswer((_) async {});
    getIt.registerLazySingleton<AudioService>(() => mockAudio);
  });

  tearDown(() => getIt.reset());

  group('InCallScreen Widget Tests', () {
    testWidgets('renders in-call screen', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const InCallScreen(callerName: 'Mom')),
      );
      await tester.pump();
      expect(find.byType(InCallScreen), findsOneWidget);
    });

    testWidgets('displays caller name', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const InCallScreen(callerName: 'Mom')),
      );
      await tester.pump();
      expect(find.text('Mom'), findsAtLeast(1));
    });

    testWidgets('displays different caller name', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: const InCallScreen(callerName: 'John Smith'),
        ),
      );
      await tester.pump();
      expect(find.text('John Smith'), findsAtLeast(1));
    });

    testWidgets('has interactive buttons', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const InCallScreen(callerName: 'Mom')),
      );
      await tester.pump();

      // InCallScreen should have at least one tappable action
      final buttons = find.byType(IconButton);
      final gestureDetectors = find.byType(GestureDetector);
      final inkWells = find.byType(InkWell);

      expect(
        buttons.evaluate().isNotEmpty ||
            gestureDetectors.evaluate().isNotEmpty ||
            inkWells.evaluate().isNotEmpty,
        true,
        reason: 'Should have interactive call action buttons',
      );
    });

    testWidgets('has visual call indicator', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const InCallScreen(callerName: 'Dad')),
      );
      await tester.pump();

      // Should contain visual elements (icons, text)
      expect(find.byType(Icon), findsAtLeast(1));
      expect(find.text('Dad'), findsAtLeast(1));
    });
  });
}
