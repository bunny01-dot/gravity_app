# Teacher Notification Fix V2

## Issue
Teacher notifications were not "alerting" (displaying as heads-up/popup) on physical devices.

## Root Cause
1.  **System Tray Handling**: The Cloud Function was sending a `notification` payload. On Android, this causes the System Tray to handle the notification display, bypassing the app's custom `firebaseMessagingBackgroundHandler`. The System Tray implementation often suppresses "Full Screen Intents" or "Heads-up" behavior unless the device is configured perfectly.
2.  **Channel Staleness**: The notification channel (`announcements_channel_v2`) might have arguably been cached on the physical device with lower importance settings (e.g., sound off, popup off), which Android prevents apps from changing programmatically once created.

## The Fix
1.  **Data-Only Messages**: Modified `functions/index.js` to **remove the `notification` payload**. This converts the messages to "Data-Only" messages.
    *   **Result**: The OS delivers the message to the app's `firebaseMessagingBackgroundHandler` (even in background).
    *   **Benefit**: The app now runs its `NotificationService.showNotification()` code, which explicitly requests `Importance.max`, `fullScreenIntent`, and `priority: high` using `flutter_local_notifications`. This guarantees the "Alert" behavior defined in code.

2.  **channel Upgrade**: Bumped notification channel ID in `notification_service.dart` and `AndroidManifest.xml` from `v2` to `v3`.
    *   **Result**: Forces the creation of a *new* notification channel on the device, ensuring the fresh "High Importance" settings are applied.

## REQUIRED ACTION
You **MUST** redeploy the Cloud Functions for this to work.

Run this command in your terminal:
```bash
firebase deploy --only functions
```

After deployment, send a new announcement from the Teacher Dashboard. The physical device should now receive a High Priority notification that alerts properly.
