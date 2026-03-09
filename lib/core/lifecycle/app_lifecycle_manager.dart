import 'package:flutter/widgets.dart';
import 'package:gravity_app/services/student_data_preloader.dart';

/// Manages app lifecycle events and coordinates cache cleanup
///
/// Features:
/// - Detects when app goes to background/foreground
/// - Clears cache appropriately based on lifecycle state
/// - Ensures cache is cleared when app terminates
class AppLifecycleManager extends WidgetsBindingObserver {
  static final AppLifecycleManager _instance = AppLifecycleManager._internal();
  factory AppLifecycleManager() => _instance;
  AppLifecycleManager._internal();

  bool _isInitialized = false;

  /// Initialize lifecycle monitoring
  void initialize() {
    if (_isInitialized) return;

    WidgetsBinding.instance.addObserver(this);
    _isInitialized = true;

    // Start preloader monitoring
    StudentDataPreloader().startMonitoring();

    debugPrint('[APP] AppLifecycleManager: Initialized');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('[APP] App lifecycle changed: $state');

    switch (state) {
      case AppLifecycleState.resumed:
        _onAppResumed();
        break;

      case AppLifecycleState.inactive:
        _onAppInactive();
        break;

      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _onAppPaused();
        break;

      case AppLifecycleState.detached:
        _onAppDetached();
        break;
    }
  }

  /// App came to foreground
  void _onAppResumed() {
    debugPrint('[APP] App resumed - restarting monitoring');
    StudentDataPreloader().startMonitoring();

    // Cleanup expired cache entries
    StudentDataPreloader().cleanupExpired();
  }

  /// App is transitioning (e.g., user switching between apps)
  void _onAppInactive() {
    debugPrint('[APP] App inactive');
    // Don't clear cache - user might come back quickly
  }

  /// App went to background
  void _onAppPaused() {
    debugPrint('[APP] App paused - clearing non-critical cache');

    // Stop monitoring to save battery
    StudentDataPreloader().stopMonitoring();

    // Clear non-critical cache to free memory
    StudentDataPreloader().clearNonCriticalCache();
  }

  /// App is terminating
  void _onAppDetached() {
    debugPrint('[APP] App detaching - clearing ALL cache');

    // Stop monitoring
    StudentDataPreloader().stopMonitoring();

    // Clear everything
    StudentDataPreloader().clearAllCache();
  }

  /// Dispose and cleanup
  void dispose() {
    if (_isInitialized) {
      WidgetsBinding.instance.removeObserver(this);
      _isInitialized = false;
      debugPrint('[APP] AppLifecycleManager: Disposed');
    }
  }

  /// Get current state
  bool get isInitialized => _isInitialized;
}
