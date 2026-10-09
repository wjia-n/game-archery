import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Archery engine: deterministic rules, state, bot AI. UI-agnostic.
//
// A match: each player shoots 10 arrows, alternating turns, across 3
// distances (30m / 50m / 70m). Wind pushes the arrow sideways; the shooter
// compensates by aiming INTO the wind. Highest total score wins.
//
// Turn phases are owned entirely by the engine. The UI only renders.
// [awaitingAim] = the current player may aim (human drags the reticle, or
// the bot aims visibly). [botAiming] = the bot's animated aiming run-up:
// its reticle visibly drifts from center to its final aim before it
// looses — never silently auto-played. [flying] = arrow in flight.
// [settling] = brief narration pause between shots. This is what makes
// stuck states impossible by construction.
// ---------------------------------------------------------------------------

/// 0 = easy, 1 = medium, 2 = hard (RULES.md §11).
enum BotDifficulty { easy, medium, hard }

/// Turn phases owned entirely by the engine. The UI only renders.
enum Phase { awaitingAim, botAiming, flying, settling, over }

class ArcheryPlayer {
  String name;
  final Color color;
  final bool isBot;

  ArcheryPlayer(
      {required this.name, required this.color, required this.isBot});
}

/// A visible flight in progress. [to] is the landing point in
/// target-radius units (1.0 = target edge). The UI converts to pixels.
class FlightAnim {
  final Offset to;
  final int totalMs;
  DateTime startedAt;

  FlightAnim({required this.to, required this.totalMs})
      : startedAt = DateTime.now();

  double get progress {
    final e = DateTime.now().difference(startedAt).inMilliseconds;
    return (e / totalMs).clamp(0.0, 1.0);
  }

  int get remainingMs =>
      (totalMs - DateTime.now().difference(startedAt).inMilliseconds)
          .clamp(0, totalMs);
}

/// The bot's visible aiming run-up. The UI interpolates the reticle from
/// [from] to [to] over [totalMs] before the arrow is loosed.
class BotAim {
  final Offset from;
  final Offset to;
  final int totalMs;
  DateTime startedAt;

  BotAim({required this.from, required this.to, required this.totalMs})
      : startedAt = DateTime.now();

  double get progress {
    final e = DateTime.now().difference(startedAt).inMilliseconds;
    return (e / totalMs).clamp(0.0, 1.0);
  }

  int get remainingMs =>
      (totalMs - DateTime.now().difference(startedAt).inMilliseconds)
          .clamp(0, totalMs);
}

class ArcheryEngine extends ChangeNotifier {
  static const shotsPerPlayer = 10;

  // Distance config by shot number: 0-2 = 30m, 3-6 = 50m, 7-9 = 70m.
  static const windFactors = [1.0, 1.6, 2.3];
  static const targetScales = [1.0, 0.82, 0.66];
  static const distLabels = ['30m', '50m', '70m'];
  static const maxAim = 1.15; // reticle clamp, in target-radius units

  final List<ArcheryPlayer> players;
  final BotDifficulty botDifficulty;

  int turn = 0;
  List<int> shotsFired = [0, 0];
  List<int> scores = [0, 0];

  /// All landings per player, in target-radius units (stuck arrows).
  List<List<Offset>> landings = [<Offset>[], <Offset>[]];

  double wind = 0; // -5..5, + pushes right
  Phase phase = Phase.awaitingAim;

  /// Human aim reticle, in target-radius units.
  Offset reticle = Offset.zero;

  FlightAnim? flightAnim;
  BotAim? botAim;

  bool over = false;
  int? winner;

  String banner = '';
  int lastScore = -1;
  String lastNote = '';
  int? lastLandingPlayer; // which player stuck the newest arrow

  /// UI hook for sounds / haptics. Set by the screen.
  void Function(ArcheryEvent event)? onEvent;

  final _rand = Random();
  Timer? _timer; // single phase-transition timer
  Timer? _watchdog; // stuck-state recovery
  bool _disposed = false;
  bool paused = false;
  DateTime? _pausedAt;

  /// Flight state stashed across the animation for _resolveShot.
  bool _lastShotEndedGame = false;

  /// Test hook: when set, the next shot uses this wind. Consumed after use.
  @visibleForTesting
  double? forcedWind;

  ArcheryEngine({required this.players, this.botDifficulty = BotDifficulty.medium}) {
    assert(players.length == 2, 'Archery is a 2-seat game');
    banner = 'Drag to aim, ${players[0].name}!';
    _newWind();
    _watchdog = Timer.periodic(const Duration(seconds: 3), (_) => _recover());
    // If the first player is a bot, kick off their turn.
    _afterPhase();
  }

  int get n => players.length;
  ArcheryPlayer get current => players[turn];

  /// 0-based shot number for the current player, and its distance config.
  int get shotNo => shotsFired[turn];
  int get distIndex => shotNo < 3 ? 0 : (shotNo < 7 ? 1 : 2);
  double get windFactor => windFactors[distIndex];
  double get targetScale => targetScales[distIndex];
  String get distLabel => distLabels[distIndex];
  int get arrowsLeft => shotsPerPlayer - shotsFired[turn];

  bool get canAim => phase == Phase.awaitingAim && !current.isBot && !over;
  bool get botVisible =>
      (phase == Phase.awaitingAim || phase == Phase.botAiming) &&
      current.isBot &&
      !over;

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _watchdog?.cancel();
    super.dispose();
  }

  void _arm(Duration d, void Function() fn) {
    if (_disposed || paused) return;
    _timer?.cancel();
    _timer = Timer(d, () {
      _timer = null;
      if (!_disposed && !paused) fn();
    });
  }

  /// Pause: freeze the phase timer and shift in-flight animations so they
  /// resume exactly where they stopped. Resume re-arms the current phase.
  void setPaused(bool v) {
    if (paused == v || _disposed) return;
    paused = v;
    if (v) {
      _pausedAt = DateTime.now();
      _timer?.cancel();
      _timer = null;
    } else {
      final at = _pausedAt;
      _pausedAt = null;
      if (at != null) {
        final shift = DateTime.now().difference(at);
        if (flightAnim != null) {
          flightAnim!.startedAt = flightAnim!.startedAt.add(shift);
        }
        if (botAim != null) {
          botAim!.startedAt = botAim!.startedAt.add(shift);
        }
      }
      _recover();
    }
    notifyListeners();
  }

  /// Watchdog: if the single phase timer ever dies without progress,
  /// recover. This makes stuck states impossible by construction.
  /// Respects [paused]: a paused game is frozen, not stuck.
  void _recover() {
    if (_disposed || over || paused || _timer != null) return;
    if (phase == Phase.awaitingAim && current.isBot) {
      _startBotAim();
    } else if (phase == Phase.botAiming && botAim != null) {
      final remain = botAim!.remainingMs.clamp(50, botAim!.totalMs);
      _arm(Duration(milliseconds: remain), _botLoose);
    } else if (phase == Phase.botAiming) {
      _startBotAim();
    } else if (phase == Phase.flying && flightAnim != null) {
      final remain = flightAnim!.remainingMs.clamp(50, flightAnim!.totalMs);
      _arm(Duration(milliseconds: remain), _resolveShot);
    } else if (phase == Phase.flying) {
      _resolveShot();
    } else if (phase == Phase.settling) {
      // Settling with no timer (e.g. after backgrounding): advance.
      _advanceTurn();
    }
  }

  void _newWind() {
    wind = forcedWind ?? (_rand.nextDouble() * 2 - 1) * 5;
    forcedWind = null;
  }

  double _gauss() =>
      (_rand.nextDouble() + _rand.nextDouble() + _rand.nextDouble()) / 1.5 - 1;

  // ------------------------------------------------------------- human input
  /// Human drags the reticle. Guarded: correct phase, human turn only.
  void setReticle(Offset normalized) {
    if (!canAim) return;
    reticle = Offset(
      normalized.dx.clamp(-maxAim, maxAim),
      normalized.dy.clamp(-maxAim, maxAim),
    );
    notifyListeners();
  }

  /// Human releases the string (pan end). Guarded like setReticle.
  void loose() {
    if (!canAim) {
      onEvent?.call(ArcheryEvent.invalid);
      return;
    }
    _beginFlight(reticle);
  }

  // ------------------------------------------------------------- bot logic
  /// Called whenever we enter awaitingAim: bots start their visible
  /// aiming run-up; humans just wait for input.
  void _afterPhase() {
    if (over || phase != Phase.awaitingAim) return;
    if (current.isBot) {
      _arm(const Duration(milliseconds: 700), _startBotAim);
    }
  }

  void _startBotAim() {
    if (over || phase != Phase.awaitingAim || !current.isBot) return;
    phase = Phase.botAiming;
    banner = '${current.name} is lining up… 🏹';
    // The bot compensates for wind, imperfectly, per difficulty
    // (RULES.md §11).
    final comp = [0.55, 0.8, 0.95][botDifficulty.index];
    final errScale = [0.42, 0.26, 0.15][botDifficulty.index];
    final driftComp = wind * windFactor * _driftK * comp;
    final err = errScale * (1.0 + distIndex * 0.35);
    final aim = Offset(
      (-driftComp + _gauss() * err).clamp(-maxAim, maxAim),
      (_gauss() * err).clamp(-maxAim, maxAim),
    );
    botAim = BotAim(
      from: reticle,
      to: aim,
      totalMs: 1100,
    );
    reticle = aim; // logical aim lands here; UI interpolates visually
    notifyListeners();
    _arm(const Duration(milliseconds: 1100), _botLoose);
  }

  void _botLoose() {
    if (over || phase != Phase.botAiming || !current.isBot) return;
    _beginFlight(reticle);
  }

  // ---------------------------------------------------------------- flight
  /// Wind drift per unit of (wind * windFactor), in target-radius units.
  /// Calibrated from the original range physics (8px at 130px radius).
  static const _driftK = 0.0615;

  void _beginFlight(Offset aim) {
    if (over || phase == Phase.flying) return;
    botAim = null;
    phase = Phase.flying;
    // Landing = aim + wind drift + wobble.
    final drift = wind * windFactor * _driftK;
    final wobble = Offset(_gauss() * 0.07, _gauss() * 0.07);
    final landing = aim + Offset(drift, 0) + wobble;
    flightAnim = FlightAnim(to: landing, totalMs: 620);
    banner = current.isBot ? '${current.name} looses! 💨' : 'Arrow away! 💨';
    notifyListeners();
    onEvent?.call(ArcheryEvent.aimLoosed);
    onEvent?.call(ArcheryEvent.arrowFlying);
    _arm(const Duration(milliseconds: 620), _resolveShot);
  }

  /// Engine-owned settle — the UI never calls this. No desync possible.
  void _resolveShot() {
    if (over || phase != Phase.flying || flightAnim == null) return;
    final landing = flightAnim!.to;
    flightAnim = null;

    final d = landing.distance;
    int score;
    String note;
    ArcheryEvent sfx;
    if (d > 1.0) {
      score = 0;
      note = 'Miss! The wind laughed. 💨';
      sfx = ArcheryEvent.miss;
    } else {
      score = (10 - (d * 10).floor()).clamp(1, 10);
      note = switch (score) {
        10 => 'BULLSEYE! 🎯🔥',
        >= 8 => '+$score — superb shot! 🏹',
        >= 5 => '+$score — solid!',
        _ => '+$score — on the board.',
      };
      sfx = score == 10 ? ArcheryEvent.bullseye : ArcheryEvent.arrowHit;
    }
    scores[turn] += score;
    shotsFired[turn]++;
    landings[turn] = [...landings[turn], landing];
    lastLandingPlayer = turn;
    lastScore = score;
    lastNote = note;
    phase = Phase.settling;
    notifyListeners();
    onEvent?.call(sfx);

    _lastShotEndedGame =
        shotsFired.every((f) => f >= shotsPerPlayer);
    _arm(const Duration(milliseconds: 1250), _advanceTurn);
  }

  void _advanceTurn() {
    if (over) return;
    if (_lastShotEndedGame) {
      _finish();
      return;
    }
    turn = (turn + 1) % n;
    phase = Phase.awaitingAim;
    reticle = Offset.zero;
    lastScore = -1;
    _newWind();
    banner = current.isBot
        ? '${current.name} is up…'
        : 'Drag to aim, ${current.name}!';
    notifyListeners();
    _afterPhase();
  }

  void _finish() {
    over = true;
    phase = Phase.over;
    flightAnim = null;
    botAim = null;
    final s0 = scores[0];
    final s1 = scores[1];
    if (s0 == s1) {
      winner = null;
      banner = "It's a dead heat! 🤝";
    } else {
      winner = s0 > s1 ? 0 : 1;
      banner = '${players[winner!].name} takes the gold! 🏆';
    }
    notifyListeners();
    if (winner != null) {
      onEvent?.call(players[winner!].isBot
          ? ArcheryEvent.botWon
          : ArcheryEvent.humanWon);
    }
  }

  void restart() {
    _timer?.cancel();
    paused = false;
    _pausedAt = null;
    turn = 0;
    shotsFired = [0, 0];
    scores = [0, 0];
    landings = [<Offset>[], <Offset>[]];
    phase = Phase.awaitingAim;
    reticle = Offset.zero;
    flightAnim = null;
    botAim = null;
    over = false;
    winner = null;
    lastScore = -1;
    lastNote = '';
    lastLandingPlayer = null;
    _lastShotEndedGame = false;
    _newWind();
    banner = current.isBot ? '${current.name} is up…' : 'Drag to aim, ${players[0].name}!';
    notifyListeners();
    onEvent?.call(ArcheryEvent.gameStart);
    _afterPhase();
  }
}

enum ArcheryEvent {
  aimLoosed, // bowstring twang
  arrowFlying, // whoosh
  arrowHit, // thud
  bullseye, // chime
  miss,
  invalid,
  gameStart,
  humanWon,
  botWon,
}
