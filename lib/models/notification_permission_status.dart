/// Represents the current state of notification permissions
enum NotificationPermissionStatus {
  /// Permissions are granted and notifications will work
  granted,

  /// Permissions were denied but can be requested again
  denied,

  /// Permissions were permanently denied (user selected "Don't ask again")
  /// User must manually enable in system settings
  permanentlyDenied,

  /// Permission status cannot be determined (rare edge case)
  unknown,
}

/// Extension methods for NotificationPermissionStatus
extension NotificationPermissionStatusExtension
    on NotificationPermissionStatus {
  /// Whether notifications are currently enabled
  bool get isEnabled => this == NotificationPermissionStatus.granted;

  /// Whether the user can be prompted again
  bool get canPrompt => this == NotificationPermissionStatus.denied;

  /// Whether user must go to settings to enable
  bool get requiresSettings =>
      this == NotificationPermissionStatus.permanentlyDenied;

  /// User-friendly description
  String get description {
    switch (this) {
      case NotificationPermissionStatus.granted:
        return 'Notifications are enabled';
      case NotificationPermissionStatus.denied:
        return 'Notifications are disabled';
      case NotificationPermissionStatus.permanentlyDenied:
        return 'Notifications are blocked. Please enable in settings.';
      case NotificationPermissionStatus.unknown:
        return 'Notification status unknown';
    }
  }
}
