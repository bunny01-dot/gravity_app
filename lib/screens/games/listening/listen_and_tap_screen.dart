import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gravity_app/services/sound_service.dart';

class ListenAndTapScreen extends StatefulWidget {
  const ListenAndTapScreen({super.key});

  @override
  State<ListenAndTapScreen> createState() => _ListenAndTapScreenState();
}

class _ListenAndTapScreenState extends State<ListenAndTapScreen> {
  late FlutterTts _flutterTts;
  int _currentIndex = 0;
  bool _answered = false;

  // Since we don't have image assets, we'll use Emojis or Icons as "Images"
  final List<Map<String, dynamic>> _rounds = [
    {
      'target': 'Apple',
      'options': [
        {'label': 'Apple', 'icon': Icons.apple, 'color': Colors.redAccent},
        {
          'label': 'Banana',
          'icon': Icons.change_history,
          'color': Colors.yellow,
        }, // Abstract representation if no asset
        {'label': 'Car', 'icon': Icons.directions_car, 'color': Colors.blue},
        {'label': 'House', 'icon': Icons.house, 'color': Colors.green},
      ],
      'correctIndex': 0,
    },
    {
      'target': 'Star',
      'options': [
        {
          'label': 'Moon',
          'icon': Icons.nightlight_round,
          'color': Colors.blueGrey,
        },
        {'label': 'Sun', 'icon': Icons.wb_sunny, 'color': Colors.orangeAccent},
        {'label': 'Star', 'icon': Icons.star, 'color': Colors.amber},
        {
          'label': 'Cloud',
          'icon': Icons.cloud,
          'color': Colors.lightBlueAccent,
        },
      ],
      'correctIndex': 2,
    },
    {
      'target': 'Book',
      'options': [
        {'label': 'Phone', 'icon': Icons.phone_android, 'color': Colors.grey},
        {'label': 'Book', 'icon': Icons.menu_book, 'color': Colors.brown},
        {'label': 'Laptop', 'icon': Icons.laptop, 'color': Colors.blueGrey},
        {'label': 'Pencil', 'icon': Icons.edit, 'color': Colors.yellowAccent},
      ],
      'correctIndex': 1,
    },
    {
      'target': 'Music',
      'options': [
        {'label': 'Camera', 'icon': Icons.camera_alt, 'color': Colors.black45},
        {
          'label': 'Music',
          'icon': Icons.music_note,
          'color': Colors.purpleAccent,
        },
        {
          'label': 'Movie',
          'icon': Icons.movie,
          'color': Colors.deepOrangeAccent,
        },
        {
          'label': 'Game',
          'icon': Icons.videogame_asset,
          'color': Colors.indigoAccent,
        },
      ],
      'correctIndex': 1,
    },
    {
      'target': 'Heart',
      'options': [
        {'label': 'Home', 'icon': Icons.home, 'color': Colors.brown},
        {'label': 'Face', 'icon': Icons.face, 'color': Colors.orange},
        {'label': 'Hand', 'icon': Icons.back_hand, 'color': Colors.amberAccent},
        {'label': 'Heart', 'icon': Icons.favorite, 'color': Colors.pinkAccent},
      ],
      'correctIndex': 3,
    },
  ];

  @override
  void initState() {
    super.initState();
    _flutterTts = FlutterTts();
  }

  void _play() async {
    await _flutterTts.speak(_rounds[_currentIndex]['target']);
  }

  void _onTap(int index) {
    if (_answered) return;
    setState(() => _answered = true);

    if (index == _rounds[_currentIndex]['correctIndex']) {
      SoundService().playSuccess();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Correct!"),
          backgroundColor: Colors.green,
        ),
      );
      Future.delayed(const Duration(seconds: 1), _next);
    } else {
      SoundService().playError();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Try Again"),
          backgroundColor: Colors.redAccent,
        ),
      );
      Future.delayed(const Duration(seconds: 1), _next);
    }
  }

  void _next() {
    if (_currentIndex < _rounds.length - 1) {
      setState(() {
        _currentIndex++;
        _answered = false;
      });
      _play();
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    var round = _rounds[_currentIndex];
    var options = round['options'] as List<Map<String, dynamic>>;

    return Scaffold(
      backgroundColor: const Color(0xFF030305),
      appBar: AppBar(
        title: const Text("Listen & Tap"),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          // Audio Control
          GestureDetector(
            onTap: _play,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withOpacity(0.4),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.volume_up, color: Colors.black),
                  SizedBox(width: 8),
                  Text(
                    "Play Sound",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 40),

          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
              ),
              itemCount: options.length,
              itemBuilder: (context, index) {
                final opt = options[index];
                return GestureDetector(
                  onTap: () => _onTap(index),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E2C),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(opt['icon'], size: 64, color: opt['color']),
                        const SizedBox(height: 12),
                        // Label hidden initially for higher difficulty?
                        // Or shown? Prompt says "Tap the image".
                        // Let's hide text to focus on listening -> visual connection.
                        // But maybe show it small? Let's hide it to make it a real listening test.
                      ],
                    ),
                  ),
                ).animate().scale(delay: (index * 50).ms);
              },
            ),
          ),
        ],
      ),
    );
  }
}
