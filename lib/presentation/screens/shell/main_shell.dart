import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../blocs/alerts/alerts_cubit.dart';
import '../../blocs/alerts/alerts_state.dart';
import '../../widgets/safora_nav_icons.dart';

/// Shell widget with a premium curved, floating glassmorphism bottom
/// navigation bar. Five branches: Home, Alerts, Contacts, Map, More.
/// Uses custom Safora-branded vector icons instead of Material icons.
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
      bottomNavigationBar: _FloatingNavBar(
        currentIndex: widget.navigationShell.currentIndex,
        onTap: _onTabTapped,
        springAnimation: _springAnimation,
      ),
    );
  }
}

// ===================================================================
// Floating Glassmorphism Navigation Bar
// ===================================================================

class _FloatingNavBar extends StatelessWidget {
  const _FloatingNavBar({
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

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: bottomPadding + 8,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: 68,
            decoration: BoxDecoration(
              // Glassmorphism: translucent with blur.
              color: isDark
                  ? const Color(0xFF1A1D24).withValues(alpha: 0.88)
                  : Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.4)
                      : Colors.black.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                  spreadRadius: -2,
                ),
                if (!isDark)
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    blurRadius: 40,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(_items.length, (index) {
                final item = _items[index];
                final isSelected = index == currentIndex;

                return Expanded(
                  child: _CurvedNavItem(
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
    );
  }
}

// ===================================================================
// Individual Nav Item with Capsule Indicator
// ===================================================================

class _CurvedNavItem extends StatelessWidget {
  const _CurvedNavItem({
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
        isDark ? AppColors.textDisabled : AppColors.textSecondary;
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
              // Animated Capsule Background
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.symmetric(
                  horizontal: isSelected ? 14 : 10,
                  vertical: isSelected ? 6 : 4,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? activeColor.withValues(alpha: isDark ? 0.18 : 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Custom Safora branded icon
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
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
                        size: isSelected ? 24 : 22,
                      ),
                    ),
                    if (item.hasBadge)
                      _AlertBadge(isSelected: isSelected),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              // Animated Label
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                style: AppTypography.labelSmall.copyWith(
                  color: color,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: isSelected ? 10.5 : 9.5,
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
          right: -6,
          top: -4,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.critical,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.3)
                    : Colors.transparent,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.critical.withValues(alpha: 0.4),
                  blurRadius: 4,
                  spreadRadius: 0,
                ),
              ],
            ),
            constraints: const BoxConstraints(
              minWidth: 16,
              minHeight: 14,
            ),
            child: Text(
              count > 99 ? '99+' : '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w700,
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
