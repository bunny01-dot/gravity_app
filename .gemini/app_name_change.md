# 🏷️ App Name Changed

## Status: UPDATED

The app name has been successfully changed from `gravity_app` / `Gravity App` to **"Gravity"**.

## Changes Made:

### 1. **Android** 🤖
- **File**: `android/app/src/main/AndroidManifest.xml`
- **Change**: Updated `android:label` to **"Gravity"**.
- **Effect**: The name displayed on the Android home screen and app settings will now be "Gravity".

### 2. **iOS** 🍎
- **File**: `ios/Runner/Info.plist`
- **Change**: Updated `CFBundleDisplayName` and `CFBundleName` to **"Gravity"**.
- **Effect**: The name displayed on the iOS home screen will now be "Gravity".

## Verification:

To see the change, you need to rebuild the app:

**For Development (Debug):**
1. Stop the current running app.
2. Run again: `flutter run` (or `flutter build apk --debug`)

**For Release (APK):**
1. Run: `flutter build apk --release`

The app icon on your device will now interpret the name as "Gravity".
