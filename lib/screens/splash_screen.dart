import 'dart:async';

import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/range_art.dart';
import '../theme/range_themes.dart';
import 'menu_screen.dart';

/// Launch splash: SINGLE splash flow — WAJIHA company moment first, then
/// the game splash (logo + name + animated loading line + "Credits: WAJIHA").
/// The company logo is copied unchanged into assets; never redrawn.
class SplashScreen extends StatefulWidget {
  final RangeAudio audio;
  final RangeSettings settings;
  const SplashScreen({super.key, required this.audio, required this.settings});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loader;
  bool _companyMoment = true;

  @override
  void initState() {
    super.initState();
    _loader = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _run();
  }

  Future<void> _run() async {
    // Pre-warm audio while the company moment shows (fire-and-forget).
    unawaited(widget.audio.prewarm());
    // Company splash moment: official WAJIHA logo, held briefly.
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    setState(() => _companyMoment = false);
    // Game splash: start menu music and run the loading line.
    unawaited(widget.audio.startMenuMusic());
    _loader.forward();
    await Future.delayed(const Duration(milliseconds: 1900));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MenuScreen(
          audio: widget.audio,
          settings: widget.settings,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _loader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = RangeThemes.byId(
      widget.settings.themeId,
      custom: widget.settings.customTheme,
    );
    return Scaffold(
      backgroundColor: theme.ink,
      body: _companyMoment
          ? _CompanySplash(theme: theme)
          : _GameSplash(theme: theme, loader: _loader),
    );
  }
}

/// Company splash moment: the official WAJIHA winged-W logo, full screen.
class _CompanySplash extends StatelessWidget {
  final RangeThemeDef theme;
  const _CompanySplash({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/wajiha_logo.png',
              width: 150,
              height: 150,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 18),
            Text(
              'WAJIHA',
              style: Range.display(30, theme: theme),
            ),
          ],
        ),
      ),
    );
  }
}

/// Game splash: logo + name + animated loading line + credits.
class _GameSplash extends StatelessWidget {
  final RangeThemeDef theme;
  final AnimationController loader;
  const _GameSplash({required this.theme, required this.loader});

  @override
  Widget build(BuildContext context) {
    return RangeBackdrop(
      theme: theme,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: theme.accent, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    offset: const Offset(0, 10),
                    blurRadius: 24,
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset('assets/archery_logo.png', fit: BoxFit.cover),
            ),
            const SizedBox(height: 22),
            Text('Archery', style: Range.display(52, theme: theme)),
            const SizedBox(height: 6),
            Text(
              'READ THE WIND • SPLIT THE GOLD',
              style: Range.label(13, theme: theme),
            ),
            const SizedBox(height: 30),
            // Animated loading line.
            SizedBox(
              width: 220,
              child: AnimatedBuilder(
                animation: loader,
                builder: (_, _) => Column(
                  children: [
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: Colors.black.withValues(alpha: 0.45),
                        border: Border.all(
                            color: theme.accent.withValues(alpha: 0.5)),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: loader.value.clamp(0.02, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            gradient: LinearGradient(
                              colors: [
                                theme.accentLight,
                                theme.accent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      loader.value < 1 ? 'Stringing the bows…' : 'Ready!',
                      style: Range.body(13,
                          theme: theme,
                          color: theme.ivory.withValues(alpha: 0.75)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 44),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/wajiha_logo.png',
                  width: 30,
                  height: 30,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 10),
                Text(
                  'Credits: WAJIHA',
                  style: Range.label(14, theme: theme),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
