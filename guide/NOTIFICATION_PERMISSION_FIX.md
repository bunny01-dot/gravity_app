# Notification & Permission Fixes

## Issues Addressed
1.  **Pop-up Not Working**: Caused by missing/incorrect notification icon reference (`@mipmap/ic_launcher` vs `@mipmap/launcher_icon`). If the icon is invalid, the notification often crashes silently or downgrades to a silent entry.
2.  **No Permission Request**: The initialization logic was running in `main()` before the app context was ready, often swallowing the permission dialog. On Android 13+, this request MUST happen when the app is in the foreground and active.

## Fix Implementation

### 1. Fixed Permission Request Logic
*   Refactored `main.dart` to move `FCMService().init()` **out of `main()`** and into `EnglishLearningApp`'s `initState()`.
*   **Why?** Running in `initState` ensures the Flutter engine is fully attached and ready to display system dialogs (permissions).
*   Added explicit support for **Android 13+ (API 33)** permission requests using `permission_handler`, which is more reliable than the Firebase plugin alone for triggering the OS dialog if it was previously denied/dismissed.

### 2. Fixed Notification Icon
*   Updated `lib/services/notification_service.dart` to use `@mipmap/launcher_icon` instead of `@mipmap/ic_launcher`.
*   **Verification**: We checked the `android/app/src/main/res/mipmap-hdpi` folder and confirmed the file is named `launcher_icon.png`. A mismatch here causes notifications to fail silently.

### 3. Background Handler Stability
*   Kept the `onBackgroundMessage` registration in `main()` (as required by FlutterFire) but wrapped it safely.

## Testing Steps
1.  **Uninstall** the app from your physical device (to clear permission cache).
2.  **Reinstall** and Run.
3.  **Launch**: You should immediately see the "Allow Notifications?" system dialog. **Click Allow**.
4.  **Test**: Send an "Important Announcement" from the Teacher Dashboard.
    *   *Result:* It should now pop up with the correct icon.
