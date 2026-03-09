import 'package:flutter/material.dart';
import 'package:gravity_app/features/daily_sentences/daily_sentence_card.dart';

class DashboardRecentActivitySection extends StatelessWidget {
  final String preferredLanguage;
  final VoidCallback onCompleted;

  const DashboardRecentActivitySection({
    super.key,
    required this.preferredLanguage,
    required this.onCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return DailySentenceCard(
      preferredLanguage: preferredLanguage,
      onCompleted: onCompleted,
    );
  }
}
