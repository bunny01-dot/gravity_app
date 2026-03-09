import 'package:flutter/material.dart';
import 'package:gravity_app/services/tts_service.dart';

class DailyVerbDetailScreen extends StatefulWidget {
  final Map<String, dynamic> verb;
  final String preferredLanguage;

  const DailyVerbDetailScreen({
    super.key,
    required this.verb,
    required this.preferredLanguage,
  });

  @override
  State<DailyVerbDetailScreen> createState() => _DailyVerbDetailScreenState();
}

class _DailyVerbDetailScreenState extends State<DailyVerbDetailScreen> {
  final TtsService _ttsService = TtsService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final verb = widget.verb;
    final meaning = widget.preferredLanguage == 'Tamil'
        ? verb['Tamil'] ?? verb['Meaning']
        : widget.preferredLanguage == 'Hindi'
        ? verb['Hindi'] ?? verb['Meaning']
        : verb['Meaning'];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Verb Practice',
          style: TextStyle(color: colorScheme.onSurface, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Meaning Card
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.translate,
                        color: Color(0xFF4FACFE),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Meaning',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    meaning ?? 'N/A',
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Verb Forms Card
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.change_circle,
                            color: Color(0xFFC779D0),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Three Forms',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.play_circle_fill_rounded,
                          color: Color(0xFFC779D0),
                        ),
                        onPressed: () async {
                          await _ttsService.speak(verb['V1'] ?? "");
                          await Future.delayed(
                            const Duration(milliseconds: 500),
                          );
                          await _ttsService.speak(verb['V2'] ?? "");
                          await Future.delayed(
                            const Duration(milliseconds: 500),
                          );
                          await _ttsService.speak(verb['V3'] ?? "");
                        },
                        tooltip: "Play all forms with pauses",
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildVerbRow('V1 (Base)', verb['V1'] ?? 'N/A'),
                  Divider(
                    height: 24,
                    color: colorScheme.outlineVariant.withValues(alpha: 0.45),
                  ),
                  _buildVerbRow('V2 (Past)', verb['V2'] ?? 'N/A'),
                  Divider(
                    height: 24,
                    color: colorScheme.outlineVariant.withValues(alpha: 0.45),
                  ),
                  _buildVerbRow('V3 (Participle)', verb['V3'] ?? 'N/A'),
                ],
              ),
            ),

            // Examples (if present)
            if (verb['Example'] != null &&
                verb['Example'].toString().isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.lightbulb_outline,
                          color: Color(0xFFFFC107),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Example',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      verb['Example'].toString(),
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 16,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Complete Button
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Mark as Completed',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHigh : colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.45),
          width: 1,
        ),
      ),
      child: child,
    );
  }

  Widget _buildVerbRow(String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
        ),
        Row(
          children: [
            Text(
              value,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(
                Icons.volume_up,
                color: Color(0xFF4FACFE),
                size: 20,
              ),
              onPressed: () => _ttsService.speak(value),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _ttsService.stop();
    super.dispose();
  }
}
