# Feedback & Notification Fixes

## Issues Addressed
1.  **Teacher Notification Alerting**: Physical devices were not showing "Heads-up" / Pop-up notifications for important announcements.
2.  **Student Feedback Failing**: Students were unable to send feedback because the backend blocked non-teacher users from sending notifications.

## Fix Implementation

### 1. Teacher Notification Alerts (Physical Device)
*   **Data-Only Messages**: We modified the Cloud Function `sendAnnouncement` to **remove** the `notification` payload.
    *   *Why?* The Android System Tray hijacks messages with a `notification` payload and often suppresses "Heads-up" alerts based on battery/usage patterns.
    *   *Result:* Messages are now handled exclusively by the app's `firebaseMessagingBackgroundHandler` (in Dart code), which forces `Importance.max` and `fullScreenIntent`.
*   **Notification Channel Upgrade**: Upgraded channel ID to `announcements_channel_v3`.
    *   *Why?* This forces Android to create a fresh channel, resetting any "Silent" or "Block" settings that might have been cached on physical devices.

### 2. Feedback Failure Fix
*   **Firestore Triggers**: We replaced the insecure client-side notification call with a robust **Firestore Cloud Function Trigger**.
    *   *Old Way:* Student App -> Calls `sendAnnouncement` -> Fails (Security: Only Teachers allowed).
    *   *New Way:* Student App -> Writes to Firestore (`feedback` collection) -> Cloud Function `notifyTeachersOnFeedback` triggers automatic notification.
    *   *Benefit:* 100% reliable, secure, and works even if the app creates the doc while offline (syncs later).

## Status
*   Cloud Functions are being deployed.
*   Client code (`ProfileScreen`) has been updated to remove the failing call.

## Testing
1.  **As Student**: Go to Profile -> Give Feedback. Submit.
    *   *Expected:* You get a local "Thank you" notification.
    *   *Expected:* Teacher device receives a "New Feedback Received" notification.
2.  **As Teacher**: Send an "Important Announcement".
    *   *Expected:* Physical devices should now show a Pop-up/Heads-up notification with sound.
