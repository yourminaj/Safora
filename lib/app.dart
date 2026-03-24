import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:safora/l10n/app_localizations.dart';
import 'data/models/emergency_contact.dart';
import 'data/models/user_profile.dart';
import 'injection.dart';
import 'presentation/blocs/alerts/alerts_cubit.dart';
import 'presentation/blocs/battery/battery_cubit.dart';
import 'presentation/blocs/contacts/contacts_cubit.dart';
import 'presentation/blocs/profile/profile_cubit.dart';
import 'presentation/blocs/reminders/reminders_cubit.dart';
import 'presentation/blocs/sos/sos_cubit.dart';
import 'presentation/screens/splash/splash_screen.dart';
import 'presentation/screens/onboarding/onboarding_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/signup_screen.dart';
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

/// Named route paths.
abstract final class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
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
}

/// GoRouter configuration.
GoRouter createRouter() => GoRouter(
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
                  onPressed: () => context.go(AppRoutes.home),
                  child: Text(l?.goHome ?? 'Go Home'),
                ),
              ],
            ),
          ),
        );
      },
      routes: [
        GoRoute(
          path: AppRoutes.splash,
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: AppRoutes.onboarding,
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: AppRoutes.login,
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: AppRoutes.signup,
          builder: (context, state) => const SignupScreen(),
        ),
        GoRoute(
          path: AppRoutes.home,
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: AppRoutes.contacts,
          builder: (context, state) => const ContactsScreen(),
        ),
        GoRoute(
          path: AppRoutes.addContact,
          builder: (context, state) => const AddContactScreen(),
        ),
        GoRoute(
          path: AppRoutes.editContact,
          builder: (context, state) {
            // Enterprise: null-safe cast prevents crash from deep links.
            final contact = state.extra as EmergencyContact?;
            if (contact == null) {
              // Redirect to contacts list if no contact was passed.
              return const ContactsScreen();
            }
            return EditContactScreen(contact: contact);
          },
        ),
        GoRoute(
          path: AppRoutes.profile,
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: AppRoutes.editProfile,
          builder: (context, state) {
            final profile = state.extra as UserProfile?;
            return EditProfileScreen(existingProfile: profile);
          },
        ),
        GoRoute(
          path: AppRoutes.alerts,
          builder: (context, state) => const AlertsScreen(),
        ),
        GoRoute(
          path: AppRoutes.alertMap,
          builder: (context, state) => const AlertMapScreen(),
        ),
        GoRoute(
          path: AppRoutes.settings,
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: AppRoutes.decoyCall,
          builder: (context, state) => const DecoyCallScreen(),
        ),
        GoRoute(
          path: AppRoutes.lock,
          builder: (context, state) => const LockScreen(),
        ),
      ],
    );

/// Provides all BLoCs at the app root level.
Widget wrapWithProviders(Widget child) {
  return MultiBlocProvider(
    providers: [
      BlocProvider<SosCubit>(
        create: (_) => getIt<SosCubit>(),
      ),
      BlocProvider<ContactsCubit>(
        create: (_) => getIt<ContactsCubit>(),
      ),
      BlocProvider<BatteryCubit>(
        create: (_) => getIt<BatteryCubit>()..startMonitoring(),
      ),
      BlocProvider<AlertsCubit>(
        create: (_) => getIt<AlertsCubit>(),
      ),
      BlocProvider<ProfileCubit>(
        create: (_) => getIt<ProfileCubit>(),
      ),
      BlocProvider<RemindersCubit>(
        create: (_) => getIt<RemindersCubit>(),
      ),
    ],
    child: child,
  );
}
