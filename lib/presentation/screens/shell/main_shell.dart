import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../blocs/alerts/alerts_cubit.dart';
import '../../blocs/alerts/alerts_state.dart';
import '../../widgets/safora_nav_icons.dart';

/// The height of the floating navigation bar itself.
const double kNavBarHeight = 64;

/// The total bottom inset (nav bar + margin + safe area) that child screens
/// should use for padding / FAB spacing so nothing is hidden.
double saforaBottomInset(BuildContext context) {
  final safeBottom = MediaQuery.of(context).padding.bottom;
  // 16 padding below bar + bar height + 12 above bar
  return kNavBarHeight + safeBottom + 28;
}

/// Shell widget with a premium floating glassmorphism bottom navigation bar.
/// Five branches: Home, Alerts, Contacts, Map, More.
class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with TickerProviderStateMixin {
  late final AnimationController _springController;
  late final Animation<double> _springAnimation;

  @override
  void initState() {
    super.initState();
    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _springAnimation = CurvedAnimation(
      parent: _springController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _springController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (index != widget.navigationShell.currentIndex) {
      _springController.forward(from: 0.0);
    }
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: widget.navigationShell,
      bottomNavigationBar: _PremiumNavBar(
        currentIndex: widget.navigationShell.currentIndex,
        onTap: _onTabTapped,
        springAnimation: _springAnimation,
      ),
    );
  }
}

// ===================================================================
// Premium Floating Glassmorphism Navigation Bar
// ===================================================================

class _PremiumNavBar extends StatelessWidget {
  const _PremiumNavBar({
    required this.currentIndex,
    required this.onTap,
    required this.springAnimation,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final Animation<double> springAnimation;

  static const _items = [
    _NavItem(type: SaforaNavIconType.home, label: 'Home'),
    _NavItem(type: SaforaNavIconType.alerts, label: 'Alerts', hasBadge: true),
    _NavItem(type: SaforaNavIconType.contacts, label: 'Contacts'),
    _NavItem(type: SaforaNavIconType.map, label: 'Map'),
    _NavItem(type: SaforaNavIconType.more, label: 'More'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      // Outer padding for the floating effect.
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: bottomPadding + 10,
      ),
      child: Container(
        height: kNavBarHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          // Multi-layer shadow for depth.
          boxShadow: [
            // Primary ambient shadow
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.5)
                  : Colors.black.withValues(alpha: 0.08),
              blurRadius: 32,
              offset: const Offset(0, 12),
              spreadRadius: -4,
            ),
            // Accent glow under the bar
            BoxShadow(
              color: AppColors.primary.withValues(alpha: isDark ? 0.08 : 0.05),
              blurRadius: 48,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
            child: Container(
              decoration: BoxDecoration(
                // Layered gradient for depth — top-light to bottom-heavy.
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? [
                          const Color(0xFF1E2128).withValues(alpha: 0.92),
                          const Color(0xFF15171C).withValues(alpha: 0.96),
                        ]
                      : [
                          Colors.white.withValues(alpha: 0.92),
                          const Color(0xFFF8F9FB).withValues(alpha: 0.96),
                        ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.07)
                      : Colors.black.withValues(alpha: 0.04),
                  width: 0.5,
                ),
              ),
              child: Row(
                children: List.generate(_items.length, (index) {
                  final item = _items[index];
                  final isSelected = index == currentIndex;

                  return Expanded(
                    child: _PremiumNavItem(
                      item: item,
                      isSelected: isSelected,
                      onTap: () => onTap(index),
                      springAnimation: springAnimation,
                      isDark: isDark,
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ===================================================================
// Individual Nav Item with Pill Indicator
// ===================================================================

class _PremiumNavItem extends StatelessWidget {
  const _PremiumNavItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.springAnimation,
    required this.isDark,
  });

  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final Animation<double> springAnimation;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    const activeColor = AppColors.primary;
    final inactiveColor =
        isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF);
    final color = isSelected ? activeColor : inactiveColor;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SaforaAnimatedBuilder(
        animation: springAnimation,
        builder: (context, child) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ─── Active Indicator Dot ────────────────────
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                width: isSelected ? 20 : 0,
                height: 3,
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: isSelected ? activeColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: activeColor.withValues(alpha: 0.4),
                            blurRadius: 8,
                            spreadRadius: 0,
                          ),
                        ]
                      : null,
                ),
              ),
              // ─── Icon with Badge ─────────────────────────
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(
                        scale: animation,
                        child: child,
                      );
                    },
                    child: SaforaNavIcon(
                      key: ValueKey('${item.label}_$isSelected'),
                      type: item.type,
                      isActive: isSelected,
                      color: color,
                      size: isSelected ? 22 : 20,
                    ),
                  ),
                  if (item.hasBadge) _AlertBadge(isSelected: isSelected),
                ],
              ),
              const SizedBox(height: 4),
              // ─── Label ───────────────────────────────────
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontFamily: AppTypography.labelSmall.fontFamily,
                  color: color,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: isSelected ? 10 : 9,
                  letterSpacing: isSelected ? 0.3 : 0,
                  height: 1,
                ),
                child: Text(item.label),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ===================================================================
// Alert Badge
// ===================================================================

class _AlertBadge extends StatelessWidget {
  const _AlertBadge({required this.isSelected});

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AlertsCubit, AlertsState>(
      builder: (context, state) {
        final count = state is AlertsLoaded ? state.alerts.length : 0;
        if (count == 0) return const SizedBox.shrink();

        return Positioned(
          right: -8,
          top: -6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.6),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                  blurRadius: 6,
                  spreadRadius: 0,
                ),
              ],
            ),
            constraints: const BoxConstraints(
              minWidth: 18,
              minHeight: 14,
            ),
            child: Text(
              count > 99 ? '99+' : '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }
}

// ===================================================================
// Data Model
// ===================================================================

class _NavItem {
  const _NavItem({
    required this.type,
    required this.label,
    this.hasBadge = false,
  });

  final SaforaNavIconType type;
  final String label;
  final bool hasBadge;
}

/// Bridge for SaforaAnimatedBuilder to accept named [animation] parameter.
class SaforaAnimatedBuilder extends AnimatedWidget {
  const SaforaAnimatedBuilder({
    super.key,
    required Animation<double> animation,
    required this.builder,
  }) : super(listenable: animation);

  final Widget Function(BuildContext context, Widget? child) builder;

  @override
  Widget build(BuildContext context) => builder(context, null);
}
