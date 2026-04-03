import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safora/core/services/subscription_service.dart';
import 'package:safora/presentation/screens/settings/paywall_screen.dart';

import '../../helpers/widget_test_helpers.dart';

class _MockSubscriptionService extends Mock implements SubscriptionService {}

void main() {
  late _MockSubscriptionService mockSubscription;

  setUp(() {
    final getIt = GetIt.instance;

    if (getIt.isRegistered<SubscriptionService>()) {
      getIt.unregister<SubscriptionService>();
    }
    mockSubscription = _MockSubscriptionService();
    when(() => mockSubscription.monthlyPriceString).thenReturn('\$4.99');
    when(() => mockSubscription.yearlyPriceString).thenReturn('\$29.99');
    when(() => mockSubscription.lifetimePriceString).thenReturn('\$79.99');
    when(() => mockSubscription.isInitialized).thenReturn(true);
    when(() => mockSubscription.isPurchasing).thenReturn(false);
    when(() => mockSubscription.purchaseMonthly())
        .thenAnswer((_) async => false);
    when(() => mockSubscription.purchaseYearly())
        .thenAnswer((_) async => false);
    when(() => mockSubscription.purchaseLifetime())
        .thenAnswer((_) async => false);
    when(() => mockSubscription.restorePurchases())
        .thenAnswer((_) async => false);
    getIt.registerSingleton<SubscriptionService>(mockSubscription);
  });

  tearDown(() {
    final getIt = GetIt.instance;
    if (getIt.isRegistered<SubscriptionService>()) {
      getIt.unregister<SubscriptionService>();
    }
  });

  group('PaywallScreen Widget Tests', () {
    testWidgets('renders paywall screen', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const PaywallScreen()),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(PaywallScreen), findsOneWidget);
    });

    testWidgets('displays Safora Pro title', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const PaywallScreen()),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Safora Pro'), findsOneWidget);
    });

    testWidgets('displays subtitle text', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const PaywallScreen()),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        find.text('Complete safety protection for you and your family'),
        findsOneWidget,
      );
    });

    testWidgets('renders verified_user shield icon', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const PaywallScreen()),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byIcon(Icons.verified_user), findsOneWidget);
    });

    testWidgets('renders back button', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const PaywallScreen()),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('displays What you get with Pro section', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: const PaywallScreen()),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('What you get with Pro'), findsOneWidget);
    });
  });
}
