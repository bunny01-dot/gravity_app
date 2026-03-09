import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:share_plus/share_plus.dart';

class SystemCrashCard extends StatefulWidget {
  final FlutterErrorDetails details;
  final VoidCallback? onRestart;

  const SystemCrashCard({super.key, required this.details, this.onRestart});

  @override
  State<SystemCrashCard> createState() => _SystemCrashCardState();
}

class _SystemCrashCardState extends State<SystemCrashCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    // If we are in release mode, we might want to be less verbose,
    // but the user seemingly wants to debug/solve issues.

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          // Background Gradient (Subtle Error Theme)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF2C0B0E), // Dark Red
                  Color(0xFF0F172A), // Dark Blue
                ],
              ),
            ),
          ),

          // Glass blur
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.black.withValues(alpha: 0.3)),
          ),

          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Error Icon with Glow
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.redAccent.withValues(alpha: 0.3),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.bug_report_rounded,
                        size: 40,
                        color: Colors.redAccent,
                      ),
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      "System Error",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "An unexpected issue occurred.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                    const SizedBox(height: 32),

                    // The Crash Card
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Error Summary
                            Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Colors.orangeAccent,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    widget.details.exception
                                        .toString()
                                        .split('\n')
                                        .first,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),
                            const Divider(color: Colors.white10),
                            const SizedBox(height: 16),

                            // Detail View (Expandable)
                            Flexible(
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (_isExpanded) ...[
                                      const Text(
                                        "Full Exception:",
                                        style: TextStyle(
                                          color: Colors.white54,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      SelectableText(
                                        widget.details.exception.toString(),
                                        style: const TextStyle(
                                          color: Colors.redAccent,
                                          fontFamily: 'monospace',
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        "Stack Trace:",
                                        style: TextStyle(
                                          color: Colors.white54,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      SelectableText(
                                        widget.details.stack.toString(),
                                        style: const TextStyle(
                                          color: Colors.white60,
                                          fontFamily: 'monospace',
                                          fontSize: 10,
                                        ),
                                      ),
                                    ] else
                                      Center(
                                        child: TextButton.icon(
                                          onPressed: () {
                                            setState(() {
                                              _isExpanded = true;
                                            });
                                          },
                                          icon: const Icon(
                                            Icons.keyboard_arrow_down,
                                            color: Colors.cyanAccent,
                                          ),
                                          label: const Text(
                                            "Show Technical Details",
                                            style: TextStyle(
                                              color: Colors.cyanAccent,
                                            ),
                                          ),
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

                    const SizedBox(height: 32),

                    // Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildActionButton(
                          label: "Copy",
                          icon: Icons.copy_rounded,
                          color: const Color(0xFF4FACFE),
                          onTap: _handleCopy,
                        ),
                        const SizedBox(width: 16),
                        _buildActionButton(
                          label: "Share",
                          icon: Icons.share_rounded,
                          color: const Color(0xFF00F2FE),
                          onTap: _handleShare,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleCopy() {
    final text =
        "System Error Report:\n\nException:\n${widget.details.exception}\n\nStack:\n${widget.details.stack}";
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Error details copied to clipboard"),
        backgroundColor: Color(0xFF4FACFE),
      ),
    );
  }

  void _handleShare() {
    final text =
        "System Error Report:\n\nException:\n${widget.details.exception}\n\nStack:\n${widget.details.stack}";
    SharePlus.instance.share(
      ShareParams(text: text, subject: "Gravity App Crash Report"),
    );
  }
}
