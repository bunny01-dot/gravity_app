class LearningDay {
  final int dayNumber;
  final bool vocabCompleted;
  final bool verbsCompleted;
  final DateTime date;

  const LearningDay({
    required this.dayNumber,
    required this.vocabCompleted,
    required this.verbsCompleted,
    required this.date,
  });

  bool get isCompleted => vocabCompleted && verbsCompleted;
}
