# Where to find Error Logs (Teacher Guide)

## ❓ The Confusion
- You received **Notifications** about errors (e.g. "Network Issue", "UI Layout Issue").
- You went to "View Student Bugs" and it was **Empty**.

## 💡 The Reason
- **Notifications** came from the **System Crash Logger** (Collection: `app_errors`).
- **"View Student Bugs"** page was only showing **Manual Reports** written by students (Collection: `bug_reports`).
- Since no student manually typed a report, the page was empty.

## ✅ The Solution (Fixed Recently)
I have updated the **Teacher Profile** screen to include TWO separate buttons:

1.  **🚨 View System Crashes**:
    - **Shows**: The error notifications you received (Network, UI, Crashes).
    - **Source**: `app_errors` collection.
    - **Status**: **This page will now be full** (showing the errors you were notified about).

2.  **🐛 View Manual Bug Reports**:
    - **Shows**: Messages students physically type in "Report a Bug".
    - **Source**: `bug_reports` collection.
    - **Status**: Likely empty until a student types something.

## 👉 Action
Go to **Profile > Settings** and click **"View System Crashes"** to see your logs!
