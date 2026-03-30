import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:safora/l10n/app_localizations.dart';
import 'data/models/emergency_contact.dart';
import 'data/models/user_profile.dart';
import 'injection.dart';
import 'presentation/blocs/alerts/alerts_cubit.dart';
import 'presentation/blocs/alert_preferences/alert_preferences_cubit.dart';
import 'presentation/blocs/battery/battery_cubit.dart';
import 'presentation/blocs/contacts/contacts_cubit.dart';
import 'presentation/blocs/profile/profile_cubit.dart';
import 'presentation/blocs/reminders/reminders_cubit.dart';
import 'presentation/blocs/sos/sos_cubit.dart';
import 'presentation/screens/splash/splash_screen.dart';
import 'presentation/screens/settings/sos_history_screen.dart';
import 'presentation/screens/onboarding/onboarding_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/signup_screen.dart';
import 'presentation/screens/auth/verify_email_screen.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/contacts/contacts_screen.dart';
import 'presentation/screens/contacts/add_contact_screen.dart';
import 'presentation/screens/contacts/edit_contact_screen.dart';
import 'presentation/screens/profile/profile_screen.dart';
import 'presentation/screens/profile/edit_profile_screen.dart';
import 'presentation/screens/alerts/alerts_screen.dart';
import 'presentation/screens/alerts/alert_map_screen.dart';
import 'presentation/screens/settings/settings_screen.dart';
import 'presentation/screens/decoycall/decoy_call_screen.dart';
import 'presentation/screens/lock/lock_screen.dart';
import 'presentation/screens/map/live_map_screen.dart';
import 'presentation/screens/settings/alert_preferences_screen.dart';
import 'presentation/screens/more/more_screen.dart';
import 'presentation/screens/emergency/emergency_center_screen.dart';
import 'presentation/screens/settings/paywall_screen.dart';
import 'presentation/screens/shell/main_shell.dart';

/// Named route paths.
abstract final class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String verifyEmail = '/verify-email';
  static const String home = '/home';
  static const String contacts = '/contacts';
  static const String addContact = '/contacts/add';
  static const String editContact = '/contacts/edit';
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String alerts = '/alerts';
  static const String settings = '/settings';
  static const String decoyCall = '/decoy-call';
  static const String alertMap = '/alert-map';
  static const String lock = '/lock';
  static const String sosHistory = '/sos-history';
  static const String liveMap = '/live-map';
  static const String more = '/more';
  static const String alertPreferences = '/alert-preferences';
  static const String emergencyCenter = '/emergency-center';
  static const String paywall = '/paywall';
}

// Navigation keys for the shell branches.
// Re-created each time createRouter() is called so hot restart works cleanly.
GlobalKey<NavigatorState> _rootKey = GlobalKey<NavigatorState>();
GlobalKey<NavigatorState> _homeKey = GlobalKey<NavigatorState>(debugLabel: 'home');
GlobalKey<NavigatorState> _alertsKey = GlobalKey<NavigatorState>(debugLabel: 'alerts');
GlobalKey<NavigatorState> _contactsKey = GlobalKey<NavigatorState>(debugLabel: 'contacts');
GlobalKey<NavigatorState> _mapKey = GlobalKey<NavigatorState>(debugLabel: 'map');
GlobalKey<NavigatorState> _moreKey = GlobalKey<NavigatorState>(debugLabel: 'more');

void _resetNavKeys() {
  _rootKey = GlobalKey<NavigatorState>();
  _homeKey = GlobalKey<NavigatorState>(debugLabel: 'home');
  _alertsKey = GlobalKey<NavigatorState>(debugLabel: 'alerts');
  _contactsKey = GlobalKey<NavigatorState>(debugLabel: 'contacts');
  _mapKey = GlobalKey<NavigatorState>(debugLabel: 'map');
  _moreKey = GlobalKey<NavigatorState>(debugLabel: 'more');
}

/// GoRouter configuration with StatefulShellRoute for bottom tab navigation.
GoRouter createRouter() {
  _resetNavKeys();
  return GoRouter(
      navigatorKey: _rootKey,
      initialLocation: AppRoutes.splash,
      // Enterprise: friendly error page for unknown routes / deep links.
      errorBuilder: (context, state) {
        final l = AppLocalizations.of(context);
        return Scaffold(
          appBar: AppBar(title: Text(l?.pageNotFound ?? 'Page Not Found')),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.explore_off_rounded, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(l?.routeNotFound(state.uri.toString()) ?? 'Route not found: ${state.uri}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  // Route to /login (safe for all auth states) rather than /home
                  // which is a protected shell route.
                  onPressed: () => context.go(AppRoutes.login),
                  child: Text(l?.goHome ?? 'Go Home'),
                ),
              ],
            ),
          ),
        );
      },
      routes: [
        // All use pageBuilder with unique ValueKeys to prevent
        // duplicate key assertions when coexisting with StatefulShellRoute.
        GoRoute(
          path: AppRoutes.splash,
          pageBuilder: (context, state) => const MaterialPage(
            key: ValueKey('page-splash'),
            name: '/',
            child: SplashScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.onboarding,
          pageBuilder: (context, state) => const MaterialPage(
            key: ValueKey('page-onboarding'),
            name: '/onboarding',
            child: OnboardingScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.login,
          pageBuilder: (context, state) => const MaterialPage(
            key: ValueKey('page-login'),
            name: '/login',
            child: LoginScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.signup,
          pageBuilder: (context, state) => const MaterialPage(
            key: ValueKey('page-signup'),
            name: '/signup',
            child: SignupScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.verifyEmail,
          pageBuilder: (context, state) => const MaterialPage(
            key: ValueKey('page-verify-email'),
            name: '/verify-email',
            child: VerifyEmailScreen(),
          ),
        ),
        GoRoute(
          parentNavigatorKey: _rootKey,
          path: AppRoutes.lock,
          pageBuilder: (context, state) => const MaterialPage(
            key: ValueKey('page-lock'),
            name: '/lock',
            child: LockScreen(),
          ),
        ),

        // Each route uses pageBuilder with a unique ValueKey to prevent
        // duplicate page key assertions in the root Navigator (GoRouter
        // can generate colliding keys when StatefulShellRoute and
        // root-level pushed routes coexist).
        GoRoute(
          parentNavigatorKey: _rootKey,
          path: AppRoutes.addContact,
          pageBuilder: (context, state) => const MaterialPage(
            key: ValueKey('page-add-contact'),
            name: AppRoutes.addContact,
            child: AddContactScreen(),
          ),
        ),
        GoRoute(
          parentNavigatorKey: _rootKey,
          path: AppRoutes.editContact,
          pageBuilder: (context, state) {
            final contact = state.extra as EmergencyContact?;
            return MaterialPage(
              key: const ValueKey('page-edit-contact'),
              name: AppRoutes.editContact,
              child: contact == null
                  ? const ContactsScreen()
                  : EditContactScreen(contact: contact),
            );
          },
        ),
        GoRoute(
          parentNavigatorKey: _rootKey,
          path: AppRoutes.editProfile,
          pageBuilder: (context, state) {
            final profile = state.extra as UserProfile?;
            return MaterialPage(
              key: const ValueKey('page-edit-profile'),
              name: AppRoutes.editProfile,
              child: EditProfileScreen(existingProfile: profile),
            );
          },
        ),
        GoRoute(
          parentNavigatorKey: _rootKey,
          path: AppRoutes.profile,
          pageBuilder: (context, state) => const MaterialPage(
            key: ValueKey('page-profile'),
            name: AppRoutes.profile,
            child: ProfileScreen(),
          ),
        ),
        GoRoute(
          parentNavigatorKey: _rootKey,
          path: AppRoutes.settings,
          pageBuilder: (context, state) => const MaterialPage(
            key: ValueKey('page-settings'),
            name: AppRoutes.settings,
            child: SettingsScreen(),
          ),
        ),
        GoRoute(
          parentNavigatorKey: _rootKey,
          path: AppRoutes.decoyCall,
          pageBuilder: (context, state) => const MaterialPage(
            key: ValueKey('page-decoy-call'),
            name: AppRoutes.decoyCall,
            child: DecoyCallScreen(),
          ),
        ),
        GoRoute(
          parentNavigatorKey: _rootKey,
          path: AppRoutes.alertMap,
          pageBuilder: (context, state) => const MaterialPage(
            key: ValueKey('page-alert-map'),
            name: AppRoutes.alertMap,
            child: AlertMapScreen(),
          ),
        ),
        GoRoute(
          parentNavigatorKey: _rootKey,
          path: AppRoutes.sosHistory,
          pageBuilder: (context, state) => const MaterialPage(
            key: ValueKey('page-sos-history'),
            name: AppRoutes.sosHistory,
            child: SosHistoryScreen(),
          ),
        ),
        GoRoute(
          parentNavigatorKey: _rootKey,
          path: AppRoutes.alertPreferences,
          pageBuilder: (context, state) => MaterialPage(
            key: const ValueKey('page-alert-preferences'),
            name: AppRoutes.alertPreferences,
            child: BlocProvider.value(
              value: getIt<AlertPreferencesCubit>(),
              child: const AlertPreferencesScreen(),
            ),
          ),
        ),
        GoRoute(
          parentNavigatorKey: _rootKey,
          path: AppRoutes.emergencyCenter,
          pageBuilder: (context, state) => const MaterialPage(
            key: ValueKey('page-emergency-center'),
            name: AppRoutes.emergencyCenter,
            child: EmergencyCenterScreen(),
          ),
        ),
        GoRoute(
          parentNavigatorKey: _rootKey,
          path: AppRoutes.paywall,
          pageBuilder: (context, state) => const MaterialPage(
            key: ValueKey('page-paywall'),
            name: AppRoutes.paywall,
            child: PaywallScreen(),
          ),
        ),

        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return MainShell(navigationShell: navigationShell);
          },
          branches: [
            // Tab 0: Home
            StatefulShellBranch(
              navigatorKey: _homeKey,
              routes: [
                GoRoute(
                  path: AppRoutes.home,
                  builder: (context, state) => const HomeScreen(),
                ),
              ],
            ),
            // Tab 1: Alerts
            StatefulShellBranch(
              navigatorKey: _alertsKey,
              routes: [
                GoRoute(
                  path: AppRoutes.alerts,
                  builder: (context, state) => const AlertsScreen(),
                ),
              ],
            ),
            // Tab 2: Contacts
            StatefulShellBranch(
              navigatorKey: _contactsKey,
              routes: [
                GoRoute(
                  path: AppRoutes.contacts,
                  builder: (context, state) => const ContactsScreen(),
                ),
              ],
            ),
            // Tab 3: Map
            StatefulShellBranch(
              navigatorKey: _mapKey,
              routes: [
                GoRoute(
                  path: AppRoutes.liveMap,
                  builder: (context, state) => const LiveMapScreen(),
                ),
              ],
            ),
            // Tab 4: More
            StatefulShellBranch(
              navigatorKey: _moreKey,
              routes: [
                GoRoute(
                  path: AppRoutes.more,
                  builder: (context, state) => const MoreScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    );
}

/// Provides all BLoCs at the app root level.
Widget wrapWithProviders(Widget child) {
  return MultiBlocProvider(
    providers: [
      BlocProvider<SosCubit>.value(
        value: getIt<SosCubit>(),
      ),
      BlocProvider<ContactsCubit>(
        create: (_) => getIt<ContactsCubit>(),
      ),
      // BatteryCubit.startMonitoring() is called by ServiceBootstrapper
      // (deferred post-frame). Calling it here as well causes a double-start
      // with duplicate SMS alerts. Use .value to wire the singleton without
      // triggering a second monitoring session.
      BlocProvider<BatteryCubit>.value(
        value: getIt<BatteryCubit>(),
      ),
      BlocProvider<AlertsCubit>.value(
        value: getIt<AlertsCubit>(),
      ),
      BlocProvider<ProfileCubit>.value(
        value: getIt<ProfileCubit>(),
      ),
      BlocProvider<RemindersCubit>(
        create: (_) => getIt<RemindersCubit>(),
      ),
    ],
    child: child,
  );
}
