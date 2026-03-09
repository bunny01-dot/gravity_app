import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gravity_app/widgets/blackhole_icon.dart';
import 'package:gravity_app/widgets/custom_animations.dart';

class DashboardHeader extends StatelessWidget {
  final String title;
  final String userRole;
  final Set<String> readIds;
  final Set<String> deletedIds;
  final Set<String> teacherReadIds;
  final Set<String> teacherDeletedIds;
  final String photoUrl;
  final String avatarSeed;
  final bool notificationsReady;
  final GlobalKey? blackHoleKey;
  final bool highlightBlackHole;
  final VoidCallback onBlackHoleTap;
  final VoidCallback onNotificationsTap;
  final VoidCallback onProfileTap;

  const DashboardHeader({
    super.key,
    required this.title,
    required this.userRole,
    required this.readIds,
    required this.deletedIds,
    required this.teacherReadIds,
    required this.teacherDeletedIds,
    required this.photoUrl,
    required this.avatarSeed,
    required this.notificationsReady,
    this.blackHoleKey,
    this.highlightBlackHole = false,
    required this.onBlackHoleTap,
    required this.onNotificationsTap,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final titleColor = colorScheme.onSurface;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                    letterSpacing: 0.5,
                  ),
                ),
                // Teacher Badge
                if (userRole == 'teacher') ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Text(
                      'TEACHER',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E1E2C),
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colorScheme.primary, colorScheme.secondary],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
        Row(
          children: [
            // Black Hole Button
            Container(
              key: blackHoleKey,
              child:
                  (highlightBlackHole
                          ? BlackholeIcon(
                                  size: 24,
                                  color: titleColor.withValues(alpha: 0.95),
                                  showGlow: false,
                                  onTap: onBlackHoleTap,
                                  tooltip: "Black Hole (Difficult Words)",
                                )
                                .animate(
                                  onPlay: (controller) {
                                    controller.repeat(reverse: true);
                                  },
                                )
                                .scaleXY(
                                  begin: 1,
                                  end: 1.14,
                                  duration: 900.ms,
                                  curve: Curves.easeInOut,
                                )
                                .shimmer(
                                  duration: 1600.ms,
                                  color: const Color(
                                    0xFF4FACFE,
                                  ).withValues(alpha: 0.55),
                                )
                          : BlackholeIcon(
                              size: 24,
                              color: titleColor.withValues(alpha: 0.8),
                              showGlow: false,
                              onTap: onBlackHoleTap,
                              tooltip: "Black Hole (Difficult Words)",
                            ))
                      .animate()
                      .fadeIn(duration: 180.ms),
            ),
            const SizedBox(width: 8),

            // Notification Bell
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection(
                    userRole == 'teacher'
                        ? 'teacher_notifications'
                        : 'announcements',
                  )
                  .orderBy('timestamp', descending: true)
                  .limit(50)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!notificationsReady || !snapshot.hasData) {
                  return RingingBellIcon(
                    unreadCount: null,
                    onPressed: onNotificationsTap,
                  );
                }

                int unreadCount = 0;
                unreadCount = snapshot.data!.docs.where((doc) {
                  if (userRole == 'teacher') {
                    final data = doc.data() as Map<String, dynamic>;
                    final isRead =
                        (data['isRead'] == true) ||
                        teacherReadIds.contains(doc.id);
                    final isDeleted = teacherDeletedIds.contains(doc.id);
                    return !isRead && !isDeleted;
                  }

                  final isRead = readIds.contains(doc.id);
                  final isDeleted = deletedIds.contains(doc.id);
                  return !isRead && !isDeleted;
                }).length;
                return RingingBellIcon(
                  unreadCount: unreadCount,
                  onPressed: onNotificationsTap,
                );
              },
            ),
            const SizedBox(width: 16),
            GestureDetector(
              key: null,
              onTap: onProfileTap,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
                  ),
                ),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: isDark
                      ? const Color(0xFF030305)
                      : colorScheme.surface,
                  backgroundImage: photoUrl.isNotEmpty
                      ? CachedNetworkImageProvider(photoUrl)
                      : (avatarSeed.isNotEmpty
                            ? CachedNetworkImageProvider(
                                "https://api.dicebear.com/7.x/bottts/png?seed=$avatarSeed",
                              )
                            : null),
                  child: (photoUrl.isEmpty && avatarSeed.isEmpty)
                      ? Icon(Icons.person_outline, color: colorScheme.onSurface)
                      : null,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
