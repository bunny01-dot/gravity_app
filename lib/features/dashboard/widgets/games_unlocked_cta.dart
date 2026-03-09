import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class GamesUnlockedCTA extends StatelessWidget {
  final VoidCallback onTap;

  const GamesUnlockedCTA({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child:
          Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF6C63FF).withValues(alpha: 0.85),
                      const Color(0xFF4FACFE).withValues(alpha: 0.85),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C63FF).withValues(alpha: 0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.onPrimary.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.sports_esports_rounded,
                        color: colorScheme.onPrimary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Play a Game",
                            style: TextStyle(
                              color: colorScheme.onPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Take a short break and practice with games.",
                            style: TextStyle(
                              color: colorScheme.onPrimary.withValues(
                                alpha: 0.78,
                              ),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: colorScheme.onPrimary.withValues(alpha: 0.78),
                      size: 16,
                    ),
                  ],
                ),
              )
              .animate(onPlay: (c) => c.repeat())
              .shimmer(duration: 700.ms, delay: 5.seconds),
    );
  }
}
