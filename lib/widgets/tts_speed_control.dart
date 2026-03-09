import 'package:flutter/material.dart';
import 'package:gravity_app/services/tts_service.dart';

class TtsSpeedControl extends StatefulWidget {
  final bool compact;
  final VoidCallback? onChange; // Optional callback

  const TtsSpeedControl({super.key, this.compact = false, this.onChange});

  @override
  State<TtsSpeedControl> createState() => _TtsSpeedControlState();
}

class _TtsSpeedControlState extends State<TtsSpeedControl> {
  final TtsService _tts = TtsService();
  bool _isExpanded = false;

  void _updateSpeed(double value) async {
    await _tts.setSpeechRate(value);
    if (widget.onChange != null) widget.onChange!();
    setState(() {});
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final double speed = _tts.currentRate;
    final double sliderValue = speed.clamp(0.25, 1.0);

    return GestureDetector(
      onTap: () {
        // If expanded, tapping the container (outside slider) checks if they hit the icon/text area basically.
        // But the Slider consumes taps. So tapping the "header" part should toggle.
        // For simplicity, we can just not toggle on tap of the *whole* container if expanded,
        // but we need a way to close it. Let's make the Icon+Text act as the toggle button.
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: widget.compact ? 8 : 12,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: const Color(
            0xFF1E1E2C,
          ).withValues(alpha: widget.compact ? 0.6 : 0.9),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white24),
          boxShadow: widget.compact
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics:
              const NeverScrollableScrollPhysics(), // Only scroll programmatically if needed, but mainly to catch overflow errors
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Toggle Button (Icon + Text)
              InkWell(
                onTap: _toggleExpand,
                borderRadius: BorderRadius.circular(20),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.speed_rounded,
                      color: _isExpanded
                          ? const Color(0xFFFFD700)
                          : const Color(0xFF4FACFE),
                      size: widget.compact ? 16 : 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "${speed.toStringAsFixed(2)}x",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: widget.compact ? 12 : 14,
                        fontWeight: FontWeight.bold,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),

              // Collapsible Slider
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: SizedBox(
                  width: _isExpanded ? (widget.compact ? 120 : 150) : 0,
                  child: _isExpanded
                      ? Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: SizedBox(
                            height: 20,
                            child: SliderTheme(
                              data: SliderThemeData(
                                trackHeight: 2,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 6,
                                ),
                                overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 12,
                                ),
                                activeTrackColor: const Color(0xFF4FACFE),
                                inactiveTrackColor: Colors.white24,
                                thumbColor: Colors.white,
                                overlayColor: const Color(
                                  0xFF4FACFE,
                                ).withValues(alpha: 0.2),
                              ),
                              child: Slider(
                                value: sliderValue,
                                min: 0.25,
                                max: 1.0,
                                divisions: 3,
                                onChanged: _updateSpeed,
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
