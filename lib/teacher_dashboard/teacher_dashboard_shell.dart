// ignore_for_file: invalid_use_of_protected_member, library_private_types_in_public_api

part of 'teacher_dashboard_screen.dart';

extension TeacherDashboardShell on _TeacherDashboardState {
  Widget _buildBottomNav() {
    return Animated3DBottomNav(
      currentIndex: _currentIndex,
      onTap: _handleBottomNavTap,
      role: 'teacher',
    );
  }

  String _getAppBarTitle() {
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
        return 'Teacher Portal';
    }
  }

  Future<void> _refreshDashboard() async {
    await _loadTeacherInfo();
    setState(() {});
  }

  Future<void> _handleDashboardPullRefresh() async {
    if (_isDashboardPullRefreshing) return;
    if (mounted) {
      setState(() {
        _isDashboardPullRefreshing = true;
        _showDashboardPullRefreshLottie = false;
      });
    }
    _dashboardPullRefreshLottieTimer?.cancel();
    _dashboardPullRefreshLottieTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted || !_isDashboardPullRefreshing) return;
      setState(() => _showDashboardPullRefreshLottie = true);
    });
    try {
      await _refreshDashboard();
      await Future<void>.delayed(const Duration(milliseconds: 180));
    } finally {
      _dashboardPullRefreshLottieTimer?.cancel();
      if (mounted) {
        setState(() {
          _isDashboardPullRefreshing = false;
          _showDashboardPullRefreshLottie = false;
        });
      }
    }
  }

  Widget _buildAsyncLoader({
    required String label,
    double size = 78,
    double fontSize = 12,
    Color textColor = Colors.white70,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: Lottie.asset(
              'assets/lottie/loading.json',
              fit: BoxFit.contain,
              repeat: true,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
