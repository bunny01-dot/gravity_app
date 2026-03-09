# System Settings Access Added

## Feature Description
Added a new **"System Settings"** option to both the **Teacher Dashboard** (Settings Tab) and **Student Profile** screen.

## Purpose
This feature addresses the user's need to verify notification permissions at the OS level, especially if they suspect "banner" notifications are being suppressed by system optimizing settings.

## Implementation Details
1.  **Teacher Dashboard**: Added a `ListTile` under `SwitchListTile` in the Settings tab.
2.  **Student Profile**: Added a `_buildSettingsItem` entry in the main list.
3.  **Functionality**: Both buttons call `openAppSettings()` from the `permission_handler` package, which takes the user directly to the App Info page for "English Learning App" in Android Settings.

## Usage
1.  **Teacher**: Go to `Settings` tab -> Tap **"System Settings"**.
2.  **Student**: Go to `Profile` -> Tap **"System Notification Settings"**.
3.  **Result**: The Android App Info screen opens. The user can then tap "Notifications" to verify if "Show notifications" and "Pop on screen" are enabled.
