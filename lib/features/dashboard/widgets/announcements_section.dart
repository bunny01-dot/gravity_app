import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gravity_app/profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AnnouncementsSection extends StatelessWidget {
  final Set<String> deletedIds;
  final Set<String> readIds;
  final bool isReady;
  final String userRole;
  final Function(String) onDelete;
  final Function(String) onMarkRead;

  const AnnouncementsSection({
    super.key,
    required this.deletedIds,
    required this.readIds,
    required this.isReady,
    this.userRole = 'student',
    required this.onDelete,
    required this.onMarkRead,
  });

  void _showAnnouncementDetails(
    BuildContext context, {
    required String title,
    required String message,
    required String dateStr,
    required bool isImportant,
    String? actionType,
    String? buttonText,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final isDark = theme.brightness == Brightness.dark;
        final height = MediaQuery.of(context).size.height * 0.75;
        return Container(
          height: height,
          decoration: BoxDecoration(
            color: isDark
                ? colorScheme.surfaceContainerHigh
                : colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isImportant
                            ? const Color(0xFFFF5E62).withValues(alpha: 0.2)
                            : const Color(0xFF4FACFE).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.campaign_rounded,
                        color: isImportant
                            ? colorScheme.error
                            : colorScheme.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      dateStr,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    if (isImportant) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer.withValues(
                            alpha: 0.75,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'IMPORTANT',
                          style: TextStyle(
                            color: colorScheme.onErrorContainer,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    message,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    if (actionType == 'navigate_to_feedback')
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ProfileScreen(
                                  highlightFeedback: true,
                                ),
                              ),
                            );
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
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
                      ),
                    if (actionType == 'navigate_to_feedback')
                      const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.pop(context),
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          "Close",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (!isReady) return const SizedBox.shrink();
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('announcements')
          .orderBy('timestamp', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final currentUserId = FirebaseAuth.instance.currentUser?.uid;
        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>? ?? {};
          final targetRole = (data['targetRole'] ?? data['target_role'])
              ?.toString();
          final targetRoles = data['targetRoles'];
          final senderId = data['senderId'] ?? data['sender_id'];
          if (senderId != null &&
              currentUserId != null &&
              senderId.toString() == currentUserId) {
            return false;
          }
          if (targetRole != null &&
              targetRole.isNotEmpty &&
              targetRole != userRole) {
            return false;
          }
          if (targetRoles is List &&
              targetRoles.isNotEmpty &&
              !targetRoles.map((e) => e.toString()).contains(userRole)) {
            return false;
          }
          return !deletedIds.contains(doc.id) && !readIds.contains(doc.id);
        }).toList();

        if (docs.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.campaign_rounded,
                          color: Color(0xFF1E1E2C),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Announcements",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  if (docs.length > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.7,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.55,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.swipe_rounded,
                            size: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "${docs.length}",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Cards
            SizedBox(
              height: 160,
              child: PageView.builder(
                controller: PageController(
                  viewportFraction: docs.length > 1 ? 0.92 : 1.0,
                ),
                itemCount: docs.length,
                padEnds: false,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final title = data['title'] ?? 'No Title';
                  final message = data['message'] ?? '';
                  final type = data['type'] ?? 'normal';
                  final isImportant = type == 'important';
                  final timestamp = data['timestamp'] as Timestamp?;
                  final dateStr = timestamp != null
                      ? DateFormat('MMM d, h:mm a').format(timestamp.toDate())
                      : 'Just now';

                  return GestureDetector(
                        onTap: () async {
                          // Mark as read immediately when tapped from dashboard
                          onMarkRead(docs[index].id);

                          // Prevent flicker by waiting a frame
                          await Future.delayed(Duration.zero);

                          if (context.mounted) {
                            _showAnnouncementDetails(
                              context,
                              title: title,
                              message: message,
                              dateStr: dateStr,
                              isImportant: isImportant,
                              actionType: data['actionType']?.toString(),
                              buttonText: data['buttonText']?.toString(),
                            );
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isImportant
                                  ? [
                                      const Color(0xFF8E2DE2),
                                      const Color(0xFFFF5E62),
                                    ]
                                  : [
                                      const Color(0xFF00D4AA),
                                      const Color(0xFF4FACFE),
                                    ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    (isImportant
                                            ? const Color(0xFF8E2DE2)
                                            : const Color(0xFF00D4AA))
                                        .withValues(alpha: 0.3),
                                blurRadius: 16,
                                spreadRadius: 2,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              // Decorative circle
                              Positioned(
                                top: -30,
                                right: -30,
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha: 0.1),
                                  ),
                                ),
                              ),

                              // Content
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Header Row
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        // Important Badge
                                        if (isImportant)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(
                                                alpha: 0.2,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.priority_high_rounded,
                                                  size: 14,
                                                  color: Colors.white,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'IMPORTANT',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        const Spacer(),
                                        // Close Button
                                        InkWell(
                                          onTap: () => onDelete(docs[index].id),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(
                                                alpha: 0.2,
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.close_rounded,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 12),

                                    // Title
                                    Text(
                                      title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        letterSpacing: 0.3,
                                      ),
                                    ),

                                    const SizedBox(height: 4),

                                    // Date
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time_rounded,
                                          size: 12,
                                          color: Colors.white.withValues(
                                            alpha: 0.7,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          dateStr,
                                          style: TextStyle(
                                            color: Colors.white.withValues(
                                              alpha: 0.8,
                                            ),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 10),

                                    // Message
                                    Expanded(
                                      child: Text(
                                        message,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.95,
                                          ),
                                          fontSize: 14,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 300.ms)
                      .scale(
                        begin: const Offset(0.95, 0.95),
                        end: const Offset(1.0, 1.0),
                        curve: Curves.easeOut,
                      );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
