import 'package:safora/presentation/widgets/safora_toast.dart';
// dart:ui import removed — BackdropFilter was removed for performance reasons.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/alert_types.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../data/models/alert_preferences.dart';
import '../../blocs/alert_preferences/alert_preferences_cubit.dart';

/// Premium alert preferences screen with enterprise-grade UX.
///
/// Features:
/// - Gradient header with enabled-count progress ring
/// - Real-time search across 127 alert types
/// - Glassmorphism category cards with master toggles
/// - Priority-coded alert tiles with styled switches
/// - "Enable All Free" quick action
class AlertPreferencesScreen extends StatefulWidget {
  const AlertPreferencesScreen({super.key});

  @override
  State<AlertPreferencesScreen> createState() => _AlertPreferencesScreenState();
}

class _AlertPreferencesScreenState extends State<AlertPreferencesScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: BlocConsumer<AlertPreferencesCubit, AlertPreferencesState>(
        listener: (context, state) {
          if (state.permissionDeniedMessage != null) {
            SaforaToast.showError(context, state.permissionDeniedMessage!);
          }
          if (state.successMessage != null) {
            SaforaToast.showSuccess(context, state.successMessage!);
          }
          if (state.infoMessage != null) {
            SaforaToast.showInfo(context, state.infoMessage!);
          }
        },
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final grouped = _filterAndGroup(state);
          final categories = grouped.keys.toList();

          return CustomScrollView(
            slivers: [
              _PremiumHeader(
                enabledCount: state.enabledCount,
                totalCount: state.totalCount,
                isDark: isDark,
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: _SearchBar(
                    controller: _searchController,
                    isDark: isDark,
                    onChanged: (q) => setState(() => _searchQuery = q),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: _QuickActions(isDark: isDark),
              ),

              SliverToBoxAdapter(
                child: _SeverityThresholdSelector(isDark: isDark),
              ),

              if (categories.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off_rounded,
                            size: 48,
                            color: isDark
                                ? AppColors.textDisabled
                                : AppColors.textSecondary),
                        const SizedBox(height: 12),
                        Text(
                          'No alerts match "$_searchQuery"',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final category = categories[index];
                      final alerts = grouped[category]!;
                      final enabledInCategory =
                          alerts.where((a) => a.enabled).length;

                      return _PremiumCategoryCard(
                        category: category,
                        alerts: alerts,
                        enabledCount: enabledInCategory,
                        isDark: isDark,
                      );
                    },
                    childCount: categories.length,
                  ),
                ),

              // Bottom padding for floating nav bar
              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          );
        },
      ),
    );
  }

  /// Filter alert types by search query, then group by category.
  Map<AlertCategory, List<AlertTypeStatus>> _filterAndGroup(
      AlertPreferencesState state) {
    final grouped = state.groupedByCategory;
    if (_searchQuery.isEmpty) return grouped;

    final query = _searchQuery.toLowerCase();
    final filtered = <AlertCategory, List<AlertTypeStatus>>{};
    for (final entry in grouped.entries) {
      final matches = entry.value
          .where((a) => a.type.label.toLowerCase().contains(query))
          .toList();
      if (matches.isNotEmpty) {
        filtered[entry.key] = matches;
      }
    }
    return filtered;
  }
}

// Premium Gradient Header with Progress Ring

class _PremiumHeader extends StatelessWidget {
  const _PremiumHeader({
    required this.enabledCount,
    required this.totalCount,
    required this.isDark,
  });

  final int enabledCount;
  final int totalCount;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final progress = totalCount > 0 ? enabledCount / totalCount : 0.0;

    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      stretch: true,
      backgroundColor: isDark
          ? const Color(0xFF1A1D24)
          : AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF1A1D24), const Color(0xFF2C1F1F)]
                  : [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
              child: Row(
                children: [
                  // Progress Ring
                  SizedBox(
                    width: 72,
                    height: 72,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 72,
                          height: 72,
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 5,
                            backgroundColor: Colors.white.withValues(alpha: 0.15),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white),
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$enabledCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'of $totalCount',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Title + Subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Alert Preferences',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Control which alerts you receive.\nToggle categories or individual alerts.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Search Bar

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.isDark,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool isDark;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceVariant : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: AppTypography.bodyMedium.copyWith(
          color: isDark ? AppColors.darkOnSurface : AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: 'Search 127 alert types...',
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: AppColors.textDisabled,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.textSecondary,
            size: 20,
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

// Quick Actions Row

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AlertPreferencesCubit>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          _QuickActionChip(
            label: 'Enable All Free',
            icon: Icons.check_circle_outline_rounded,
            color: AppColors.success,
            isDark: isDark,
            onTap: () => cubit.enableAllFree(),
          ),
          const SizedBox(width: 8),
          BlocBuilder<AlertPreferencesCubit, AlertPreferencesState>(
            builder: (context, state) {
              final freeEnabled = AlertType.values
                  .where((t) => t.isFree)
                  .where((t) => state.preferences[t] == true)
                  .length;
              final totalFree =
                  AlertType.values.where((t) => t.isFree).length;
              return Text(
                '$freeEnabled/$totalFree free enabled',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  const _QuickActionChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: isDark ? 0.15 : 0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Severity Threshold Selector

class _SeverityThresholdSelector extends StatelessWidget {
  const _SeverityThresholdSelector({required this.isDark});

  final bool isDark;

  static const _labels = ['Info', 'Advisory', 'Warning', 'Danger', 'Critical'];
  static const _severityIcons = [Icons.info_outline_rounded, Icons.assignment_outlined, Icons.warning_amber_rounded, Icons.local_fire_department_rounded, Icons.crisis_alert_rounded];
  static const _descriptions = [
    'Receive all alerts including informational updates',
    'Skip informational, show advisory and above',
    'Only warnings, danger, and critical alerts',
    'Only dangerous and critical emergencies',
    'Only life-threatening critical alerts',
  ];

  Color _sliderColor(int idx) {
    return switch (idx) {
      0 => AppColors.textSecondary,
      1 => AppColors.info,
      2 => AppColors.warning,
      3 => AppColors.high,
      _ => AppColors.danger,
    };
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AlertPreferencesCubit, AlertPreferencesState>(
      builder: (context, state) {
        final cubit = context.read<AlertPreferencesCubit>();
        final currentIdx =
            AlertPreferences.priorityLevels.indexOf(state.severityThreshold);
        final color = _sliderColor(currentIdx);

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceVariant.withValues(alpha: 0.7)
                  : Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : color.withValues(alpha: 0.15),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            color.withValues(alpha: 0.2),
                            color.withValues(alpha: 0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.tune_rounded, color: color, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Minimum Severity',
                            style: AppTypography.titleSmall.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _labels[currentIdx],
                            style: AppTypography.labelMedium.copyWith(
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Step slider
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: color,
                    inactiveTrackColor: color.withValues(alpha: 0.15),
                    thumbColor: color,
                    overlayColor: color.withValues(alpha: 0.12),
                    trackHeight: 4,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 8),
                  ),
                  child: Slider(
                    value: currentIdx.toDouble(),
                    min: 0,
                    max: 4,
                    divisions: 4,
                    onChanged: (val) {
                      cubit.setSeverity(
                          AlertPreferences.priorityLevels[val.round()]);
                    },
                  ),
                ),
                // Labels row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(5, (i) {
                      final isActive = i == currentIdx;
                      return Icon(
                        _severityIcons[i],
                        size: isActive ? 20 : 14,
                        color: isActive
                            ? _sliderColor(i)
                            : AppColors.textDisabled,
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _descriptions[currentIdx],
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Premium Category Card with Glassmorphism

class _PremiumCategoryCard extends StatefulWidget {
  const _PremiumCategoryCard({
    required this.category,
    required this.alerts,
    required this.enabledCount,
    required this.isDark,
  });

  final AlertCategory category;
  final List<AlertTypeStatus> alerts;
  final int enabledCount;
  final bool isDark;

  @override
  State<_PremiumCategoryCard> createState() => _PremiumCategoryCardState();
}

class _PremiumCategoryCardState extends State<_PremiumCategoryCard> {
  bool _expanded = false;

  IconData _categoryIcon(AlertCategory cat) {
    return switch (cat) {
      AlertCategory.healthMedical => Icons.local_hospital_rounded,
      AlertCategory.vehicleTransport => Icons.directions_car_rounded,
      AlertCategory.naturalDisaster => Icons.public_rounded,
      AlertCategory.weatherEmergency => Icons.thunderstorm_rounded,
      AlertCategory.personalSafety => Icons.shield_rounded,
      AlertCategory.homeDomestic => Icons.home_rounded,
      AlertCategory.workplace => Icons.work_rounded,
      AlertCategory.waterMarine => Icons.water_rounded,
      AlertCategory.travelOutdoor => Icons.hiking_rounded,
      AlertCategory.environmentalChemical => Icons.science_rounded,
      AlertCategory.digitalCyber => Icons.security_rounded,
      AlertCategory.childElder => Icons.family_restroom_rounded,
      AlertCategory.militaryDefense => Icons.military_tech_rounded,
      AlertCategory.infrastructure => Icons.construction_rounded,
      AlertCategory.spaceAstronomical => Icons.rocket_launch_rounded,
      AlertCategory.maritimeAviation => Icons.flight_rounded,
    };
  }

  Color _categoryColor(AlertCategory cat) {
    return switch (cat) {
      AlertCategory.healthMedical => const Color(0xFFEF5350),
      AlertCategory.vehicleTransport => const Color(0xFF78909C),
      AlertCategory.naturalDisaster => const Color(0xFFFF8F00),
      AlertCategory.weatherEmergency => const Color(0xFF42A5F5),
      AlertCategory.personalSafety => const Color(0xFF7E57C2),
      AlertCategory.homeDomestic => const Color(0xFFFFB74D),
      AlertCategory.workplace => const Color(0xFF66BB6A),
      AlertCategory.waterMarine => const Color(0xFF29B6F6),
      AlertCategory.travelOutdoor => const Color(0xFF8D6E63),
      AlertCategory.environmentalChemical => const Color(0xFFFF7043),
      AlertCategory.digitalCyber => const Color(0xFF26C6DA),
      AlertCategory.childElder => const Color(0xFFEC407A),
      AlertCategory.militaryDefense => const Color(0xFF5C6BC0),
      AlertCategory.infrastructure => const Color(0xFFBDBDBD),
      AlertCategory.spaceAstronomical => const Color(0xFF9575CD),
      AlertCategory.maritimeAviation => const Color(0xFF4FC3F7),
    };
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AlertPreferencesCubit>();
    final allEnabled = widget.enabledCount == widget.alerts.length;
    final catColor = _categoryColor(widget.category);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        // NOTE: BackdropFilter removed — stacking 16 blur passes (one per
        // category card) caused severe GPU overload on mid-range devices,
        // presenting as a dim/frozen UI. Plain Container is used instead.
        child: Container(
          decoration: BoxDecoration(
            color: widget.isDark
                ? AppColors.darkSurfaceVariant.withValues(alpha: 0.7)
                : Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: widget.isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : catColor.withValues(alpha: 0.12),
            ),
            boxShadow: [
              BoxShadow(
                color: widget.isDark
                    ? Colors.black.withValues(alpha: 0.2)
                    : catColor.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => setState(() => _expanded = !_expanded),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Category Icon with colored circle
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                catColor.withValues(alpha: 0.2),
                                catColor.withValues(alpha: 0.08),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _categoryIcon(widget.category),
                            color: catColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Category Label + Count
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.category.label,
                                style: AppTypography.titleSmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  // Mini progress bar
                                  SizedBox(
                                    width: 40,
                                    height: 3,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: widget.alerts.isNotEmpty
                                            ? widget.enabledCount /
                                                widget.alerts.length
                                            : 0,
                                        backgroundColor: catColor
                                            .withValues(alpha: 0.12),
                                        valueColor: AlwaysStoppedAnimation(
                                            catColor),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${widget.enabledCount}/${widget.alerts.length}',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Master toggle
                        Transform.scale(
                          scale: 0.85,
                          child: Switch.adaptive(
                            value: allEnabled,
                            onChanged: (_) {
                              if (allEnabled) {
                                cubit.disableCategory(widget.category);
                              } else {
                                cubit.enableCategory(widget.category);
                              }
                            },
                            activeTrackColor: catColor,
                          ),
                        ),
                        // Expand chevron
                        AnimatedRotation(
                          turns: _expanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: const Icon(
                            Icons.expand_more_rounded,
                            color: AppColors.textSecondary,
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Column(
                  children: [
                    Divider(
                      height: 1,
                      color: widget.isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.04),
                    ),
                    ...widget.alerts.map((alertStatus) {
                      return _PremiumAlertTile(
                        alertStatus: alertStatus,
                        catColor: catColor,
                        isDark: widget.isDark,
                      );
                    }),
                  ],
                ),
                crossFadeState: _expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 250),
                sizeCurve: Curves.easeOutCubic,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Premium Alert Toggle Tile

class _PremiumAlertTile extends StatelessWidget {
  const _PremiumAlertTile({
    required this.alertStatus,
    required this.catColor,
    required this.isDark,
  });

  final AlertTypeStatus alertStatus;
  final Color catColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AlertPreferencesCubit>();
    final type = alertStatus.type;
    final priorityColor = _priorityColor(type.priority);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: priorityColor.withValues(alpha: 0.6),
            width: 3,
          ),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: 20, right: 12),
        dense: true,
        title: Row(
          children: [
            Expanded(
              child: Text(
                type.label,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight:
                      alertStatus.enabled ? FontWeight.w600 : FontWeight.w400,
                  color: alertStatus.enabled
                      ? (isDark ? AppColors.darkOnSurface : AppColors.textPrimary)
                      : AppColors.textSecondary,
                ),
              ),
            ),
            // Free/Premium badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: type.isFree
                    ? AppColors.success.withValues(alpha: isDark ? 0.2 : 0.1)
                    : AppColors.accent.withValues(alpha: isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                type.isFree ? 'FREE' : 'PRO',
                style: AppTypography.labelSmall.copyWith(
                  color: type.isFree ? AppColors.success : AppColors.accent,
                  fontWeight: FontWeight.w800,
                  fontSize: 9,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        subtitle: Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: priorityColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              _priorityLabel(type.priority),
              style: AppTypography.labelSmall.copyWith(
                color: priorityColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: Transform.scale(
          scale: 0.8,
          child: Switch.adaptive(
            value: alertStatus.enabled,
            onChanged: (_) => cubit.toggleAlert(type),
            activeTrackColor: catColor,
          ),
        ),
      ),
    );
  }

  String _priorityLabel(AlertPriority p) {
    return switch (p) {
      AlertPriority.critical => 'Critical',
      AlertPriority.danger => 'Danger',
      AlertPriority.warning => 'Warning',
      AlertPriority.advisory => 'Advisory',
      AlertPriority.info => 'Info',
    };
  }

  Color _priorityColor(AlertPriority p) {
    return switch (p) {
      AlertPriority.critical => AppColors.danger,
      AlertPriority.danger => AppColors.high,
      AlertPriority.warning => AppColors.warning,
      AlertPriority.advisory => AppColors.info,
      AlertPriority.info => AppColors.textSecondary,
    };
  }
}
