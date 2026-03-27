import '../core/constants/alert_types.dart';

/// Offline-bundled action cards — survival instructions for each alert type.
///
/// Every card answers: "What should I do RIGHT NOW?"
/// These are static, offline-available instructions that display
/// on the alert detail screen.
///
/// The data is structured as a map from [AlertCategory] to a list of
/// [ActionCard] objects. Each card has:
/// - A title (e.g. "During an Earthquake")
/// - Step-by-step instructions
/// - A priority indicator
class ActionCardsData {
  const ActionCardsData._();

  /// Get action cards for a specific alert type.
  static List<ActionCard> forType(AlertType type) {
    return _typeActions[type] ?? _categoryActions[type.category] ?? [];
  }

  /// Get action cards for a specific category.
  static List<ActionCard> forCategory(AlertCategory category) {
    return _categoryActions[category] ?? [];
  }

  // ── Type-Specific Actions ────────────────────────────────

  static final Map<AlertType, List<ActionCard>> _typeActions = {
    AlertType.earthquake: [
      const ActionCard(
        title: 'During the Earthquake',
        steps: [
          'DROP to the ground immediately',
          'Take COVER under a sturdy desk or table',
          'HOLD ON until the shaking stops',
          'Stay away from windows and heavy objects',
          'If outdoors, move to an open area',
        ],
        urgency: ActionUrgency.immediate,
      ),
      const ActionCard(
        title: 'After the Earthquake',
        steps: [
          'Check yourself and others for injuries',
          'Be prepared for aftershocks',
          'Do NOT use elevators',
          'Check for gas leaks and structural damage',
          'Listen to emergency broadcasts',
        ],
        urgency: ActionUrgency.followUp,
      ),
    ],
    AlertType.carAccident: [
      const ActionCard(
        title: 'Immediate Response',
        steps: [
          'Turn off the engine if possible',
          'Turn on hazard lights',
          'Check yourself and passengers for injuries',
          'Call emergency services (999/911)',
          'Do NOT move injured persons unless in danger',
          'Move to a safe area if vehicle is in traffic',
        ],
        urgency: ActionUrgency.immediate,
      ),
    ],
    AlertType.airRaid: [
      const ActionCard(
        title: 'Air Raid Protocol',
        steps: [
          'Move to the nearest shelter immediately',
          'Stay away from windows and exterior walls',
          'If no shelter, lie flat in a ditch or low area',
          'Cover your head and neck',
          'Wait for the all-clear signal',
          'Do NOT go outside to look',
        ],
        urgency: ActionUrgency.immediate,
      ),
    ],
    AlertType.missileStrike: [
      const ActionCard(
        title: 'Missile Alert Protocol',
        steps: [
          'Seek shelter in the lowest floor or basement',
          'Stay away from windows completely',
          'If caught outside, lie flat face down',
          'Cover head with hands',
          'Stay sheltered for at least 15 minutes after the last impact',
        ],
        urgency: ActionUrgency.immediate,
      ),
    ],
  };

  // ── Category-Level Fallback Actions ──────────────────────

  static final Map<AlertCategory, List<ActionCard>> _categoryActions = {
    AlertCategory.naturalDisaster: [
      const ActionCard(
        title: 'General Disaster Response',
        steps: [
          'Stay calm and assess the situation',
          'Move to higher ground if flooding',
          'Secure yourself against falling debris',
          'Have emergency kit ready (water, flashlight, documents)',
          'Follow official evacuation orders',
          'Check on vulnerable neighbors after the event',
        ],
        urgency: ActionUrgency.immediate,
      ),
    ],
    AlertCategory.weatherEmergency: [
      const ActionCard(
        title: 'Severe Weather Safety',
        steps: [
          'Move indoors to a sturdy structure',
          'Stay away from windows and glass doors',
          'Unplug sensitive electronics',
          'Fill bathtub with water for emergency use',
          'Monitor weather updates via radio',
        ],
        urgency: ActionUrgency.immediate,
      ),
    ],
    AlertCategory.healthMedical: [
      const ActionCard(
        title: 'Medical Emergency',
        steps: [
          'Call emergency medical services immediately',
          'Keep the person calm and still',
          'Apply first aid if trained',
          'Do NOT give food or water to unconscious persons',
          'Prepare medical history information for responders',
        ],
        urgency: ActionUrgency.immediate,
      ),
    ],
    AlertCategory.personalSafety: [
      const ActionCard(
        title: 'Personal Safety Threat',
        steps: [
          'Move to a safe, populated area',
          'Call emergency services or trusted contact',
          'Do NOT confront the threat',
          'Use SOS feature to alert emergency contacts',
          'Document details if safe to do so',
        ],
        urgency: ActionUrgency.immediate,
      ),
    ],
    AlertCategory.militaryDefense: [
      const ActionCard(
        title: 'Military Threat Response',
        steps: [
          'Seek shelter immediately — basement or interior room',
          'Stay away from windows and exterior walls',
          'Turn off gas and electricity if possible',
          'Keep radio on for official updates',
          'Do NOT use elevators',
          'Stay sheltered until official all-clear',
        ],
        urgency: ActionUrgency.immediate,
      ),
    ],
    AlertCategory.infrastructure: [
      const ActionCard(
        title: 'Infrastructure Emergency',
        steps: [
          'Evacuate the area if structure is unstable',
          'Do NOT use elevators',
          'Call emergency services',
          'Report gas leaks or downed power lines',
          'Move upwind from any chemical release',
        ],
        urgency: ActionUrgency.immediate,
      ),
    ],
    AlertCategory.digitalCyber: [
      const ActionCard(
        title: 'Cyber Threat Response',
        steps: [
          'Disconnect affected devices from the internet',
          'Change passwords for critical accounts',
          'Enable two-factor authentication',
          'Report the incident to authorities',
          'Monitor accounts for unauthorized activity',
        ],
        urgency: ActionUrgency.followUp,
      ),
    ],
  };
}

/// A single actionable instruction card.
class ActionCard {
  const ActionCard({
    required this.title,
    required this.steps,
    required this.urgency,
  });

  final String title;
  final List<String> steps;
  final ActionUrgency urgency;
}

/// How urgently the action should be taken.
enum ActionUrgency {
  /// Do this RIGHT NOW.
  immediate,

  /// Do this after the immediate danger has passed.
  followUp,

  /// Preparation for future events.
  preparatory,
}
