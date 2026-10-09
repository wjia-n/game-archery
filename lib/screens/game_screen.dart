import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import '../engine/archery_engine.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/range_art.dart';
import '../theme/range_themes.dart';

/// Archery game screen — renders the engine's state.
///
/// The engine owns ALL turn phases and settles every shot on its own
/// timers; this screen only paints. Every side has its own score strip:
/// the active side highlights, the bot's aim drifts visibly into place
/// with narration, and every arrow flight animates. Nothing is silently
/// auto-played.
class GameScreen extends StatefulWidget {
  final ArcheryEngine engine;
  final RangeAudio audio;
  final RangeSettings settings;

  const GameScreen({
    super.key,
    required this.engine,
    required this.audio,
    required this.settings,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  ArcheryEngine get _e => widget.engine;
  RangeThemeDef get _t => RangeThemes.byId(
        widget.settings.themeId,
        custom: widget.settings.customTheme,
      );

  /// Per-frame repaint driver. The engine's [FlightAnim] and [BotAim]
  /// interpolate against the clock, but the engine only notifies at phase
  /// boundaries — without this ticker the arrow flight and the bot's aim
  /// run-up would render frozen and jump. The ticker only runs during the
  /// animated phases.
  late final Ticker _anim;
  bool _animRunning = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _anim = createTicker((_) {
      if (mounted) setState(() {});
    });
    _e.onEvent = _onEngineEvent;
    widget.audio.startGameMusic();
    widget.audio.gameStart();
    _e.addListener(_onEngineChanged);
    _syncAnim();
  }

  void _syncAnim() {
    final want = _e.phase == Phase.flying || _e.phase == Phase.botAiming;
    if (want != _animRunning && mounted) {
      _animRunning = want;
      if (want) {
        _anim.start();
      } else {
        _anim.stop();
      }
    }
  }

  void _onEngineEvent(ArcheryEvent event) {
    final a = widget.audio;
    switch (event) {
      case ArcheryEvent.aimLoosed:
        a.bowstring();
      case ArcheryEvent.arrowFlying:
        a.whoosh();
      case ArcheryEvent.arrowHit:
        a.thud();
      case ArcheryEvent.bullseye:
        a.bullseye();
      case ArcheryEvent.miss:
        a.miss();
      case ArcheryEvent.invalid:
        a.invalid();
      case ArcheryEvent.gameStart:
        a.gameStart();
      case ArcheryEvent.humanWon:
        a.win();
      case ArcheryEvent.botWon:
        a.lose();
    }
  }

  bool _reviewAsked = false;

  void _onEngineChanged() {
    _syncAnim();
    if (_e.over && !_reviewAsked) {
      _reviewAsked = true;
      final s = widget.settings;
      final humanScore = _humanBestScore();
      s.recordGame(
        humanWon: _e.winner != null && !_e.players[_e.winner!].isBot,
        humanScore: humanScore,
      );
      // Sensible in-app-review moment: a finished match, a few games in,
      // and only when the human did well. Graceful when not from Play.
      if (s.gamesPlayed >= 3 && humanScore >= 60) {
        _requestReview();
      }
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted) _showGameOver();
      });
    }
  }

  int _humanBestScore() {
    var best = 0;
    for (int i = 0; i < _e.n; i++) {
      if (!_e.players[i].isBot) best = best > _e.scores[i] ? best : _e.scores[i];
    }
    return best;
  }

  Future<void> _requestReview() async {
    final review = InAppReview.instance;
    try {
      if (await review.isAvailable()) {
        await review.requestReview();
      }
    } catch (_) {
      // Review UI unavailable on this device/build: stay silent, no fake UI.
    }
  }

  void _showGameOver() {
    final t = _t;
    final winner = _e.winner;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [t.wood, t.woodDeep],
            ),
            border: Border.all(color: t.accent, width: 3),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🏁 Match Over', style: Range.display(30, theme: t)),
              const SizedBox(height: 12),
              Text(
                winner == null
                    ? "It's a dead heat! 🤝"
                    : '${_e.players[winner].name} takes the gold! 🏆',
                style: Range.body(18, theme: t),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              for (int i = 0; i < _e.n; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _e.players[i].color,
                          border: Border.all(color: t.ivory, width: 1.5),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${_e.players[i].name}: ${_e.scores[i]}',
                          style: Range.label(17, theme: t)),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              RangeButton(
                label: '🔁  Rematch',
                theme: t,
                width: 220,
                onTap: () {
                  widget.audio.click();
                  Navigator.of(context).pop();
                  _e.restart();
                },
              ),
              const SizedBox(height: 10),
              RangeButton(
                label: '📤  Share',
                theme: t,
                width: 220,
                fontSize: 17,
                onTap: () async {
                  widget.audio.click();
                  final myScore = winner == null
                      ? _e.scores[0]
                      : _e.scores[winner];
                  // ignore: deprecated_member_use
                  await Share.share(
                      'I scored $myScore points in Archery! Can you beat me? https://play.google.com/store/apps/details?id=com.gameswajiha.archery');
                },
              ),
              const SizedBox(height: 10),
              RangeButton(
                label: '🏠  Menu',
                theme: t,
                width: 220,
                fontSize: 17,
                onTap: () {
                  widget.audio.click();
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _pause() {
    final t = _t;
    _e.setPaused(true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [t.wood, t.woodDeep],
            ),
            border: Border.all(color: t.accent, width: 3),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('⏸ Paused', style: Range.display(30, theme: t)),
              const SizedBox(height: 18),
              RangeButton(
                label: '▶  Resume',
                theme: t,
                width: 220,
                onTap: () {
                  widget.audio.click();
                  Navigator.of(context).pop();
                  _e.setPaused(false);
                },
              ),
              const SizedBox(height: 10),
              RangeButton(
                label: '🔁  Restart',
                theme: t,
                width: 220,
                fontSize: 17,
                onTap: () {
                  widget.audio.click();
                  Navigator.of(context).pop();
                  _e.setPaused(false);
                  _e.restart();
                },
              ),
              const SizedBox(height: 10),
              RangeButton(
                label: '🏠  Quit',
                theme: t,
                width: 220,
                fontSize: 17,
                onTap: () {
                  widget.audio.click();
                  _e.setPaused(false);
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && !_e.over) {
      _e.setPaused(true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _anim.dispose();
    _e.removeListener(_onEngineChanged);
    _e.onEvent = null;
    _e.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    return RangeBackdrop(
      theme: t,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: t.ivory),
            onPressed: () {
              widget.audio.click();
              Navigator.of(context).pop();
            },
          ),
          title: Text('Archery', style: Range.display(22, theme: t)),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.pause, color: t.ivory),
              onPressed: () {
                widget.audio.click();
                if (!_e.over) _pause();
              },
            ),
          ],
        ),
        body: SafeArea(
          child: ListenableBuilder(
            listenable: _e,
            builder: (_, _) {
              if (_e.over) return _buildOver();
              return Column(
                children: [
                  _PlayerStrips(t),
                  _windRow(t),
                  Expanded(child: _RangeArea(t)),
                  _narration(t),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildOver() => const SizedBox.shrink();

  Widget _PlayerStrips(RangeThemeDef t) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(child: _PlayerStrip(t, 0)),
          const SizedBox(width: 10),
          Expanded(child: _PlayerStrip(t, 1)),
        ],
      ),
    );
  }

  Widget _PlayerStrip(RangeThemeDef t, int i) {
    final p = _e.players[i];
    final active = _e.turn == i && !_e.over;
    final arrowsLeft = ArcheryEngine.shotsPerPlayer - _e.shotsFired[i];
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: active
            ? t.accent.withValues(alpha: 0.28)
            : t.woodDeep.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active ? t.accentLight : t.accent.withValues(alpha: 0.35),
          width: active ? 2.5 : 1.5,
        ),
        boxShadow: active
            ? [
                BoxShadow(
                    color: t.accentLight.withValues(alpha: 0.35),
                    blurRadius: 10,
                    spreadRadius: 1)
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: p.color,
                  border: Border.all(color: t.ivory, width: 1.5),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  p.name,
                  style: Range.label(14, theme: t),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (p.isBot)
                Text('🤖', style: TextStyle(fontSize: 14, color: t.ivory)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text('Score ${_e.scores[i]}',
                  style: Range.body(14, theme: t)),
              const Spacer(),
              // Arrow quiver: remaining arrows as small marks.
              Text('🏹×$arrowsLeft', style: Range.body(13, theme: t)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _windRow(RangeThemeDef t) {
    final strength = _e.wind.abs().round().clamp(0, 5);
    final arrows = _e.wind >= 0 ? '→' * strength : '←' * strength;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: t.woodDeep.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.accent.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('💨', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Text(arrows.isEmpty ? 'calm' : arrows,
              style: Range.label(18, theme: t)),
          const SizedBox(width: 8),
          Text('wind $strength  •  ${_e.distLabel}',
              style: Range.body(13, theme: t)),
        ],
      ),
    );
  }

  Widget _RangeArea(RangeThemeDef t) {
    return LayoutBuilder(builder: (ctx, box) {
      final size = box.biggest;
      final center = Offset(size.width / 2, size.height * 0.36);
      final radius = (size.width * 0.40).clamp(90.0, size.height * 0.30) *
          _e.targetScale;
      return GestureDetector(
        onPanStart: _e.canAim
            ? (d) => _e.setReticle((d.localPosition - center) / radius)
            : null,
        onPanUpdate: _e.canAim
            ? (d) => _e.setReticle((d.localPosition - center) / radius)
            : null,
        onPanEnd: _e.canAim ? (_) => _e.loose() : null,
        child: CustomPaint(
          size: size,
          painter: _RangePainter(
            theme: t,
            engine: _e,
            bow: BowStyles.all[widget.settings.bowStyle],
            arrow: ArrowStyles.all[widget.settings.arrowStyle],
            target: TargetStyles.all[widget.settings.targetStyle],
            center: center,
            radius: radius,
          ),
        ),
      );
    });
  }

  Widget _narration(RangeThemeDef t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: Text(
          _e.banner,
          key: ValueKey(_e.banner),
          style: Range.body(16, theme: t),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _RangePainter extends CustomPainter {
  final RangeThemeDef theme;
  final ArcheryEngine engine;
  final BowStyle bow;
  final ArrowStyle arrow;
  final TargetStyle target;
  final Offset center;
  final double radius;

  _RangePainter({
    required this.theme,
    required this.engine,
    required this.bow,
    required this.arrow,
    required this.target,
    required this.center,
    required this.radius,
  });

  Offset _toPx(Offset normalized) => center + normalized * radius;

  @override
  void paint(Canvas canvas, Size size) {
    _drawStand(canvas, size);
    _drawTarget(canvas);
    _drawStuckArrows(canvas);
    _drawBow(canvas, size);
    _drawAimReticle(canvas);
    _drawFlight(canvas, size);
  }

  void _drawStand(Canvas canvas, Size size) {
    // Wooden tripod legs under the target.
    final legPaint = Paint()
      ..color = theme.wood
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    final groundY = size.height * 0.72;
    canvas.drawLine(
        center + Offset(-radius * 0.45, radius * 0.6),
        Offset(center.dx - radius * 0.75, groundY),
        legPaint);
    canvas.drawLine(
        center + Offset(radius * 0.45, radius * 0.6),
        Offset(center.dx + radius * 0.75, groundY),
        legPaint);
    // Shadow.
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(center.dx, groundY + 6),
          width: radius * 1.8,
          height: 18),
      Paint()..color = Colors.black.withValues(alpha: 0.25),
    );
    // Frame ring around the target face.
    canvas.drawCircle(
      center,
      radius * 1.04,
      Paint()..color = theme.woodDeep,
    );
    canvas.drawCircle(
      center,
      radius * 1.0,
      Paint()..color = theme.wood,
    );
  }

  void _drawTarget(Canvas canvas) {
    // Rings: outer (score 1) .. inner (score 10).
    for (int i = 0; i < 10; i++) {
      final r = radius * (10 - i) / 10;
      canvas.drawCircle(center, r, Paint()..color = target.rings[i]);
    }
    // Thin separators + outer shadow ring.
    final sep = Paint()
      ..color = theme.ink.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (int i = 0; i < 10; i++) {
      canvas.drawCircle(center, radius * (10 - i) / 10, sep);
    }
  }

  void _drawStuckArrows(Canvas canvas) {
    // Every landed arrow sticks in the target, newest last (on top).
    for (int p = 0; p < 2; p++) {
      for (int k = 0; k < engine.landings[p].length; k++) {
        final last = p == engine.lastLandingPlayer &&
            k == engine.landings[p].length - 1 &&
            engine.phase == Phase.settling;
        _drawArrow(
          canvas,
          _toPx(engine.landings[p][k]),
          -0.6,
          arrow,
          scale: last ? 1.12 : 0.85,
        );
      }
    }
  }

  void _drawBow(Canvas canvas, Size size) {
    // Hand-drawn wooden bow at the bottom, in the chosen bow style.
    final bowBase = Offset(size.width / 2, size.height - 26);
    final limbPaint = Paint()
      ..color = bow.limb
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: bowBase + const Offset(0, -38), radius: 38),
      -1.25,
      2.5,
      false,
      limbPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: bowBase + const Offset(0, -38), radius: 38),
      -1.25,
      2.5,
      false,
      Paint()
        ..color = bow.limbDark
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
    // String.
    canvas.drawLine(
      bowBase + const Offset(-17, -64),
      bowBase + const Offset(17, -12),
      Paint()
        ..color = theme.ivory.withValues(alpha: 0.9)
        ..strokeWidth = 2,
    );
    // Leather grip.
    canvas.drawLine(
      bowBase + const Offset(2, -52),
      bowBase + const Offset(-2, -26),
      Paint()
        ..color = bow.grip
        ..strokeWidth = 11
        ..strokeCap = StrokeCap.round,
    );
    // Nocked arrow when the human is aiming.
    if (engine.canAim) {
      _drawArrow(
        canvas,
        bowBase + const Offset(0, -40),
        -pi / 2.6,
        arrow,
        scale: 1.0,
      );
    }
  }

  void _drawAimReticle(Canvas canvas) {
    Offset? show;
    if (engine.phase == Phase.awaitingAim &&
        !engine.current.isBot &&
        !engine.over) {
      show = _toPx(engine.reticle);
    } else if (engine.phase == Phase.botAiming && engine.botAim != null) {
      final b = engine.botAim!;
      final e = b.progress;
      final eased = 1 - (1 - e) * (1 - e);
      show = _toPx(
          Offset(b.from.dx + (b.to.dx - b.from.dx) * eased,
              b.from.dy + (b.to.dy - b.from.dy) * eased));
    }
    if (show == null) return;
    final rp = Paint()
      ..color = engine.current.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(show, 15, rp);
    canvas.drawLine(show + const Offset(-24, 0), show + const Offset(24, 0), rp);
    canvas.drawLine(show + const Offset(0, -24), show + const Offset(0, 24), rp);
    canvas.drawCircle(
        show, 3, Paint()..color = engine.current.color);
  }

  void _drawFlight(Canvas canvas, Size size) {
    final f = engine.flightAnim;
    if (f == null) return;
    final from = Offset(size.width / 2, size.height - 66);
    final to = _toPx(f.to);
    final p = f.progress;
    final pos = Offset(
      from.dx + (to.dx - from.dx) * p,
      from.dy + (to.dy - from.dy) * p - sin(p * pi) * radius * 0.45,
    );
    final dir = (to - from).direction;
    // Motion streak.
    canvas.drawLine(
      pos - Offset(cos(dir), sin(dir)) * 26,
      pos,
      Paint()
        ..color = theme.ivory.withValues(alpha: 0.35 * (1 - p))
        ..strokeWidth = 3,
    );
    _drawArrow(canvas, pos, dir, arrow, scale: 1.0);
  }

  void _drawArrow(
      Canvas canvas, Offset tip, double angle, ArrowStyle style,
      {double scale = 1.0}) {
    canvas.save();
    canvas.translate(tip.dx, tip.dy);
    canvas.rotate(angle);
    final s = scale;
    final shaft = Paint()
      ..color = style.shaft
      ..strokeWidth = 4 * s
      ..strokeCap = StrokeCap.round;
    final fletch = Paint()
      ..color = style.fletch
      ..strokeWidth = 5 * s
      ..strokeCap = StrokeCap.round;
    // Shaft.
    canvas.drawLine(Offset(-46 * s, 0), Offset(-4 * s, 0), shaft);
    // Fletching.
    canvas.drawLine(Offset(-46 * s, 0), Offset(-36 * s, -9 * s), fletch);
    canvas.drawLine(Offset(-46 * s, 0), Offset(-36 * s, 9 * s), fletch);
    // Arrowhead.
    canvas.drawCircle(Offset(2 * s, 0), 4.5 * s, Paint()..color = style.shaft);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RangePainter old) => true;
}
