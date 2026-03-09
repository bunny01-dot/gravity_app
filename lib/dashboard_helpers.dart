part of 'dashboard/dashboard_screen.dart';

/// Mixin to handle periodic progress polling.
/// Usage: with DashboardPollingHelpers
mixin DashboardPollingHelpers<T extends StatefulWidget> on State<T> {
  Timer? _progressPollingTimer;

  /// abstract method that must be implemented by the host state class.
  /// If your method is private (_checkDailyProgress), you might need to make it public
  /// or use 'part of' directive to share scope.
  void checkDailyProgress();

  void startProgressPolling() {
    stopProgressPolling();
    _progressPollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        checkDailyProgress();
      }
    });
    debugPrint('[DATA] Started daily progress polling');
  }

  void stopProgressPolling() {
    _progressPollingTimer?.cancel();
    _progressPollingTimer = null;
    debugPrint('[STOP] Stopped daily progress polling');
  }
}
