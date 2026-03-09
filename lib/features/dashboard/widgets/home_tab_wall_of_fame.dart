part of 'home_tab.dart';

extension _HomeTabWallOfFameMainExtension on _HomeTabState {
  Widget _buildWallOfFame() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _awardsStream,
      builder: (context, snapshot) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final panelStart = isDark
            ? const Color(0xFF2C2C3E)
            : const Color(0xFF0EA5A8);
        final panelEnd = isDark
            ? const Color(0xFF1E1E2C)
            : const Color(0xFF38BDF8);
        final panelBadgeBg = isDark
            ? Colors.black54
            : const Color(0xFFE8FCFF).withValues(alpha: 0.9);
        final panelBadgeBorder = isDark
            ? Colors.white10
            : const Color(0xFF9EE7F0).withValues(alpha: 0.8);
        final panelBadgeTextColor = isDark
            ? Colors.white
            : const Color(0xFF0E7490);
        final panelBadgeIconColor = isDark
            ? const Color(0xFF4FACFE)
            : const Color(0xFF0891B2);
        final panelOutlineColor = const Color(
          0xFF4FACFE,
        ).withValues(alpha: isDark ? 0.45 : 0.0);
        const streakAccent = Color(0xFF2DD4BF);
        const xpAccent = Color(0xFF38BDF8);

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildWallOfFameSkeleton();
        }

        if (snapshot.hasError) {
          return _buildWallOfFameSkeleton();
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return _buildWallOfFameSkeleton();
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        if (data == null || data.isEmpty) return _buildWallOfFameSkeleton();

        final rawWinnerName = _extractDisplayNameFromMap(
          data,
          fallback: 'Student',
        );
        final sanitizedWinnerName = _sanitizeAwardWinnerName(rawWinnerName);
        final winnerId =
            (data['current_winner_uid'] ??
                    data['currentWinnerUid'] ??
                    data['winner_uid'] ??
                    data['winnerUid'] ??
                    '')
                .toString()
                .trim();
        final isCurrentUserWinner =
            winnerId.isNotEmpty &&
            winnerId == FirebaseAuth.instance.currentUser?.uid;

        final hasPreviewName = _awardNamePreviewFallback.isNotEmpty;
        final shouldUsePreviewName =
            hasPreviewName &&
            (_HomeTabState._forceAwardNamePreview ||
                sanitizedWinnerName == '-----' ||
                sanitizedWinnerName.toLowerCase() == 'student' ||
                isCurrentUserWinner);
        final name = shouldUsePreviewName
            ? _awardNamePreviewFallback
            : sanitizedWinnerName;
        final photo =
            (shouldUsePreviewName || isCurrentUserWinner) &&
                _awardPhotoPreviewFallback.isNotEmpty
            ? _awardPhotoPreviewFallback
            : _withPhotoVersion(_extractPhotoUrlFromMap(data), data);
        final reason = (data['reason'] ?? 'Excellence in Learning').toString();
        final leaderboardRows = _extractAwardLeaderboard(data);
        final awardPeriod = _formatAwardPeriod(data);
        final streakWinnerRow = _findHighestStreakAwardRow(leaderboardRows);
        final highestXpRow = _findHighestXpAwardRow(leaderboardRows);

        final streakWinnerId =
            ((streakWinnerRow?['uid'] ?? winnerId).toString()).trim();
        final streakWinnerName = ((streakWinnerRow?['name'] ?? name).toString())
            .trim();
        final streakWinnerStreak = _extractStreakValue(streakWinnerRow);
        final hasLeaderboardSevenStreak =
            streakWinnerStreak >= 7 ||
            leaderboardRows.any((row) => _extractStreakValue(row) >= 7);
        final streakDetail = _resolveAwardReasonDetail(
          rawReason: reason,
          hasLeaderboardSevenStreak: hasLeaderboardSevenStreak,
        );
        final streakWinnerPhotoCandidate = streakWinnerRow == null
            ? ''
            : _withPhotoVersion(
                _extractPhotoUrlFromMap(streakWinnerRow),
                streakWinnerRow,
              );
        final streakWinnerPhoto = streakWinnerPhotoCandidate.isNotEmpty
            ? streakWinnerPhotoCandidate
            : photo;
        final streakInitial = _initialFromName(
          streakWinnerName.isEmpty ? 'Top Student' : streakWinnerName,
        );

        final highestXpName = ((highestXpRow?['name'] ?? name).toString())
            .trim();
        final highestXpValue = _safeInt(
          highestXpRow?['total_xp'] ?? highestXpRow?['xp'],
        );
        final highestXpId = ((highestXpRow?['uid'] ?? '').toString()).trim();
        final highestXpPhotoCandidate = highestXpRow == null
            ? ''
            : _withPhotoVersion(
                _extractPhotoUrlFromMap(highestXpRow),
                highestXpRow,
              );
        final highestXpPhoto = highestXpPhotoCandidate.isNotEmpty
            ? highestXpPhotoCandidate
            : (highestXpId == streakWinnerId ? streakWinnerPhoto : '');
        final highestXpInitial = _initialFromName(
          highestXpName.isEmpty ? 'Top Student' : highestXpName,
        );

        final slides = <Map<String, dynamic>>[
          {
            'label': 'HIGHEST STREAK',
            'title': streakWinnerName.isEmpty
                ? 'Top Student'
                : streakWinnerName,
            'headline': streakWinnerStreak > 0
                ? '$streakWinnerStreak Level Streak'
                : 'Top streak performer',
            'detail': streakDetail,
            'accent': streakAccent,
            'icon': Icons.workspace_premium_rounded,
            'isWinner': true,
            'showAvatar': true,
            'badgeIcon': Icons.military_tech_rounded,
            'winnerId': streakWinnerId,
            'photoUrl': streakWinnerPhoto,
            'initial': streakInitial,
          },
          {
            'label': 'HIGHEST XP SCORED',
            'title': highestXpName.isEmpty ? 'Top Student' : highestXpName,
            'headline': highestXpValue > 0
                ? '$highestXpValue XP earned'
                : 'Top XP performer',
            'detail': 'Live score rankings',
            'accent': xpAccent,
            'icon': Icons.auto_graph_rounded,
            'isWinner': false,
            'showAvatar': true,
            'badgeIcon': Icons.local_fire_department_rounded,
            'winnerId': highestXpId,
            'photoUrl': highestXpPhoto,
            'initial': highestXpInitial,
          },
        ];

        _maybeRotateStudentOfWeek(data);

        return GestureDetector(
              onTap: () => _showAwardScoreboard(
                winnerId: streakWinnerId,
                rankings: leaderboardRows,
                awardPeriod: awardPeriod,
              ),
              child: Container(
                height: 220,
                margin: const EdgeInsets.only(top: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [panelStart, panelEnd],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: isDark
                      ? Border.all(color: panelOutlineColor, width: 1.25)
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: streakAccent.withValues(alpha: 0.16),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      // Shine effect
                      Positioned(
                        top: -50,
                        right: -50,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: streakAccent.withValues(alpha: 0.1),
                            boxShadow: [
                              BoxShadow(
                                color: streakAccent.withValues(alpha: 0.2),
                                blurRadius: 20,
                                spreadRadius: 20,
                              ),
                            ],
                          ),
                        ),
                      ),

                      PageView.builder(
                        controller: _awardPageController,
                        itemCount: slides.length,
                        onPageChanged: (index) {
                          _setAwardSlideIndex(index);
                        },
                        itemBuilder: (context, index) {
                          return _buildAwardSlideItem(
                            slide: slides[index],
                            photoUrl: streakWinnerPhoto,
                            winnerId: streakWinnerId,
                            initial: streakInitial,
                          );
                        },
                      ),

                      Positioned(
                        bottom: 14,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(slides.length, (index) {
                            final accent = slides[index]['accent'] as Color;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: _awardSlideIndex == index ? 24 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _awardSlideIndex == index
                                    ? accent
                                    : Colors.white24,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            );
                          }),
                        ),
                      ),

                      Positioned(
                        top: 14,
                        right: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: panelBadgeBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: panelBadgeBorder),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.emoji_events_rounded,
                                color: panelBadgeIconColor,
                                size: 14,
                              ),
                              SizedBox(width: 6),
                              Text(
                                "WEEKLY AWARDS",
                                style: TextStyle(
                                  color: panelBadgeTextColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .animate()
            .fadeIn(duration: 600.ms)
            .animate(onPlay: (controller) => controller.repeat())
            .shimmer(duration: 700.ms, delay: 5.seconds);
      },
    );
  }

  Widget _buildWallOfFameSkeleton() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final panelStart = isDark
        ? const Color(0xFF2C2C3E)
        : const Color(0xFF0EA5A8);
    final panelEnd = isDark ? const Color(0xFF1E1E2C) : const Color(0xFF38BDF8);
    final panelOutlineColor = const Color(
      0xFF4FACFE,
    ).withValues(alpha: isDark ? 0.45 : 0.0);

    return Container(
          height: 220,
          margin: const EdgeInsets.only(top: 24),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [panelStart, panelEnd],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(20),
            border: isDark
                ? Border.all(color: panelOutlineColor, width: 1.25)
                : null,
          ),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 96,
                  height: 22,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAwardSkeletonLine(width: 128, height: 10),
                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildAwardSkeletonLine(width: 170, height: 16),
                            const SizedBox(height: 10),
                            _buildAwardSkeletonLine(width: 210, height: 12),
                            const SizedBox(height: 8),
                            _buildAwardSkeletonLine(
                              width: double.infinity,
                              height: 11,
                            ),
                            const SizedBox(height: 6),
                            _buildAwardSkeletonLine(width: 140, height: 11),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      2,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: index == 0 ? 22 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(
                            alpha: index == 0 ? 0.25 : 0.14,
                          ),
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms)
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(duration: 950.ms, delay: 200.ms);
  }

  Widget _buildAwardSkeletonLine({
    required double width,
    required double height,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(height / 2),
      ),
    );
  }

  Widget _buildAwardSlideItem({
    required Map<String, dynamic> slide,
    required String photoUrl,
    required String winnerId,
    required String initial,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = slide['accent'] as Color;
    final icon = slide['icon'] as IconData;
    final isWinner = slide['isWinner'] as bool? ?? false;
    final showAvatar = slide['showAvatar'] as bool? ?? isWinner;
    final badgeIcon = slide['badgeIcon'] as IconData?;
    final hasBadge =
        badgeIcon != null || (slide['showCrown'] as bool? ?? isWinner);
    final resolvedBadgeIcon = badgeIcon ?? Icons.military_tech_rounded;
    final slideWinnerId = (slide['winnerId'] ?? winnerId).toString().trim();
    final slidePhotoUrl = _safeRemotePhotoUrl(slide['photoUrl'] ?? photoUrl);
    final slideInitialRaw = (slide['initial'] ?? initial).toString().trim();
    final slideInitial = slideInitialRaw.isEmpty
        ? _initialFromName((slide['title'] ?? '').toString())
        : slideInitialRaw;
    final avatarBorderColor = hasBadge
        ? accent
        : accent.withValues(alpha: 0.75);
    final labelColor = isDark ? accent : const Color(0xFF0B2F57);
    final titleColor = Colors.white.withValues(alpha: 0.98);
    final subtitleColor = Colors.white.withValues(alpha: 0.97);
    final detailColor = Colors.white.withValues(alpha: 0.9);
    final textShadows = <Shadow>[
      Shadow(
        color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.28),
        blurRadius: 5,
        offset: const Offset(0, 1),
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent.withValues(alpha: 0.16), Colors.transparent],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 34),
      child: Row(
        children: [
          if (showAvatar)
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: avatarBorderColor, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: _buildWinnerAvatar(
                    photoUrl: slidePhotoUrl,
                    winnerId: slideWinnerId,
                    initial: slideInitial,
                  ),
                ),
                if (hasBadge)
                  Positioned(
                    top: -20,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF2C2C3E)
                              : colorScheme.surfaceContainerHigh,
                          shape: BoxShape.circle,
                          border: Border.all(color: accent, width: 1.6),
                          boxShadow: [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.4),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Icon(resolvedBadgeIcon, color: accent, size: 24),
                      ),
                    ),
                  ),
              ],
            )
          else
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: accent.withValues(alpha: 0.45)),
              ),
              child: Icon(icon, color: accent, size: 28),
            ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  (slide['label'] ?? '').toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: labelColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.4,
                    shadows: textShadows,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  (slide['title'] ?? '').toString(),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  softWrap: true,
                  overflow: TextOverflow.fade,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    shadows: textShadows,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  (slide['headline'] ?? '').toString(),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  softWrap: true,
                  overflow: TextOverflow.fade,
                  style: TextStyle(
                    color: subtitleColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    shadows: textShadows,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  (slide['detail'] ?? '').toString(),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  softWrap: true,
                  overflow: TextOverflow.fade,
                  style: TextStyle(
                    color: detailColor,
                    fontSize: 12,
                    shadows: textShadows,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic>? _findHighestXpAwardRow(
    List<Map<String, dynamic>> rankings,
  ) {
    if (rankings.isEmpty) return null;

    Map<String, dynamic> best = rankings.first;
    int bestXp = _safeInt(best['total_xp'] ?? best['xp']);
    for (final row in rankings.skip(1)) {
      final xp = _safeInt(row['total_xp'] ?? row['xp']);
      if (xp > bestXp) {
        best = row;
        bestXp = xp;
      }
    }
    return best;
  }

  Map<String, dynamic>? _findHighestStreakAwardRow(
    List<Map<String, dynamic>> rankings,
  ) {
    if (rankings.isEmpty) return null;

    Map<String, dynamic> best = rankings.first;
    int bestStreak = _extractStreakValue(best);
    int bestXp = _safeInt(best['total_xp'] ?? best['xp']);

    for (final row in rankings.skip(1)) {
      final streak = _extractStreakValue(row);
      final xp = _safeInt(row['total_xp'] ?? row['xp']);
      if (streak > bestStreak || (streak == bestStreak && xp > bestXp)) {
        best = row;
        bestStreak = streak;
        bestXp = xp;
      }
    }
    return best;
  }
}
