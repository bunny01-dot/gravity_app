// ignore_for_file: invalid_use_of_protected_member, library_private_types_in_public_api, use_build_context_synchronously

part of 'dashboard_screen.dart';

extension DashboardNotifications on _DashboardScreenState {
  Future<void> _checkPendingAnnouncements() async {
    // Intentionally disabled:
    // Important announcements are shown as dashboard cards only.
    return;
  }

  bool _canShowAttentionUI() {
    return mounted &&
        !_isAttentionModalActive &&
        !_isLoggingOut &&
        !TutorialService().isTutorialInProgress;
  }

  bool _announcementMatchesRole(Map<String, dynamic> data) {
    final targetRole = (data['targetRole'] ?? data['target_role'])?.toString();
    final targetRoles = data['targetRoles'];
    final senderId = data['senderId'] ?? data['sender_id'];
    final currentUserId =
        import_firebase_auth.FirebaseAuth.instance.currentUser?.uid;
    if (senderId != null &&
        currentUserId != null &&
        senderId.toString() == currentUserId) {
      return false;
    }
    if (targetRole != null &&
        targetRole.isNotEmpty &&
        targetRole != _userRole) {
      return false;
    }
    if (targetRoles is List &&
        targetRoles.isNotEmpty &&
        !targetRoles.map((e) => e.toString()).contains(_userRole)) {
      return false;
    }
    return true;
  }

  Future<void> _showImportantAnnouncementDialog({
    required String title,
    required String message,
    required List<String> ackIds,
    String? actionType,
    String? buttonText,
  }) async {
    if (!_canShowAttentionUI()) return;
    _isAttentionModalActive = true;

    final prefs = await SharedPreferences.getInstance();
    if (!mounted) {
      _isAttentionModalActive = false;
      return;
    }
    final acknowledgedIds =
        prefs.getStringList('acknowledged_important_announcements') ?? [];

    await showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (dialogContext) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
        },
        child: AlertDialog(
          backgroundColor: const Color(0xFF1E1E2C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4757).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.campaign_rounded,
                  color: Color(0xFFFF4757),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ),
          actions: [
            if (actionType == 'navigate_to_feedback')
              FilledButton(
                onPressed: () async {
                  for (final id in ackIds) {
                    if (!acknowledgedIds.contains(id)) {
                      acknowledgedIds.add(id);
                    }
                  }
                  await prefs.setStringList(
                    'acknowledged_important_announcements',
                    acknowledgedIds,
                  );
                  if (!dialogContext.mounted) return;
                  Navigator.of(dialogContext).pop();
                  if (!mounted) return;
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const ProfileScreen(highlightFeedback: true),
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF4FACFE),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  buttonText?.trim().isNotEmpty == true
                      ? buttonText!.trim()
                      : 'Open Profile',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            FilledButton(
              onPressed: () async {
                for (final id in ackIds) {
                  if (!acknowledgedIds.contains(id)) {
                    acknowledgedIds.add(id);
                  }
                }
                await prefs.setStringList(
                  'acknowledged_important_announcements',
                  acknowledgedIds,
                );
                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop();
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF4FACFE),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Got it',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );

    _isAttentionModalActive = false;
    if (mounted) {
      await _drainAttentionQueue();
    }
  }

  Future<void> _handlePostTutorialFlow() async {
    // Important announcements are intentionally shown only as dashboard cards.
    // No modal queue should run here.
    await _checkPendingAnnouncements();
  }

  Future<void> _drainAttentionQueue() async {
    if (!_canShowAttentionUI()) return;
    if (_pendingImportantAnnouncement != null &&
        _pendingImportantAnnouncementIds.isNotEmpty) {
      final data = _pendingImportantAnnouncement!;
      final ackIds = List<String>.from(_pendingImportantAnnouncementIds);
      _pendingImportantAnnouncement = null;
      _pendingImportantAnnouncementIds = [];
      await _showImportantAnnouncementDialog(
        title: data['title'] ?? 'Important Announcement',
        message: data['message'] ?? '',
        ackIds: ackIds,
        actionType: data['actionType']?.toString(),
        buttonText: data['buttonText']?.toString(),
      );
    }
  }

  void _setupNotificationListener() {
    // Listen for NEW announcements to trigger alert
    _announcementSubscription?.cancel();
    _announcementSubscription = FirebaseFirestore.instance
        .collection('announcements')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) async {
          if (snapshot.docs.isEmpty) return;

          final doc = snapshot.docs.first;
          final data = doc.data();
          final timestamp = (data['timestamp'] as Timestamp?)?.toDate();

          if (timestamp != null && timestamp.isAfter(_dashboardStartTime)) {
            // It's a new announcement created while app is running

            final type = data['type'] as String? ?? 'normal';

            // Important announcements stay on the dashboard card only.
            if (type == 'important') {
              return;
            }

            // Show notification tray notification for non-important announcements (if enabled)
            if (_notificationsEnabled && _announcementMatchesRole(data)) {
              _notificationService.showNotification(
                data['title'] ?? 'New Announcement',
                data['message'] ?? 'Check the dashboard for details.',
              );
            }
          }
        });
  }

  Future<void> _setupNotificationTapHandlers() async {
    _localNotificationTapSubscription?.cancel();
    _localNotificationTapSubscription = _notificationService.onNotificationTap
        .listen((payload) => _handleLocalNotificationTap(payload));

    _remoteNotificationTapSubscription?.cancel();
    _remoteNotificationTapSubscription = FirebaseMessaging.onMessageOpenedApp
        .listen((message) => _handleRemoteNotificationTap(message));

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      await _handleRemoteNotificationTap(initialMessage);
    }
  }

  Future<void> _handleLocalNotificationTap(String? payload) async {
    if (payload == null) return;
    if (payload == 'daily_tasks' || payload == 'daily_reminder') {
      await _queueDailyTasksNavigation();
    }
  }

  Future<void> _handleRemoteNotificationTap(RemoteMessage message) async {
    final type = message.data['type']?.toString();
    final screen = message.data['screen']?.toString();
    if (type == 'daily_reminder' || screen == 'daily_tasks') {
      await _queueDailyTasksNavigation();
    }
  }

  Future<void> _queueDailyTasksNavigation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_DashboardScreenState._pendingDailyTasksNavKey, true);
    await _navigateToPendingDailyTasks();
  }

  Future<void> _navigateToPendingDailyTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final pending =
        prefs.getBool(_DashboardScreenState._pendingDailyTasksNavKey) ?? false;
    if (!pending) return;
    if (_userRole != 'student') {
      await prefs.remove(_DashboardScreenState._pendingDailyTasksNavKey);
      return;
    }
    if (!mounted) return;
    _setDashboardTabIndex(1, animate: true);
    await prefs.remove(_DashboardScreenState._pendingDailyTasksNavKey);
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _preferredLanguage = prefs.getString('preferred_language') ?? 'Tamil';
      // Word Count
      _savedDailyWordCount = 5.0;
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      // Also load user role here
      _userRole = prefs.getString('user_role') ?? 'student';

      _avatarSeed = prefs.getString('avatar_seed') ?? '';
      _photoUrl = prefs.getString('photo_url') ?? '';
      _userEmail = prefs.getString('user_email') ?? '';
      _totalXp = prefs.getInt('user_total_xp') ?? 0;
      _xpLevel =
          prefs.getInt('user_xp_level') ?? prefs.getInt('user_level') ?? 1;
      _currentXp = prefs.getInt('user_current_xp') ?? 0;
      _requiredXp = XpRewardPolicy.requiredXpForLevel(_xpLevel);

      if (_userEmail.isEmpty) {
        final user = import_firebase_auth.FirebaseAuth.instance.currentUser;
        if (user != null) {
          _userEmail = user.email ?? '';
          prefs.setString('user_email', _userEmail);
        }
      }

      // Ensure name is loaded for notifications
      final user = import_firebase_auth.FirebaseAuth.instance.currentUser;
      if (user != null) {
        FirebaseFirestore.instance.collection('users').doc(user.uid).get().then(
          (doc) {
            if (doc.exists && doc.data() != null) {
              final data = doc.data() as Map<String, dynamic>;
              if (data.containsKey('name')) {
                final dbName = data['name'];
                prefs.setString('user_name', dbName);
                debugPrint("Dashboard: Synced user name from DB: $dbName");
              }
              if (data.containsKey('avatar_seed')) {
                final seed = data['avatar_seed'];
                prefs.setString('avatar_seed', seed);
                if (mounted) setState(() => _avatarSeed = seed);
              } else {
                prefs.remove('avatar_seed');
                if (mounted) setState(() => _avatarSeed = '');
              }
              if (data.containsKey('photo_url')) {
                final photo = data['photo_url'];
                prefs.setString('photo_url', photo);
                if (mounted) setState(() => _photoUrl = photo);
              } else {
                prefs.remove('photo_url');
                if (mounted) setState(() => _photoUrl = '');
              }
            }
          },
        );
      }
    });

    // Cloud Progress Sync
    await _dataService.syncProgressFromCloud();
    await _updateCurrentDayLabel(prefs: prefs);

    // Reload with synced data if needed (some local state might have changed)
    _preferredLanguage = prefs.getString('preferred_language') ?? 'Tamil';
    _savedDailyWordCount = 5.0;
    final syncedTotalXp = prefs.getInt('user_total_xp') ?? _totalXp;
    final syncedXpLevel =
        prefs.getInt('user_xp_level') ?? prefs.getInt('user_level') ?? _xpLevel;
    final syncedCurrentXp = prefs.getInt('user_current_xp') ?? _currentXp;
    final syncedRequiredXp = XpRewardPolicy.requiredXpForLevel(syncedXpLevel);
    if (mounted &&
        (syncedTotalXp != _totalXp ||
            syncedXpLevel != _xpLevel ||
            syncedCurrentXp != _currentXp ||
            syncedRequiredXp != _requiredXp)) {
      setState(() {
        _totalXp = syncedTotalXp;
        _xpLevel = syncedXpLevel;
        _currentXp = syncedCurrentXp;
        _requiredXp = syncedRequiredXp;
      });
    }

    // Load Notification State via Service (outside setState because it's async)
    final readIds = await _notificationService.getReadIds();
    final deletedIds = await _notificationService.getDeletedIds();
    debugPrint(
      "Dashboard: Loaded ${readIds.length} read, ${deletedIds.length} deleted.",
    );

    final teacherReadIds =
        (prefs.getStringList('teacher_read_notifications') ?? []).toSet();
    final teacherDeletedIds =
        (prefs.getStringList('teacher_deleted_notifications') ?? []).toSet();

    if (mounted) {
      setState(() {
        _readIds = readIds;
        _deletedIds = deletedIds;
        _teacherReadIds = teacherReadIds;
        _teacherDeletedIds = teacherDeletedIds;
        _announcementFiltersReady = true;
      });
    }
  }

  Future<void> _updateCurrentDayLabel({SharedPreferences? prefs}) async {
    final sharedPrefs = prefs ?? await SharedPreferences.getInstance();
    final stage = await _stageService.getCurrentStage(prefs: sharedPrefs);
    final label = _stageService.stageLabel(stage);

    if (mounted && _currentDayLabel != label) {
      setState(() => _currentDayLabel = label);
    }
  }

  Future<void> _fetchPlacementState() async {
    try {
      await PlacementStateService.ensureInitialized().timeout(
        const Duration(seconds: 5),
      );
      final status = await PlacementStateService.getPlacementQuizStatus()
          .timeout(const Duration(seconds: 5));
      if (mounted) {
        setState(() {
          _placementQuizStatus = status;
          _isPlacementStateLoading = false;
        });
        if (_currentIndex == 1 && !_isPlacementLocked) {
          _startProgressPolling();
          unawaited(_showDailyTasksTutorialIfNeeded());
        }
      }
      if (mounted) {
        await _drainAttentionQueue();
      }
    } catch (e) {
      debugPrint("Dashboard: Error fetching placement state: $e");
      if (mounted) setState(() => _isPlacementStateLoading = false);
    }
  }

  Future<void> _fetchAssessmentStatus() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Try local cache first for instant responsiveness
    if (mounted) {
      setState(() {
        _isAssessmentCompleted = prefs.getBool('assessment_completed') ?? false;
      });
    }

    // Backward compatibility: migrate legacy assessment_status to completion flags.
    final localUser = import_firebase_auth.FirebaseAuth.instance.currentUser;
    final localUserId = localUser?.uid ?? 'guest';
    final legacyStatus = prefs.getString('assessment_status_$localUserId');
    if (legacyStatus == 'completed' &&
        (!prefs.containsKey('assessment_completed') ||
            !_isAssessmentCompleted)) {
      await prefs.setBool('assessment_completed', true);
      await prefs.setBool('assessment_skipped', false);
      if (mounted) {
        setState(() {
          _isAssessmentCompleted = true;
        });
      }
    }

    // 2. Fetch from Cloud to be sure
    final user = import_firebase_auth.FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          bool completed = data['assessment_completed'] ?? false;
          bool skipped = data['assessment_skipped'] ?? false;
          final status = data['assessment_status'];
          if (status == 'completed' && completed == false) {
            completed = true;
            skipped = false;
          }

          await prefs.setBool('assessment_completed', completed);
          await prefs.setBool('assessment_skipped', skipped);

          if (mounted) {
            setState(() {
              _isAssessmentCompleted = completed;
            });
          }
        }
      } catch (e) {
        debugPrint("Dashboard: Error fetching assessment status: $e");
      }
    }
  }
}
