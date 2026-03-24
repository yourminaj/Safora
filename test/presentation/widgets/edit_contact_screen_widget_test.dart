import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safora/data/models/emergency_contact.dart';
import 'package:safora/data/repositories/contacts_repository.dart';
import 'package:safora/presentation/blocs/contacts/contacts_cubit.dart';
import 'package:safora/presentation/screens/contacts/edit_contact_screen.dart';
import '../../helpers/widget_test_helpers.dart';

class MockContactsRepository extends Mock implements ContactsRepository {}

void main() {
  late MockContactsRepository mockRepo;
  late ContactsCubit cubit;

  const testContact = EmergencyContact(
    id: 'c1',
    name: 'Alice',
    phone: '+1234567890',
    relationship: 'Sister',
  );

  setUp(() {
    mockRepo = MockContactsRepository();
    when(() => mockRepo.getAll()).thenReturn([testContact]);
    when(() => mockRepo.count).thenReturn(1);
    when(() => mockRepo.isLimitReached).thenReturn(false);
    cubit = ContactsCubit(mockRepo);
    registerFallbackValue(testContact);
  });

  tearDown(() => cubit.close());

  Widget buildScreen() {
    return buildTestableWidget(
      child: BlocProvider<ContactsCubit>.value(
        value: cubit,
        child: const EditContactScreen(contact: testContact),
      ),
    );
  }

  group('EditContactScreen Widget Tests', () {
    testWidgets('renders edit contact screen', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      expect(find.byType(EditContactScreen), findsOneWidget);
    });

    testWidgets('pre-fills contact name', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      expect(find.text('Alice'), findsAtLeast(1));
    });

    testWidgets('pre-fills phone number', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      expect(find.text('+1234567890'), findsAtLeast(1));
    });

    testWidgets('has form fields', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsAtLeast(2));
    });

    testWidgets('has an app bar', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('can modify name field', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Find name field and clear + re-enter text
      final nameField = find.byType(TextFormField).first;
      await tester.enterText(nameField, 'Bob');
      await tester.pump();
      expect(find.text('Bob'), findsOneWidget);
    });
  });
}
