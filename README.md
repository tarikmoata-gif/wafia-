# Meyah Water Delivery App

Flutter Android app for Meyah water delivery service (Arabic, Saudi Arabia).
Connected to Odoo 17 backend with Moyasar payment gateway.

## Features
- OTP login (Saudi phone numbers)
- Order water tanks (potable / non-potable), sizes 5–20 m³
- Schedule or instant delivery
- Moyasar payment checkout
- Live order tracking with Google Maps
- Profile & account deletion

## Build APK

### Prerequisites
1. Install Flutter SDK 3.24+ (https://flutter.dev/docs/get-started/install)
2. Run: `flutter doctor` — ensure Android toolchain is OK
3. Android Studio with SDK 34, JDK 17

### Steps
```bash
cd meyah_app
flutter pub get

# Set your Odoo backend URL in lib/core/network/odoo_api_client.dart
# Set your Google Maps API key in android/app/src/main/AndroidManifest.xml
# Set your Moyasar publishable key in lib/features/checkout/moyasar_checkout_screen.dart

# Debug APK
flutter build apk --debug

# Release APK (signed with debug key by default; configure signing for production)
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### App bundle (Play Store)
```bash
flutter build appbundle --release
```

## Configuration Checklist
| Item | Location |
|------|----------|
| Odoo API base URL | `lib/core/network/odoo_api_client.dart` → `baseUrl` |
| Google Maps API key | `android/app/src/main/AndroidManifest.xml` → `YOUR_GOOGLE_MAPS_API_KEY` |
| Moyasar publishable key | `lib/features/checkout/moyasar_checkout_screen.dart` |
| App ID / version | `android/app/build.gradle`, `pubspec.yaml` |
