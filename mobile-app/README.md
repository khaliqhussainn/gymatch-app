# Moovit Flutter App

A production-ready Flutter app structure built around your splash screen identity — dark, neon-accented, location-focused.

## 🎨 Design System

| Token | Value |
|---|---|
| Primary (Neon) | `#CBF135` |
| Background | `#0A0A0A` |
| Surface | `#141414` |
| Font | Space Grotesk |

---

## 📁 Project Structure

```
lib/
├── main.dart                    # Entry point, system UI setup
├── theme/
│   └── app_theme.dart           # AppColors, AppTheme (dark)
├── routes/
│   └── app_router.dart          # GoRouter config + all routes
├── widgets/
│   └── app_logo.dart            # Custom painted logo (vector)
└── screens/
    ├── main_scaffold.dart        # Shell with bottom nav
    ├── splash/
    │   └── splash_screen.dart   # Animated splash (StatefulWidget)
    ├── onboarding/
    │   └── onboarding_screen.dart
    ├── auth/
    │   ├── login_screen.dart
    │   └── register_screen.dart
    ├── home/
    │   └── home_screen.dart
    ├── explore/
    │   └── explore_screen.dart
    ├── map/
    │   └── map_screen.dart
    ├── profile/
    │   └── profile_screen.dart
    ├── notifications/
    │   └── notifications_screen.dart
    └── settings/
        └── settings_screen.dart
```

---

## 🚀 Getting Started

### 1. Install Flutter
https://docs.flutter.dev/get-started/install

### 2. Get dependencies
```bash
flutter pub get
```

### 3. Run the app
```bash
flutter run
```

---

## 📦 Key Dependencies

| Package | Purpose |
|---|---|
| `go_router` | Declarative routing / deep links |
| `google_fonts` | Space Grotesk typography |
| `flutter_animate` | Smooth entry animations |
| `provider` | State management (ready to wire) |
| `shared_preferences` | Persist user session |

---

## 🗺️ Adding Google Maps

In `map_screen.dart`, replace `CustomPaint` with:

```dart
// pubspec.yaml: add google_maps_flutter: ^2.9.0
import 'package:google_maps_flutter/google_maps_flutter.dart';

GoogleMap(
  initialCameraPosition: CameraPosition(
    target: LatLng(24.8607, 67.0011), // Karachi
    zoom: 14,
  ),
  myLocationEnabled: true,
  mapType: MapType.normal,
),
```

Also add your API key to `AndroidManifest.xml` and `AppDelegate.swift`.

---

## 🧩 Architecture Notes

- **Screens** are `StatelessWidget` wherever possible; `StatefulWidget` only for forms, animations, and page controllers.
- **GoRouter** with `ShellRoute` handles the bottom nav tab state.
- **AppTheme** centralizes all colors — swap the primary neon by changing `AppColors.primary`.
- **AppLogo** is a `CustomPainter` vector — no asset dependency, always crisp.

---

## 📋 Next Steps

- [ ] Wire `Provider` / `Riverpod` for auth state
- [ ] Integrate real Google Maps SDK
- [ ] Add Firebase Auth / Supabase
- [ ] Connect a places API (Google Places, Foursquare)
- [ ] Replace placeholder images with `CachedNetworkImage`
