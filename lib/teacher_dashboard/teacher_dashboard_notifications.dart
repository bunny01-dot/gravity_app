// ignore_for_file: invalid_use_of_protected_member, library_private_types_in_public_api

part of 'teacher_dashboard_screen.dart';

extension TeacherDashboardNotifications on _TeacherDashboardState {
  void _showAnnouncementDialog() {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    bool isImportant = true;

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, _, __) => StatefulBuilder(
          builder: (context, setState) {
            final theme = Theme.of(context);
            final isDark = theme.brightness == Brightness.dark;
            final onSurface = theme.colorScheme.onSurface;
            final colorScheme = theme.colorScheme;
            return Stack(
              children: [
                // Blurred & Darkened Background
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(color: Colors.black.withValues(alpha: 0.7)),
                ),

                // Centered Announcement Card
                Center(
                  child: Material(
                    type: MaterialType.transparency,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      constraints: const BoxConstraints(maxWidth: 500),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? const [Color(0xFF1E1E2C), Color(0xFF2C2C3E)]
                              : const [Color(0xFFFFFFFF), Color(0xFFF1F6FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color:
                              (isDark
                                      ? const Color(0xFFFFD700)
                                      : colorScheme.primary)
                                  .withValues(alpha: 0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                (isDark
                                        ? const Color(0xFFFFD700)
                                        : colorScheme.primary)
                                    .withValues(alpha: isDark ? 0.3 : 0.18),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                              ),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(24),
                                topRight: Radius.circular(24),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color:
                                        (isDark ? Colors.black : Colors.white)
                                            .withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.campaign_rounded,
                                    color: Color(0xFF1E1E2C),
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Expanded(
                                  child: Text(
                                    "Send Announcement",
                                    style: TextStyle(
                                      color: Color(0xFF1E1E2C),
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _handleCloseDialog(context),
                                  icon: const Icon(
                                    Icons.close,
                                    color: Color(0xFF1E1E2C),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Content
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                TextField(
                                  controller: titleController,
                                  decoration: InputDecoration(
                                    hintText: "Announcement Title",
                                    hintStyle: TextStyle(
                                      color: onSurface.withValues(alpha: 0.5),
                                    ),
                                    filled: true,
                                    fillColor: isDark
                                        ? Colors.white.withValues(alpha: 0.05)
                                        : Colors.white.withValues(alpha: 0.9),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: onSurface.withValues(
                                          alpha: 0.12,
                                        ),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: onSurface.withValues(
                                          alpha: 0.12,
                                        ),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFFFD700),
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  style: TextStyle(color: onSurface),
                                  autofocus: true,
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: messageController,
                                  decoration: InputDecoration(
                                    hintText: "Message body...",
                                    hintStyle: TextStyle(
                                      color: onSurface.withValues(alpha: 0.5),
                                    ),
                                    filled: true,
                                    fillColor: isDark
                                        ? Colors.white.withValues(alpha: 0.05)
                                        : Colors.white.withValues(alpha: 0.9),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: onSurface.withValues(
                                          alpha: 0.12,
                                        ),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: onSurface.withValues(
                                          alpha: 0.12,
                                        ),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFFFD700),
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  style: TextStyle(color: onSurface),
                                  maxLines: 4,
                                ),
                                const SizedBox(height: 16),
                                TeacherTranslucentCard(
                                  child: Theme(
                                    data: Theme.of(context).copyWith(
                                      switchTheme: SwitchThemeData(
                                        thumbColor:
                                            WidgetStateProperty.resolveWith((
                                              states,
                                            ) {
                                              if (states.contains(
                                                WidgetState.selected,
                                              )) {
                                                return const Color(0xFFFFD700);
                                              }
                                              return null;
                                            }),
                                        trackColor:
                                            WidgetStateProperty.resolveWith((
                                              states,
                                            ) {
                                              if (states.contains(
                                                WidgetState.selected,
                                              )) {
                                                return const Color(
                                                  0xFFFFD700,
                                                ).withValues(alpha: 0.5);
                                              }
                                              return null;
                                            }),
                                      ),
                                    ),
                                    child: SwitchListTile(
                                      title: const Text(
                                        "Important Notification",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                      subtitle: Text(
                                        isImportant
                                            ? "Sent as High Priority (Heads-up)"
                                            : "Sent as Standard Notification",
                                        style: TextStyle(
                                          color: onSurface.withValues(
                                            alpha: 0.62,
                                          ),
                                          fontSize: 11,
                                        ),
                                      ),
                                      value: isImportant,
                                      onChanged: (val) =>
                                          _handleAnnouncementImportantChanged(
                                            setState,
                                            (value) => isImportant = value,
                                            val,
                                          ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                          ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    onPressed: () =>
                                        _handleManageHistoryTap(context),
                                    icon: const Icon(
                                      Icons.delete_sweep,
                                      color: Colors.white54,
                                      size: 16,
                                    ),
                                    label: Text(
                                      "Manage History",
                                      style: TextStyle(
                                        color: onSurface.withValues(
                                          alpha: 0.62,
                                        ),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Action Buttons
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                            child: Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () =>
                                        _handleCloseDialog(context),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: onSurface,
                                      side: BorderSide(
                                        color: onSurface.withValues(alpha: 0.3),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text("Cancel"),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _handleSendAnnouncement(
                                      context,
                                      titleController,
                                      messageController,
                                      isImportant,
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFFD700),
                                      foregroundColor: const Color(0xFF1E1E2C),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.send, size: 18),
                                        SizedBox(width: 8),
                                        Text(
                                          "Send",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showClearHistoryDialog() {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModernDialog(
      context,
      title: "History",
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('announcements')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildAsyncLoader(label: "Loading history...");
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        "No history",
                        style: TextStyle(
                          color: onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    );
                  }

                  final docs = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final title = data['title'] ?? 'No Title';
                      final message = data['message'] ?? '';
                      final date = (data['timestamp'] as Timestamp?)?.toDate();
                      final dateStr = date != null
                          ? "${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}"
                          : '-';

                      return TeacherTranslucentCard(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(
                            title,
                            style: TextStyle(
                              color: onSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                message,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: onSurface.withValues(alpha: 0.72),
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                dateStr,
                                style: TextStyle(
                                  color: onSurface.withValues(alpha: 0.3),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                              size: 20,
                            ),
                            onPressed: () =>
                                _handleDeleteAnnouncementDoc(doc.reference),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Divider(
              color: isDark
                  ? Colors.white10
                  : onSurface.withValues(alpha: 0.12),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleDeleteAnnouncementsFromHistory(
                      context,
                      olderThan7Days: true,
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.orangeAccent),
                      foregroundColor: Colors.orangeAccent,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      "Delete Older (>7d)",
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleDeleteAnnouncementsFromHistory(
                      context,
                      olderThan7Days: false,
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.redAccent),
                      foregroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      "Delete All",
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      primaryButtonText: "Close",
      onPrimaryPressed: () => _handleCloseRootDialog(context),
      // Remove secondary buttons from standard dialog as we put them in content
      icon: Icons.history_rounded,
    );
  }

  Future<void> _deleteAnnouncements({required bool olderThan7Days}) async {
    bool loadingDialogShown = false;
    try {
      final collection = FirebaseFirestore.instance.collection('announcements');
      QuerySnapshot snapshot;

      if (olderThan7Days) {
        final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
        snapshot = await collection
            .where('timestamp', isLessThan: Timestamp.fromDate(sevenDaysAgo))
            .get();
      } else {
        snapshot = await collection.get();
      }

      if (snapshot.docs.isEmpty) {
        if (mounted) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final onSurface = Theme.of(context).colorScheme.onSurface;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: isDark ? Colors.white : onSurface,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "No announcements found to delete.",
                    style: TextStyle(color: isDark ? Colors.white : onSurface),
                  ),
                ],
              ),
              backgroundColor: Colors.blueGrey,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
        return;
      }

      // Show Loading Dialog
      if (mounted) {
        loadingDialogShown = true;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final onSurface = Theme.of(context).colorScheme.onSurface;
            return Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF11131A).withValues(alpha: 0.92)
                      : Colors.white.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFFFF4757).withValues(alpha: 0.36),
                  ),
                ),
                child: _buildAsyncLoader(
                  label: "Deleting announcements...",
                  size: 88,
                  fontSize: 13,
                  textColor: isDark
                      ? const Color(0xFFFF8A93)
                      : onSurface.withValues(alpha: 0.72),
                ),
              ),
            );
          },
        );
      }

      // Batch delete
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      if (mounted && loadingDialogShown) {
        Navigator.of(
          context,
          rootNavigator: true,
        ).pop(); // Close loading dialog safely
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  olderThan7Days
                      ? "Old announcements removed successfully."
                      : "All announcements cleared successfully.",
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Safe Close
        if (loadingDialogShown) {
          Navigator.of(context, rootNavigator: true).pop();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to clear: $e"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _sendStudentNotification({
    required String uid,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _notificationService.sendTeacherNotification(
        studentUid: uid,
        title: title,
        body: body,
        type: type,
        data: data,
      );
    } catch (e) {
      debugPrint("In-app notification failed: $e");
    }

    // Attempt push via Cloud Function (best-effort)
    try {
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('sendIndividualNotification');
      final result = await callable.call({
        'targetUserId': uid,
        'title': title,
        'body': body,
        'data': {
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          'type': type,
          ...?data,
        },
      });
      final resData = result.data;
      if (resData is Map && resData['success'] == false) {
        debugPrint("Push skipped (no token). In-app saved.");
      }
    } catch (e) {
      debugPrint("Cloud Function push failed: $e");
    }
  }

  Future<void> _notifyStudentAccountChange({
    required String uid,
    required bool isBlocked,
    required String reason,
  }) async {
    final title = isBlocked ? "Account Deactivated" : "Account Reactivated";
    final body = isBlocked
        ? "Your account access was disabled by your teacher. Please contact your teacher to regain access."
        : "Your account access has been restored. You can now continue learning.";

    await _sendStudentNotification(
      uid: uid,
      title: title,
      body: body,
      type: isBlocked ? "account_blocked" : "account_unblocked",
      data: {'reason': reason},
    );
  }

  Future<void> _notifyStudentProgressReset({required String uid}) async {
    await _sendStudentNotification(
      uid: uid,
      title: "Progress Reset",
      body:
          "Your learning progress was reset by your teacher. Please take the placement quiz to start fresh.",
      type: "progress_reset",
      data: {'requires_placement_quiz': true},
    );
  }

  Future<void> _toggleBlockStudent(
    String docId,
    bool isAlreadyBlocked, {
    String reason = 'manual_block',
  }) async {
    try {
      final update = <String, dynamic>{'isBlocked': !isAlreadyBlocked};

      if (!isAlreadyBlocked) {
        update['blockedAt'] = FieldValue.serverTimestamp();
        update['blockedReason'] = reason;
        final teacher = FirebaseAuth.instance.currentUser;
        if (teacher != null) {
          update['blockedBy'] = teacher.uid;
        }
      } else {
        update['blockedAt'] = FieldValue.delete();
        update['blockedReason'] = FieldValue.delete();
        update['blockedBy'] = FieldValue.delete();
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(docId)
          .update(update);

      await _notifyStudentAccountChange(
        uid: docId,
        isBlocked: !isAlreadyBlocked,
        reason: reason,
      );

      await StudentsCache().refresh();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAlreadyBlocked ? "User unblocked" : "User blocked"),
            backgroundColor: isAlreadyBlocked ? Colors.green : Colors.orange,
          ),
        );
        setState(() {});
      }
    } catch (e) {
      debugPrint("Error blocking user: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _confirmDeactivateStudent(
    BuildContext context,
    String docId,
    String name,
  ) {
    showModernDialog(
      context,
      title: "Deactivate Student?",
      message:
          "This will block '$name' from accessing the app until you unblock them. They will need to request access to regain entry.",
      primaryButtonText: "Deactivate",
      onPrimaryPressed: () =>
          _handleDeactivateStudentConfirm(context, docId, name),
      secondaryButtonText: "Cancel",
      onSecondaryPressed: () => _handleCloseRootDialog(context),
      icon: Icons.lock_person_rounded,
      accentColor: Colors.red,
    );
  }

  void _confirmResetProgress(BuildContext context, String uid, String name) {
    showModernDialog(
      context,
      title: "Reset Progress?",
      message:
          "Are you sure you want to RESET progress for '$name'?\n\nThey will lose all XP, Levels, and Streaks. This cannot be undone.",
      primaryButtonText: "Reset Everything",
      onPrimaryPressed: () => _handleResetProgressConfirm(context, uid, name),
      secondaryButtonText: "Cancel",
      onSecondaryPressed: () => _handleCloseRootDialog(context),
      icon: Icons.warning_amber_rounded,
      accentColor: Colors.orange,
    );
  }
}
