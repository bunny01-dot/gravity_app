import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gravity_app/services/data_service.dart';
import 'package:gravity_app/services/day_based_progress_service.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class VocabularyHistoryScreen extends StatefulWidget {
  const VocabularyHistoryScreen({super.key});

  @override
  State<VocabularyHistoryScreen> createState() =>
      _VocabularyHistoryScreenState();
}

class _VocabularyHistoryScreenState extends State<VocabularyHistoryScreen> {
  final DataService _dataService = DataService();
  Map<String, List<Map<String, String>>> _vocabularyByDate = {};
  bool _isLoading = true;
  final int _daysToShow = 90; // Show last 90 days for calendar
  bool _showCalendarView = false;

  // Statistics
  int _totalWords = 0;
  int _currentStreak = 0;
  int _longestStreak = 0;
  DateTime? _focusedDay;
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _loadVocabularyHistory();
  }

  Future<void> _loadVocabularyHistory() async {
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final progressService = DayBasedProgressService();
    final now = DateTime.now();
    final Map<String, List<Map<String, String>>> history = {};
    int totalWords = 0;

    // Load vocabulary for each past day
    for (int i = 0; i < _daysToShow; i++) {
      final date = now.subtract(Duration(days: i));
      final dateKey = date.toIso8601String().split('T')[0];

      // ISSUE #1 FIX: Only count LEARNED words, not assigned words
      // Check if there are any learned words for this date
      final key = 'learned_vocab_$dateKey';

      if (prefs.containsKey(key)) {
        try {
          // Get the IDs of learned vocabulary for this date
          final learnedIds = await progressService.getLearnedVocabularyIds(
            date,
          );

          if (learnedIds.isNotEmpty) {
            // Fetch the actual word data for these IDs
            final words = await _dataService.getVocabularyForDate(date);

            // Filter to only include learned words
            final learnedWords = words.where((word) {
              final wordId = word['id'] ?? word['serial_number'] ?? '';
              return learnedIds.contains(wordId);
            }).toList();

            if (learnedWords.isNotEmpty) {
              history[dateKey] = learnedWords;
              totalWords += learnedWords.length;
            }
          }
        } catch (e) {
          debugPrint('Error loading learned vocabulary for $dateKey: $e');
        }
      }
    }

    // Calculate streaks
    final streakData = _calculateStreaks(history.keys.toList());

    if (mounted) {
      setState(() {
        _vocabularyByDate = history;
        _totalWords = totalWords;
        _currentStreak = streakData['current']!;
        _longestStreak = streakData['longest']!;
        _isLoading = false;
      });
    }
  }

  Map<String, int> _calculateStreaks(List<String> dateKeys) {
    if (dateKeys.isEmpty) return {'current': 0, 'longest': 0};

    // Sort dates
    final sortedDates = dateKeys.map((k) => DateTime.parse(k)).toList()
      ..sort((a, b) => b.compareTo(a)); // Most recent first

    int currentStreak = 0;
    int longestStreak = 0;
    int tempStreak = 0;
    DateTime? lastDate;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (var date in sortedDates) {
      final checkDate = DateTime(date.year, date.month, date.day);

      if (lastDate == null) {
        tempStreak = 1;
        // Check if the most recent entry is today or yesterday for current streak
        final yesterday = today.subtract(const Duration(days: 1));
        if (checkDate.isAtSameMomentAs(today) ||
            checkDate.isAtSameMomentAs(yesterday)) {
          currentStreak = 1;
        }
      } else {
        final dayDiff = DateTime(
          lastDate.year,
          lastDate.month,
          lastDate.day,
        ).difference(checkDate).inDays;
        if (dayDiff == 1) {
          tempStreak++;
          // Only increment current streak if it was already active
          if (currentStreak > 0) currentStreak++;
        } else if (dayDiff > 1) {
          longestStreak = tempStreak > longestStreak
              ? tempStreak
              : longestStreak;
          tempStreak = 1;
          currentStreak = 0; // Break in current streak
        }
        // If dayDiff is 0, it means multiple entries for the same day, ignore for streak
      }
      lastDate = date;
    }

    longestStreak = tempStreak > longestStreak ? tempStreak : longestStreak;

    return {'current': currentStreak, 'longest': longestStreak};
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: colorScheme.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Vocabulary History',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showCalendarView
                  ? Icons.list_rounded
                  : Icons.calendar_month_rounded,
              color: colorScheme.onSurface,
            ),
            onPressed: () {
              setState(() => _showCalendarView = !_showCalendarView);
            },
          ),
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: colorScheme.onSurface),
            onPressed: _loadVocabularyHistory,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Loading History...",
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 200,
                    child: LinearProgressIndicator(
                      backgroundColor: colorScheme.outlineVariant.withValues(
                        alpha: 0.35,
                      ),
                      color: colorScheme.primary,
                      minHeight: 4,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            )
          : _vocabularyByDate.isEmpty
          ? _buildEmptyState()
          : Column(
              children: [
                _buildStatisticsHeader(),
                if (!_showCalendarView) _buildWeeklyChart(),
                Expanded(
                  child: _showCalendarView
                      ? _buildCalendarView()
                      : _buildHistoryList(),
                ),
              ],
            ),
    );
  }

  Widget _buildStatisticsHeader() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Learning Progress',
            style: TextStyle(
              color: colorScheme.onPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard(
                icon: Icons.menu_book_rounded,
                value: '$_totalWords',
                label: 'Total Words',
              ),
              Container(
                width: 1,
                height: 40,
                color: colorScheme.onPrimary.withValues(alpha: 0.3),
              ),
              _buildStatCard(
                icon: Icons.local_fire_department_rounded,
                value: '$_currentStreak',
                label: 'Current Streak',
              ),
              Container(
                width: 1,
                height: 40,
                color: colorScheme.onPrimary.withValues(alpha: 0.3),
              ),
              _buildStatCard(
                icon: Icons.emoji_events_rounded,
                value: '$_longestStreak',
                label: 'Best Streak',
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.2, end: 0);
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Icon(icon, color: colorScheme.onPrimary, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: colorScheme.onPrimary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: colorScheme.onPrimary.withValues(alpha: 0.8),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyChart() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Get last 7 days of data
    final now = DateTime.now();
    final List<MapEntry<String, int>> weekData = [];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey = date.toIso8601String().split('T')[0];
      final wordCount = _vocabularyByDate[dateKey]?.length ?? 0;
      final dayLabel = DateFormat('EEE').format(date).substring(0, 1);
      weekData.add(MapEntry(dayLabel, wordCount));
    }

    final maxCount = weekData
        .map((e) => e.value)
        .reduce((a, b) => a > b ? a : b);
    final chartHeight = maxCount > 0 ? maxCount.toDouble() : 10.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHigh : colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bar_chart_rounded,
                color: colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'This Week',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: weekData.map((entry) {
                final heightPercent = entry.value / chartHeight;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (entry.value > 0)
                      Text(
                        '${entry.value}',
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Container(
                      width: 32,
                      height: entry.value > 0 ? 60 * heightPercent : 4,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: entry.value > 0
                              ? [colorScheme.primary, colorScheme.secondary]
                              : [
                                  colorScheme.outlineVariant.withValues(
                                    alpha: 0.2,
                                  ),
                                  colorScheme.outlineVariant.withValues(
                                    alpha: 0.2,
                                  ),
                                ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      entry.key,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.8,
                        ),
                        fontSize: 11,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 300.ms);
  }

  Widget _buildCalendarView() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? colorScheme.surfaceContainerHigh
                  : colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.2),
              ),
            ),
            child: TableCalendar(
              firstDay: DateTime.now().subtract(const Duration(days: 90)),
              lastDay: DateTime.now(),
              focusedDay: _focusedDay!,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              calendarFormat: CalendarFormat.month,
              startingDayOfWeek: StartingDayOfWeek.monday,
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                leftChevronIcon: Icon(
                  Icons.chevron_left_rounded,
                  color: colorScheme.onSurface,
                ),
                rightChevronIcon: Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.onSurface,
                ),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: TextStyle(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.85),
                ),
                weekendStyle: TextStyle(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.85),
                ),
              ),
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                defaultTextStyle: TextStyle(color: colorScheme.onSurface),
                weekendTextStyle: TextStyle(color: colorScheme.onSurface),
                selectedDecoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: colorScheme.secondary,
                  shape: BoxShape.circle,
                ),
              ),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              eventLoader: (day) {
                final dateKey = day.toIso8601String().split('T')[0];
                return _vocabularyByDate.containsKey(dateKey) ? [1] : [];
              },
            ),
          ),
          const SizedBox(height: 16),
          if (_selectedDay != null) _buildSelectedDayWords(),
        ],
      ),
    );
  }

  Widget _buildSelectedDayWords() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final dateKey = _selectedDay!.toIso8601String().split('T')[0];
    final words = _vocabularyByDate[dateKey];

    if (words == null || words.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark
              ? colorScheme.surfaceContainerHigh.withValues(alpha: 0.7)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'No vocabulary for ${DateFormat('MMM d, yyyy').format(_selectedDay!)}',
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isDark
                ? colorScheme.surfaceContainerHigh.withValues(alpha: 0.95)
                : colorScheme.surface,
            isDark
                ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.95)
                : colorScheme.surfaceContainerHighest,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.calendar_today_rounded,
                  color: colorScheme.primary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                DateFormat('EEEE, MMMM d').format(_selectedDay!),
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${words.length} words',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...words.asMap().entries.map((entry) {
            return _buildWordItem(entry.value, entry.key);
          }),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_edu_rounded,
            size: 80,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 24),
          Text(
            'No Vocabulary History',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Start learning vocabulary from Daily Tasks to build your history!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    final sortedDates = _vocabularyByDate.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // Most recent first

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final dateKey = sortedDates[index];
        final words = _vocabularyByDate[dateKey]!;
        final date = DateTime.parse(dateKey);

        return _buildDateCard(date, words, index);
      },
    );
  }

  Widget _buildDateCard(
    DateTime date,
    List<Map<String, String>> words,
    int index,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    final isYesterday =
        date.year == now.year &&
        date.month == now.month &&
        date.day == now.day - 1;

    String dateLabel;
    if (isToday) {
      dateLabel = 'Today';
    } else if (isYesterday) {
      dateLabel = 'Yesterday';
    } else {
      dateLabel = DateFormat('EEEE, MMM d').format(date);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isDark
                ? colorScheme.surfaceContainerHigh.withValues(alpha: 0.95)
                : colorScheme.surface,
            isDark
                ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.95)
                : colorScheme.surfaceContainerHighest,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          childrenPadding: const EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: 16,
          ),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isToday
                  ? Icons.today_rounded
                  : isYesterday
                  ? Icons.history_rounded
                  : Icons.calendar_today_rounded,
              color: colorScheme.primary,
              size: 20,
            ),
          ),
          title: Text(
            dateLabel,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            '${words.length} words',
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
          ),
          trailing: Icon(
            Icons.expand_more_rounded,
            color: colorScheme.onSurfaceVariant,
          ),
          children: [
            ...words.asMap().entries.map((entry) {
              final wordIndex = entry.key;
              final word = entry.value;
              return _buildWordItem(word, wordIndex);
            }),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1, end: 0);
  }

  Widget _buildWordItem(Map<String, String> word, int index) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerHigh.withValues(alpha: 0.55)
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Text(
              '${index + 1}',
              style: TextStyle(
                color: colorScheme.primary,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  word['word'] ?? word['title'] ?? 'Unknown',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  word['meaning'] ??
                      word['tamil_meaning'] ??
                      word['hindi_meaning'] ??
                      'No meaning available',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
                if (word['english_example'] != null &&
                    word['english_example']!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? colorScheme.surfaceContainerHighest.withValues(
                              alpha: 0.55,
                            )
                          : colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      word['english_example']!,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.9,
                        ),
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
