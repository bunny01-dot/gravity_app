# Student Deletion Fix
## Issue
When a student was deleted, the UI did not update to reflect this change. The student would remain in the list until the app was restarted or the cache expired (24 hours).

## Root Cause
The app uses a `StudentsCache` to minimize database reads. When `_confirmDeleteStudent` deleted the user from Firestore, it **failed to notify the cache** that the data was stale. Consequently, the UI continued to display the cached list containing the deleted student.

## Fix
Updated `_confirmDeleteStudent` in `teacher_dashboard.dart` to:
1.  **Invalidate Cache**: Explicitly call `StudentsCache().refresh()` immediately after a successful deletion.
2.  **Rebuild UI**: Call `setState(() {})` to trigger a rebuild of the dashboard, compelling it to fetch the fresh list from the updated cache.
3.  **Safe Dialog Close**: Updated the dialog closing logic to use `rootNavigator: true` to prevent any "stuck dialog" issues.

## Testing
1.  Go to **Teacher Dashboard** -> **Students Tab**.
2.  Tap on a student.
3.  Tap **Delete Student**.
4.  Confirm deletion.
5.  *Result*: The dialog closes, "Student deleted" snackbar appears, and the student **immediately disappears** from the list.
