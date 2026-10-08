import 'dart:math';
import 'package:flutter/material.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';

/// Archery — drag to aim, release to loose, read the wind.
class ArcheryScreen extends StatefulWidget {
  final List<Player> players;
  final GameCallbacks callbacks;

  const ArcheryScreen({super.key, required this.players, required this.callbacks});

  @override
  State<ArcheryScreen> createState() => _ArcheryScreenState();
}

class _ArcheryScreenState extends State<ArcheryScreen>
    with SingleTickerProviderStateMixin {
  static const shotsPerPlayer = 10;
  final _rnd = Random();
  late List<int> fired; // shots fired per player
  int turn = 0;
  double wind = 0; // -5..5, + pushes right
  Offset reticle = Offset.zero; // aim offset from target center (px)
  bool aiming = false;
  bool flying = false;
  bool over = false;

  // flight animation
  late AnimationController _flight;
  Offset flightFrom = Offset.zero;
  Offset flightTo = Offset.zero;
  Offset? lastLanding; // stuck arrow marker
  int lastScore = -1;
  String lastNote = '';

  int get _shotNo => fired[turn]; // 0-based shot number for current player
  int get _distIndex => _shotNo < 3 ? 0 : (_shotNo < 7 ? 1 : 2);
  double get _windFactor => [1.0, 1.6, 2.3][_distIndex];
  double get _targetScale => [1.0, 0.82, 0.66][_distIndex];
  String get _distLabel => ['30m', '50m', '70m'][_distIndex];

  @override
  void initState() {
    super.initState();
    fired = List.filled(widget.players.length, 0);
    _flight = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 650))
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) _resolveShot();
      });
    _newWind();
    widget.callbacks.setActivePlayer(0);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeBot());
  }

  @override
  void dispose() {
    _flight.dispose();
    super.dispose();
  }

  void _newWind() {
    wind = (_rnd.nextDouble() * 2 - 1) * 5;
  }

  void _maybeBot() {
    if (over || !widget.players[turn].isBot) return;
    Future.delayed(const Duration(milliseconds: 850), () {
      if (!mounted || over || flying || !widget.players[turn].isBot) return;
      // bot compensates wind, imperfectly
      final err = 26 + _distIndex * 14.0;
      reticle = Offset(
        -wind * _windFactor * 8 * 0.85 + _gauss() * err,
        _gauss() * err,
      );
      _loose();
    });
  }

  double _gauss() => (_rnd.nextDouble() + _rnd.nextDouble() + _rnd.nextDouble()) / 1.5 - 1;

  void _loose() {
    if (over || flying) return;
    setState(() => flying = true);
    Sfx.move();
    // landing = aim + wind drift + wobble
    final drift = Offset(wind * _windFactor * 8, 0);
    final wobble = Offset(_gauss() * 9, _gauss() * 9);
    flightTo = reticle + drift + wobble;
    _flight.forward(from: 0);
  }

  void _resolveShot() {
    final r = _targetRadius;
    final d = flightTo.distance;
    int score;
    String note;
    if (d > r) {
      score = 0;
      note = 'Miss! The wind laughed. 💨';
      Sfx.lose();
    } else {
      score = 10 - (d / r * 10).floor();
      score = score.clamp(1, 10);
      note = score == 10 ? 'BULLSEYE! 🎯🔥' : '+$score — nice shot!';
      if (score >= 8) {
        Sfx.win();
      } else {
        Sfx.click();
      }
    }
    final p = widget.players[turn];
    p.score += score;
    widget.callbacks.refreshHud();
    setState(() {
      flying = false;
      lastLanding = flightTo;
      lastScore = score;
      lastNote = note;
      fired[turn]++;
    });

    final totalNeeded = shotsPerPlayer * widget.players.length;
    final totalFired = fired.reduce((a, b) => a + b);
    if (totalFired >= totalNeeded) {
      _endGame();
      return;
    }
    setState(() {
      turn = (turn + 1) % widget.players.length;
      reticle = Offset.zero;
      aiming = false;
    });
    widget.callbacks.setActivePlayer(turn);
    _newWind();
    _maybeBot();
  }

  void _endGame() {
    setState(() => over = true);
    final ps = widget.players;
    final best = ps.map((p) => p.score).reduce(max);
    final winners = ps.where((p) => p.score == best).toList();
    if (winners.length == 1) {
      widget.callbacks.finish(
          winner: winners.first,
          headline: '${winners.first.name} takes the gold! 🏆',
          subline: 'Final score: $best');
    } else {
      widget.callbacks.finish(
          headline: "It's a dead heat! 🤝",
          subline: 'Everyone scored $best. Rematch?');
    }
  }

  double get _targetRadius => 130 * _targetScale;

  @override
  Widget build(BuildContext context) {
    final t = ThemeController.of(context).theme;
    final current = widget.players[turn];
    final arrowsLeft = shotsPerPlayer - fired[turn];
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (!over)
            TurnBanner(
                player: current,
                action: current.isBot
                    ? ' is lining up… 🤖'
                    : ', drag to aim, release to loose!'),
          const SizedBox(height: 8),
          _windRow(t),
          const SizedBox(height: 4),
          Expanded(
            child: LayoutBuilder(builder: (ctx, box) {
              final size = box.biggest;
              final center = Offset(size.width / 2, size.height * 0.38);
              return GestureDetector(
                onPanStart: current.isBot || over || flying
                    ? null
                    : (d) {
                        setState(() {
                          aiming = true;
                          reticle = _clampReticle(d.localPosition - center);
                        });
                      },
                onPanUpdate: current.isBot || over || flying
                    ? null
                    : (d) {
                        setState(() {
                          reticle = _clampReticle(d.localPosition - center);
                        });
                      },
                onPanEnd: current.isBot || over || flying
                    ? null
                    : (_) {
                        setState(() => aiming = false);
                        _loose();
                      },
                child: CustomPaint(
                  size: size,
                  painter: _RangePainter(
                    theme: t,
                    center: center,
                    radius: _targetRadius,
                    reticle: reticle,
                    aiming: aiming,
                    flightT: flying ? _flight.value : -1,
                    flightFrom: Offset(size.width / 2, size.height - 40),
                    flightTo: center + flightTo,
                    lastLanding:
                        lastLanding == null ? null : center + lastLanding!,
                  ),
                ),
              );
            }),
          ),
          if (lastScore >= 0 && !over)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(lastNote,
                  style: TextStyle(
                      color: t.text, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          Text(
              '🏹 $_distLabel • $arrowsLeft arrow${arrowsLeft == 1 ? '' : 's'} left',
              style: TextStyle(color: t.muted, fontSize: 14)),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Offset _clampReticle(Offset o) {
    final m = _targetRadius * 1.15;
    return Offset(o.dx.clamp(-m, m), o.dy.clamp(-m, m));
  }
}

class _RangePainter extends CustomPainter {
  final GameTheme theme;
  final Offset center;
  final double radius;
  final Offset reticle;
  final bool aiming;
  final double flightT; // -1 = no flight
  final Offset flightFrom;
  final Offset flightTo;
  final Offset? lastLanding;

  _RangePainter({
    required this.theme,
    required this.center,
    required this.radius,
    required this.reticle,
    required this.aiming,
    required this.flightT,
    required this.flightFrom,
    required this.flightTo,
    required this.lastLanding,
  });

  // archery colors: white, white, black, black, blue, blue, red, red, gold, gold
  static const _ringColors = [
    Color(0xFFF5F5F5), Color(0xFFF5F5F5),
    Color(0xFF2B2B2B), Color(0xFF2B2B2B),
    Color(0xFF29B6F6), Color(0xFF29B6F6),
    Color(0xFFEF5350), Color(0xFFEF5350),
    Color(0xFFFFD54F), Color(0xFFFFD54F),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // grass
    final grass = Paint()..color = theme.primary.withValues(alpha: 0.10);
    canvas.drawRect(Offset.zero & size, grass);

    // target rings (outer = 1 ... inner = 10)
    for (int i = 0; i < 10; i++) {
      final r = radius * (10 - i) / 10;
      canvas.drawCircle(center, r,
          Paint()..color = _ringColors[i]);
      canvas.drawCircle(
          center, r, Paint()..color = theme.muted..style = PaintingStyle.stroke..strokeWidth = 1);
    }
    // stand
    canvas.drawLine(center + Offset(-radius * 0.5, radius),
        center + Offset(-radius * 0.5, size.height * 0.62),
        Paint()..color = theme.muted..strokeWidth = 6);
    canvas.drawLine(center + Offset(radius * 0.5, radius),
        center + Offset(radius * 0.5, size.height * 0.62),
        Paint()..color = theme.muted..strokeWidth = 6);

    // last stuck arrow
    if (lastLanding != null && flightT < 0) {
      _drawArrow(canvas, lastLanding!, -0.5, theme.accent);
    }

    // bow at bottom
    final bowBase = Offset(size.width / 2, size.height - 30);
    final bowPaint = Paint()
      ..color = theme.secondary
      ..strokeWidth = 7
      ..style = PaintingStyle.stroke;
    canvas.drawArc(Rect.fromCircle(center: bowBase + const Offset(0, -34), radius: 34),
        -1.2, 2.4, false, bowPaint);
    canvas.drawLine(bowBase + const Offset(-16, -58), bowBase + const Offset(16, -10),
        Paint()..color = theme.muted..strokeWidth = 2);

    // aim reticle
    if (aiming) {
      final rc = center + reticle;
      final rp = Paint()
        ..color = theme.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawCircle(rc, 14, rp);
      canvas.drawLine(rc + const Offset(-22, 0), rc + const Offset(22, 0), rp);
      canvas.drawLine(rc + const Offset(0, -22), rc + const Offset(0, 22), rp);
    }

    // flying arrow
    if (flightT >= 0) {
      final p = Offset(
        flightFrom.dx + (flightTo.dx - flightFrom.dx) * flightT,
        flightFrom.dy +
            (flightTo.dy - flightFrom.dy) * flightT -
            sin(flightT * pi) * 60,
      );
      final dir = (flightTo - flightFrom).direction;
      _drawArrow(canvas, p, dir, theme.text);
    }
  }

  void _drawArrow(Canvas canvas, Offset tip, double angle, Color color) {
    canvas.save();
    canvas.translate(tip.dx, tip.dy);
    canvas.rotate(angle);
    final p = Paint()..color = color..strokeWidth = 4..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(-46, 0), const Offset(0, 0), p);
    canvas.drawLine(const Offset(-46, 0), const Offset(-36, -8), p);
    canvas.drawLine(const Offset(-46, 0), const Offset(-36, 8), p);
    canvas.drawCircle(const Offset(2, 0), 4, Paint()..color = color);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RangePainter old) => true;
}

extension _WindRow on _ArcheryScreenState {
  Widget _windRow(GameTheme t) {
    final strength = wind.abs().round().clamp(0, 5);
    final arrows = wind >= 0 ? '→' * strength : '←' * strength;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
          color: t.surface, borderRadius: BorderRadius.circular(14)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('💨', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Text(arrows.isEmpty ? 'calm' : arrows,
              style: TextStyle(
                  color: t.text, fontWeight: FontWeight.w900, fontSize: 18)),
          const SizedBox(width: 8),
          Text('wind $strength',
              style: TextStyle(color: t.muted, fontSize: 13)),
        ],
      ),
    );
  }
}
