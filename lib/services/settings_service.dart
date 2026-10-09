import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../theme/range_themes.dart';

/// Persisted settings + stats for Archery. Survives app restarts.
///
/// Stores: audio toggles, player names (2 slots, human + AI seat), theme /
/// bow / arrow / target choices (incl. custom theme colors), mode setup
/// (vs-bot with difficulty, or 2-player pass-and-play), Pro unlock state,
/// and lifetime stats.
class RangeSettings extends ChangeNotifier {
  static const _kMusic = 'archery_music_on';
  static const _kSfx = 'archery_sfx_on';
  static const _kVolume = 'archery_volume';
  static const _kVsBot = 'archery_vs_bot';
  static const _kDifficulty = 'archery_bot_difficulty'; // 0 easy, 1 med, 2 hard
  static const _kNames = 'archery_player_names'; // legacy unordered StringSet
  /// Order-safe player-name storage: a single JSON string. Android's
  /// SharedPreferences stores StringLists as an unordered StringSet, so a
  /// plain StringList key would scramble name order on every app restart.
  /// Never use a StringList for ordered data on Android.
  static const _kNamesJson = 'archery_player_names_json';
  static const _kTheme = 'archery_theme_id';
  static const _kBow = 'archery_bow_style';
  static const _kArrow = 'archery_arrow_style';
  static const _kTarget = 'archery_target_style';
  static const _kWins = 'archery_wins';
  static const _kGames = 'archery_games_played';
  static const _kBestScore = 'archery_best_score';
  static const _kIsPro = 'archery_is_pro';
  static const _kCustomPrefix = 'archery_custom_';

  static const defaultNames = ['Archer', 'Bow Bot'];

  /// Encode the 2 player names as one JSON string (order-preserving).
  static String encodePlayerNames(List<String> names) => jsonEncode(names);

  static String _cleanName(int i, Object? v) {
    final s = v is String ? v.trim() : '';
    return s.isEmpty ? defaultNames[i] : s;
  }

  /// Decode persisted names; falls back to defaults on missing/corrupt data.
  static List<String> decodePlayerNames(String? raw) {
    if (raw == null) return List.of(defaultNames);
    try {
      final d = jsonDecode(raw);
      if (d is List && d.length == 2) {
        return [for (int i = 0; i < 2; i++) _cleanName(i, d[i])];
      }
    } catch (_) {}
    return List.of(defaultNames);
  }

  bool musicOn = true;
  bool sfxOn = true;
  double volume = 0.8;
  bool vsBot = true; // false = 2-player pass-and-play
  int difficulty = 1; // medium default
  List<String> playerNames = List.of(defaultNames);
  String themeId = 'classic';
  int bowStyle = 0;
  int arrowStyle = 0;
  int targetStyle = 0;
  int wins = 0;
  int gamesPlayed = 0;
  int bestScore = 0; // highest single-game human score (0 = none yet)
  bool isPro = false;

  /// Custom theme colors (ARGB ints). Defaults mirror Classic Range.
  Map<String, int> customColors = Map.of(_defaultCustomColors);

  static const Map<String, int> _defaultCustomColors = {
    'skyTop': 0xFF7FB2D9,
    'skyBottom': 0xFFD9EAF5,
    'sun': 0xFFFFF3C4,
    'grassLight': 0xFF7CB342,
    'grassDark': 0xFF33691E,
    'wood': 0xFF6D4C2F,
    'woodDeep': 0xFF3E2A17,
    'accent': 0xFFB8860B,
    'accentLight': 0xFFE8C66A,
    'accentDark': 0xFF7A5A08,
    'ivory': 0xFFFBF6E9,
    'ink': 0xFF1D1408,
  };

  /// Builds the user-designed custom theme from stored colors.
  RangeThemeDef get customTheme {
    Color c(String k) => Color(customColors[k] ?? 0xFF000000);
    return RangeThemeDef(
      id: 'custom',
      name: 'My Creation',
      skyTop: c('skyTop'),
      skyBottom: c('skyBottom'),
      sun: c('sun'),
      grassLight: c('grassLight'),
      grassDark: c('grassDark'),
      wood: c('wood'),
      woodDeep: c('woodDeep'),
      accent: c('accent'),
      accentLight: c('accentLight'),
      accentDark: c('accentDark'),
      ivory: c('ivory'),
      ink: c('ink'),
      playerColors: const [Color(0xFFB71C1C), Color(0xFF1565C0)],
    );
  }

  SharedPreferences? _prefs;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final p = _prefs!;
    musicOn = p.getBool(_kMusic) ?? true;
    sfxOn = p.getBool(_kSfx) ?? true;
    volume = p.getDouble(_kVolume) ?? 0.8;
    vsBot = p.getBool(_kVsBot) ?? true;
    difficulty = (p.getInt(_kDifficulty) ?? 1).clamp(0, 2);
    // Player names: prefer the order-safe JSON key. Fall back to the legacy
    // StringList key once (one-time migration); it may already be scrambled
    // on Android, which is exactly the bug this replaces.
    final namesRaw = p.getString(_kNamesJson);
    if (namesRaw != null) {
      playerNames = decodePlayerNames(namesRaw);
    } else {
      final legacy = p.getStringList(_kNames);
      playerNames = (legacy != null && legacy.length == 2)
          ? [for (int i = 0; i < 2; i++) _cleanName(i, legacy[i])]
          : List.of(defaultNames);
    }
    themeId = p.getString(_kTheme) ?? 'classic';
    bowStyle = (p.getInt(_kBow) ?? 0).clamp(0, BowStyles.all.length - 1);
    arrowStyle =
        (p.getInt(_kArrow) ?? 0).clamp(0, ArrowStyles.all.length - 1);
    targetStyle =
        (p.getInt(_kTarget) ?? 0).clamp(0, TargetStyles.all.length - 1);
    wins = p.getInt(_kWins) ?? 0;
    gamesPlayed = p.getInt(_kGames) ?? 0;
    bestScore = p.getInt(_kBestScore) ?? 0;
    isPro = p.getBool(_kIsPro) ?? false;
    for (final k in _defaultCustomColors.keys) {
      customColors[k] =
          p.getInt('$_kCustomPrefix$k') ?? _defaultCustomColors[k]!;
    }
    _enforceFreeLimits(silent: true);
    notifyListeners();
  }

  Future<void> _save() async {
    final p = _prefs;
    if (p == null) return;
    await p.setBool(_kMusic, musicOn);
    await p.setBool(_kSfx, sfxOn);
    await p.setDouble(_kVolume, volume);
    await p.setBool(_kVsBot, vsBot);
    await p.setInt(_kDifficulty, difficulty);
    await p.setString(_kNamesJson, encodePlayerNames(playerNames));
    await p.remove(_kNames); // drop the legacy unordered key for good
    await p.setString(_kTheme, themeId);
    await p.setInt(_kBow, bowStyle);
    await p.setInt(_kArrow, arrowStyle);
    await p.setInt(_kTarget, targetStyle);
    await p.setInt(_kWins, wins);
    await p.setInt(_kGames, gamesPlayed);
    await p.setInt(_kBestScore, bestScore);
    await p.setBool(_kIsPro, isPro);
    for (final e in customColors.entries) {
      await p.setInt('$_kCustomPrefix${e.key}', e.value);
    }
  }

  /// Free-tier limits: clamp pro-only choices back when not Pro.
  /// Called after load and whenever Pro status could have changed.
  void _enforceFreeLimits({bool silent = false}) {
    if (isPro) return;
    var changed = false;
    if (themeId == 'custom' || RangeThemes.isProTheme(themeId)) {
      themeId = 'classic';
      changed = true;
    }
    if (BowStyles.isPro(bowStyle)) {
      bowStyle = 0;
      changed = true;
    }
    if (ArrowStyles.isPro(arrowStyle)) {
      arrowStyle = 0;
      changed = true;
    }
    if (TargetStyles.isPro(targetStyle)) {
      targetStyle = 0;
      changed = true;
    }
    if (difficulty > 1) {
      difficulty = 1;
      changed = true;
    }
    if (changed && !silent) {
      notifyListeners();
      _save();
    }
  }

  Future<void> setPro(bool v) async {
    isPro = v;
    if (!v) _enforceFreeLimits();
    notifyListeners();
    await _save();
  }

  Future<void> setCustomColor(String key, int argb) async {
    if (!isPro) return; // custom theme creator is a Pro feature
    if (!_defaultCustomColors.containsKey(key)) return;
    customColors[key] = argb;
    notifyListeners();
    await _save();
  }

  Future<void> resetCustomColors() async {
    customColors = Map.of(_defaultCustomColors);
    notifyListeners();
    await _save();
  }

  Future<void> setMusic(bool v) async {
    musicOn = v;
    notifyListeners();
    await _save();
  }

  Future<void> setSfx(bool v) async {
    sfxOn = v;
    notifyListeners();
    await _save();
  }

  Future<void> setVolume(double v) async {
    volume = v.clamp(0.0, 1.0);
    notifyListeners();
    await _save();
  }

  Future<void> setMode({required bool vsBot, required int difficulty}) async {
    this.vsBot = vsBot;
    this.difficulty = difficulty.clamp(0, 2);
    // Hard mode is a Pro feature.
    if (!isPro && this.difficulty > 1) this.difficulty = 1;
    notifyListeners();
    await _save();
  }

  Future<void> setPlayerName(int index, String name) async {
    if (index < 0 || index > 1) return;
    final clean = name.trim();
    playerNames[index] = clean.isEmpty ? defaultNames[index] : clean;
    notifyListeners();
    await _save();
  }

  Future<void> setTheme(String id) async {
    if (!isPro && (id == 'custom' || RangeThemes.isProTheme(id))) return;
    themeId = id;
    notifyListeners();
    await _save();
  }

  Future<void> setBowStyle(int v) async {
    v = v.clamp(0, BowStyles.all.length - 1);
    if (!isPro && BowStyles.isPro(v)) return;
    bowStyle = v;
    notifyListeners();
    await _save();
  }

  Future<void> setArrowStyle(int v) async {
    v = v.clamp(0, ArrowStyles.all.length - 1);
    if (!isPro && ArrowStyles.isPro(v)) return;
    arrowStyle = v;
    notifyListeners();
    await _save();
  }

  Future<void> setTargetStyle(int v) async {
    v = v.clamp(0, TargetStyles.all.length - 1);
    if (!isPro && TargetStyles.isPro(v)) return;
    targetStyle = v;
    notifyListeners();
    await _save();
  }

  /// Record a finished game. [humanScore] is the human's final score;
  /// [humanWon] true if a human player won outright.
  Future<void> recordGame(
      {required bool humanWon, required int humanScore}) async {
    gamesPlayed++;
    if (humanWon) wins++;
    if (humanScore > bestScore) bestScore = humanScore;
    notifyListeners();
    await _save();
  }
}
