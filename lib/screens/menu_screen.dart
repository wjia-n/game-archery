import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import '../engine/archery_engine.dart';
import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/range_art.dart';
import '../theme/range_themes.dart';
import 'custom_theme_screen.dart';
import 'game_screen.dart';
import 'pro_screen.dart';
import 'settings_screen.dart';

/// Main menu — Range Craft edition.
/// Logo, PLAY, mode setup (vs bot with 3 difficulties / 2-player
/// pass-and-play), range theme picker, bow/arrow/target style pickers,
/// player renaming, tip jar, settings.
class MenuScreen extends StatefulWidget {
  final RangeAudio audio;
  final RangeSettings settings;

  const MenuScreen({super.key, required this.audio, required this.settings});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final StoreService _store = StoreService();

  RangeSettings get _s => widget.settings;
  RangeThemeDef get _t => RangeThemes.byId(_s.themeId, custom: _s.customTheme);

  @override
  void initState() {
    super.initState();
    widget.audio.startMenuMusic();
    _store.init().then((_) {
      if (mounted) setState(() {});
    });
    _store.lastThanks.addListener(_onThanks);
  }

  void _onThanks() {
    final msg = _store.lastThanks.value;
    if (msg == null || !mounted) return;
    widget.audio.win();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: Range.body(15, theme: _t)),
        backgroundColor: _t.woodDeep,
        behavior: SnackBarBehavior.floating,
      ),
    );
    _store.lastThanks.value = null;
  }

  
  @override
  void dispose() {
    _store.lastThanks.removeListener(_onThanks);
    _store.dispose();
    super.dispose();
  }

  /// Real in-app review flow: the Play in-app review sheet when available,
  /// otherwise fall back to opening the store listing. No fake dialogs.
  Future<void> _requestReview() async {
    final review = InAppReview.instance;
    try {
      if (await review.isAvailable()) {
        await review.requestReview();
      } else {
        await review.openStoreListing(appStoreId: null);
      }
    } catch (_) {
      // Review UI unavailable on this device/build: stay silent, no fake UI.
    }
  }

  void _play() {
    widget.audio.gameStart();
    final t = _t;
    final players = [
      ArcheryPlayer(
        name: _s.playerNames[0],
        color: t.playerColors[0],
        isBot: false,
      ),
      ArcheryPlayer(
        name: _s.playerNames[1],
        color: t.playerColors[1],
        isBot: _s.vsBot,
      ),
    ];
    final engine = ArcheryEngine(
      players: players,
      botDifficulty: BotDifficulty.values[_s.difficulty],
    );
    // App-scoped music: keep playing across screens. GameScreen switches
    // to the game track on entry; we switch back to menu music on return.
    Navigator.of(context)
        .push(MaterialPageRoute(
      builder: (_) => GameScreen(
        engine: engine,
        audio: widget.audio,
        settings: _s,
      ),
    ))
        .then((_) {
      if (mounted) widget.audio.startMenuMusic();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    return RangeBackdrop(
      theme: t,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ListenableBuilder(
            listenable: _s,
            builder: (_, _) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  // Logo plaque.
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: t.accent, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.6),
                          offset: const Offset(0, 8),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset('assets/archery_logo.png',
                        fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 14),
                  Text('Archery', style: Range.display(46, theme: t)),
                  Text(
                    'READ THE WIND • SPLIT THE GOLD',
                    style: Range.label(12, theme: t),
                  ),
                  const SizedBox(height: 22),
                  RangeButton(
                      label: '🏹  Play', onTap: _play, theme: t, width: 260),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      widget.audio.click();
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => ProScreen(
                          audio: widget.audio,
                          settings: _s,
                          store: _store,
                        ),
                      ));
                    },
                    child: Container(
                      width: 260,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: LinearGradient(colors: [
                          t.accent.withValues(alpha: 0.9),
                          t.accentDark,
                        ]),
                        border:
                            Border.all(color: t.accentLight, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            offset: const Offset(0, 4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '☕  Tip Jar',
                        style: Range.label(17, theme: t, color: t.ink),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  _ModeCard(theme: t),
                  const SizedBox(height: 14),
                  _ThemeCard(theme: t),
                  const SizedBox(height: 14),
                  _StylesCard(theme: t),
                  const SizedBox(height: 14),
                  _NamesCard(theme: t),
                  const SizedBox(height: 14),
                  _SupportCard(theme: t, store: _store),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _MenuIcon(
                        theme: t,
                        icon: Icons.share,
                        label: 'Share',
                        onTap: () async {
                          widget.audio.click();
                          // ignore: deprecated_member_use
                          await Share.share(
                              'Play Archery with me! https://play.google.com/store/apps/details?id=com.gameswajiha.archery');
                        },
                      ),
                      const SizedBox(width: 22),
                      _MenuIcon(
                        theme: t,
                        icon: Icons.star_rate,
                        label: 'Rate',
                        onTap: () async {
                          widget.audio.click();
                          await _requestReview();
                        },
                      ),
                      const SizedBox(width: 22),
                      _MenuIcon(
                        theme: t,
                        icon: Icons.settings,
                        label: 'Settings',
                        onTap: () async {
                          widget.audio.click();
                          await Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => SettingsScreen(
                              audio: widget.audio,
                              settings: _s,
                            ),
                          ));
                          if (mounted) setState(() {});
                        },
                      ),
                      const SizedBox(width: 26),
                      _MenuIcon(
                        theme: t,
                        icon: Icons.help_outline,
                        label: 'How to Play',
                        onTap: () {
                          widget.audio.click();
                          _showHowTo(context, t);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (_s.gamesPlayed > 0)
                    Text(
                      'Wins: ${_s.wins}   •   Games: ${_s.gamesPlayed}${_s.bestScore > 0 ? '   •   Best: ${_s.bestScore} pts' : ''}',
                      style: Range.label(12, theme: t),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/wajiha_logo.png',
                          width: 22, height: 22, fit: BoxFit.contain),
                      const SizedBox(width: 8),
                      Text('Credits: WAJIHA',
                          style: Range.label(12, theme: t)),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showHowTo(BuildContext context, RangeThemeDef t) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [t.wood, t.woodDeep],
            ),
            border: Border.all(color: t.accent, width: 2.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('How to Play', style: Range.display(24, theme: t)),
              const SizedBox(height: 12),
              Text(
                '• Drag anywhere on the target to move your aim reticle.\n'
                '• Release to loose your arrow — watch the wind! 💨\n'
                '• Aim INTO the wind: it pushes your arrow sideways.\n'
                '• 10 arrows each across 3 distances (30m / 50m / 70m).\n'
                '• Rings score 1–10 from the outside in; gold is 9–10.\n'
                '• Highest total score wins the match! 🏆\n\n'
                'Solo? Pick a bot difficulty — the bot aims visibly, '
                'no secret auto-play.',
                style: Range.body(15, theme: t),
              ),
              const SizedBox(height: 16),
              Center(
                child: RangeButton(
                  label: 'Got it!',
                  theme: t,
                  width: 180,
                  onTap: () {
                    widget.audio.click();
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuIcon extends StatelessWidget {
  final RangeThemeDef theme;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MenuIcon(
      {required this.theme,
      required this.icon,
      required this.label,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [t.wood, t.woodDeep],
              ),
              border: Border.all(color: t.accent, width: 2),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    offset: const Offset(0, 4),
                    blurRadius: 8),
              ],
            ),
            child: Icon(icon, color: t.accentLight, size: 26),
          ),
          const SizedBox(height: 6),
          Text(label, style: Range.label(11, theme: t)),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final RangeThemeDef theme;
  const _ModeCard({required this.theme});

  @override
  Widget build(BuildContext context) {
    // Reach the state + settings through the ancestor.
    final state = context.findAncestorStateOfType<_MenuScreenState>()!;
    final s = state._s;
    final t = theme;
    const diffNames = ['Easy 🌿', 'Medium 🎯', 'Hard 🔥'];
    return RangeCard(
      title: 'Game Mode',
      theme: t,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _ModeChip(
                  label: '🤖  Vs Bot',
                  selected: s.vsBot,
                  theme: t,
                  onTap: () {
                    state.widget.audio.click();
                    s.setMode(vsBot: true, difficulty: s.difficulty);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ModeChip(
                  label: '👥  2 Players',
                  selected: !s.vsBot,
                  theme: t,
                  onTap: () {
                    state.widget.audio.click();
                    s.setMode(vsBot: false, difficulty: s.difficulty);
                  },
                ),
              ),
            ],
          ),
          if (s.vsBot) ...[
            const SizedBox(height: 12),
            Text('Bot difficulty', style: Range.body(14, theme: t)),
            const SizedBox(height: 8),
            Row(
              children: [
                for (int i = 0; i < 3; i++)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: i < 2 ? 8 : 0),
                      child: _DiffChip(
                        label: diffNames[i],
                        selected: s.difficulty == i,
                        locked: i == 2 && !s.isPro,
                        theme: t,
                        onTap: () {
                          if (i == 2 && !s.isPro) {
                            _goPro(context, state);
                            return;
                          }
                          state.widget.audio.click();
                          s.setMode(vsBot: true, difficulty: i);
                        },
                      ),
                    ),
                  ),
              ],
            ),
            if (!s.isPro)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('🔥 Hard mode is PRO',
                    style: Range.body(12,
                        theme: t,
                        color: t.accentLight.withValues(alpha: 0.8))),
              ),
          ],
        ],
      ),
    );
  }

  Future<void> _goPro(BuildContext context, _MenuScreenState state) async {
    state.widget.audio.click();
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ProScreen(
        audio: state.widget.audio,
        settings: state._s,
        store: state._store,
      ),
    ));
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final RangeThemeDef theme;
  final VoidCallback onTap;
  const _ModeChip(
      {required this.label,
      required this.selected,
      required this.theme,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: selected
              ? LinearGradient(colors: [t.accent, t.accentDark])
              : null,
          color: selected ? null : t.woodDeep.withValues(alpha: 0.5),
          border: Border.all(
              color: selected ? t.accentLight : t.accent.withValues(alpha: 0.4),
              width: 2),
        ),
        alignment: Alignment.center,
        child: Text(label,
            style: Range.label(15,
                theme: t, color: selected ? t.ink : t.ivory)),
      ),
    );
  }
}

class _DiffChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool locked;
  final RangeThemeDef theme;
  final VoidCallback onTap;
  const _DiffChip(
      {required this.label,
      required this.selected,
      required this.locked,
      required this.theme,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient:
              selected ? LinearGradient(colors: [t.accent, t.accentDark]) : null,
          color: selected ? null : t.woodDeep.withValues(alpha: 0.5),
          border: Border.all(
              color: selected ? t.accentLight : t.accent.withValues(alpha: 0.4),
              width: 2),
        ),
        alignment: Alignment.center,
        child: Text(
          locked ? '🔒 $label' : label,
          style: Range.label(13,
              theme: t,
              color: selected
                  ? t.ink
                  : t.ivory.withValues(alpha: locked ? 0.55 : 1.0)),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final RangeThemeDef theme;
  const _ThemeCard({required this.theme});

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_MenuScreenState>()!;
    final s = state._s;
    final t = theme;
    return RangeCard(
      title: 'Range Theme',
      theme: t,
      child: Column(
        children: [
          SizedBox(
            height: 86,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: RangeThemes.all.length + 1, // + custom creator
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                if (i == RangeThemes.all.length) {
                  return _ThemeTile(
                    name: 'My Creation',
                    colors: [
                      Color(s.customColors['grassLight']!),
                      Color(s.customColors['skyTop']!),
                      Color(s.customColors['accent']!),
                    ],
                    selected: s.themeId == 'custom',
                    locked: !s.isPro,
                    theme: t,
                    onTap: () async {
                      if (!s.isPro) {
                        state.widget.audio.click();
                        await Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => ProScreen(
                            audio: state.widget.audio,
                            settings: s,
                            store: state._store,
                          ),
                        ));
                        return;
                      }
                      state.widget.audio.click();
                      await Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => CustomThemeScreen(
                          audio: state.widget.audio,
                          settings: s,
                        ),
                      ));
                      if (context.mounted) s.setTheme('custom');
                    },
                  );
                }
                final th = RangeThemes.all[i];
                return _ThemeTile(
                  name: th.name,
                  colors: [th.grassLight, th.skyTop, th.accent],
                  selected: s.themeId == th.id,
                  locked: RangeThemes.isProTheme(th.id) && !s.isPro,
                  theme: t,
                  onTap: () {
                    if (RangeThemes.isProTheme(th.id) && !s.isPro) {
                      state.widget.audio.click();
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => ProScreen(
                          audio: state.widget.audio,
                          settings: s,
                          store: state._store,
                        ),
                      ));
                      return;
                    }
                    state.widget.audio.click();
                    s.setTheme(th.id);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StylesCard extends StatelessWidget {
  final RangeThemeDef theme;
  const _StylesCard({required this.theme});

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_MenuScreenState>()!;
    final s = state._s;
    final t = theme;
    return RangeCard(
      title: 'Bow • Arrow • Target',
      theme: t,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StyleRow(
            label: 'Bow',
            names: BowStyles.names,
            isPro: BowStyles.isPro,
            value: s.bowStyle,
            theme: t,
            onPick: (i) => s.setBowStyle(i),
            state: state,
          ),
          const SizedBox(height: 10),
          _StyleRow(
            label: 'Arrow',
            names: ArrowStyles.names,
            isPro: ArrowStyles.isPro,
            value: s.arrowStyle,
            theme: t,
            onPick: (i) => s.setArrowStyle(i),
            state: state,
          ),
          const SizedBox(height: 10),
          _StyleRow(
            label: 'Target',
            names: TargetStyles.names,
            isPro: TargetStyles.isPro,
            value: s.targetStyle,
            theme: t,
            onPick: (i) => s.setTargetStyle(i),
            state: state,
          ),
        ],
      ),
    );
  }
}

class _StyleRow extends StatelessWidget {
  final String label;
  final List<String> names;
  final bool Function(int) isPro;
  final int value;
  final RangeThemeDef theme;
  final void Function(int) onPick;
  final _MenuScreenState state;
  const _StyleRow({
    required this.label,
    required this.names,
    required this.isPro,
    required this.value,
    required this.theme,
    required this.onPick,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Range.body(14, theme: t)),
        const SizedBox(height: 6),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: names.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final locked = isPro(i) && !state._s.isPro;
              final selected = value == i;
              return GestureDetector(
                onTap: () {
                  if (locked) {
                    state.widget.audio.click();
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ProScreen(
                        audio: state.widget.audio,
                        settings: state._s,
                        store: state._store,
                      ),
                    ));
                    return;
                  }
                  state.widget.audio.click();
                  onPick(i);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: selected
                        ? LinearGradient(colors: [t.accent, t.accentDark])
                        : null,
                    color:
                        selected ? null : t.woodDeep.withValues(alpha: 0.5),
                    border: Border.all(
                      color: selected
                          ? t.accentLight
                          : t.accent.withValues(alpha: 0.4),
                      width: 2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    locked ? '🔒 ${names[i]}' : names[i],
                    style: Range.label(12,
                        theme: t,
                        color: selected
                            ? t.ink
                            : t.ivory.withValues(alpha: locked ? 0.55 : 1)),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ThemeTile extends StatelessWidget {
  final String name;
  final List<Color> colors;
  final bool selected;
  final bool locked;
  final RangeThemeDef theme;
  final VoidCallback onTap;
  const _ThemeTile({
    required this.name,
    required this.colors,
    required this.selected,
    required this.locked,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: selected ? t.accentLight : t.accent.withValues(alpha: 0.4),
                  width: selected ? 3 : 1.5),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    offset: const Offset(0, 3),
                    blurRadius: 6),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Row(
                  children: [
                    for (final c in colors) Expanded(child: Container(color: c)),
                  ],
                ),
                if (locked)
                  Container(
                    color: Colors.black.withValues(alpha: 0.45),
                    child: const Center(
                        child: Text('🔒', style: TextStyle(fontSize: 20))),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 70,
            child: Text(
              name,
              style: Range.label(10,
                  theme: t,
                  color: t.ivory.withValues(alpha: locked ? 0.55 : 1)),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _NamesCard extends StatelessWidget {
  final RangeThemeDef theme;
  const _NamesCard({required this.theme});

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_MenuScreenState>()!;
    final s = state._s;
    final t = theme;
    return RangeCard(
      title: 'Archers',
      theme: t,
      child: Column(
        children: [
          _NameField(
            theme: t,
            label: 'You',
            initial: s.playerNames[0],
            onSubmit: (v) => s.setPlayerName(0, v),
          ),
          const SizedBox(height: 8),
          _NameField(
            theme: t,
            label: s.vsBot ? 'Bot' : 'Player 2',
            initial: s.playerNames[1],
            onSubmit: (v) => s.setPlayerName(1, v),
          ),
        ],
      ),
    );
  }
}

class _NameField extends StatefulWidget {
  final RangeThemeDef theme;
  final String label;
  final String initial;
  final void Function(String) onSubmit;
  const _NameField({
    required this.theme,
    required this.label,
    required this.initial,
    required this.onSubmit,
  });

  @override
  State<_NameField> createState() => _NameFieldState();
}

class _NameFieldState extends State<_NameField> {
  late final TextEditingController _ctrl;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initial);
    _focus = FocusNode();
    // Commit on focus loss: the order-safe JSON key is rewritten on every
    // keystroke already (onChanged), but this guarantees the final value
    // lands even if the app is killed mid-edit.
    _focus.addListener(() {
      if (!_focus.hasFocus && _ctrl.text != widget.initial) {
        widget.onSubmit(_ctrl.text);
      }
    });
  }

  @override
  void didUpdateWidget(covariant _NameField old) {
    super.didUpdateWidget(old);
    if (widget.initial != old.initial &&
        _ctrl.text != widget.initial &&
        !_focus.hasFocus) {
      _ctrl.text = widget.initial;
    }
  }

  @override
  void dispose() {
    _focus.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    return Row(
      children: [
        SizedBox(
            width: 76, child: Text(widget.label, style: Range.body(14, theme: t))),
        Expanded(
          child: TextField(
            controller: _ctrl,
            focusNode: _focus,
            style: Range.body(15, theme: t),
            maxLength: 16,
            decoration: InputDecoration(
              counterText: '',
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              filled: true,
              fillColor: t.woodDeep.withValues(alpha: 0.6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    BorderSide(color: t.accent.withValues(alpha: 0.4)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    BorderSide(color: t.accent.withValues(alpha: 0.4)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: t.accentLight, width: 2),
              ),
            ),
            // Save on EVERY keystroke into the order-preserving JSON key —
            // never wait for keyboard-done.
            onChanged: (v) => widget.onSubmit(v),
            onSubmitted: (_) {
              FocusScope.of(context).unfocus();
            },
          ),
        ),
      ],
    );
  }
}

class _SupportCard extends StatelessWidget {
  final RangeThemeDef theme;
  final StoreService store;
  const _SupportCard({required this.theme, required this.store});

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return RangeCard(
      title: 'Support the Range',
      theme: t,
      child: Column(
        children: [
          Text(
            'Archery is free forever. Tips keep the arrows flying! 🏹',
            style: Range.body(14, theme: t),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _TipChip(
                theme: t,
                store: store,
                productId: StoreService.coffeeId,
                emoji: '☕',
              ),
              const SizedBox(width: 12),
              _TipChip(
                theme: t,
                store: store,
                productId: StoreService.chocolateId,
                emoji: '🍫',
              ),
            ],
          ),
          if (!store.storeReady)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                'Tips available after store setup',
                style: Range.body(12,
                    theme: t,
                    color: t.ivory.withValues(alpha: 0.6)),
              ),
            ),
        ],
      ),
    );
  }
}

class _TipChip extends StatelessWidget {
  final RangeThemeDef theme;
  final StoreService store;
  final String productId;
  final String emoji;
  const _TipChip({
    required this.theme,
    required this.store,
    required this.productId,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    final t = theme;
    ProductDetails? product;
    for (final p in store.products) {
      if (p.id == productId) product = p;
    }
    return GestureDetector(
      onTap: product == null ? null : () => store.buyTip(product!),
      child: Opacity(
        opacity: product == null ? 0.5 : 1.0,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: t.woodDeep.withValues(alpha: 0.6),
            border:
                Border.all(color: t.accent.withValues(alpha: 0.5), width: 2),
          ),
          child: Text(
            '$emoji ${product?.price ?? 'Tip'}',
            style: Range.label(14, theme: t),
          ),
        ),
      ),
    );
  }
}
