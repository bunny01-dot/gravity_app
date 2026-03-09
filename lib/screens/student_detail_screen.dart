import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gravity_app/widgets/modern_glass_dialog.dart';
import 'package:gravity_app/services/fcm_service.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class StudentDetailScreen extends StatefulWidget {
  final String studentId;
  final Map<String, dynamic> studentData;

  const StudentDetailScreen({
    super.key,
    required this.studentId,
    required this.studentData,
  });

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  int _currentStreak = 0;
  String _currentLevel = "Loading...";
  int _bugCount = 0;
  int _attendanceCount = 0;
  int _currentStage = 1;
  int _completedStages = 0;
  int _assessmentCompletedCount = 0;
  int _assessmentTotalCount = 0;
  DateTime? _lastActiveAt;
  late Stream<QuerySnapshot> _activityStream;

  @override
  void initState() {
    super.initState();
    _loadDetailedData();
    _activityStream = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.studentId)
        .collection('activity')
        .orderBy('timestamp', descending: true)
        .limit(10)
        .snapshots();
  }

  Future<void> _loadDetailedData() async {
    try {
      // 1. Level (User Specific)
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.studentId)
          .get();
      final level =
          userDoc.data()?['english_proficiency_level'] ?? "Beginner (A1)";

      // 2. Level progress + level streak
      final progressSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.studentId)
          .collection('progress')
          .doc('all_data')
          .get();
      final progData = progressSnap.data() ?? {};
      final currentStage = (progData['current_learning_stage'] as int?) ?? 1;
      final completedStages = currentStage > 1 ? currentStage - 1 : 0;
      final stageStreak = completedStages;
      int assessmentCompleted = 0;
      for (int stage = 1; stage <= completedStages; stage++) {
        if (progData['assessment_completed_stage_$stage'] == true) {
          assessmentCompleted++;
        }
      }

      DateTime? lastActive;
      final lastActiveValue = userDoc.data()?['lastActive'];
      if (lastActiveValue is Timestamp) {
        lastActive = lastActiveValue.toDate();
      } else if (lastActiveValue is int) {
        lastActive = DateTime.fromMillisecondsSinceEpoch(lastActiveValue);
      }

      // 4. Bug Reports
      final bugsSnap = await FirebaseFirestore.instance
          .collection('bug_reports')
          .where('userId', isEqualTo: widget.studentId)
          .count()
          .get();

      // 5. Attendance (Approximate via email or uid)
      final attendanceSnap = await FirebaseFirestore.instance
          .collection('attendance')
          .where('studentEmail', isEqualTo: widget.studentData['email'])
          .count()
          .get();

      if (mounted) {
        setState(() {
          _currentLevel = level;
          _currentStreak = stageStreak;
          _bugCount = bugsSnap.count ?? 0;
          _attendanceCount = attendanceSnap.count ?? 0;
          _currentStage = currentStage;
          _completedStages = completedStages;
          _assessmentCompletedCount = assessmentCompleted;
          _assessmentTotalCount = completedStages;
          _lastActiveAt = lastActive;
        });
      }
    } catch (e) {
      debugPrint("Error loading details: $e");
    }
  }

  Future<void> _awardStudentOfWeek() async {
    final reasonController = TextEditingController();

    await showModernDialog(
      context,
      title: "Student of the Week",
      content: SingleChildScrollView(
        child: Column(
          children: [
            const Text(
              "Award this student for their exceptional performance?",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, height: 1.5),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Reason (e.g. 7 Learning Streak!)",
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
      ),
      primaryButtonText: "Award & Notify",
      accentColor: const Color(0xFFFFD700),
      icon: Icons.emoji_events_rounded,
      onPrimaryPressed: () async {
        if (reasonController.text.trim().isEmpty) return;

        Navigator.pop(context); // Close dialog

        try {
          // 1. Update System Award
          await FirebaseFirestore.instance
              .collection('system')
              .doc('awards')
              .set({
                'current_winner_uid': widget.studentId,
                'current_winner_name': widget.studentData['name'] ?? 'Student',
                'current_winner_photo':
                    widget.studentData['photo_url'] ??
                    widget.studentData['photoUrl'] ??
                    '',
                'reason': reasonController.text.trim(),
                'awarded_at': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));

          // 2. Add to History
          await FirebaseFirestore.instance
              .collection('system')
              .doc('awards')
              .collection('history')
              .add({
                'uid': widget.studentId,
                'name': widget.studentData['name'],
                'reason': reasonController.text.trim(),
                'date': FieldValue.serverTimestamp(),
              });

          // 3. Notify Student
          await FCMService().notifyStudent(
            uid: widget.studentId,
            title: "You are the Student of the Week!",
            body:
                "Congratulations! You've been awarded for: ${reasonController.text.trim()}",
            data: {'type': 'award_announcement'},
          );

          // 4. Notify Everyone Else (Optional, maybe just a general announcement)
          // For now, let's just notify the individual.

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Awarded successfully!"),
                backgroundColor: Color(0xFFFFD700),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } catch (e) {
          debugPrint("Error awarding: $e");
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
            );
          }
        }
      },
      secondaryButtonText: "Cancel",
      onSecondaryPressed: () => Navigator.pop(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Shared Colors
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF030305) : theme.scaffoldBackgroundColor;
    final cardBg = const Color(0xFF1E1E2C);
    final accent = const Color(0xFF4FACFE);
    final photoUrl =
        (widget.studentData['photo_url'] ??
                widget.studentData['photoUrl'] ??
                '')
            .toString();
    final name = (widget.studentData['name'] ?? "Student").toString();
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          // Background Decor
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.1),
              ),
            ).animate().scale(duration: 2.seconds).fadeIn(),
          ),

          CustomScrollView(
            slivers: [
              // 1. App Bar
              SliverAppBar(
                backgroundColor: bg.withValues(alpha: 0.8),
                expandedHeight: 200,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Blurred Image or Gradient
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [accent.withValues(alpha: 0.2), bg],
                          ),
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 40),
                            Hero(
                              tag: 'avatar_${widget.studentId}',
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white24,
                                    width: 2,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: photoUrl.isNotEmpty
                                    ? ClipOval(
                                        child: CachedNetworkImage(
                                          imageUrl: photoUrl,
                                          width: 76,
                                          height: 76,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => Center(
                                            child: Text(
                                              initial,
                                              style: const TextStyle(
                                                fontSize: 30,
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          errorWidget: (context, url, error) =>
                                              Center(
                                                child: Text(
                                                  initial,
                                                  style: const TextStyle(
                                                    fontSize: 30,
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                        ),
                                      )
                                    : Text(
                                        initial,
                                        style: const TextStyle(
                                          fontSize: 30,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              widget.studentData['email'] ?? "",
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  IconButton(
                    onPressed: _awardStudentOfWeek,
                    icon: const Icon(
                      Icons.emoji_events_rounded,
                      color: Color(0xFFFFD700),
                    ),
                    tooltip: "Student of the Week",
                  ),
                ],
              ),

              // 2. Vital Signs (Stats)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _buildStatCard(
                            "Streak",
                            "$_currentStreak Levels",
                            Icons.local_fire_department_rounded,
                            Colors.orange,
                          ),
                          const SizedBox(width: 12),
                          _buildStatCard(
                            "Level",
                            _currentLevel.split(' ').first,
                            Icons.trending_up_rounded,
                            Colors.greenAccent,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildStatCard(
                            "Issues Reported",
                            "$_bugCount",
                            Icons.bug_report_rounded,
                            Colors.redAccent,
                          ),
                          const SizedBox(width: 12),
                          _buildStatCard(
                            "Days Present",
                            "$_attendanceCount",
                            Icons.calendar_today_rounded,
                            Colors.blueAccent,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Learning Progress
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Learning Progress",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildProgressRow(
                          "Current Level",
                          "Level $_currentStage",
                        ),
                        const SizedBox(height: 10),
                        _buildProgressRow(
                          "Levels Completed",
                          "$_completedStages",
                        ),
                        const SizedBox(height: 10),
                        _buildProgressRow(
                          "Assessments Completed",
                          "$_assessmentCompletedCount/$_assessmentTotalCount",
                        ),
                        const SizedBox(height: 10),
                        _buildProgressRow(
                          "Last Active",
                          _lastActiveAt == null
                              ? "Never"
                              : DateFormat('MMM d, y').format(_lastActiveAt!),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // 4. Activity Log (Recent)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Recent Activity",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        StreamBuilder<QuerySnapshot>(
                          stream: _activityStream,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white24,
                                ),
                              );
                            }
                            if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty) {
                              return Center(
                                child: Text(
                                  "No recent activity.",
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              );
                            }

                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: snapshot.data!.docs.length,
                              separatorBuilder: (context, index) =>
                                  const Divider(color: Colors.white10),
                              itemBuilder: (context, index) {
                                final data =
                                    snapshot.data!.docs[index].data()
                                        as Map<String, dynamic>;
                                final title = data['title'] ?? 'Activity';
                                final subtitle = data['description'] ?? '';
                                final type = data['type'] ?? 'general';
                                final timestamp =
                                    (data['timestamp'] as Timestamp?)?.toDate();

                                IconData icon = Icons.circle;
                                Color color = Colors.white;

                                switch (type) {
                                  case 'quiz':
                                    icon = Icons.quiz_rounded;
                                    color = Colors.purpleAccent;
                                    break;
                                  case 'lesson':
                                    icon = Icons.menu_book_rounded;
                                    color = Colors.blueAccent;
                                    break;
                                  case 'streak':
                                    icon = Icons.local_fire_department_rounded;
                                    color = Colors.orangeAccent;
                                    break;
                                  default:
                                    icon = Icons.check_circle_outline;
                                    color = Colors.greenAccent;
                                }

                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(icon, color: color, size: 20),
                                  ),
                                  title: Text(
                                    title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (subtitle.isNotEmpty)
                                        Text(
                                          subtitle,
                                          style: TextStyle(
                                            color: Colors.white.withValues(
                                              alpha: 0.7,
                                            ),
                                          ),
                                        ),
                                      if (timestamp != null)
                                        Text(
                                          DateFormat(
                                            'MMM d, h:mm a',
                                          ).format(timestamp),
                                          style: TextStyle(
                                            color: Colors.white.withValues(
                                              alpha: 0.4,
                                            ),
                                            fontSize: 12,
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2C),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
