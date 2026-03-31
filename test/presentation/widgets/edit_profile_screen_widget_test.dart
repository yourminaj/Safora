import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:mocktail/mocktail.dart';
import 'package:safora/data/models/user_profile.dart';
import 'package:safora/injection.dart';
import 'package:safora/presentation/screens/profile/edit_profile_screen.dart';
import '../../helpers/widget_test_helpers.dart';

class MockBox extends Mock implements Box {}

void main() {
  setUp(() {
    getIt.reset();
    final mockBox = MockBox();
    when(() => mockBox.get(any(), defaultValue: any(named: 'defaultValue')))
        .thenReturn(null);
    when(() => mockBox.put(any(), any())).thenAnswer((_) async {});
    getIt.registerSingleton<Box>(mockBox, instanceName: 'user_profile');
  });

  tearDown(() => getIt.reset());

  group('EditProfileScreen Widget Tests', () {
    testWidgets('renders edit profile screen', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const EditProfileScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(EditProfileScreen), findsOneWidget);
    });

    testWidgets('renders with existing profile', (tester) async {
      const profile = UserProfile(
        fullName: 'Jane Doe',
        bloodType: 'O+',
      );
      await tester.pumpWidget(
        buildTestableWidget(
          child: const EditProfileScreen(existingProfile: profile),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(EditProfileScreen), findsOneWidget);
    });

    testWidgets('has form fields', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const EditProfileScreen()),
      );
      await tester.pumpAndSettle();

      // Should have text form fields for profile data
      expect(find.byType(TextFormField), findsAtLeast(1));
    });
  });
}
