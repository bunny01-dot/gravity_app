# Announcement History Management Updated

## Changes
1.  **New Interface**:
    *   Replaced the simple "Clear Announcements" dialog with a **Full History List**.
    *   Teachers can now view all past announcements with their **Title**, **Message snippet**, and **Timestamp**.

2.  **Individual Deletion**:
    *   Added a `Trash Icon` next to *each* announcement in the list.
    *   Teachers can now delete specific mistakes or outdated messages without clearing everything.

3.  **UI Fixes**:
    *   **Text Overflow**: Changed the button label from "Delete Old (>7 days)" to **"Delete Older (>7d)"** to fit comfortably on all screen sizes.
    *   **Layout**: Moved the bulk action buttons ("Delete All", "Delete Older") to the bottom of the list for easy access.

4.  **Functionality**:
    *   The list updates in real-time (using `StreamBuilder`) as you delete items.

## How to Test
1.  Go to **Teacher Dashboard** -> **Send Announcement**.
2.  Tap **Manage History**.
3.  **Verify List**: You should see your past announcements.
4.  **Test Individual Delete**: Tap the trash icon on one item. It should vanish immediately.
5.  **Test Batch Delete**: Verify the buttons at the bottom still work as expected.
