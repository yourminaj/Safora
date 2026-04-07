
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../data/repositories/contacts_repository.dart';
import '../../../injection.dart';
import '../../widgets/safora_animated_icons.dart';

/// Emergency Center — the command hub for all emergency actions.
///
/// Features:
/// • One-tap SOS (triggers countdown + alert)
/// • Share Live Location
/// • Call Emergency Contacts (quick dial list)
/// • Nearest Safe Places (police, hospital, fire station)
/// • First Aid Steps (essential procedures)
/// • Offline Survival Instructions
class EmergencyCenterScreen extends StatelessWidget {
  const EmergencyCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: const Text('Emergency Center'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SosBanner(isDark: isDark),
            const SizedBox(height: 24),

            const _SectionLabel(text: 'QUICK ACTIONS'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ActionCard(
                    icon: const SaforaLiveLocationIcon(size: 36, animated: true, color: Colors.white),
                    title: 'Share Location',
                    subtitle: 'Send live GPS to contacts',
                    gradientColors: const [Color(0xFF43A047), Color(0xFF2E7D32)],
                    onTap: () => _shareLiveLocation(context),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionCard(
                    icon: const SaforaContactsIcon(size: 36, animated: false),
                    title: 'Call Contacts',
                    subtitle: 'Dial emergency contacts',
                    gradientColors: const [Color(0xFF42A5F5), Color(0xFF1565C0)],
                    onTap: () => _showContactsDialer(context),
                    isDark: isDark,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            const _SectionLabel(text: 'SAFETY RESOURCES'),
            const SizedBox(height: 12),

            _ResourceTile(
              icon: const SaforaSafePlaceIcon(size: 44, animated: true),
              title: 'Nearest Safe Places',
              subtitle: 'Find police stations, hospitals, fire stations nearby',
              color: const Color(0xFF5C6BC0),
              onTap: () => _showNearestSafePlaces(context),
              isDark: isDark,
            ),
            const SizedBox(height: 10),
            _ResourceTile(
              icon: const SaforaFirstAidIcon(size: 44, animated: true),
              title: 'First Aid Guide',
              subtitle: 'CPR, burns, bleeding, choking — step by step',
              color: const Color(0xFFEF5350),
              onTap: () => _showFirstAidGuide(context),
              isDark: isDark,
            ),
            const SizedBox(height: 10),
            _ResourceTile(
              icon: const SaforaOfflineIcon(size: 44, animated: true),
              title: 'Offline Survival',
              subtitle: 'Essential safety info — works without internet',
              color: const Color(0xFFFFA726),
              onTap: () => _showOfflineSurvival(context),
              isDark: isDark,
            ),

            const SizedBox(height: 24),

            const _SectionLabel(text: 'EMERGENCY NUMBERS'),
            const SizedBox(height: 12),
            _EmergencyNumbersGrid(isDark: isDark),
          ],
        ),
      ),
    );
  }

  void _shareLiveLocation(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _LiveLocationSheet(isDark: Theme.of(ctx).brightness == Brightness.dark),
    );
  }

  void _showContactsDialer(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ContactsDialerSheet(isDark: Theme.of(ctx).brightness == Brightness.dark),
    );
  }

  void _showNearestSafePlaces(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SafePlacesSheet(isDark: Theme.of(ctx).brightness == Brightness.dark),
    );
  }

  void _showFirstAidGuide(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _FirstAidSheet(isDark: Theme.of(ctx).brightness == Brightness.dark),
    );
  }

  void _showOfflineSurvival(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _OfflineSurvivalSheet(isDark: Theme.of(ctx).brightness == Brightness.dark),
    );
  }
}

//  SOS BANNER — Large pulsing emergency button

class _SosBanner extends StatefulWidget {
  const _SosBanner({required this.isDark});
  final bool isDark;

  @override
  State<_SosBanner> createState() => _SosBannerState();
}

class _SosBannerState extends State<_SosBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (context, child) {
        final pulse = 1.0 + 0.03 * _pulseCtrl.value;
        return Transform.scale(
          scale: pulse,
          child: child,
        );
      },
      child: GestureDetector(
        onTap: () {
          HapticFeedback.heavyImpact();
          // Navigate to home SOS flow
          context.go('/home');
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE53935).withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              const SaforaSosIcon(size: 56, animated: true),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ONE-TAP SOS',
                      style: AppTypography.titleLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to alert all emergency contacts with your location',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white.withValues(alpha: 0.7),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//  SECTION LABEL

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.labelSmall.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}

//  ACTION CARD — Compact gradient card for quick actions

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradientColors,
    required this.onTap,
    required this.isDark,
  });

  final Widget icon;
  final String title;
  final String subtitle;
  final List<Color> gradientColors;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(16),
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: gradientColors.first.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              icon,
              const SizedBox(height: 12),
              Text(
                title,
                style: AppTypography.titleSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//  RESOURCE TILE — Full-width tile for safety resources

class _ResourceTile extends StatelessWidget {
  const _ResourceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    required this.isDark,
  });

  final Widget icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(child: icon),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textDisabled,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//  EMERGENCY NUMBERS GRID — Common emergency numbers

class _EmergencyNumbersGrid extends StatelessWidget {
  const _EmergencyNumbersGrid({required this.isDark});
  final bool isDark;

  static const _numbers = [
    _EmNum('Police', '999', Color(0xFF1565C0)),
    _EmNum('Fire', '199', Color(0xFFE53935)),
    _EmNum('Ambulance', '199', Color(0xFF43A047)),
    _EmNum('Women Helpline', '10921', Color(0xFF8E24AA)),
    _EmNum('Child Helpline', '1098', Color(0xFFFFA726)),
    _EmNum('Disaster', '1090', Color(0xFF546E7A)),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.1,
      ),
      itemCount: _numbers.length,
      itemBuilder: (context, index) {
        final n = _numbers[index];
        return Material(
          color: isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: () => _call(n.number),
            borderRadius: BorderRadius.circular(14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: n.color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.phone_rounded, color: n.color, size: 18),
                ),
                const SizedBox(height: 6),
                Text(
                  n.label,
                  style: AppTypography.labelSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  n.number,
                  style: AppTypography.bodySmall.copyWith(
                    color: n.color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _call(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

class _EmNum {
  const _EmNum(this.label, this.number, this.color);
  final String label;
  final String number;
  final Color color;
}

//  BOTTOM SHEETS — Detailed views for each section

class _LiveLocationSheet extends StatelessWidget {
  const _LiveLocationSheet({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return _SheetContainer(
      isDark: isDark,
      title: 'Share Live Location',
      icon: const SaforaLiveLocationIcon(size: 48, animated: true),
      children: [
        Text(
          'Your live location will be shared with all emergency contacts via SMS with a real-time tracking link.',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),
        _SheetAction(
          label: 'Share for 15 minutes',
          color: const Color(0xFF43A047),
          onTap: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Live location shared for 15 minutes'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        _SheetAction(
          label: 'Share for 1 hour',
          color: const Color(0xFF1565C0),
          onTap: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Live location shared for 1 hour'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        _SheetAction(
          label: 'Share until I stop',
          color: const Color(0xFFE53935),
          onTap: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Live location shared continuously'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ContactsDialerSheet extends StatelessWidget {
  const _ContactsDialerSheet({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final repo = getIt<ContactsRepository>();
    final contacts = repo.getAll();

    return _SheetContainer(
      isDark: isDark,
      title: 'Emergency Contacts',
      icon: const SaforaContactsIcon(size: 48, animated: false),
      children: [
        if (contacts.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                const SaforaEmptyState(size: 60),
                const SizedBox(height: 12),
                Text(
                  'No emergency contacts added yet',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.push('/contacts/add');
                  },
                  child: const Text('Add Contact'),
                ),
              ],
            ),
          )
        else
          ...contacts.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    leading: CircleAvatar(
                      backgroundColor: c.isPrimary
                          ? AppColors.primary.withValues(alpha: 0.15)
                          : AppColors.info.withValues(alpha: 0.15),
                      child: Icon(
                        c.isPrimary ? Icons.star_rounded : Icons.person_rounded,
                        color: c.isPrimary ? AppColors.primary : AppColors.info,
                      ),
                    ),
                    title: Text(c.name, style: AppTypography.titleSmall),
                    subtitle: Text(c.phone, style: AppTypography.bodySmall),
                    trailing: IconButton(
                      icon: const Icon(Icons.phone_rounded, color: AppColors.success),
                      onPressed: () async {
                        final uri = Uri.parse('tel:${c.phone}');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      },
                    ),
                  ),
                ),
              )),
      ],
    );
  }
}

class _SafePlacesSheet extends StatelessWidget {
  const _SafePlacesSheet({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return _SheetContainer(
      isDark: isDark,
      title: 'Nearest Safe Places',
      icon: const SaforaSafePlaceIcon(size: 48, animated: true),
      children: [
        Text(
          'Find the closest safe locations near you. Tap to navigate.',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        _SafePlaceCategory(
          label: 'Police Stations',
          icon: Icons.local_police_rounded,
          color: const Color(0xFF1565C0),
          isDark: isDark,
        ),
        _SafePlaceCategory(
          label: 'Hospitals',
          icon: Icons.local_hospital_rounded,
          color: const Color(0xFFE53935),
          isDark: isDark,
        ),
        _SafePlaceCategory(
          label: 'Fire Stations',
          icon: Icons.local_fire_department_rounded,
          color: const Color(0xFFFFA726),
          isDark: isDark,
        ),
        _SafePlaceCategory(
          label: 'Pharmacies',
          icon: Icons.local_pharmacy_rounded,
          color: const Color(0xFF43A047),
          isDark: isDark,
        ),
        _SafePlaceCategory(
          label: 'Shelters',
          icon: Icons.night_shelter_rounded,
          color: const Color(0xFF8E24AA),
          isDark: isDark,
        ),
      ],
    );
  }
}

class _SafePlaceCategory extends StatelessWidget {
  const _SafePlaceCategory({
    required this.label,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          title: Text(label, style: AppTypography.titleSmall),
          trailing: Icon(Icons.map_rounded, color: color, size: 20),
          onTap: () async {
            Navigator.pop(context);
            // Open Google Maps with search
            final query = Uri.encodeComponent('$label near me');
            final uri = Uri.parse('https://www.google.com/maps/search/$query');
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
        ),
      ),
    );
  }
}

class _FirstAidSheet extends StatelessWidget {
  const _FirstAidSheet({required this.isDark});
  final bool isDark;

  static const _guides = [
    _FirstAidTopic('CPR (Cardiopulmonary Resuscitation)', [
      '1. Call emergency services (999/911)',
      '2. Place heel of hand on center of chest',
      '3. Push hard and fast — 100-120 compressions/min',
      '4. Push at least 2 inches deep',
      '5. Allow chest to fully recoil between compressions',
      '6. Give 2 rescue breaths after 30 compressions',
      '7. Continue until help arrives',
    ]),
    _FirstAidTopic('Severe Bleeding', [
      '1. Apply direct pressure with clean cloth',
      '2. Maintain pressure — do NOT remove cloth',
      '3. If blood soaks through, add another layer',
      '4. Elevate the wound above heart level if possible',
      '5. Apply tourniquet as last resort (above wound)',
      '6. Call emergency services immediately',
    ]),
    _FirstAidTopic('Burns', [
      '1. Cool the burn under running water for 20 mins',
      '2. Remove clothing/jewelry near burn (if not stuck)',
      '3. Cover with cling film or clean dressing',
      '4. Do NOT apply ice, butter, or creams',
      '5. Take painkillers if available',
      '6. Seek medical help for serious burns',
    ]),
    _FirstAidTopic('Choking', [
      '1. Encourage coughing if person can still cough',
      '2. Give 5 back blows between shoulder blades',
      '3. Give 5 abdominal thrusts (Heimlich maneuver)',
      '4. Alternate between back blows and thrusts',
      '5. If unconscious, begin CPR immediately',
      '6. Call emergency services',
    ]),
    _FirstAidTopic('Heart Attack Signs', [
      '• Chest pain/pressure/tightness',
      '• Pain spreading to arm, jaw, neck, back',
      '• Shortness of breath',
      '• Nausea, lightheadedness, sweating',
      '→ Call 999/911 immediately',
      '→ Have patient chew aspirin if available',
      '→ Have them sit up and rest',
    ]),
    _FirstAidTopic('Seizure', [
      '1. Clear the area of hard/sharp objects',
      '2. Cushion their head',
      '3. Do NOT hold person down or put anything in mouth',
      '4. Time the seizure',
      '5. Once stopped, roll into recovery position',
      '6. Call 999 if seizure lasts > 5 mins',
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    return _SheetContainer(
      isDark: isDark,
      title: 'First Aid Guide',
      icon: const SaforaFirstAidIcon(size: 48, animated: true),
      children: [
        ..._guides.map((guide) => _FirstAidCard(guide: guide, isDark: isDark)),
      ],
    );
  }
}

class _FirstAidTopic {
  const _FirstAidTopic(this.title, this.steps);
  final String title;
  final List<String> steps;
}

class _FirstAidCard extends StatefulWidget {
  const _FirstAidCard({required this.guide, required this.isDark});
  final _FirstAidTopic guide;
  final bool isDark;

  @override
  State<_FirstAidCard> createState() => _FirstAidCardState();
}

class _FirstAidCardState extends State<_FirstAidCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: widget.isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.medical_services_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.guide.title,
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
                if (_expanded) ...[
                  const SizedBox(height: 10),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  ...widget.guide.steps.map((step) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          step,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      )),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OfflineSurvivalSheet extends StatelessWidget {
  const _OfflineSurvivalSheet({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return _SheetContainer(
      isDark: isDark,
      title: 'Offline Survival Guide',
      icon: const SaforaOfflineIcon(size: 48, animated: true),
      children: [
        _SurvivalSection(
          title: 'Fire Emergency',
          content: '• Stay low — smoke rises\n• Feel doors before opening\n• Use stairs, never elevators\n• Stop, Drop, Roll if clothes catch fire\n• Meet at designated meeting point',
          isDark: isDark,
        ),
        _SurvivalSection(
          title: 'Flood Emergency',
          content: '• Move to higher ground immediately\n• Do NOT walk or drive through flood water\n• 6 inches of water can knock you down\n• 2 feet of water can float a car\n• Stay away from power lines',
          isDark: isDark,
        ),
        _SurvivalSection(
          title: 'Earthquake',
          content: '• DROP, COVER, HOLD ON\n• Get under sturdy furniture\n• Stay away from windows\n• If outside, move to open area\n• After: Check for gas leaks, injuries',
          isDark: isDark,
        ),
        _SurvivalSection(
          title: 'Power Outage',
          content: '• Conserve phone battery\n• Turn off unnecessary apps\n• Use flashlight, not candles\n• Keep refrigerator closed\n• Unplug electronics to prevent surge',
          isDark: isDark,
        ),
        _SurvivalSection(
          title: 'Extreme Cold',
          content: '• Layer clothing loosely\n• Stay dry — wet clothing loses heat fast\n• Watch for frostbite (numbness, white skin)\n• Eat and drink — body needs fuel for warmth\n• If stranded in car: run engine briefly for heat',
          isDark: isDark,
        ),
      ],
    );
  }
}

class _SurvivalSection extends StatelessWidget {
  const _SurvivalSection({
    required this.title,
    required this.content,
    required this.isDark,
  });

  final String title;
  final String content;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//  SHARED SHEET CONTAINER

class _SheetContainer extends StatelessWidget {
  const _SheetContainer({
    required this.isDark,
    required this.title,
    required this.icon,
    required this.children,
  });

  final bool isDark;
  final String title;
  final Widget icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textDisabled.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                icon,
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.headlineSmall.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

//  SHEET ACTION BUTTON

class _SheetAction extends StatelessWidget {
  const _SheetAction({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: AppTypography.titleSmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
