// ignore_for_file: invalid_use_of_protected_member, library_private_types_in_public_api, use_build_context_synchronously

part of 'dashboard_screen.dart';

extension DashboardInit on _DashboardScreenState {
  Future<void> _safeInit() async {
    try {
      final canProceed = await _enforceAccountStatus();
      if (!canProceed) return;

      // Immediate Data Loads (Non-Blocking)
      _checkDailyProgress().catchError((e) {
        debugPrint("Dashboard: Error checking daily progress: $e");
      });
      _checkLevelUpgradeCelebration().catchError((e) {
        debugPrint("Dashboard: Error checking level celebration: $e");
      });
      _fetchPlacementState().catchError((e) {
        debugPrint("Dashboard: Error fetching placement state: $e");
      });

      _initData().catchError((e) {
        debugPrint("Dashboard: Error initializing data: $e");
      });

      // Listen for teacher-driven level changes (student immediate updates)
      _dataService.listenToUserChanges(
        onLevelChanged: (newLevel) async {
          if (!mounted) return;
          await _checkDailyProgress();
          if (mounted) {
            setState(() {});
          }
        },
      );

      // Internet Check
      _checkInitialConnection();

      // Listen for connection changes
      _internetSubscription = InternetConnection().onStatusChange.listen(
        (status) {
          if (!mounted) return;

          if (status == InternetStatus.connected) {
            // Connected
            _offlineTimer?.cancel();
            _offlineTimer = null;

            if (!_isConnected) {
              setState(() {
                _isConnected = true;
                _showOnlineSuccess = true;
              });

              // Hide success message after 3 seconds
              Future.delayed(const Duration(seconds: 3), () {
                if (mounted) {
                  setState(() {
                    _showOnlineSuccess = false;
                  });
                }
              });
            }
          } else {
            // Disconnected - wait 30 seconds before showing offline (more stable)
            if (_isConnected && _offlineTimer == null) {
              _offlineTimer = Timer(const Duration(seconds: 30), () async {
                if (!mounted) return;
                final hasInternet =
                    await InternetConnection().hasInternetAccess;
                if (!mounted) return;
                if (!hasInternet) {
                  setState(() {
                    _isConnected = false;
                  });
                }
                _offlineTimer = null;
              });
            }
          }
        },
        onError: (e) {
          debugPrint("Dashboard: Internet connection listener error: $e");
        },
      );

      // Notification Service Init
      await _notificationService.init();
      _setupNotificationListener();
      await _setupNotificationTapHandlers();

      // UI-Dependent Tasks: Permissions & Popups
      // Use addPostFrameCallback to ensure context is ready for Dialogs/Permissions
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;

        // 1. Request Notification Permissions (Interactive)
        try {
          debugPrint("Dashboard: Requesting FCM permissions...");
          await FCMService().requestPermissionInteractive();
        } catch (e) {
          debugPrint("Dashboard: FCM permission error: $e");
        }
        if (!mounted) return;

        // ISSUE #1 FIX: Tutorial/Onboarding Check FIRST (Only for students)
        if (_userRole == 'student') {
          final shouldShowTutorial = await TutorialService()
              .shouldShowOnboarding();
          if (!mounted) return;
          if (shouldShowTutorial) {
            TutorialService().startTutorial();
            await _showTutorialIfNeeded();
            TutorialService().endTutorial();
          }
        }

        // Keep this hook for sequencing, but important announcements are
        // intentionally dashboard-card only (no modal/popup flow).
        if (!TutorialService().isTutorialInProgress) {
          _handlePostTutorialFlow().catchError((e) {
            debugPrint("Dashboard: Error in post-tutorial flow: $e");
          });
        }
      });
    } catch (e) {
      debugPrint("Dashboard: Critical error in init: $e");
      // Don't rethrow - allow app to continue
    }
  }

  Future<void> _checkLevelUpgradeCelebration() async {
    final pending = await UserLevelService.consumePendingCelebration();
    if (pending == null || pending.isEmpty) return;
    if (!mounted) return;
    setState(() {
      _showLevelUpOverlay = true;
      _levelUpLabel = pending;
    });
    SoundService().playCompletion();
    _confettiController.play();
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        _showLevelUpOverlay = false;
      });
    });
  }

  Future<bool> _enforceAccountStatus() async {
    try {
      final status = await _dataService.getUserStatus();
      if (!mounted) return false;

      final isBlocked = status['isBlocked'] == true;
      if (isBlocked) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AccountBlockedScreen()),
        );
        return false;
      }

      final forceOnboarding = status['force_onboarding'] == true;
      if (forceOnboarding) {
        await _applyForceOnboardingReset();
      }
    } catch (e) {
      debugPrint("Dashboard: Error enforcing account status: $e");
    }

    return true;
  }

  Future<void> _applyForceOnboardingReset() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid =
          import_firebase_auth.FirebaseAuth.instance.currentUser?.uid ??
          'guest';

      final explicitKeys = <String>{
        'assessment_completed',
        'assessment_skipped',
        'assessment_status_$uid',
        'assessment_timestamp_$uid',
        'assessment_score',
        'placement_quiz_status',
        'placement_user_level',
        'placement_level',
        'placement_completed',
        'placement_skipped',
        'placement_score',
        'placement_level_code',
        'english_proficiency_level',
        'english_proficiency_level_$uid',
        'user_level',
        'user_xp_level',
        'user_current_xp',
        'user_total_xp',
        'user_streak_days',
        'user_stage_streak',
        'points',
        'badges',
        'progress_start_date',
        'current_learning_day',
        'current_learning_stage',
        'completed_days',
        'learning_start_date',
      };

      final prefixes = ['task_', 'quiz_', 'mastery_', 'blackhole_', 'learned_'];

      final keys = prefs.getKeys();
      for (final key in keys) {
        if (explicitKeys.contains(key) ||
            prefixes.any((prefix) => key.startsWith(prefix))) {
          await prefs.remove(key);
        }
      }

      final user = import_firebase_auth.FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'force_onboarding': false,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint("Dashboard: Failed to apply onboarding reset: $e");
    }
  }

  Future<void> _checkInitialConnection() async {
    // Wait 5 seconds after app startup before checking connection
    // This prevents "No Internet" from flashing on app reopen
    await Future.delayed(const Duration(seconds: 5));

    if (!mounted) return;

    bool hasInternet = await InternetConnection().hasInternetAccess;
    if (mounted && !hasInternet) {
      setState(() {
        _isConnected = false;
      });
    }
  }

  Future<void> _initData() async {
    await _loadPreferences();
    await _fetchOverallProgress();
    await _fetchStreak();
    await _checkDailyProgress();

    await _fetchUserRole();
    await _fetchPlacementState();
    await _fetchAssessmentStatus();
    if (_isMasteryFeatureEnabled) {
      await _fetchMasteryProgress();
    }
    await _navigateToPendingDailyTasks();
  }

  Future<void> _fetchMasteryProgress() async {
    final r = await _dataService.getMasteryProgress('reading');
    final w = await _dataService.getMasteryProgress('writing');
    final s = await _dataService.getMasteryProgress('speaking');
    final l = await _dataService.getMasteryProgress('listening');
    // Quiz progress not currently used in Mastery cards

    if (mounted) {
      setState(() {
        _readingProgress = r;
        _writingProgress = w;
        _speakingProgress = s;
        _listeningProgress = l;
      });
    }
  }

  Future<void> _fetchUserRole() async {
    final role = await _dataService.getUserRole();
    if (mounted && role != null) {
      setState(() {
        _userRole = role;
      });
      // Also save to prefs for offline use
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_role', role);
    }
  }

  Future<void> _fetchStreak() async {
    final streak = await _dataService.getStreakCount();
    if (mounted) {
      setState(() {
        _streakCount = streak;
        _isStreakLoaded = true;
      });
    }
  }

  Future<void> _fetchOverallProgress() async {
    final progress = await _dataService.getOverallProgress();
    if (mounted) {
      setState(() {
        _overallProgress = progress;
      });
    }
  }

  /// Start polling for progress updates when on Core Tasks tab
  void _startProgressPolling() {
    _stopProgressPolling(); // Cancel any existing timer first

    // Poll every 5 seconds to check for progress changes
    _progressPollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _checkDailyProgress();
      } else {
        timer.cancel();
      }
    });

    debugPrint('âœ… Started progress polling for Core Tasks tab');
  }

  /// Stop the progress polling timer
  void _stopProgressPolling() {
    _progressPollingTimer?.cancel();
    _progressPollingTimer = null;
    debugPrint('â¹ï¸ Stopped progress polling');
  }
}
