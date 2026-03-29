import 'package:flutter/material.dart';
import '../../../core/services/app_logger.dart';
import '../../../core/services/premium_manager.dart';
import '../../../core/services/subscription_service.dart';
import '../../../core/theme/colors.dart';
import '../../../injection.dart';

/// Custom-branded Safora Pro paywall screen.
///
/// Fully custom design matching Safora's branding.
/// Uses RevenueCat SDK for purchase logic only — no native paywall UI.
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen>
    with SingleTickerProviderStateMixin {
  bool _isPurchasing = false;
  bool _isRestoring = false;
  String? _errorMessage;
  int _selectedPlanIndex = 1; // Default to yearly (best value)

  late AnimationController _shieldController;
  late Animation<double> _shieldPulse;

  @override
  void initState() {
    super.initState();
    _shieldController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _shieldPulse = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _shieldController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _shieldController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Gradient Header ───────────────────────────────
          SliverToBoxAdapter(child: _buildHeader(isDark)),

          // ── Feature Comparison ────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: _buildFeatureComparison(theme, isDark),
            ),
          ),

          // ── Plan Selection ────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: _buildPlanSelection(theme, isDark),
            ),
          ),

          // ── Error Message ─────────────────────────────────
          if (_errorMessage != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _buildErrorBanner(),
              ),
            ),

          // ── Purchase Button ───────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: _buildPurchaseButton(theme),
            ),
          ),

          // ── Restore + Legal ───────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              child: _buildFooter(theme),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ── Header with Shield Icon ───────────────────────────────
  // ═══════════════════════════════════════════════════════════

  Widget _buildHeader(bool isDark) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [AppColors.primaryDark, const Color(0xFF1A1A2E)]
              : [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Back button
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 4, top: 4),
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Animated shield
            ScaleTransition(
              scale: _shieldPulse,
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.verified_user,
                  size: 48,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              'Safora Pro',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),

            const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Complete safety protection for you and your family',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 15,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ── Feature Comparison ────────────────────────────────────
  // ═══════════════════════════════════════════════════════════

  Widget _buildFeatureComparison(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What you get with Pro',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? AppColors.darkSurfaceVariant
                  : AppColors.primary.withValues(alpha: 0.12),
            ),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Column(
            children: [
              _featureRow(
                Icons.group,
                'Unlimited Emergency Contacts',
                'Free: 3 contacts',
                true,
              ),
              _divider(isDark),
              _featureRow(
                Icons.car_crash,
                'Crash & Fall Detection',
                'Auto-detect accidents',
                true,
              ),
              _divider(isDark),
              _featureRow(
                Icons.pan_tool,
                'Snatch Detection',
                'Phone grab alerts',
                true,
              ),
              _divider(isDark),
              _featureRow(Icons.speed, 'Speed Alerts', 'Driving safety', true),
              _divider(isDark),
              _featureRow(
                Icons.fence,
                'Geofence Zones',
                'Area monitoring',
                true,
              ),
              _divider(isDark),
              _featureRow(
                Icons.timer,
                'Dead Man\'s Switch',
                'Timed check-ins',
                true,
              ),
              _divider(isDark),
              _featureRow(
                Icons.history,
                'Full SOS History',
                'Complete activity log',
                true,
              ),
              _divider(isDark),
              _featureRow(
                Icons.block,
                'Ad-Free Experience',
                'No interruptions',
                true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _featureRow(IconData icon, String title, String subtitle, bool isPro) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle, size: 20, color: AppColors.success),
        ],
      ),
    );
  }

  Widget _divider(bool isDark) {
    return Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
      color: isDark
          ? AppColors.darkSurfaceVariant
          : Colors.grey.withValues(alpha: 0.15),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ── Plan Selection Cards ──────────────────────────────────
  // ═══════════════════════════════════════════════════════════

  Widget _buildPlanSelection(ThemeData theme, bool isDark) {
    final plans = <_PlanData>[
      _PlanData(
        title: 'Monthly',
        price: getIt<SubscriptionService>().monthlyPriceString ?? '--',
        period: '/month',
        badge: null,
      ),
      _PlanData(
        title: 'Yearly',
        price: getIt<SubscriptionService>().yearlyPriceString ?? '--',
        period: '/year',
        badge: 'Best Value',
      ),
      _PlanData(
        title: 'Lifetime',
        price: getIt<SubscriptionService>().lifetimePriceString ?? '--',
        period: 'one-time',
        badge: 'Pay Once',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose your plan',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(plans.length, (i) {
          final plan = plans[i];
          final isSelected = _selectedPlanIndex == i;

          return Padding(
            padding: EdgeInsets.only(bottom: i < plans.length - 1 ? 10 : 0),
            child: _buildPlanCard(plan, isSelected, isDark, () {
              setState(() => _selectedPlanIndex = i);
            }),
          );
        }),
      ],
    );
  }

  Widget _buildPlanCard(
    _PlanData plan,
    bool isSelected,
    bool isDark,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : AppColors.primary.withValues(alpha: 0.06))
              : (isDark ? AppColors.darkSurface : AppColors.surface),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark
                      ? AppColors.darkSurfaceVariant
                      : Colors.grey.withValues(alpha: 0.25)),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Radio indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  width: 2,
                ),
                color: isSelected ? AppColors.primary : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),

            const SizedBox(width: 14),

            // Plan info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        plan.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: isSelected ? AppColors.primary : null,
                        ),
                      ),
                      if (plan.badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            plan.badge!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Price
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  plan.price,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: isSelected ? AppColors.primary : null,
                  ),
                ),
                Text(
                  plan.period,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ── Error Banner ──────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 18, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(color: AppColors.error, fontSize: 13),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _errorMessage = null),
            child: Icon(Icons.close, size: 16, color: AppColors.error),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ── Purchase Button ───────────────────────────────────────
  // ═══════════════════════════════════════════════════════════

  Widget _buildPurchaseButton(ThemeData theme) {
    final planLabels = ['Monthly', 'Yearly', 'Lifetime'];

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton.icon(
        onPressed: _isPurchasing ? null : _handlePurchase,
        icon: _isPurchasing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.verified_user, size: 20),
        label: Text(
          _isPurchasing
              ? 'Processing...'
              : 'Get ${planLabels[_selectedPlanIndex]} Pro',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ── Footer ────────────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════

  Widget _buildFooter(ThemeData theme) {
    return Column(
      children: [
        const SizedBox(height: 4),
        TextButton.icon(
          onPressed: _isRestoring ? null : _handleRestore,
          icon: _isRestoring
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh, size: 16),
          label: Text(
            _isRestoring ? 'Restoring...' : 'Restore Purchases',
            style: const TextStyle(fontSize: 13),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Subscriptions auto-renew unless cancelled at least 24 hours'
          ' before the end of the current period. Cancel anytime in'
          ' Google Play Store settings.',
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ── Purchase Logic ────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════

  Future<void> _handlePurchase() async {
    final purchaseFns = [
      getIt<SubscriptionService>().purchaseMonthly,
      getIt<SubscriptionService>().purchaseYearly,
      getIt<SubscriptionService>().purchaseLifetime,
    ];

    setState(() {
      _isPurchasing = true;
      _errorMessage = null;
    });

    try {
      final success = await purchaseFns[_selectedPlanIndex]();

      if (mounted) {
        if (success) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text('Welcome to Safora Pro!'),
                ],
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        } else {
          setState(() => _isPurchasing = false);
        }
      }
    } catch (e) {
      AppLogger.warning('[Paywall] Purchase error: $e');
      if (mounted) {
        setState(() {
          _isPurchasing = false;
          _errorMessage = 'Purchase failed. Please try again.';
        });
      }
    }
  }

  Future<void> _handleRestore() async {
    setState(() {
      _isRestoring = true;
      _errorMessage = null;
    });

    try {
      final restored = await getIt<SubscriptionService>().restorePurchases();

      if (mounted) {
        if (restored) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text('Pro subscription restored!'),
                ],
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        } else {
          setState(() {
            _isRestoring = false;
            _errorMessage = 'No active subscription found.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRestoring = false;
          _errorMessage = 'Restore failed. Please try again.';
        });
      }
    }
  }
}

/// Internal data model for plan display.
class _PlanData {
  final String title;
  final String price;
  final String period;
  final String? badge;

  const _PlanData({
    required this.title,
    required this.price,
    required this.period,
    required this.badge,
  });
}
