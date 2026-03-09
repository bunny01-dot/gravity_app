# Dialog & Stuck UI Fixes
## Issues Addressed
1.  **Stuck Loading Dialog**: 
    *   **Root Cause**: The app used `Navigator.popUntil((route) => true)` inside the error handler. This logic effectively says "Stop popping when the route is true", which returns immediately without popping anything. This caused the loading spinner to stay on screen indefinitely if an error occurred (e.g., trying to delete when network is flaky).
    *   **Fix**: Replaced this with **explicit pop logic**. We now track `loadingDialogShown = true` when we open the dialog, and rely on that flag to safely close it using `Navigator.pop()`.

2.  **Unresponsive Menu Buttons**:
    *   **Root Cause**: The dialog buttons were using `Navigator.pop(context)`. Sometimes, due to context nesting or async timing, this could be ambiguous or fail to find the correct dialog route to pop, leaving the menu open.
    *   **Fix**: Updated all dialog buttons to use `Navigator.of(context, rootNavigator: true).pop()`. This is the standard, safe way to close dialogs in Flutter to avoid context confusion.

## Testing Steps
1.  **Clear Announcements**: Go to Teacher Dashboard -> "Send Announcement" -> "Manage History".
2.  **Delete All**: Tap "Delete All". 
    *   *Observation*: The menu should close immediately. A loading spinner will appear briefly, then disappear with a success message.
3.  **Simulate Error (Optional)**: If you are offline and try to delete, the loading spinner should now correctly disappear and show an error SnackBar, instead of freezing existing UI.

Your "Stuck" and "Button not working" issues should be resolved.
