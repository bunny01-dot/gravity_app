# Teacher Notification History Fixes

## Issue
1.  **Old Notifications Reappearing**: Notifications were previously only "deleted" by hiding them locally on the device (SharedPreferences).
    *   **Result**: When the teacher reinstalled the app or cleared data, the "hidden" list was lost, and all 45+ old notifications reappeared from Firestore.
    *   **Correction**: Updated the delete logic to perform a **permanent delete** from Firestore.

2.  **Read Status Lost**: Similarly, "Mark as Read" status was mostly relied upon locally.
    *   **Result**: On reinstall, all notifications looked "New".
    *   **Correction**: Updated the display logic to check the `isRead` field from the database first. Updated "Mark as Read" to ensure it writes this status to the database.

## Solution Implemented
*   **Permanent Delete**: The "Delete" button (swipe or selection) now sends a delete command to Firestore. These notifications are gone forever and will not reappear on any device.
*   **Batch Operations**: "Select All -> Delete" now efficiently batch deletes all selected documents from the cloud.
*   **Cloud Sync**: Read status is now reliably synced.

## Testing
1.  **Open Teacher Dashboard** -> Notifications icon (Bell).
2.  **Delete**: Swipe left on an old notification or select multiple and hit the trash icon.
    *   *Observation*: They will be removed from the list.
3.  **Verify**: Restart the app (or uninstall/reinstall).
    *   *Observation*: The deleted items **should NOT comeback**.
4.  **Mark Read**: Tap an unread item.
    *   *Observation*: It turns gray.
    *   *Verify*: Restart app. It stays gray.

You can now clean up those 45 old notifications using the "Select All" -> "Delete" feature.
