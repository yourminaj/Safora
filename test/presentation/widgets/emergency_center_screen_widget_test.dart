import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safora/data/repositories/contacts_repository.dart';
import 'package:safora/presentation/screens/emergency/emergency_center_screen.dart';

import '../../helpers/widget_test_helpers.dart';

void main() {
  setUp(() {
    final getIt = GetIt.instance;
    // Ensure ContactsRepository is registered (widget_test_helpers does this).
    if (!getIt.isRegistered<ContactsRepository>()) {
      final mockContacts = MockContactsRepository();
      when(() => mockContacts.getAll()).thenReturn([]);
      getIt.registerSingleton<ContactsRepository>(mockContacts);
    }
  });

  group('EmergencyCenterScreen Widget Tests', () {
    testWidgets('renders emergency center screen', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const EmergencyCenterScreen()),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(EmergencyCenterScreen), findsOneWidget);
    });

    testWidgets('displays Emergency Center title in app bar', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const EmergencyCenterScreen()),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Emergency Center'), findsOneWidget);
    });

    testWidgets('renders quick action cards', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const EmergencyCenterScreen()),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Share Location'), findsOneWidget);
      expect(find.text('Call Contacts'), findsOneWidget);
    });

    testWidgets('renders QUICK ACTIONS section label', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const EmergencyCenterScreen()),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('QUICK ACTIONS'), findsOneWidget);
    });

    testWidgets('renders SAFETY RESOURCES section label', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const EmergencyCenterScreen()),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('SAFETY RESOURCES'), findsOneWidget);
    });

    testWidgets('renders safety resource tiles', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const EmergencyCenterScreen()),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Nearest Safe Places'), findsOneWidget);
      expect(find.text('First Aid Guide'), findsOneWidget);
      expect(find.text('Offline Survival'), findsOneWidget);
    });

    testWidgets('renders back button', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const EmergencyCenterScreen()),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
    });
  });
}
