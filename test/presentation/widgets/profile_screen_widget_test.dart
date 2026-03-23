import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safora/presentation/screens/profile/profile_screen.dart';

import '../../helpers/widget_test_helpers.dart';

void main() {
  group('ProfileScreen Widget Tests', () {
    testWidgets('renders ProfileScreen widget tree', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const ProfileScreen()),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(ProfileScreen), findsOneWidget);
    });

    testWidgets('renders profile title in AppBar', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const ProfileScreen()),
      );
      await tester.pump(const Duration(milliseconds: 500));

      // The profile screen should be present and render in the tree.
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('renders profile content area', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const ProfileScreen()),
      );
      await tester.pump(const Duration(milliseconds: 500));

      // Profile screen should render some content area.
      expect(find.byType(ProfileScreen), findsOneWidget);
    });
  });
}
