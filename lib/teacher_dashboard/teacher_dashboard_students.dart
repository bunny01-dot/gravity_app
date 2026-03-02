// ignore_for_file: invalid_use_of_protected_member, library_private_types_in_public_api, use_build_context_synchronously

part of 'teacher_dashboard_screen.dart';

extension TeacherDashboardStudents on _TeacherDashboardState {
  void _showStudentDetails(
    BuildContext context,
    String uid,
    Map<String, dynamic> data,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            StudentDetailScreen(studentId: uid, studentData: data),
      ),
    );
  }

  void _showFindStudentDialog() {
    final emailController = TextEditingController();
    bool isSearching = false;
    String resultMessage = "";

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return ModernGlassDialog(
            title: "Find Missing Student",
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Search the database for a student who isn't appearing.",
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Student Email",
                    labelStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                if (isSearching) ...[
                  const SizedBox(height: 16),
                  _buildAsyncLoader(
                    label: "Searching...",
                    size: 52,
                    fontSize: 11,
                    textColor: const Color(0xFFFFD700),
                  ),
                ],
                if (resultMessage.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    resultMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.orangeAccent,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (resultMessage.contains("MISSING ROLE") ||
                      resultMessage.contains("Wrong Role") ||
                      resultMessage.contains("MISSING DATE"))
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      onPressed: () => _handleFindStudentFix(
                        dialogContext: context,
                        dialogSetState: setState,
                        emailController: emailController,
                        getResultMessage: () => resultMessage,
                        setResultMessage: (value) => resultMessage = value,
                        setIsSearching: (value) => isSearching = value,
                      ),
                      child: Text(
                        resultMessage.contains("DATE")
                            ? "Fix Date Now"
                            : "Fix Role Now",
                      ),
                    ),
                ],
              ],
            ),
            primaryButtonText: "Search",
            onPrimaryPressed: () => _handleFindStudentSearch(
              dialogContext: context,
              dialogSetState: setState,
              emailController: emailController,
              setIsSearching: (value) => isSearching = value,
              setResultMessage: (value) => resultMessage = value,
            ),
            secondaryButtonText: "Close",
            onSecondaryPressed: () => _handleCloseDialog(context),
            icon: Icons.person_search_rounded,
            accentColor: Colors.orangeAccent,
          );
        },
      ),
    );
  }

  Future<_StageMetrics> _getStageMetrics(String uid) async {
    try {
      final progressSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('progress')
          .doc('all_data')
          .get();

      final data = progressSnap.data() ?? {};
      final currentStage = (data['current_learning_stage'] as int?) ?? 1;
      final completedStages = currentStage > 1 ? currentStage - 1 : 0;

      int assessmentCompleted = 0;
      for (int stage = 1; stage <= completedStages; stage++) {
        if (data['assessment_completed_stage_$stage'] == true) {
          assessmentCompleted++;
        }
      }

      return _StageMetrics(
        currentStage: currentStage,
        completedStages: completedStages,
        assessmentCompleted: assessmentCompleted,
      );
    } catch (e) {
      debugPrint('Error fetching stage metrics: $e');
      return _StageMetrics.empty();
    }
  }

  Widget _buildStageProgressBadge(_StageMetrics metrics) {
    final assessmentLabel =
        "${metrics.assessmentCompleted}/${metrics.assessmentTotal}";
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF232336),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Level ${metrics.currentStage}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            "Done ${metrics.completedStages}",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            "Assess $assessmentLabel",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  /// Fetch user's current difficulty level from Firestore
  Future<String> _getUserDifficultyLevel(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (doc.exists && doc.data() != null) {
        return doc.data()!['english_proficiency_level'] as String? ?? '';
      }
    } catch (e) {
      debugPrint('Error fetching difficulty level: $e');
    }
    return '';
  }

  /// Show dialog to change student's difficulty level
  void _showChangeDifficultyDialog(
    String uid,
    String name,
    String email,
  ) async {
    // Get current level
    final currentLevel = await _getUserDifficultyLevel(uid);
    String selectedLevel = currentLevel.isEmpty
        ? 'Beginner (A1)'
        : currentLevel;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return ModernGlassDialog(
            title: "Change Difficulty Level",
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Student: $name",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 20),
                Text(
                  "Current Level: ${currentLevel.isEmpty ? 'Not Set' : currentLevel}",
                  style: TextStyle(
                    color: currentLevel.isEmpty
                        ? Colors.orangeAccent
                        : Colors.white70,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Select new difficulty level:",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                RadioGroup<String>(
                  groupValue: selectedLevel,
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => selectedLevel = val);
                    }
                  },
                  child: Column(
                    children:
                        [
                          'Beginner (A1)',
                          'Intermediate (B1)',
                          'Advanced (C1)',
                        ].map((level) {
                          Color levelColor;
                          IconData levelIcon;
                          if (level.contains('Beginner')) {
                            levelColor = const Color(0xFF4FACFE);
                            levelIcon = Icons.star_outline_rounded;
                          } else if (level.contains('Intermediate')) {
                            levelColor = const Color(0xFFFEAC5E);
                            levelIcon = Icons.stars_rounded;
                          } else {
                            levelColor = const Color(0xFFFF4757);
                            levelIcon = Icons.auto_awesome_rounded;
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: selectedLevel == level
                                  ? levelColor.withValues(alpha: 0.15)
                                  : Colors.white.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selectedLevel == level
                                    ? levelColor
                                    : Colors.white.withValues(alpha: 0.1),
                                width: selectedLevel == level ? 2 : 1,
                              ),
                            ),
                            child: RadioListTile<String>(
                              value: level,
                              title: Row(
                                children: [
                                  Icon(levelIcon, color: levelColor, size: 20),
                                  const SizedBox(width: 12),
                                  Text(
                                    level,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: selectedLevel == level
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                              activeColor: levelColor,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4FACFE).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF4FACFE).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Color(0xFF4FACFE),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "The student will be notified about this change.",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            primaryButtonText: "Update Level",
            onPrimaryPressed: () => _handleUpdateDifficultyLevel(
              context,
              uid,
              selectedLevel,
              currentLevel,
            ),
            secondaryButtonText: "Cancel",
            onSecondaryPressed: () => _handleCloseDialog(context),
            icon: Icons.tune_rounded,
            accentColor: const Color(0xFF4FACFE),
          );
        },
      ),
    );
  }
}
