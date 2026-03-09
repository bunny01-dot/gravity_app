import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gravity_app/widgets/modern_glass_dialog.dart';

class TeacherNotificationsScreen extends StatefulWidget {
  const TeacherNotificationsScreen({super.key});

  @override
  State<TeacherNotificationsScreen> createState() =>
      _TeacherNotificationsScreenState();
}

class _TeacherNotificationsScreenState
    extends State<TeacherNotificationsScreen> {
  Set<String> _readIds = {};
  Set<String> _deletedIds = {};
  final Set<String> _selectedIds = {};
  bool _isLoading = true;
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _readIds = (prefs.getStringList('teacher_read_notifications') ?? [])
          .toSet();
      _deletedIds = (prefs.getStringList('teacher_deleted_notifications') ?? [])
          .toSet();
      _isLoading = false;
    });
  }

  Future<void> _markAsRead(String id) async {
    final prefs = await SharedPreferences.getInstance();
    _readIds.add(id);
    await prefs.setStringList('teacher_read_notifications', _readIds.toList());

    // Also mark in Firestore
    try {
      await FirebaseFirestore.instance
          .collection('teacher_notifications')
          .doc(id)
          .update({'isRead': true});
    } catch (e) {
      debugPrint('Error marking as read: $e');
    }

    setState(() {});
  }

  Future<void> _deleteNotification(String id) async {
    // Delete from Firestore
    try {
      await FirebaseFirestore.instance
          .collection('teacher_notifications')
          .doc(id)
          .delete();
      // We don't strictly need to update local prefs if we use stream builder
      // but for immediate UI response before stream update:
      _deletedIds.add(id);
      setState(() {});
    } catch (e) {
      debugPrint("Error deleting notification: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to delete: $e")));
      }
    }
  }

  Future<void> _markAllAsRead(List<String> allIds) async {
    final prefs = await SharedPreferences.getInstance();
    _readIds.addAll(allIds);
    await prefs.setStringList('teacher_read_notifications', _readIds.toList());

    // Batch update Firestore
    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final id in allIds) {
        final ref = FirebaseFirestore.instance
            .collection('teacher_notifications')
            .doc(id);
        batch.update(ref, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint("Error batch marking read: $e");
    }

    setState(() {});
  }

  Future<void> _deleteSelected() async {
    final colorScheme = Theme.of(context).colorScheme;
    showModernDialog(
      context,
      title: "Permanent Delete",
      content: Text(
        "Are you sure you want to permanently delete ${_selectedIds.length} notifications? This action cannot be undone.",
        style: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 16,
          height: 1.5,
        ),
        textAlign: TextAlign.center,
      ),
      primaryButtonText: "Delete",
      secondaryButtonText: "Cancel",
      onPrimaryPressed: () async {
        Navigator.pop(context); // Close dialog

        try {
          final batch = FirebaseFirestore.instance.batch();
          for (final id in _selectedIds) {
            final ref = FirebaseFirestore.instance
                .collection('teacher_notifications')
                .doc(id);
            batch.delete(ref);
          }
          await batch.commit();

          _deletedIds.addAll(_selectedIds); // Optimistic update
          _selectedIds.clear();
          _isSelectionMode = false;
          setState(() {});

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Selected notifications permanently deleted."),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } catch (e) {
          debugPrint("Error batch deleting: $e");
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Error deleting: $e"),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        }
      },
      onSecondaryPressed: () => Navigator.pop(context),
      icon: Icons.delete_forever_rounded,
    );
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background Blobs
          Positioned(
            top: -100,
            right: -100,
            child:
                Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorScheme.primary.withValues(
                          alpha: isDark ? 0.15 : 0.1,
                        ),
                      ),
                    )
                    .animate()
                    .scale(duration: 2.seconds, curve: Curves.easeInOut)
                    .fadeIn(),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child:
                Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorScheme.secondary.withValues(
                          alpha: isDark ? 0.12 : 0.08,
                        ),
                      ),
                    )
                    .animate()
                    .scale(duration: 2.5.seconds, curve: Curves.easeInOut)
                    .fadeIn(),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(color: Colors.transparent),
          ),

          // Content
          Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('teacher_notifications')
                            .orderBy('timestamp', descending: true)
                            .limit(100)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                "Error loading notifications",
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            );
                          }

                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return _buildEmptyState();
                          }

                          // Filter deleted
                          final docs = snapshot.data!.docs
                              .where((doc) => !_deletedIds.contains(doc.id))
                              .toList();

                          if (docs.isEmpty) return _buildEmptyState();

                          // Convert to list of IDs to help "Mark All"
                          final allVisibleIds = docs.map((d) => d.id).toList();

                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (!_isSelectionMode)
                                      TextButton.icon(
                                        onPressed: () =>
                                            _markAllAsRead(allVisibleIds),
                                        icon: const Icon(
                                          Icons.done_all_rounded,
                                          size: 18,
                                        ),
                                        label: const Text("Mark All Read"),
                                        style: TextButton.styleFrom(
                                          foregroundColor: colorScheme.primary,
                                        ),
                                      )
                                    else
                                      TextButton.icon(
                                        onPressed: () {
                                          setState(() {
                                            if (_selectedIds.length ==
                                                allVisibleIds.length) {
                                              _selectedIds.clear();
                                            } else {
                                              _selectedIds.addAll(
                                                allVisibleIds,
                                              );
                                            }
                                          });
                                        },
                                        icon: Icon(
                                          _selectedIds.length ==
                                                  allVisibleIds.length
                                              ? Icons.deselect_rounded
                                              : Icons.select_all_rounded,
                                          size: 18,
                                        ),
                                        label: Text(
                                          _selectedIds.length ==
                                                  allVisibleIds.length
                                              ? "Deselect All"
                                              : "Select All",
                                        ),
                                        style: TextButton.styleFrom(
                                          foregroundColor: colorScheme.primary,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: ListView.builder(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  itemCount: docs.length,
                                  itemBuilder: (context, index) {
                                    final doc = docs[index];
                                    final data =
                                        doc.data() as Map<String, dynamic>;
                                    final id = doc.id;
                                    final bool isRead =
                                        _readIds.contains(id) ||
                                        (data['isRead'] == true);
                                    final isSelected = _selectedIds.contains(
                                      id,
                                    );

                                    return _buildNotificationItem(
                                          doc,
                                          data,
                                          isRead,
                                          isSelected,
                                          index,
                                        )
                                        .animate()
                                        .fadeIn(
                                          duration: 400.ms,
                                          delay: (50 * index).ms,
                                        )
                                        .slideY(
                                          begin: 0.1,
                                          end: 0,
                                          duration: 400.ms,
                                        );
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            if (!_isSelectionMode)
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.66,
                          )
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 20,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            if (_isSelectionMode)
              IconButton(
                onPressed: () {
                  setState(() {
                    _isSelectionMode = false;
                    _selectedIds.clear();
                  });
                },
                icon: Icon(Icons.close, color: colorScheme.onSurface),
              ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                _isSelectionMode
                    ? "${_selectedIds.length} Selected"
                    : "Student Activity",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            if (_isSelectionMode)
              IconButton(
                onPressed: _deleteSelected,
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              )
            else
              IconButton(
                onPressed: () {
                  setState(() {
                    _isSelectionMode = true;
                  });
                },
                icon: Icon(
                  Icons.checklist_rounded,
                  color: colorScheme.onSurface,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: isDark
                  ? colorScheme.surfaceContainerHigh.withValues(alpha: 0.5)
                  : colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.task_alt_rounded,
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ).animate().scale(duration: 1.seconds, curve: Curves.elasticOut),
          const SizedBox(height: 24),
          Text(
            "No Student Activity Yet",
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Student task completions will appear here.",
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(
    DocumentSnapshot doc,
    Map<String, dynamic> data,
    bool isRead,
    bool isSelected,
    int index,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    final type = data['type'] ?? 'unknown';
    final studentEmail = data['student_email'] ?? 'Unknown Student';
    final taskTitle = data['task_title'] ?? 'Task';
    final message = data['message'] ?? '';
    final timestamp = data['timestamp'] as Timestamp?;
    final dateStr = timestamp != null
        ? _formatTimestamp(timestamp.toDate())
        : 'Just now';

    IconData icon;
    Color iconColor;
    String title;

    if (type == 'task_completion') {
      icon = Icons.task_alt_rounded;
      iconColor = colorScheme.primary;
      title = 'Task Completed';
    } else {
      icon = Icons.info_outline_rounded;
      iconColor = Colors.amberAccent;
      title = 'Student Activity';
    }

    return GestureDetector(
      onLongPress: () {
        if (!_isSelectionMode) {
          setState(() {
            _isSelectionMode = true;
            _selectedIds.add(doc.id);
          });
        }
      },
      onTap: () {
        if (_isSelectionMode) {
          _toggleSelection(doc.id);
        } else {
          if (!isRead) _markAsRead(doc.id);
          _showDetailDialog(title, studentEmail, taskTitle, message, dateStr);
        }
      },
      child: Container(
        // Wrap dismissal in container if selection mode is on to disable swipe
        child: _isSelectionMode
            ? _buildContent(
                doc,
                data,
                isRead,
                isSelected,
                icon,
                iconColor,
                title,
                studentEmail,
                taskTitle,
                dateStr,
              )
            : Dismissible(
                key: Key(doc.id),
                direction: DismissDirection.endToStart,
                onDismissed: (_) async {
                  await _deleteNotification(doc.id);
                },
                background: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 24),
                  child: const Icon(
                    Icons.delete_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                child: _buildContent(
                  doc,
                  data,
                  isRead,
                  isSelected,
                  icon,
                  iconColor,
                  title,
                  studentEmail,
                  taskTitle,
                  dateStr,
                ),
              ),
      ),
    );
  }

  Widget _buildContent(
    DocumentSnapshot doc,
    Map<String, dynamic> data,
    bool isRead,
    bool isSelected,
    IconData icon,
    Color iconColor,
    String title,
    String studentEmail,
    String taskTitle,
    String dateStr,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isSelected
            ? colorScheme.primary.withValues(alpha: 0.15)
            : (isRead
                  ? colorScheme.surfaceContainerHighest.withValues(
                      alpha: isDark ? 0.42 : 0.8,
                    )
                  : (isDark
                        ? colorScheme.surfaceContainerHigh
                        : colorScheme.surface)),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected
              ? colorScheme.primary
              : (isRead
                    ? colorScheme.outlineVariant.withValues(alpha: 0.35)
                    : Colors.amber.withValues(alpha: 0.35)),
          width: isSelected ? 2 : (isRead ? 1 : 1.5),
        ),
        boxShadow: (isRead || isSelected)
            ? []
            : [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.15),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isSelectionMode)
                  Padding(
                    padding: const EdgeInsets.only(right: 16, top: 12),
                    child: Icon(
                      isSelected
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isRead
                        ? colorScheme.surfaceContainerHighest.withValues(
                            alpha: isDark ? 0.6 : 0.9,
                          )
                        : iconColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: isRead ? colorScheme.onSurfaceVariant : iconColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontWeight: isRead
                                    ? FontWeight.w500
                                    : FontWeight.bold,
                                fontSize: 16,
                                color: isRead
                                    ? colorScheme.onSurfaceVariant
                                    : colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!isRead && !isSelected)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF4757),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFFFF4757),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        studentEmail,
                        style: TextStyle(
                          color: isRead
                              ? colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.75,
                                )
                              : Colors.amberAccent,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Completed: $taskTitle',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isRead
                              ? colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.75,
                                )
                              : colorScheme.onSurfaceVariant,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        dateStr,
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.75,
                          ),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
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
    );
  }

  String _formatTimestamp(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, h:mm a').format(date);
    }
  }

  void _showDetailDialog(
    String title,
    String studentEmail,
    String taskTitle,
    String message,
    String date,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    showModernDialog(
      context,
      title: title,
      content: Column(
        children: [
          Text(
            date,
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Text(
            'Student:',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            studentEmail,
            style: TextStyle(
              color: Colors.amberAccent,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Task:',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            taskTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
      primaryButtonText: "Close",
      onPrimaryPressed: () => Navigator.of(context, rootNavigator: true).pop(),
      icon: Icons.info_outline_rounded,
    );
  }
}
