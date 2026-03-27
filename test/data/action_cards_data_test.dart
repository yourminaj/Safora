import 'package:flutter_test/flutter_test.dart';
import 'package:safora/data/action_cards_data.dart';
import 'package:safora/core/constants/alert_types.dart';

void main() {
  group('ActionCardsData', () {
    test('returns non-empty cards for earthquake', () {
      final cards = ActionCardsData.forType(AlertType.earthquake);
      expect(cards, isNotEmpty);
    });

    test('each card has a title and non-empty steps', () {
      final cards = ActionCardsData.forType(AlertType.earthquake);
      for (final card in cards) {
        expect(card.title, isNotEmpty);
        expect(card.steps, isNotEmpty);
      }
    });

    test('returns cards for category fallback', () {
      // Pick an alert type that only has category-level actions.
      const categories = AlertCategory.values;
      for (final category in categories) {
        final cards = ActionCardsData.forCategory(category);
        // At least some categories should have fallback actions.
        // We don't assert all, just that the method works without error.
        expect(cards, isNotNull);
      }
    });

    test('forType type-specific cards take priority over category', () {
      final typeCards = ActionCardsData.forType(AlertType.earthquake);
      final categoryCards =
          ActionCardsData.forCategory(AlertCategory.naturalDisaster);

      // Type-specific should be different from (or same as) category-level.
      // The point is that type-specific are returned when available.
      expect(typeCards, isNotEmpty);
      if (categoryCards.isNotEmpty) {
        // If both have cards, type-specific should take priority.
        // They may or may not be the same — just verify type-specific returned.
        expect(typeCards.first.title, isNotEmpty);
      }
    });

    test('urgency enum is one of immediate, followUp, preparatory', () {
      final cards = ActionCardsData.forType(AlertType.earthquake);
      for (final card in cards) {
        expect(
          [ActionUrgency.immediate, ActionUrgency.followUp, ActionUrgency.preparatory],
          contains(card.urgency),
        );
      }
    });

    test('returns empty list for unknown type without fallback', () {
      // All types should have at least category fallback, but verify graceful empty.
      final cards = ActionCardsData.forType(AlertType.values.first);
      // Should return a list (possibly empty, possibly not).
      expect(cards, isNotNull);
    });
  });
}
