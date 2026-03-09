import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gravity_app/services/offline_xp_service.dart';

class GlobalXpOverlay extends StatefulWidget {
  const GlobalXpOverlay({super.key});

  @override
  State<GlobalXpOverlay> createState() => _GlobalXpOverlayState();
}

class _GlobalXpOverlayState extends State<GlobalXpOverlay> {
  StreamSubscription<int>? _xpSub;
  Timer? _hideTimer;
  int _bufferedXp = 0;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _xpSub = OfflineXpService().xpAwards.listen(_onXpAwarded);
  }

  void _onXpAwarded(int amount) {
    if (!mounted || amount <= 0) return;

    setState(() {
      _bufferedXp += amount;
      _visible = true;
    });

    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(milliseconds: 1300), () {
      if (!mounted) return;
      setState(() {
        _visible = false;
      });
      Future.delayed(const Duration(milliseconds: 240), () {
        if (!mounted || _visible) return;
        setState(() {
          _bufferedXp = 0;
        });
      });
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _xpSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_bufferedXp <= 0 && !_visible) return const SizedBox.shrink();

    return IgnorePointer(
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            offset: _visible ? Offset.zero : const Offset(0, -1),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 220),
              opacity: _visible ? 1 : 0,
              child: Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD54F), Color(0xFFFFA726)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x55FFB300),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.bolt_rounded,
                      color: Colors.black87,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '+$_bufferedXp XP',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
