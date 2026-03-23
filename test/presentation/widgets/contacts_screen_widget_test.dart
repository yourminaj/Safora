import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safora/presentation/screens/contacts/contacts_screen.dart';

import '../../helpers/widget_test_helpers.dart';

void main() {
  group('ContactsScreen Widget Tests', () {
    testWidgets('renders ContactsScreen widget tree', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const ContactsScreen()),
      );
      // Use pump — Lottie empty_state animation loops infinitely.
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(ContactsScreen), findsOneWidget);
    });

    testWidgets('renders Emergency Contacts title', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const ContactsScreen()),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Emergency Contacts'), findsOneWidget);
    });

    testWidgets('renders add contact FAB', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const ContactsScreen()),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byIcon(Icons.person_add_rounded), findsOneWidget);
      expect(find.text('Add Contact'), findsOneWidget);
    });

    testWidgets('shows empty state when no contacts', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const ContactsScreen()),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.textContaining('No Emergency Contacts'), findsOneWidget);
    });
  });
}
