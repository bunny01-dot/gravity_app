// ignore_for_file: invalid_use_of_protected_member, library_private_types_in_public_api

part of 'teacher_dashboard_screen.dart';

extension TeacherDashboardActions on _TeacherDashboardState {
  void _handleBottomNavTap(int index) {
    setState(() => _currentIndex = index);
  }

  void _handleGoToLibraryTab() {
    setState(() => _currentIndex = 2);
  }

  void _handleSendAnnouncementTap() {
    _showAnnouncementDialog();
  }

  Future<void> _handleRefreshStudents() async {
    await StudentsCache().refresh();
    setState(() {});
  }

  void _handleStudentRowTap(
    BuildContext context,
    String uid,
    Map<String, dynamic> data,
  ) {
    _showStudentDetails(context, uid, data);
  }

  void _handleStudentMenuSelection(
    BuildContext context,
    String value,
    String uid,
    String name,
    String email,
    Map<String, dynamic> data,
  ) {
    if (value == 'change_difficulty') {
      _showChangeDifficultyDialog(uid, name, email);
    } else if (value == 'block') {
      _toggleBlockStudent(
        uid,
        data['isBlocked'] == true,
        reason: 'manual_block',
      );
    } else if (value == 'deactivate') {
      _confirmDeactivateStudent(context, uid, name);
    } else if (value == 'reset') {
      _confirmResetProgress(context, uid, name);
    }
  }

  void _handleImportCsvTap() {
    _showImportCsvDialog();
  }

  Future<void> _handleSyncSheet() async {
    // 1. Show Loading Dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          color: Color(0xFF1E1E2C),
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFFFFD700)),
                SizedBox(height: 16),
                Text("Syncing data...", style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ),
      ),
    );

    // 2. Perform Sync
    String log = await _dataService.forceRefreshData();

    // 3. Close Loading Dialog
    if (mounted) {
      Navigator.pop(context);
    }

    setState(() {}); // Refresh UI

    // 4. Show Report
    if (mounted) {
      showModernDialog(
        context,
        title: "Sync Report",
        content: SingleChildScrollView(
          child: Text(
            log,
            style: const TextStyle(
              color: Colors.white70,
              fontFamily: 'Courier', // Monospace for logs
              fontSize: 12,
            ),
          ),
        ),
        primaryButtonText: "Close",
        onPrimaryPressed: () => Navigator.pop(context),
        icon: Icons.sync_rounded,
        accentColor: Colors.greenAccent,
      );
    }
  }

  Future<bool?> _confirmDeleteLibraryItem({
    required Map<String, String> item,
    required String title,
  }) async {
    bool? confirm = await showModernDialog(
      context,
      title: "Delete Item?",
      message:
          "Are you sure you want to delete '${item['word'] ?? title}' from $_selectedCategory?",
      primaryButtonText: "Delete",
      onPrimaryPressed: () =>
          Navigator.pop(context, true), // Pop with true for confirmation
      secondaryButtonText: "Cancel",
      onSecondaryPressed: () =>
          Navigator.pop(context, false), // Pop with false for cancellation
      icon: Icons.delete_forever_rounded,
      accentColor: Colors.redAccent,
    );
    return confirm;
  }

  Future<void> _handleLibraryItemDismissed(int index) async {
    await _dataService.deleteItem(_selectedCategory, index);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Item deleted")));
      setState(() {}); // Refresh
    }
  }

  void _handleEditItemTap(Map<String, String> item, int index) {
    _showEditDialog(item, index);
  }

  Future<void> _handleSaveEditedItem(
    Map<String, TextEditingController> controllers,
    int index,
  ) async {
    try {
      // Close dialog first using root navigator to be safe
      Navigator.of(context, rootNavigator: true).pop();

      // Collect updated data
      final Map<String, String> updatedItem = {};
      controllers.forEach((key, controller) {
        updatedItem[key] = controller.text.trim();
      });

      await _dataService.updateItem(_selectedCategory, index, updatedItem);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Item updated locally. Remember to update your Google Sheet!",
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
        setState(() {});
      }
    } catch (e) {
      debugPrint("Error updating item: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error updating item: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleNotificationsChanged(bool val) async {
    setState(() => _notificationsEnabled = val);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', val);
  }

  void _handleOpenDebugErrors() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TeacherDebugErrorsScreen()),
    );
  }

  void _handleOpenBugReports() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TeacherFeedbackScreen(
          collection: 'bug_reports',
          title: 'Manual Bug Reports',
        ),
      ),
    );
  }

  Future<void> _handleOpenSystemSettings() async {
    await openAppSettings();
  }

  void _handleNotificationsTap() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TeacherNotificationsScreen()),
    ).then((_) {
      _loadTeacherInfo();
      _refreshNotificationCount(); // Refresh after viewing
    });
  }

  void _handleProfileTap() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    ).then((_) => _loadTeacherInfo());
  }

  void _handleAnnouncementImportantChanged(
    StateSetter dialogSetState,
    void Function(bool) setImportant,
    bool val,
  ) {
    dialogSetState(() => setImportant(val));
  }

  void _handleManageHistoryTap(BuildContext dialogContext) {
    Navigator.pop(dialogContext);
    _showClearHistoryDialog();
  }

  Future<void> _handleSendAnnouncement(
    BuildContext dialogContext,
    TextEditingController titleController,
    TextEditingController messageController,
    bool isImportant,
  ) async {
    if (titleController.text.trim().isEmpty) return;

    final title = titleController.text.trim();
    final message = messageController.text.trim();
    final important = isImportant;

    // ✅ FIX: Capture ScaffoldMessenger before popping
    final scaffoldMessenger = ScaffoldMessenger.of(dialogContext);

    Navigator.pop(dialogContext);

    try {
      await FirebaseFirestore.instance.collection('announcements').add({
        'title': title,
        'message': message,
        'sender': 'Teacher',
        'type': important ? 'important' : 'normal',
        'timestamp': FieldValue.serverTimestamp(),
      });

      try {
        await FCMService().notifyAllStudents(
          title: title,
          message: message,
          isImportant: important,
        );
      } catch (fcmError) {
        debugPrint("⚠️ Notification send failed: $fcmError");
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text("Saved to DB, but Push failed: $fcmError"),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }

      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text("Announcement posted successfully!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint("❌ Error posting announcement: $e");
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  void _handleCloseDialog(BuildContext dialogContext) {
    Navigator.pop(dialogContext);
  }

  void _handleCloseRootDialog(BuildContext dialogContext) {
    Navigator.of(dialogContext, rootNavigator: true).pop();
  }

  Future<void> _handleDeleteAnnouncementDoc(DocumentReference reference) async {
    await reference.delete();
  }

  Future<void> _handleDeleteAnnouncementsFromHistory(
    BuildContext dialogContext, {
    required bool olderThan7Days,
  }) async {
    Navigator.of(dialogContext, rootNavigator: true).pop();
    await _deleteAnnouncements(olderThan7Days: olderThan7Days);
  }

  void _handleImportTypeChanged(
    StateSetter dialogSetState,
    void Function(String) setSelectedType,
    String? value,
  ) {
    if (value == null) return;
    dialogSetState(() => setSelectedType(value));
  }

  Future<void> _handleImportCsvSubmit(
    TextEditingController urlController,
    String selectedType,
  ) async {
    if (urlController.text.trim().isEmpty) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Importing data... Please wait.")),
    );
    bool success = await _dataService.importCsvFromUrl(
      urlController.text.trim(),
      selectedType,
    );
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Import successful!"),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {});
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("❌ Import failed."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleDeactivateStudentConfirm(
    BuildContext dialogContext,
    String docId,
    String name,
  ) async {
    Navigator.of(dialogContext, rootNavigator: true).pop(); // Close dialog
    try {
      await _toggleBlockStudent(docId, false, reason: 'deactivated_by_teacher');

      if (dialogContext.mounted) {
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          const SnackBar(
            content: Text("Student deactivated"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (dialogContext.mounted) {
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          SnackBar(
            content: Text("Error deactivating: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleResetProgressConfirm(
    BuildContext dialogContext,
    String uid,
    String name,
  ) async {
    Navigator.of(dialogContext, rootNavigator: true).pop();
    try {
      // Show loading
      ScaffoldMessenger.of(dialogContext).showSnackBar(
        const SnackBar(
          content: Text("Resetting progress..."),
          backgroundColor: Colors.orangeAccent,
        ),
      );

      await _dataService.resetStudentProgress(uid);
      await _notifyStudentProgressReset(uid: uid);
      await StudentsCache().refresh();

      if (dialogContext.mounted) {
        setState(() {});
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          const SnackBar(
            content: Text("Progress has been reset."),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (dialogContext.mounted) {
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleFindStudentFix({
    required BuildContext dialogContext,
    required StateSetter dialogSetState,
    required TextEditingController emailController,
    required String Function() getResultMessage,
    required void Function(String) setResultMessage,
    required void Function(bool) setIsSearching,
  }) async {
    dialogSetState(() => setIsSearching(true));
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: emailController.text.trim().toLowerCase())
          .get();
      if (snap.docs.isNotEmpty) {
        // Fix Role or Date based on message
        Map<String, dynamic> updates = {};
        if (getResultMessage().contains("MISSING DATE")) {
          updates['createdAt'] = FieldValue.serverTimestamp();
        } else {
          updates['role'] = 'student';
        }

        await snap.docs.first.reference.update(updates);

        // Force immediate refresh of the cache
        await StudentsCache().refresh();

        // Update UI
        dialogSetState(() {
          setResultMessage("✅ ACCOUNT FIXED! Refreshing list...");
          setIsSearching(false);
        });

        // Close dialog after short delay to show success
        Future.delayed(const Duration(seconds: 1), () {
          if (dialogContext.mounted) {
            Navigator.pop(dialogContext);
            // Trigger parent rebuild
            _refreshDashboard();
          }
        });
      }
    } catch (e) {
      dialogSetState(() {
        setResultMessage("Error fixing: $e");
        setIsSearching(false);
      });
    }
  }

  Future<void> _handleFindStudentSearch({
    required BuildContext dialogContext,
    required StateSetter dialogSetState,
    required TextEditingController emailController,
    required void Function(bool) setIsSearching,
    required void Function(String) setResultMessage,
  }) async {
    final email = emailController.text.trim().toLowerCase();
    if (email.isEmpty) return;

    dialogSetState(() {
      setIsSearching(true);
      setResultMessage("");
    });

    try {
      // Also searching by 'email' field, which is standard in this app
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      dialogSetState(() {
        setIsSearching(false);
        if (snap.docs.isEmpty) {
          setResultMessage("❌ Not Found: No account exists with this email.");
        } else {
          final data = snap.docs.first.data();
          final role = data['role'];
          final createdAt = data['createdAt'];

          if (role == 'student') {
            if (createdAt == null) {
              setResultMessage(
                "⚠️ Found but MISSING DATE. The 'createdAt' field is missing, so they are hidden from the sorted list.",
              );
            } else {
              // FORCE ADD to cache if it's correct but missing
              StudentsCache().forceAddStudent(snap.docs.first);

              // Update UI
              setResultMessage(
                "✅ Found & Added! Account is healthy. Refreshing list...",
              );

              // Close dialog and refresh
              Future.delayed(const Duration(seconds: 1), () {
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                  _refreshDashboard();
                }
              });
            }
          } else if (role == null) {
            setResultMessage(
              "⚠️ Found but MISSING ROLE. This is why they aren't in the list.",
            );
          } else {
            setResultMessage(
              "⚠️ Found but Wrong Role: '$role'. Only 'student' role appears in this list.",
            );
          }
        }
      });
    } catch (e) {
      dialogSetState(() {
        setIsSearching(false);
        setResultMessage("Error: $e");
      });
    }
  }

  Future<void> _handleUpdateDifficultyLevel(
    BuildContext dialogContext,
    String uid,
    String selectedLevel,
    String currentLevel,
  ) async {
    if (selectedLevel == currentLevel) {
      Navigator.pop(dialogContext);
      return;
    }

    try {
      // Update Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'effective_difficulty_level': selectedLevel,
        'english_proficiency_level': selectedLevel, // Legacy support
        'proficiency_changed_by_teacher': true,
        'proficiency_changed_at': FieldValue.serverTimestamp(),
      });

      // Notify student: always write in-app notification, then attempt push
      try {
        await _notificationService.sendTeacherNotification(
          studentUid: uid,
          title: "Difficulty Level Updated",
          body:
              "Your teacher has adjusted your difficulty level to: $selectedLevel",
          type: "difficulty_change",
          data: {'new_level': selectedLevel, 'changed_by': 'teacher'},
        );

        // Send Push Notification via Cloud Function (FCM)
        // This ensures delivery even if app is terminated
        try {
          final functions = FirebaseFunctions.instance;
          final callable = functions.httpsCallable(
            'sendIndividualNotification',
          );
          final result = await callable.call({
            'targetUserId': uid, // Common naming convention
            'title': "Difficulty Level Updated",
            'body': "Your level has been changed to $selectedLevel.",
            'data': {
              'click_action':
                  'FLUTTER_NOTIFICATION_CLICK', // Required for click handling
              'type': 'difficulty_change',
              'new_level': selectedLevel,
            },
          });
          final data = result.data;
          if (data is Map && data['success'] == false) {
            debugPrint(
              "⚠️ Push skipped (no token). In-app notification saved.",
            );
          }
        } catch (e) {
          debugPrint("⚠️ Cloud Function Push Failed: $e");
        }
      } catch (notiError) {
        debugPrint("⚠️ Notification failed: $notiError");
        // Proceed anyway since DB update succeeded
      }

      if (dialogContext.mounted) {
        Navigator.pop(dialogContext);
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          SnackBar(
            content: Text(
              "✅ Difficulty updated to $selectedLevel. Student notified.",
            ),
            backgroundColor: const Color(0xFF4FACFE),
          ),
        );
        // Refresh student list
        setState(() {});
      }
    } catch (e) {
      if (dialogContext.mounted) {
        Navigator.pop(dialogContext);
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          SnackBar(
            content: Text("Error updating difficulty: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}
