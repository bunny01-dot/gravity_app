// ignore_for_file: invalid_use_of_protected_member, library_private_types_in_public_api

part of 'teacher_dashboard_screen.dart';

extension TeacherDashboardTabs on _TeacherDashboardState {
  // --- Dashboard Tab ---
  Widget _buildDashboardTab() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final colorScheme = theme.colorScheme;
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _handleDashboardPullRefresh,
          color: Colors.transparent,
          backgroundColor: Colors.transparent,
          strokeWidth: 0.1,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TeacherWelcomeCard(email: _userEmail),
                const SizedBox(height: 32),
                Text(
                  "Quick Actions",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                TeacherQuickActionCard(
                  title: "Manage Library",
                  subtitle: "Import and edit content",
                  icon: Icons.library_books_rounded,
                  color: const Color(0xFF4FACFE),
                  onTap: _handleGoToLibraryTab,
                ),
                const SizedBox(height: 12),
                TeacherQuickActionCard(
                  title: "Send Announcement",
                  subtitle: "Notify all students",
                  icon: Icons.campaign_rounded,
                  color: const Color(0xFFFF4757),
                  onTap: _handleSendAnnouncementTap,
                ),
                const SizedBox(height: 32),
                _buildAttendanceSection(),
              ],
            ),
          ),
        ),
        Positioned(
          top: 8,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: !_isDashboardPullRefreshing
                  ? const SizedBox.shrink()
                  : Center(
                      key: const ValueKey('teacher_pull_refresh_indicator'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF11131A).withValues(alpha: 0.86)
                              : Colors.white.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color:
                                (isDark
                                        ? const Color(0xFFFFD700)
                                        : colorScheme.primary)
                                    .withValues(alpha: 0.42),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: _showDashboardPullRefreshLottie ? 52 : 24,
                              height: _showDashboardPullRefreshLottie ? 52 : 24,
                              child: _showDashboardPullRefreshLottie
                                  ? Lottie.asset(
                                      'assets/lottie/loading.json',
                                      fit: BoxFit.contain,
                                      repeat: true,
                                    )
                                  : const CircularProgressIndicator(
                                      strokeWidth: 2.6,
                                      color: Color(0xFFFFD700),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceSection() {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Today's Attendance",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: onSurface,
          ),
        ),
        const SizedBox(height: 16),
        TeacherPanel(
          padding: const EdgeInsets.all(20),
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: AttendanceCache().getTodayAttendance(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildAsyncLoader(
                  label: "Loading attendance...",
                  textColor: onSurface.withValues(alpha: 0.72),
                );
              }

              final attendees = snapshot.data ?? [];

              if (attendees.isEmpty) {
                return Center(
                  child: Text(
                    "No students present yet today.",
                    style: TextStyle(color: onSurface.withValues(alpha: 0.62)),
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Present: ${attendees.length}",
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(
                        Icons.people_alt_rounded,
                        color: onSurface.withValues(alpha: 0.62),
                      ),
                    ],
                  ),
                  Divider(color: onSurface.withValues(alpha: 0.24), height: 24),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: attendees.length,
                    itemBuilder: (context, index) {
                      final data = attendees[index];
                      final email = data['studentEmail'] ?? 'Unknown Email';
                      final name = data['studentName'] as String?;
                      final displayName = (name != null && name.isNotEmpty)
                          ? name
                          : email.split('@')[0];

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.greenAccent.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.greenAccent,
                          ),
                        ),
                        title: Text(
                          displayName,
                          style: TextStyle(
                            color: onSurface,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle:
                            (name != null && name.isNotEmpty && name != email)
                            ? Text(
                                email,
                                style: TextStyle(
                                  color: onSurface.withValues(alpha: 0.5),
                                  fontSize: 12,
                                ),
                              )
                            : null,
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  // --- Students Tab ---
  Widget _buildStudentsTab() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    // ZERO-COST: Use StudentsCache instead of real-time listener
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: StudentsCache().getStudents(page: 0, pageSize: 100),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildAsyncLoader(label: "Loading students...");
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.redAccent),
            ),
          );
        }

        final students = snapshot.data ?? [];

        if (students.isEmpty) {
          return TeacherEmptyState(
            icon: Icons.people_outline,
            message: "No students found yet",
            onRefresh: _handleRefreshStudents,
            onFindMissing: _showFindStudentDialog,
          );
        }

        return Column(
          children: [
            TeacherStudentsHeader(
              studentCount: students.length,
              onFindMissing: _showFindStudentDialog,
            ),
            const TeacherStageLegend(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                itemCount: students.length,
                itemBuilder: (context, index) {
                  final data = students[index]; // Already a Map
                  final name = data['name'] ?? 'Unknown Student';
                  final email = data['email'] ?? '';
                  final photoUrl = data['photo_url'] ?? '';
                  final uid = data['uid'] ?? ''; // Get uid from map

                  // Handle lastActive - can be Timestamp or int (from cache)
                  String activeText = "Never";
                  final lastActiveValue = data['lastActive'];
                  if (lastActiveValue != null) {
                    DateTime? date;
                    if (lastActiveValue is Timestamp) {
                      date = lastActiveValue.toDate();
                    } else if (lastActiveValue is int) {
                      date = DateTime.fromMillisecondsSinceEpoch(
                        lastActiveValue,
                      );
                    }
                    if (date != null) {
                      activeText = "${date.day}/${date.month}/${date.year}";
                    }
                  }

                  final difficultyBadge = FutureBuilder<String>(
                    future: _getUserDifficultyLevel(uid),
                    builder: (context, snapshot) {
                      final level = snapshot.data ?? '';
                      if (level.isEmpty) return const SizedBox.shrink();

                      Color levelColor;
                      String levelText;
                      if (level.contains('Beginner')) {
                        levelColor = const Color(0xFF4FACFE);
                        levelText = 'Beginner';
                      } else if (level.contains('Intermediate')) {
                        levelColor = const Color(0xFFFEAC5E);
                        levelText = 'Intermediate';
                      } else if (level.contains('Advanced')) {
                        levelColor = const Color(0xFFFF4757);
                        levelText = 'Advanced';
                      } else {
                        return const SizedBox.shrink();
                      }

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: levelColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: levelColor.withValues(alpha: 0.3),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          levelText,
                          style: TextStyle(
                            color: levelColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  );

                  final progressWidget = FutureBuilder<_StageMetrics>(
                    future: _getStageMetrics(uid),
                    builder: (context, snapshot) {
                      final metrics = snapshot.data ?? _StageMetrics.empty();
                      final assessmentLabel =
                          "${metrics.assessmentCompleted}/${metrics.assessmentTotal}";
                      final tooltipText =
                          "Level ${metrics.currentStage} | Completed ${metrics.completedStages} | Assessments $assessmentLabel";
                      return Tooltip(
                        message: tooltipText,
                        triggerMode: TooltipTriggerMode.tap,
                        child: _buildStageProgressBadge(metrics),
                      );
                    },
                  );

                  final menuButton = PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: onSurface.withValues(alpha: 0.5),
                      size: 20,
                    ),
                    color: isDark ? const Color(0xFF2A2A3E) : Colors.white,
                    onSelected: (value) => _handleStudentMenuSelection(
                      context,
                      value,
                      uid,
                      name,
                      email,
                      data,
                    ),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'change_difficulty',
                        child: Row(
                          children: [
                            const Icon(
                              Icons.tune_rounded,
                              color: Color(0xFF4FACFE),
                              size: 18,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "Change Difficulty",
                              style: TextStyle(color: onSurface, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'block',
                        child: Row(
                          children: [
                            Icon(
                              data['isBlocked'] == true
                                  ? Icons.check_circle_outline
                                  : Icons.block,
                              color: data['isBlocked'] == true
                                  ? Colors.greenAccent
                                  : Colors.orangeAccent,
                              size: 18,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              data['isBlocked'] == true ? "Unblock" : "Block",
                              style: TextStyle(color: onSurface, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'reset',
                        child: Row(
                          children: [
                            const Icon(
                              Icons.playlist_remove_rounded,
                              color: Colors.orangeAccent,
                              size: 18,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "Reset Progress",
                              style: TextStyle(color: onSurface, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'deactivate',
                        child: Row(
                          children: [
                            const Icon(
                              Icons.lock_person_rounded,
                              color: Colors.redAccent,
                              size: 18,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "Deactivate",
                              style: TextStyle(color: onSurface, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );

                  final role = data['role'];
                  final roleLabel = (role != null && role != 'student')
                      ? role
                      : null;

                  return TeacherStudentListItem(
                    name: name,
                    email: email,
                    photoUrl: photoUrl,
                    isBlocked: data['isBlocked'] == true,
                    activeText: activeText,
                    roleLabel: roleLabel,
                    onTap: () => _handleStudentRowTap(context, uid, data),
                    difficultyBadge: difficultyBadge,
                    progressWidget: progressWidget,
                    menuButton: menuButton,
                  );
                }, // itemBuilder end
              ), // ListView end
            ), // Expanded end
          ], // Column end
        ); // Column builder end
      }, // StreamBuilder builder end
    ); // StreamBuilder end
  }

  // --- Library Tab (Main Feature) ---
  Widget _buildLibraryTab() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _handleImportCsvTap,
                      style: FilledButton.styleFrom(
                        backgroundColor: isDark
                            ? const Color(0xFF1E1E2C)
                            : Colors.white.withValues(alpha: 0.94),
                        foregroundColor: isDark
                            ? const Color(0xFFFFD700)
                            : const Color(0xFF0F4AA1),
                        side: BorderSide(
                          color: isDark
                              ? const Color(0xFFFFD700)
                              : const Color(0xFF4FACFE),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.cloud_download_rounded),
                      label: const Text(
                        "Import CSV",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _handleSyncSheet,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD700),
                        foregroundColor: const Color(0xFF1E1E2C),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.sync_rounded),
                      label: const Text(
                        "Sync Sheet",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TeacherFiltersBar(
                categories: _categories,
                selectedCategory: _selectedCategory,
                onCategorySelected: (category) {
                  setState(() => _selectedCategory = category);
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Map<String, String>>>(
            future: _dataService.getAllItems(_selectedCategory),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildAsyncLoader(label: "Loading library...");
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Text(
                    "No items in $_selectedCategory",
                    style: TextStyle(color: onSurface.withValues(alpha: 0.5)),
                  ),
                );
              }

              final entries = _buildLibraryEntries(snapshot.data!);
              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  if (entry.isHeader) {
                    return _buildLevelHeader(entry.header!);
                  }
                  final item = entry.item!;
                  final itemIndex =
                      int.tryParse(item['_index'] ?? index.toString()) ?? index;
                  return _buildItemCard(item, itemIndex);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // --- Settings Tab ---
  // --- Settings Tab ---
  Widget _buildSettingsTab() {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TeacherPanel(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Email",
                  style: TextStyle(
                    color: onSurface.withValues(alpha: 0.62),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _userEmail,
                  style: TextStyle(
                    color: onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Notifications Setting
          TeacherNotificationsSection(
            notificationsEnabled: _notificationsEnabled,
            onNotificationsChanged: (val) => _handleNotificationsChanged(val),
            onDebugTap: _handleOpenDebugErrors,
            onBugReportsTap: _handleOpenBugReports,
            onSystemSettingsTap: _handleOpenSystemSettings,
          ),
        ],
      ),
    );
  }
}
