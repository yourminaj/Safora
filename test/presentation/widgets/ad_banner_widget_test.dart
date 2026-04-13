import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safora/presentation/widgets/ad_banner_widget.dart';
import '../../helpers/widget_test_helpers.dart';

void main() {
  group('AdBanner Widget Tests', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: const AdBanner(
            adUnitId: 'ca-app-pub-3940256099942544/6300978111',
          ),
        ),
      );
      await tester.pump();
      // AdBanner renders SizedBox.shrink before ad loads
      expect(find.byType(AdBanner), findsOneWidget);
    });

    testWidgets('shows nothing while ad is loading', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: const AdBanner(
            adUnitId: 'ca-app-pub-3940256099942544/6300978111',
          ),
        ),
      );
      await tester.pump();
      // Before ad loads, should show SizedBox.shrink (zero size)
      expect(find.byType(SizedBox), findsAtLeast(1));
    });

    testWidgets('shows nothing when consent not granted', (tester) async {
      // ConsentService.canRequestAds defaults to false in tests.
      // Banner should render SizedBox.shrink without making ad requests.
      await tester.pumpWidget(
        buildTestableWidget(
          child: const AdBanner(
            adUnitId: 'ca-app-pub-3940256099942544/6300978111',
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(AdBanner), findsOneWidget);
      expect(find.byType(SizedBox), findsAtLeast(1));
    });
  });
}
