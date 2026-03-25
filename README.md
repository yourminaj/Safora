# Safora — Your Family's Safety Guardian 🛡️

All-in-one personal safety & emergency alert app built with Flutter.

## Features

- **SOS Emergency Alert** — One-tap panic button sends GPS location + SMS to emergency contacts
- **Shake-to-SOS** — Shake detection triggers SOS when you can't reach the screen
- **Crash & Fall Detection** — ML-powered accelerometer/gyroscope analysis detects impacts
- **Emergency Contacts** — Store up to 5 contacts with cloud sync via Firebase
- **Real-Time Disaster Alerts** — Earthquake (USGS), flood (Open-Meteo), cyclone data for your region
- **Decoy Call** — Fake incoming call to help you exit unsafe situations
- **Medical Profile** — Blood type, allergies, medications — accessible to responders
- **Medicine Reminders** — Daily medication alarms with local notifications
- **Low Battery Alert** — Auto-sends last known location when battery drops below threshold
- **App Lock** — PIN + biometric (fingerprint/Face ID) lock for privacy
- **Bilingual** — Full English & Bengali (বাংলা) localization

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.x (Dart 3.11+) |
| State Management | flutter_bloc / Cubit |
| Navigation | GoRouter |
| DI | get_it |
| Local Storage | Hive |
| Backend | Firebase (Auth, Firestore, Crashlytics, Analytics, FCM) |
| ML | Custom signal processing (crash/fall detection engine) |
| Ads | Google Mobile Ads |

## Architecture

```
lib/
├── core/           # Services, theme, constants
├── data/           # Datasources, models, repositories
├── detection/      # ML crash/fall detection
├── domain/         # Use cases
├── l10n/           # Localization (EN + BN)
├── presentation/   # Screens, BLoCs, widgets
├── app.dart        # GoRouter configuration
├── injection.dart  # Dependency injection setup
└── main.dart       # Entry point + Firebase init
```

## Getting Started

```bash
# Clone
git clone https://github.com/yourminaj/Safora.git
cd Safora

# Install dependencies
flutter pub get

# Generate localization files
flutter gen-l10n

# Run
flutter run
```

### Firebase Setup

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Add Android + iOS apps with matching package/bundle IDs
3. Download `google-services.json` → `android/app/`
4. Download `GoogleService-Info.plist` → `ios/Runner/`
5. Deploy Firestore rules: `firebase deploy --only firestore:rules`

## Testing

```bash
# Run all tests (626+ tests)
flutter test

# Analyze for errors
dart analyze
```

## Permissions

| Permission | Purpose |
|-----------|---------|
| Location (GPS) | SOS sends device coordinates |
| SMS | Send emergency SMS directly (Android) |
| Notifications | Alerts, reminders, SOS status |
| Biometric | App lock (fingerprint/Face ID) |
| Sensors | Shake detection, crash/fall detection |
| Foreground Service | Keep SOS active in background |

## License

This project is private — all rights reserved.
