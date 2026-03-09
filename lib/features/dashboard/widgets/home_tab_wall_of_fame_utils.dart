part of 'home_tab.dart';

extension _HomeTabWallOfFameUtilsExtension on _HomeTabState {
  int _extractStreakValue(Map<String, dynamic>? row) {
    if (row == null) return 0;
    return _safeInt(
      row['highest_streak'] ??
          row['current_streak'] ??
          row['currentStageStreak'] ??
          row['current_stage_streak'] ??
          row['user_stage_streak'] ??
          row['user_streak_days'] ??
          row['stage_streak'] ??
          row['streak'] ??
          row['completed_stages'] ??
          row['activity'],
    );
  }

  String _formatXpValue(int xp) {
    if (xp >= 1000000) {
      final value = xp / 1000000.0;
      return "${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)}M";
    }
    if (xp >= 1000) {
      final value = xp / 1000.0;
      return "${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)}K";
    }
    return "$xp";
  }

  List<Map<String, dynamic>> _extractAwardLeaderboard(
    Map<String, dynamic> awardData,
  ) {
    final raw = awardData['leaderboard_top'];
    if (raw is! List) return const [];

    final rows = <Map<String, dynamic>>[];
    for (int i = 0; i < raw.length; i++) {
      final item = raw[i];
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(
        item.map((key, value) => MapEntry(key.toString(), value)),
      );
      map['rank'] = _safeInt(map['rank']) > 0 ? _safeInt(map['rank']) : i + 1;
      rows.add(map);
    }

    rows.sort((a, b) => _safeInt(a['rank']).compareTo(_safeInt(b['rank'])));
    return rows;
  }

  String _formatAwardPeriod(Map<String, dynamic> awardData) {
    final start = _parseAwardedAt(awardData['week_start']);
    final end = _parseAwardedAt(awardData['week_end']);

    if (start != null && end != null) {
      return "Week: ${_formatShortDate(start)} - ${_formatShortDate(end)}";
    }

    final awardedAt = _parseAwardedAt(awardData['awarded_at']);
    if (awardedAt != null) {
      final expiresAt = awardedAt.add(const Duration(days: 7));
      return "Cycle: ${_formatShortDate(awardedAt)} - ${_formatShortDate(expiresAt)}";
    }

    return "7-day rolling cycle";
  }

  String _formatShortDate(DateTime date) {
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return "${date.year}-$m-$d";
  }

  void _maybeRotateStudentOfWeek(Map<String, dynamic> awardData) {
    // Server-side scheduler owns ranking + winner rotation.
    // Keeping this no-op avoids expensive client-side reads.
    final _ = awardData;
  }

  DateTime? _parseAwardedAt(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  String _safeRemotePhotoUrl(dynamic value) {
    final url = _normalizePhotoUrlCandidate(value);
    if (url.isEmpty) return '';
    final lower = url.toLowerCase();
    if (lower == 'null' || lower == 'undefined' || lower == 'nan') return '';
    return url;
  }

  String _normalizePhotoUrlCandidate(dynamic value) {
    if (value == null) return '';
    if (value is Map) {
      final nestedKeys = <String>[
        'url',
        'downloadUrl',
        'download_url',
        'photo_url',
        'photoUrl',
        'photoURL',
        'avatar_url',
        'avatarUrl',
        'image_url',
        'imageUrl',
        'src',
      ];
      for (final key in nestedKeys) {
        if (!value.containsKey(key)) continue;
        final nested = _normalizePhotoUrlCandidate(value[key]);
        if (nested.isNotEmpty) return nested;
      }
    }
    return value.toString().trim();
  }

  bool _isGsPhotoUrl(String value) {
    return value.toLowerCase().startsWith('gs://');
  }

  bool _isHttpPhotoUrl(String value) {
    final lower = value.toLowerCase();
    return lower.startsWith('https://') || lower.startsWith('http://');
  }

  String _stripGsVersionSuffix(String value) {
    final hashIndex = value.indexOf('#');
    if (hashIndex == -1) return value;
    return value.substring(0, hashIndex);
  }

  Future<String> _resolveRenderablePhotoUrl(String rawPhotoUrl) {
    final safePhotoUrl = _safeRemotePhotoUrl(rawPhotoUrl);
    if (safePhotoUrl.isEmpty) return Future.value('');
    if (_isHttpPhotoUrl(safePhotoUrl)) return Future.value(safePhotoUrl);
    if (!_isGsPhotoUrl(safePhotoUrl)) return Future.value('');

    return _resolvedPhotoUrlFutureCache.putIfAbsent(safePhotoUrl, () async {
      try {
        final canonicalGsUrl = _stripGsVersionSuffix(safePhotoUrl);
        final downloadUrl = await FirebaseStorage.instance
            .refFromURL(canonicalGsUrl)
            .getDownloadURL();
        final normalized = _safeRemotePhotoUrl(downloadUrl);
        return _isHttpPhotoUrl(normalized) ? normalized : '';
      } catch (_) {
        return '';
      }
    });
  }

  String _extractPhotoUrlFromMap(Map<String, dynamic> map) {
    final keys = <String>[
      'photo_url',
      'photoUrl',
      'photoURL',
      'photo',
      'profile_photo',
      'profilePhoto',
      'profile_image_url',
      'profileImageUrl',
      'avatar_url',
      'avatarUrl',
      'avatar',
      'image_url',
      'imageUrl',
      'image',
      'current_winner_photo',
      'currentWinnerPhoto',
      'winner_photo',
      'winnerPhoto',
    ];

    for (final key in keys) {
      final resolved = _safeRemotePhotoUrl(map[key]);
      if (resolved.isNotEmpty) return resolved;
    }

    for (final value in map.values) {
      if (value is! Map) continue;
      final nested = value.map((key, item) => MapEntry(key.toString(), item));
      final nestedResolved = _extractPhotoUrlFromMap(nested);
      if (nestedResolved.isNotEmpty) return nestedResolved;
    }
    return '';
  }

  String _extractDisplayNameFromMap(
    Map<String, dynamic> map, {
    String fallback = 'Student',
  }) {
    final keys = <String>[
      'name',
      'displayName',
      'display_name',
      'student_name',
      'full_name',
      'email',
      'current_winner_name',
      'currentWinnerName',
    ];
    for (final key in keys) {
      final value = (map[key] ?? '').toString().trim();
      if (value.isNotEmpty) return value;
    }
    return fallback;
  }

  String _initialFromName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'S';
    final first = trimmed.characters.first.toUpperCase();
    return RegExp(r'[A-Z0-9]').hasMatch(first) ? first : 'S';
  }

  String _withPhotoVersion(String photoUrl, Map<String, dynamic> source) {
    final safePhoto = _safeRemotePhotoUrl(photoUrl);
    if (safePhoto.isEmpty) return '';
    final rawVersion =
        source['photo_updated_at'] ??
        source['photoUpdatedAt'] ??
        source['updated_at'] ??
        source['updatedAt'];
    final version = rawVersion?.toString().trim() ?? '';
    if (!_isHttpPhotoUrl(safePhoto) && !_isGsPhotoUrl(safePhoto)) {
      return safePhoto;
    }
    if (version.isEmpty) return safePhoto;
    if (safePhoto.contains('googleusercontent.com')) return safePhoto;
    final encodedVersion = Uri.encodeQueryComponent(version);
    if (_isGsPhotoUrl(safePhoto)) {
      return '${_stripGsVersionSuffix(safePhoto)}#v=$encodedVersion';
    }
    final separator = safePhoto.contains('?') ? '&' : '?';
    return '$safePhoto$separator=$encodedVersion';
  }

  IconData _rankBadgeIcon(int rank) {
    final _ = rank;
    return Icons.star_rounded;
  }

  int _safeInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  String _sanitizeAwardWinnerName(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '-----';
    if (_isLegacyEligibilityText(trimmed)) {
      return '-----';
    }
    return trimmed;
  }

  String _resolveAwardReasonDetail({
    required String rawReason,
    required bool hasLeaderboardSevenStreak,
  }) {
    final trimmed = rawReason.trim();
    if (trimmed.isEmpty) return 'Most consistent progress';
    if (_isLegacyEligibilityText(trimmed) && hasLeaderboardSevenStreak) {
      return 'Most consistent progress';
    }
    return trimmed;
  }

  bool _isLegacyEligibilityText(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) return false;
    return normalized.contains('no eligible student') ||
        normalized.contains('no eligible students') ||
        normalized.contains('waiting for streak data') ||
        (normalized.contains('need at least 7') &&
            normalized.contains('completed stage'));
  }

  Widget _buildWinnerAvatar({
    required String photoUrl,
    required String winnerId,
    required String initial,
  }) {
    final safePhotoUrl = _safeRemotePhotoUrl(photoUrl);
    if (safePhotoUrl.isNotEmpty) {
      return _buildResolvedAvatarImage(
        photoUrl: safePhotoUrl,
        winnerId: winnerId,
        initial: initial,
      );
    }

    if (winnerId.isEmpty) {
      return _buildAvatarInitial(initial);
    }

    return FutureBuilder<String?>(
      future: _resolveWinnerPhotoUrl(winnerId),
      builder: (context, snapshot) {
        final userPhoto = _safeRemotePhotoUrl(snapshot.data);
        if (userPhoto.isNotEmpty) {
          return _buildResolvedAvatarImage(
            photoUrl: userPhoto,
            winnerId: winnerId,
            initial: initial,
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFFFFD700),
            ),
          );
        }

        return _buildAvatarInitial(initial);
      },
    );
  }

  Widget _buildResolvedAvatarImage({
    required String photoUrl,
    required String winnerId,
    required String initial,
  }) {
    return FutureBuilder<String>(
      future: _resolveRenderablePhotoUrl(photoUrl),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFFFFD700),
            ),
          );
        }
        final resolvedPhoto = snapshot.data?.trim() ?? '';
        if (resolvedPhoto.isEmpty) {
          return _buildAvatarInitial(initial);
        }
        return _buildAvatarImage(
          photoUrl: resolvedPhoto,
          winnerId: winnerId,
          initial: initial,
        );
      },
    );
  }

  Future<String?> _resolveWinnerPhotoUrl(String winnerId) {
    if (winnerId.isEmpty) return Future.value('');
    return _winnerPhotoFutureById.putIfAbsent(winnerId, () {
      return FirebaseFirestore.instance
          .collection('users')
          .doc(winnerId)
          .get()
          .then((snapshot) {
            if (!snapshot.exists || snapshot.data() == null) return '';
            final data = snapshot.data() as Map<String, dynamic>;
            final resolved = _withPhotoVersion(
              _extractPhotoUrlFromMap(data),
              data,
            );
            if (resolved.isEmpty) {
              _winnerPhotoFutureById.remove(winnerId);
            }
            return resolved;
          })
          .catchError((_) {
            _winnerPhotoFutureById.remove(winnerId);
            return '';
          });
    });
  }

  Widget _buildAvatarImage({
    required String photoUrl,
    required String winnerId,
    required String initial,
  }) {
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: photoUrl,
        cacheManager: _HomeTabState._studentOfWeekImageCache,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        placeholder: (context, url) => const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFFFFD700),
          ),
        ),
        errorWidget: (context, url, error) => _buildAvatarInitial(initial),
      ),
    );
  }

  Widget _buildAvatarInitial(String initial) {
    return Center(
      child: Text(
        initial,
        style: const TextStyle(
          color: Color(0xFFFFD700),
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
      ),
    );
  }
}
