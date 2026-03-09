import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gravity_app/services/notification_service.dart';
import 'package:gravity_app/services/data_service.dart';
import 'package:intl/intl.dart';
import 'dart:ui'; // For ImageFilter
import 'package:gravity_app/widgets/modern_glass_dialog.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  Set<String> _readIds = {};
  Set<String> _deletedIds = {};
  final Set<String> _selectedIds = {};
  bool _isLoading = true;
  bool _isSelectionMode = false;
  bool _isLoadingState = false;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    if (_isLoadingState) return; // Prevent concurrent loads
    _isLoadingState = true;

    try {
      // Reset badges when viewing notifications
      await _notificationService.resetBadgeCount();

      // Force sync from cloud first (with timeout to prevent hanging)
      await _syncFromCloud().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint(
            "NotificationsScreen: Cloud sync timed out, using local data",
          );
        },
      );

      final read = await _notificationService.getReadIds();
      final deleted = await _notificationService.getDeletedIds();

      debugPrint("NotificationsScreen: Loaded ${deleted.length} deleted IDs");

      if (mounted) {
        setState(() {
          _readIds = read;
          _deletedIds = deleted;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("NotificationsScreen: Error loading state: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } finally {
      _isLoadingState = false;
    }
  }

  Future<void> _syncFromCloud() async {
    try {
      final dataService = DataService();
      await dataService.syncProgressFromCloud();
      debugPrint("NotificationsScreen: Synced from cloud successfully");
    } catch (e) {
      debugPrint("NotificationsScreen: Error syncing from cloud: $e");
      // Don't rethrow - allow app to continue with local data
    }
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
        Navigator.pop(context); // Close Confirmation Dialog

        // Show Loading Dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (c) => Center(
            child: CircularProgressIndicator(color: colorScheme.primary),
          ),
        );

        // Perform Delete
        await _notificationService.deleteMultipleNotifications(
          _selectedIds.toList(),
        );

        if (mounted) {
          Navigator.pop(context); // Close Loading Dialog
          _deletedIds.addAll(_selectedIds);
          _selectedIds.clear();
          _isSelectionMode = false;
          setState(() {});

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Notifications deleted permanently"),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      onSecondaryPressed: () => Navigator.pop(context),
      icon: Icons.delete_forever_rounded,
    );
  }

  Future<void> _markAllAsRead(List<String> allIds) async {
    final idsToMark = allIds.where((id) => !_readIds.contains(id)).toList();
    if (idsToMark.isNotEmpty) {
      await _notificationService.markMultipleAsRead(idsToMark);
      _readIds.addAll(idsToMark);
      setState(() {});
    }
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

  Future<void> _markAsRead(String id) async {
    await _notificationService.markAsRead(id);
    setState(() {
      _readIds.add(id);
    });
  }

  Future<void> _deleteNotification(String id) async {
    await _notificationService.deleteMultipleNotifications([id]);
    setState(() {
      _deletedIds.add(id);
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
          // Background Blobs reused for consistency
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
          // Blur effect
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
                            .collection('announcements')
                            .orderBy('timestamp', descending: true)
                            .limit(50)
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
                                    final isRead = _readIds.contains(id);
                                    final isSelected = _selectedIds.contains(
                                      id,
                                    );

                                    return Dismissible(
                                          key: Key(id),
                                          direction:
                                              DismissDirection.horizontal,
                                          confirmDismiss: (direction) async {
                                            if (direction ==
                                                DismissDirection.startToEnd) {
                                              // Swipe Right -> Mark Read
                                              if (!isRead) {
                                                await _markAsRead(id);
                                              }
                                              return false; // Don't dismiss from list
                                            } else if (direction ==
                                                DismissDirection.endToStart) {
                                              // Swipe Left -> Delete
                                              return true; // Confirm dismiss
                                            }
                                            return false;
                                          },
                                          onDismissed: (direction) {
                                            if (direction ==
                                                DismissDirection.endToStart) {
                                              _deleteNotification(id);
                                            }
                                          },
                                          background: Container(
                                            margin: const EdgeInsets.only(
                                              bottom: 16,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.blueAccent
                                                  .withValues(alpha: 0.2),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            alignment: Alignment.centerLeft,
                                            padding: const EdgeInsets.only(
                                              left: 24,
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.mark_email_read_rounded,
                                                  color: Colors.blueAccent,
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  "Read",
                                                  style: TextStyle(
                                                    color: Colors.blueAccent,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          secondaryBackground: Container(
                                            margin: const EdgeInsets.only(
                                              bottom: 16,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.redAccent
                                                  .withValues(alpha: 0.2),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            alignment: Alignment.centerRight,
                                            padding: const EdgeInsets.only(
                                              right: 24,
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                Text(
                                                  "Delete",
                                                  style: TextStyle(
                                                    color: Colors.redAccent,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                SizedBox(width: 8),
                                                Icon(
                                                  Icons.delete_outline_rounded,
                                                  color: Colors.redAccent,
                                                ),
                                              ],
                                            ),
                                          ),
                                          child: _buildNotificationItem(
                                            doc,
                                            data,
                                            isRead,
                                            isSelected,
                                            index,
                                          ),
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
                    : "Notifications",
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
              Icons.notifications_none_rounded,
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ).animate().scale(duration: 1.seconds, curve: Curves.elasticOut),
          const SizedBox(height: 24),
          Text(
            "All Caught Up!",
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "You have no new notifications.",
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final title = data['title'] ?? 'Notification';
    final message = data['message'] ?? '';
    final timestamp = data['timestamp'] as Timestamp?;
    final dateStr = timestamp != null
        ? _formatTimestamp(timestamp.toDate())
        : 'Just now';

    return GestureDetector(
      key: ValueKey(doc.id),
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
          _showDetailDialog(title, message, dateStr);
        }
      },
      child: Container(
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
                      : colorScheme.primary.withValues(alpha: 0.3)),
            width: isSelected ? 2 : (isRead ? 1 : 1.5),
          ),
          boxShadow: (isRead || isSelected)
              ? []
              : [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.15),
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
                            : colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.6,
                              ),
                      ),
                    ),
                  // Icon Container
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isRead
                          ? colorScheme.surfaceContainerHighest.withValues(
                              alpha: isDark ? 0.6 : 0.9,
                            )
                          : colorScheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      boxShadow: isRead
                          ? []
                          : [
                              BoxShadow(
                                color: colorScheme.primary.withValues(
                                  alpha: 0.2,
                                ),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: Icon(
                      isRead
                          ? Icons.notifications_outlined
                          : Icons.notifications_active_rounded,
                      color: isRead
                          ? colorScheme.onSurfaceVariant
                          : colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Content
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
                          message,
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
                        Row(
                          children: [
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
                            if (data['type'] == 'important') ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withValues(
                                    alpha: 0.2,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: Colors.redAccent.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                ),
                                child: const Text(
                                  "IMPORTANT",
                                  style: TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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

  void _showDetailDialog(String title, String message, String date) {
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
            message,
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
      onPrimaryPressed: () => Navigator.pop(context),
      icon: Icons.notifications_active_rounded, // Optional icon
    );
  }
}
