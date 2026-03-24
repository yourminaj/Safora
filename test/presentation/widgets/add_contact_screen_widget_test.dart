import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safora/data/models/emergency_contact.dart';
import 'package:safora/data/repositories/contacts_repository.dart';
import 'package:safora/presentation/blocs/contacts/contacts_cubit.dart';
import 'package:safora/presentation/screens/contacts/add_contact_screen.dart';
import '../../helpers/widget_test_helpers.dart';

class MockContactsRepository extends Mock implements ContactsRepository {}

void main() {
  late MockContactsRepository mockRepo;
  late ContactsCubit cubit;

  setUp(() {
    mockRepo = MockContactsRepository();
    when(() => mockRepo.getAll()).thenReturn([]);
    when(() => mockRepo.count).thenReturn(0);
    when(() => mockRepo.isLimitReached).thenReturn(false);
    cubit = ContactsCubit(mockRepo);
    registerFallbackValue(const EmergencyContact(
      name: 'F', phone: '+0', relationship: 'Other',
    ));
  });

  tearDown(() => cubit.close());

  Widget buildScreen() {
    return buildTestableWidget(
      child: BlocProvider<ContactsCubit>.value(
        value: cubit,
        child: const AddContactScreen(),
      ),
    );
  }

  group('AddContactScreen Widget Tests', () {
    testWidgets('renders add contact screen', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      expect(find.byType(AddContactScreen), findsOneWidget);
    });

    testWidgets('has text form fields for contact details', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsAtLeast(2));
    });

    testWidgets('can type into name field', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Find the first TextFormField (name field)
      final nameField = find.byType(TextFormField).first;
      await tester.enterText(nameField, 'John Doe');
      await tester.pump();

      expect(find.text('John Doe'), findsOneWidget);
    });

    testWidgets('has a save or submit button', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Look for save/add button (could be ElevatedButton, TextButton, or FAB)
      final saveButton = find.byType(ElevatedButton);
      final fab = find.byType(FloatingActionButton);
      final iconButton = find.byIcon(Icons.check);
      final saveIcon = find.byIcon(Icons.save);

      expect(
        saveButton.evaluate().isNotEmpty ||
            fab.evaluate().isNotEmpty ||
            iconButton.evaluate().isNotEmpty ||
            saveIcon.evaluate().isNotEmpty,
        true,
        reason: 'Should have a save/submit action',
      );
    });

    testWidgets('displays app bar with title', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      expect(find.byType(AppBar), findsOneWidget);
    });
  });
}
