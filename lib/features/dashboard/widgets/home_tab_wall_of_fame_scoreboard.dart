part of 'home_tab.dart';

extension _HomeTabWallOfFameScoreboardExtension on _HomeTabState {
  Future<void> _showAwardScoreboard({
    required String winnerId,
    required List<Map<String, dynamic>> rankings,
    required String awardPeriod,
  }) async {
    if (!mounted) return;

    final isTeacher = widget.userRole == 'teacher';

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (pageContext) {
          bool isRefreshingLeaderboard = false;

          return StatefulBuilder(
            builder: (pageContext, setPageState) {
              final messenger = ScaffoldMessenger.maybeOf(pageContext);

              Future<void> refreshLeaderboardNow() async {
                if (isRefreshingLeaderboard) return;
                setPageState(() => isRefreshingLeaderboard = true);

                try {
                  final callable = FirebaseFunctions.instance.httpsCallable(
                    'refreshStudentOfWeekLeaderboardNow',
                  );
                  final result = await callable.call();
                  final data = result.data;
                  final payload = data is Map
                      ? Map<String, dynamic>.from(
                          data.map(
                            (key, value) => MapEntry(key.toString(), value),
                          ),
                        )
                      : const <String, dynamic>{};
                  final rankedCount = _safeInt(payload['leaderboardCount']);

                  messenger?.showSnackBar(
                    SnackBar(
                      content: Text(
                        rankedCount > 0
                            ? "Leaderboard refreshed: $rankedCount students ranked."
                            : "Leaderboard refresh queued.",
                      ),
                      backgroundColor: const Color(0xFF1E7C4A),
                    ),
                  );
                } on FirebaseFunctionsException catch (error) {
                  messenger?.showSnackBar(
                    SnackBar(
                      content: Text(
                        error.message ??
                            "Unable to refresh leaderboard right now.",
                      ),
                      backgroundColor: const Color(0xFFB3261E),
                    ),
                  );
                } catch (_) {
                  messenger?.showSnackBar(
                    const SnackBar(
                      content: Text("Unable to refresh leaderboard right now."),
                      backgroundColor: Color(0xFFB3261E),
                    ),
                  );
                } finally {
                  if (mounted) {
                    setPageState(() => isRefreshingLeaderboard = false);
                  }
                }
              }

              final theme = Theme.of(pageContext);
              final colorScheme = theme.colorScheme;
              final isDark = theme.brightness == Brightness.dark;

              return Scaffold(
                backgroundColor: theme.scaffoldBackgroundColor,
                appBar: AppBar(
                  title: const Text('Leaderboard'),
                  backgroundColor: Colors.transparent,
                  foregroundColor: colorScheme.onSurface,
                  elevation: 0,
                ),
                body: SafeArea(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF13131C)
                          : colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFFFFD700)
                            : colorScheme.outlineVariant.withValues(
                                alpha: 0.55,
                              ),
                        width: 1.2,
                      ),
                    ),
                    child: StreamBuilder<DocumentSnapshot>(
                      stream: _awardsStream,
                      builder: (context, snapshot) {
                        String liveWinnerId = winnerId;
                        List<Map<String, dynamic>> liveRankings = rankings;
                        String liveAwardPeriod = awardPeriod;

                        if (snapshot.hasData && snapshot.data!.exists) {
                          final rawData = snapshot.data!.data();
                          if (rawData is Map<String, dynamic>) {
                            liveRankings = _extractAwardLeaderboard(rawData);
                            liveAwardPeriod = _formatAwardPeriod(rawData);
                          } else if (rawData is Map) {
                            final map = Map<String, dynamic>.from(
                              rawData.map(
                                (key, value) => MapEntry(key.toString(), value),
                              ),
                            );
                            liveRankings = _extractAwardLeaderboard(map);
                            liveAwardPeriod = _formatAwardPeriod(map);
                          }
                        }

                        final liveStreakWinner = _findHighestStreakAwardRow(
                          liveRankings,
                        );
                        if (liveStreakWinner != null) {
                          liveWinnerId = (liveStreakWinner['uid'] ?? '')
                              .toString()
                              .trim();
                        }

                        final xpSorted =
                            List<Map<String, dynamic>>.from(liveRankings)
                              ..sort((a, b) {
                                final bXp = _safeInt(b['total_xp'] ?? b['xp']);
                                final aXp = _safeInt(a['total_xp'] ?? a['xp']);
                                if (bXp != aXp) return bXp.compareTo(aXp);
                                final aName = (a['name'] ?? '').toString();
                                final bName = (b['name'] ?? '').toString();
                                return aName.compareTo(bName);
                              });
                        final previewRankingName = _awardNamePreviewFallback
                            .trim();
                        final shouldInjectPreviewRanking =
                            _HomeTabState._forceAwardNamePreview &&
                            xpSorted.isEmpty &&
                            previewRankingName.isNotEmpty;
                        final List<Map<String, dynamic>> visibleRankings =
                            shouldInjectPreviewRanking
                            ? <Map<String, dynamic>>[
                                {
                                  'uid': 'preview_local_user',
                                  'name': previewRankingName,
                                  'total_xp': 1850,
                                },
                              ]
                            : xpSorted;
                        final effectiveWinnerId = shouldInjectPreviewRanking
                            ? 'preview_local_user'
                            : liveWinnerId;

                        if (shouldInjectPreviewRanking &&
                            _awardPhotoPreviewFallback.isNotEmpty) {
                          visibleRankings[0]['photo_url'] =
                              _awardPhotoPreviewFallback;
                        }

                        final showFallbackLayout = visibleRankings.isEmpty;
                        final List<Map<String, dynamic>> renderRankings =
                            showFallbackLayout
                            ? List<Map<String, dynamic>>.generate(
                                5,
                                (index) => <String, dynamic>{
                                  'uid': 'placeholder_rank_${index + 1}',
                                  'name': 'Student name',
                                  'total_xp': 0,
                                  'is_placeholder': true,
                                  'rank': index + 1,
                                },
                              )
                            : visibleRankings;

                        Color rankAccent(int rank) {
                          if (rank == 1) return const Color(0xFFFFD95F);
                          if (rank == 2) return const Color(0xFF67A7FF);
                          if (rank == 3) return const Color(0xFFFFA35B);
                          return const Color(0xFFFF6A3D);
                        }

                        String rowName(Map<String, dynamic> row) {
                          return _extractDisplayNameFromMap(
                            row,
                            fallback: 'Student',
                          );
                        }

                        String rowPhoto(Map<String, dynamic> row) {
                          final raw = _extractPhotoUrlFromMap(row);
                          return _withPhotoVersion(raw, row);
                        }

                        int rowXp(Map<String, dynamic> row) {
                          return _safeInt(row['total_xp'] ?? row['xp']);
                        }

                        bool isPlaceholderRow(Map<String, dynamic>? row) =>
                            row != null && row['is_placeholder'] == true;

                        Widget avatarTile(
                          Map<String, dynamic> row, {
                          required double size,
                        }) {
                          if (isPlaceholderRow(row)) {
                            return Container(
                              width: size,
                              height: size,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF2D344F),
                                    Color(0xFF1A2135),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.32),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.person_rounded,
                                color: const Color(
                                  0xFF9FA9C5,
                                ).withValues(alpha: 0.95),
                                size: size * 0.5,
                              ),
                            );
                          }

                          final name = rowName(row);
                          final photoUrl = rowPhoto(row);
                          final initial = _initialFromName(name);
                          Widget loadingAvatar() => Container(
                            color: const Color(0xFF2A3046),
                            alignment: Alignment.center,
                            child: const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF8FA0C4),
                              ),
                            ),
                          );
                          Widget fallbackAvatar() => Container(
                            alignment: Alignment.center,
                            color: const Color(0xFF2A3046),
                            child: Text(
                              initial,
                              style: const TextStyle(
                                color: Color(0xFFFF6A3D),
                                fontWeight: FontWeight.w900,
                                fontSize: 20,
                              ),
                            ),
                          );

                          return Container(
                            width: size,
                            height: size,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF2D344F), Color(0xFF1A2135)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.32),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: FutureBuilder<String>(
                                future: _resolveRenderablePhotoUrl(photoUrl),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return loadingAvatar();
                                  }
                                  final resolvedPhoto =
                                      snapshot.data?.trim() ?? '';
                                  if (resolvedPhoto.isEmpty) {
                                    return fallbackAvatar();
                                  }

                                  return CachedNetworkImage(
                                    imageUrl: resolvedPhoto,
                                    cacheManager:
                                        _HomeTabState._studentOfWeekImageCache,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) =>
                                        loadingAvatar(),
                                    errorWidget: (context, url, error) =>
                                        fallbackAvatar(),
                                  );
                                },
                              ),
                            ),
                          );
                        }

                        String formatScore(int value) {
                          final sign = value < 0 ? "-" : "";
                          final digits = value.abs().toString();
                          final chunks = <String>[];
                          for (int end = digits.length; end > 0; end -= 3) {
                            var start = end - 3;
                            if (start < 0) start = 0;
                            chunks.insert(0, digits.substring(start, end));
                          }
                          return "$sign${chunks.join(',')}";
                        }

                        Widget rankStarBadge(int rank) {
                          final accent = rankAccent(rank);
                          final size = rank == 1 ? 44.0 : 36.0;
                          final textColor = (rank == 1 || rank == 2)
                              ? const Color(0xFF1A1D29)
                              : Colors.white;

                          return SizedBox(
                            width: size,
                            height: size,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Icon(
                                  _rankBadgeIcon(rank),
                                  color: accent,
                                  size: size,
                                  shadows: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.35,
                                      ),
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                Text(
                                  '#$rank',
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: (rank == 1 || rank == 2)
                                        ? 11
                                        : 10,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        Widget topPodiumCard({
                          required Map<String, dynamic>? row,
                          required int rank,
                        }) {
                          final hasData = row != null && !isPlaceholderRow(row);
                          final name = row == null
                              ? 'Student name'
                              : rowName(row);
                          final xp = row == null ? 0 : rowXp(row);
                          final accent = rankAccent(rank);
                          final frameSize = rank == 1 ? 82.0 : 74.0;
                          final innerSize = frameSize - 10;

                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: frameSize + 8,
                                height: frameSize + 10,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Positioned.fill(
                                      child: Align(
                                        alignment: Alignment.center,
                                        child: Container(
                                          width: frameSize,
                                          height: frameSize,
                                          padding: const EdgeInsets.all(5),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            gradient: const LinearGradient(
                                              colors: [
                                                Color(0xFFE8ECF8),
                                                Color(0xFF8A93AA),
                                                Color(0xFFEEF2FC),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            border: Border.all(
                                              color: accent.withValues(
                                                alpha: 0.8,
                                              ),
                                              width: 1.3,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(
                                                  alpha: 0.35,
                                                ),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: hasData
                                              ? avatarTile(row, size: innerSize)
                                              : Container(
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                    color: const Color(
                                                      0xFF27304A,
                                                    ),
                                                  ),
                                                  alignment: Alignment.center,
                                                  child: const Icon(
                                                    Icons.person_rounded,
                                                    color: Color(0xFF9FA9C5),
                                                    size: 26,
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: -8,
                                      right: -6,
                                      child: rankStarBadge(rank),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                hasData ? formatScore(xp) : '--',
                                style: TextStyle(
                                  color: accent == const Color(0xFFFFD95F)
                                      ? const Color(0xFFFFB35F)
                                      : const Color(0xFFFF6A3D),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          );
                        }

                        Widget topThreeBoard() {
                          final podium = <int, Map<String, dynamic>?>{
                            1: renderRankings.isNotEmpty
                                ? renderRankings[0]
                                : null,
                            2: renderRankings.length > 1
                                ? renderRankings[1]
                                : null,
                            3: renderRankings.length > 2
                                ? renderRankings[2]
                                : null,
                          };

                          const displayOrder = <int>[2, 1, 3];

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: displayOrder
                                .map(
                                  (rank) => Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      child: topPodiumCard(
                                        row: podium[rank],
                                        rank: rank,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(growable: false),
                          );
                        }

                        Widget rankingRow(
                          Map<String, dynamic> row,
                          int rank,
                          bool isWinner,
                        ) {
                          final name = rowName(row);
                          final xp = rowXp(row);
                          final accent = rankAccent(rank);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(11),
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFF7FAFF),
                                        Color(0xFFCFD6E4),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.75,
                                      ),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.28,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '$rank',
                                    style: const TextStyle(
                                      color: Color(0xFF1A1D29),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 17,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                avatarTile(row, size: 44),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Container(
                                    height: 54,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFF7FAFF),
                                          Color(0xFFDDE4F0),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      border: Border.all(
                                        color: isWinner
                                            ? const Color(0xFFFFD95F)
                                            : Colors.white.withValues(
                                                alpha: 0.82,
                                              ),
                                        width: isWinner ? 1.4 : 1.0,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.34,
                                          ),
                                          blurRadius: 12,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Color(0xFF1B1F2A),
                                              fontWeight: FontWeight.w700,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            const Text(
                                              'Score',
                                              style: TextStyle(
                                                color: Color(0xFF566078),
                                                fontWeight: FontWeight.w700,
                                                fontSize: 10,
                                              ),
                                            ),
                                            Text(
                                              formatScore(xp),
                                              style: TextStyle(
                                                color:
                                                    accent ==
                                                        const Color(0xFFFF6A3D)
                                                    ? const Color(0xFFFF6A3D)
                                                    : const Color(0xFFEF5A3B),
                                                fontWeight: FontWeight.w900,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (isTeacher) ...[
                                  IconButton(
                                    onPressed: isRefreshingLeaderboard
                                        ? null
                                        : refreshLeaderboardNow,
                                    tooltip: "Refresh Rankings",
                                    icon: isRefreshingLeaderboard
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Color(0xFFFFD700),
                                            ),
                                          )
                                        : const Icon(
                                            Icons.refresh_rounded,
                                            color: Color(0xFFFFD700),
                                          ),
                                  ),
                                ],
                                IconButton(
                                  onPressed: () =>
                                      _showAwardRankingInfo(pageContext),
                                  tooltip: "How is this measured?",
                                  icon: const Icon(
                                    Icons.info_outline_rounded,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const Text(
                              "LEADERBOARD",
                              style: TextStyle(
                                color: Color(0xFFFF6A3D),
                                fontWeight: FontWeight.w900,
                                fontSize: 26,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              liveAwardPeriod,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 10),
                            topThreeBoard(),
                            const SizedBox(height: 12),
                            if (showFallbackLayout)
                              Text(
                                "Waiting for live ranking data...",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.55),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            if (showFallbackLayout) const SizedBox(height: 8),
                            Expanded(
                              child: ListView.separated(
                                itemCount: renderRankings.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final row = renderRankings[index];
                                  final rank = index + 1;
                                  final uid = (row['uid'] ?? '').toString();
                                  final isWinner =
                                      !showFallbackLayout &&
                                      effectiveWinnerId.isNotEmpty &&
                                      effectiveWinnerId == uid;
                                  return rankingRow(row, rank, isWinner);
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showAwardRankingInfo(BuildContext context) async {
    await showModernDialog(
      context,
      title: "How Rankings Are Measured",
      message:
          "Streak award goes to the student with the highest level streak.\n"
          "XP award goes to the student with the highest XP.\n\n"
          "The leaderboard list shown here is ordered by XP from highest to lowest.",
      primaryButtonText: "Got it",
      onPrimaryPressed: () => Navigator.of(context, rootNavigator: true).pop(),
      icon: Icons.info_outline_rounded,
      accentColor: const Color(0xFF4FACFE),
    );
  }
}
