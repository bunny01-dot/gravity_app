// ignore_for_file: invalid_use_of_protected_member, library_private_types_in_public_api, use_build_context_synchronously

part of 'dashboard_screen.dart';

extension DashboardShellHelpers on _DashboardScreenState {
  Widget _buildConnectivityCard() {
    if (_isConnected && !_showOnlineSuccess) return const SizedBox.shrink();
    return DashboardConnectivityCard(isOnline: _isConnected);
  }

  int _maxTabIndexForCurrentRole(bool showMastery) {
    if (_userRole == 'teacher') return 3;
    return showMastery ? 3 : 2;
  }

  Widget _buildXpBurstChip() {
    return Container(
          key: ValueKey<int>(_xpBurstVersion),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFD54F), Color(0xFFFFA726)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFC107).withValues(alpha: 0.45),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.bolt_rounded, color: Colors.black87, size: 16),
              const SizedBox(width: 6),
              Text(
                '+$_xpBurstAmount XP',
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 180.ms)
        .moveY(begin: 14, end: -6, duration: 680.ms, curve: Curves.easeOutCubic)
        .then()
        .fadeOut(duration: 260.ms);
  }

  void _showXpBurstAnimation(int xpAwarded) {
    if (xpAwarded <= 0 || !mounted) return;
    _xpBurstTimer?.cancel();
    setState(() {
      _xpBurstAmount = xpAwarded;
      _xpBurstVersion++;
      _showXpBurst = true;
    });
    _xpBurstTimer = Timer(const Duration(milliseconds: 1250), () {
      if (!mounted) return;
      setState(() {
        _showXpBurst = false;
      });
    });
  }

  String _getAppBarTitle() {
    final bool showMastery = _isMasteryFeatureEnabled && _userRole == 'student';

    if (_userRole == 'teacher') {
      switch (_currentIndex) {
        case 0:
          return 'Dashboard';
        case 1:
          return 'Students';
        case 2:
          return 'Library';
        case 3:
          return 'Settings';
        default:
          return 'English Learning App';
      }
    }

    // Student titles
    if (showMastery) {
      switch (_currentIndex) {
        case 0:
          return 'Dashboard';
        case 1:
          return _DashboardScreenState._studentPlanTabLabel;
        case 2:
          return 'Mastery';
        case 3:
          return 'Settings';
        default:
          return 'English Learning App';
      }
    }

    switch (_currentIndex) {
      case 0:
        return 'Dashboard';
      case 1:
        return _DashboardScreenState._studentPlanTabLabel;
      case 2:
        return 'Settings';
      default:
        return 'English Learning App';
    }
  }
}
