import 'package:flutter/material.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';
import 'game_screen.dart';

void main() => runApp(const ArcheryApp());

class ArcheryApp extends StatelessWidget {
  const ArcheryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GameShell(
      title: 'Archery',
      tagline: 'Read the wind, steady your hand, and split the bullseye!',
      emoji: '🏹',
      slug: 'archery',
      howToPlay:
          '• Drag anywhere on the target to move your aim reticle.\n• Release to loose your arrow — watch the wind! 💨\n• Aim INTO the wind: it pushes your arrow sideways.\n• 10 arrows each across 3 distances. Highest score wins!\n• Playing solo? The bot is a dead-eye… mostly. 🤖',
      playerOptions: const [1, 2],
      supportsBots: true,
      gameBuilder: (ctx, players, cb) => ArcheryScreen(players: players, callbacks: cb),
    );
  }
}
