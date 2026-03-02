// ignore_for_file: invalid_use_of_protected_member, library_private_types_in_public_api, use_build_context_synchronously

part of 'games_hub_card.dart';

extension GamesHubCardActions on _GamesHubCardState {
  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_currentIndex < _featuredGames.length - 1) {
        _currentIndex++;
      } else {
        _currentIndex = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentIndex,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutQuart,
        );
      }
    });
  }

  void _showGamesGrid(BuildContext context) async {
    SoundService().playTap();
    final result = await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const GamesGridSheet(),
    );

    if (result == 'go_to_daily_tasks') {
      widget.onGoToDailyTasks?.call();
    }
  }

  void _handleTap(BuildContext context) {
    if (widget.isLocked) {
      widget.onLockedTap?.call();
      return;
    }
    _showGamesGrid(context);
  }

  Widget _buildSlideItem(Map<String, dynamic> game) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            (game['color'] as Color).withValues(alpha: 0.2),
            Colors.transparent,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (game['color'] as Color).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    game['icon'] as IconData,
                    color: game['color'] as Color,
                    size: 28,
                  ),
                ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                const SizedBox(height: 12),
                Text(
                  game['title'] as String,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ).animate().fadeIn().slideX(begin: -0.2, end: 0),
                const SizedBox(height: 4),
                Text(
                  game['subtitle'] as String,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ).animate().fadeIn(delay: 100.ms),
              ],
            ),
          ),
          // Right side graphic decoration
          Opacity(
            opacity: 0.1,
            child: Icon(
              game['icon'] as IconData,
              size: 100,
              color: game['color'] as Color,
            ),
          ),
        ],
      ),
    );
  }
}
