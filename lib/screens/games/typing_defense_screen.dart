import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../services/data_service.dart';
import '../../services/sound_service.dart';
import '../../services/offline_xp_service.dart';
import 'package:gravity_app/services/safe_game_content_provider.dart';

class TypingDefenseScreen extends StatefulWidget {
  const TypingDefenseScreen({super.key});

  @override
  State<TypingDefenseScreen> createState() => _TypingDefenseScreenState();
}

class _TypingDefenseScreenState extends State<TypingDefenseScreen>
    with SingleTickerProviderStateMixin {
  late GameController _gameController;
  late Ticker _ticker;
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _gameController = GameController(
      onGameOver: _handleGameOver,
      onScoreUpdate: (s) {}, // Could use this to update Overlay UI only
      context: context,
    );
    _ticker = createTicker(_onTick);
    _inputController.addListener(_handleInput);

    // Auto-focus logic
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _onTick(Duration elapsed) {
    if (_gameController.isPlaying) {
      _gameController.update(elapsed);
    }
  }

  void _handleInput() {
    // Pass raw text to game controller to handle matching
    _gameController.handleInput(_inputController.text);
    // Clear handled input handled inside controller if matched,
    // but here we just pass the current buffer.
    // Actually better:
    // Game controller checks if matches. If match, returns true -> we clear.
    if (_gameController.tryMatch(_inputController.text)) {
      _inputController.clear();
    }
  }

  void _startGame(Difficulty difficulty) {
    _gameController.start(difficulty);
    if (!_ticker.isActive) _ticker.start();
    _focusNode.requestFocus();
    setState(() {}); // Rebuild to hide menu/show game
  }

  void _handleGameOver(int score) {
    // Ticker can stop or keep running for particles
    setState(() {}); // Rebuild to show Game Over UI
  }

  void _exitGame() {
    _ticker.stop();
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _gameController.dispose();
    _inputController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _gameController,
      builder: (context, child) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final onSurface = theme.colorScheme.onSurface;
        if (_gameController.isLoading) {
          return Scaffold(
            backgroundColor: Colors.indigo.shade50,
            body: const Center(
              child: CircularProgressIndicator(color: Colors.indigo),
            ),
          );
        }

        if (_gameController.hasInsufficientContent) {
          return Scaffold(
            backgroundColor: Colors.indigo.shade50,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.indigo),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: const Center(
              child: Text("No words found. Please complete more lessons."),
            ),
          );
        }

        // Use RepaintBoundary to isolate the CustomPaint from any parent rebuilds
        // (though here we only rebuild on menu/gameover transitions)
        return Scaffold(
          backgroundColor: isDark
              ? Colors.black
              : theme.scaffoldBackgroundColor,
          body: Stack(
            fit: StackFit.expand,
            children: [
              // 1. The Game World (CustomPainter) - Highly Optimized
              RepaintBoundary(
                child: CustomPaint(
                  painter: GamePainter(_gameController),
                  child: Container(),
                ),
              ),

              // 2. The Input Field (Hidden but active, or overlays)
              // We keep the text field invisible but focused to capture input.
              Positioned(
                bottom: -100,
                left: 0,
                child: SizedBox(
                  width: 1,
                  child: TextField(
                    controller: _inputController,
                    focusNode: _focusNode,
                    autofocus: true,
                    autocorrect: false,
                    enableSuggestions: false,
                  ),
                ),
              ),

              // 3. HUD Layer (Score, Lives, Input Feedback)
              if (_gameController.isPlaying)
                Positioned(
                  top: 40,
                  left: 20,
                  right: 20,
                  child: AnimatedBuilder(
                    animation:
                        _gameController, // Listens to score/lives/input changes
                    builder: (context, child) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "SCORE: ${_gameController.score}",
                                style: TextStyle(
                                  color: onSurface,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              // Show current typed input
                              Container(
                                margin: const EdgeInsets.only(top: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.1)
                                      : onSurface.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white30
                                        : onSurface.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Text(
                                  _inputController.text.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.cyanAccent,
                                    fontSize: 20,
                                    letterSpacing: 2,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: List.generate(
                              3,
                              (i) => Icon(
                                Icons.favorite,
                                color: i < _gameController.lives
                                    ? Colors.redAccent
                                    : Colors.grey,
                                size: 32,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

              // 4. Input Prompt (if needed at bottom)
              if (_gameController.isPlaying)
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      "TYPE TO DESTROY",
                      style: TextStyle(
                        color: onSurface.withValues(alpha: 0.3),
                        letterSpacing: 4,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),

              // 5. Menus
              if (!_gameController.isPlaying && !_gameController.isGameOver)
                _buildMenu(),

              if (_gameController.isGameOver) _buildGameOver(),

              // 6. Back Button
              Positioned(
                top: 40,
                left: 10,
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: onSurface),
                  onPressed: _exitGame,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenu() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    if (_gameController.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Container(
      color: isDark ? Colors.black87 : Colors.white.withValues(alpha: 0.95),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shield_moon_rounded, size: 80, color: Colors.cyan),
            const SizedBox(height: 16),
            Text(
              "TYPING DEFENSE",
              style: TextStyle(
                color: onSurface,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 48),
            _menuBtn("EASY", Colors.green, Difficulty.easy),
            const SizedBox(height: 16),
            _menuBtn("MEDIUM", Colors.orange, Difficulty.medium),
            const SizedBox(height: 16),
            _menuBtn("HARD", Colors.red, Difficulty.hard),
          ],
        ),
      ),
    );
  }

  Widget _menuBtn(String label, Color color, Difficulty d) {
    return InkWell(
      onTap: () => _startGame(d),
      child: Container(
        width: 200,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(30),
          color: color.withValues(alpha: 0.1),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildGameOver() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    return Container(
      color: isDark ? Colors.black87 : Colors.white.withValues(alpha: 0.95),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "GAME OVER",
              style: TextStyle(
                color: Colors.red,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Final Score: ${_gameController.score}",
              style: TextStyle(color: onSurface, fontSize: 24),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => setState(() => _gameController.reset()),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              child: const Text("MAIN MENU"),
            ),
          ],
        ),
      ),
    );
  }
}

// --- CONTROLLER ---

enum Difficulty { easy, medium, hard }

class GameController extends ChangeNotifier {
  // Config
  static const double worldWidth = 1000.0;
  static const double worldHeight = 2000.0;

  // State
  bool isPlaying = false;
  bool isGameOver = false;
  bool isLoading = true;
  int score = 0;
  int lives = 3;
  int wave = 1;
  double _timeSinceLastSpawn = 0;
  double _spawnRate = 2.0; // Seconds
  Difficulty difficulty = Difficulty.easy;

  // Entities
  List<Bomb> bombs = [];
  List<Bullet> bullets = [];
  List<Particle> particles = [];

  // Data
  List<String> _wordBag = [];
  final Random _rnd = Random();
  final Function(int) onGameOver;
  final Function(int) onScoreUpdate;
  final BuildContext context;

  GameController({
    required this.onGameOver,
    required this.onScoreUpdate,
    required this.context,
  }) {
    _loadWords();
  }

  bool hasInsufficientContent = false;

  Future<void> _loadWords() async {
    isLoading = true;
    hasInsufficientContent = false;
    notifyListeners();

    try {
      final safeProvider = SafeGameContentProvider(DataService());
      final items = await safeProvider.getEligibleVocabulary(minCount: 10);

      _wordBag = items.map((i) => i.word).toList();

      if (_wordBag.length < 10) {
        debugPrint(
          "TypingDefense: Warning, fewer items than requested were fetched.",
        );
      }
    } catch (e) {
      debugPrint("TypingDefense: Error loading dynamic words: $e");
    }

    // Check again
    if (_wordBag.isEmpty) {
      hasInsufficientContent = true;
    }

    isLoading = false;
    notifyListeners();
  }

  void start(Difficulty d) {
    difficulty = d;
    score = 0;
    lives = 3;
    wave = 1;
    bombs.clear();
    bullets.clear();
    particles.clear();
    isPlaying = true;
    isGameOver = false;

    _spawnRate = d == Difficulty.easy
        ? 2.5
        : (d == Difficulty.medium ? 1.8 : 1.2);
    notifyListeners();
  }

  void reset() {
    isPlaying = false;
    isGameOver = false;
    notifyListeners();
  }

  void handleInput(String input) {
    tryMatch(input);
  }

  // The Game Loop
  void update(Duration elapsed) {
    if (!isPlaying) return;

    // For simplicity, let's treat dt as seconds actually for physics
    double dtSec = elapsed.inMicroseconds / 1000000.0;

    _timeSinceLastSpawn += dtSec;
    if (_timeSinceLastSpawn > _spawnRate) {
      _spawnBomb();
      _timeSinceLastSpawn = 0;
      // Increase difficulty slightly
      if (_spawnRate > 0.5) _spawnRate *= 0.99;
    }

    // Update Bombs
    for (var b in bombs) {
      b.y += b.speed * dtSec * 60; // Scale speed for 60fps base
      if (b.y > worldHeight - 150 && !b.hitGround) {
        b.hitGround = true;
        lives--;
        _addExplosion(b.x, b.y, Colors.red);
        SoundService().playError();
        if (lives <= 0) {
          _triggerGameOver();
        }
      }
    }
    bombs.removeWhere((b) => b.hitGround && b.y > worldHeight);

    // Update Bullets
    for (var b in bullets) {
      double dx = b.targetX - b.x;
      double dy = b.targetY - b.y;
      double dist = sqrt(dx * dx + dy * dy);

      if (dist < 20) {
        b.hit = true;
        // Hit logic handled in cleanup loop?
        // Better: trigger hit now
      } else {
        b.x += (dx / dist) * 40 * dtSec * 60;
        b.y += (dy / dist) * 40 * dtSec * 60;
      }
    }

    // Cleanup Hit
    for (var b in bullets) {
      if (b.hit) {
        bombs.removeWhere((bomb) => bomb.id == b.targetId);
        _addExplosion(b.targetX, b.targetY, Colors.amber);
      }
    }
    bullets.removeWhere((b) => b.hit);

    // Update Particles
    for (var p in particles) {
      p.life -= 2.0 * dtSec;
      p.x += p.vx * dtSec * 60;
      p.y += p.vy * dtSec * 60;
    }
    particles.removeWhere((p) => p.life <= 0);

    // Notify CustomPainter to repaint
    notifyListeners();
  }

  void _spawnBomb() {
    if (_wordBag.isEmpty) return;
    String word = _wordBag[_rnd.nextInt(_wordBag.length)];
    // Retry for uniqueness
    int retries = 0;
    while (bombs.any((b) => b.word == word) && retries < 10) {
      word = _wordBag[_rnd.nextInt(_wordBag.length)];
      retries++;
    }

    double speed = difficulty == Difficulty.easy
        ? 1.5
        : (difficulty == Difficulty.medium ? 3.0 : 4.5);
    // Varry X
    double x = 100 + _rnd.nextDouble() * (worldWidth - 200);

    bombs.add(Bomb(word: word, x: x, y: -100, speed: speed));
  }

  bool tryMatch(String input) {
    if (input.isEmpty) return false; // Don't trigger on empty

    input = input.trim().toLowerCase();

    // Find matching bomb
    try {
      final match = bombs.firstWhere(
        (b) => b.word.toLowerCase() == input && !b.hitGround && !b.isTargeted,
      );
      // Fire
      _fireBullet(match);
      match.isTargeted = true;
      return true; // Match found, clear input
    } catch (e) {
      // No match
      return false;
    }
  }

  void _fireBullet(Bomb target) {
    bullets.add(
      Bullet(
        x: worldWidth / 2,
        y: worldHeight - 100,
        targetX: target.x,
        targetY: target.y,
        targetId: target.id,
      ),
    );
    score += (10 * (difficulty.index + 1));
    SoundService().playTap();
  }

  void _addExplosion(double x, double y, Color color) {
    for (int i = 0; i < 15; i++) {
      double angle = _rnd.nextDouble() * 2 * pi;
      double speed = 2 + _rnd.nextDouble() * 6;
      particles.add(
        Particle(
          x: x,
          y: y,
          vx: cos(angle) * speed,
          vy: sin(angle) * speed,
          color: color,
        ),
      );
    }
  }

  Future<void> _triggerGameOver() async {
    isPlaying = false;
    isGameOver = true;
    onGameOver(score);

    // Save Score
    await DataService().saveHighScore('typing_defense', score);
    // XP
    int xp = (score * 0.1).ceil();
    if (xp > 0) await OfflineXpService().addXp(xp);

    notifyListeners();
  }
}

// --- PAINTER ---

class GamePainter extends CustomPainter {
  final GameController game;

  GamePainter(this.game) : super(repaint: game);

  @override
  void paint(Canvas canvas, Size size) {
    if (!game.isPlaying) return;

    // Scale game world to screen
    final double scaleX = size.width / GameController.worldWidth;
    final double scaleY = size.height / GameController.worldHeight;

    // Background gradient? (Handled by Widget for performance, or draw here)
    // Draw here is fine.

    canvas.save();
    canvas.scale(scaleX, scaleY);

    // Draw Bombs
    for (var b in game.bombs) {
      _drawBomb(canvas, b);
    }

    // Draw Bullets
    final Paint bulletPaint = Paint()..color = Colors.yellow;
    for (var b in game.bullets) {
      canvas.drawCircle(Offset(b.x, b.y), 6, bulletPaint);
    }

    // Draw Particles
    for (var p in game.particles) {
      final Paint pPaint = Paint()
        ..color = p.color.withValues(alpha: p.life.clamp(0.0, 1.0));
      canvas.drawCircle(Offset(p.x, p.y), 4, pPaint);
    }

    // Draw Cannon (Simple Triangle)
    final Paint cannonPaint = Paint()..color = Colors.cyan;
    final Path cannon = Path();
    cannon.moveTo(
      GameController.worldWidth / 2,
      GameController.worldHeight - 120,
    );
    cannon.lineTo(
      GameController.worldWidth / 2 - 20,
      GameController.worldHeight - 80,
    );
    cannon.lineTo(
      GameController.worldWidth / 2 + 20,
      GameController.worldHeight - 80,
    );
    cannon.close();
    canvas.drawPath(cannon, cannonPaint);

    canvas.restore();
  }

  void _drawBomb(Canvas canvas, Bomb b) {
    // Draw Box
    final Paint bg = Paint()..color = Colors.black.withValues(alpha: 0.8);
    final Paint border = Paint()
      ..color = Colors.redAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // Text Layout
    final textSpan = TextSpan(
      text: b.word,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 40,
        fontWeight: FontWeight.bold,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final RRect rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(b.x, b.y),
        width: textPainter.width + 40,
        height: textPainter.height + 20,
      ),
      const Radius.circular(20),
    );

    canvas.drawRRect(rect, bg);
    canvas.drawRRect(rect, border);

    // Draw Text
    textPainter.paint(
      canvas,
      Offset(b.x - textPainter.width / 2, b.y - textPainter.height / 2),
    );

    // Connect to parachute line? (Optional)
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class Bomb {
  final String id;
  final String word;
  double x, y, speed;
  bool isTargeted = false;
  bool hitGround = false;
  Bomb({
    required this.word,
    required this.x,
    required this.y,
    required this.speed,
  }) : id =
           DateTime.now().microsecondsSinceEpoch.toString() +
           Random().nextInt(1000).toString();
}

class Bullet {
  double x, y, targetX, targetY;
  String targetId;
  bool hit = false;
  Bullet({
    required this.x,
    required this.y,
    required this.targetX,
    required this.targetY,
    required this.targetId,
  });
}

class Particle {
  double x, y, vx, vy, life = 1.0;
  Color color;
  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
  });
}
