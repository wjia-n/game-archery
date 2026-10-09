import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/range_art.dart';
import '../theme/range_themes.dart';

/// Settings: music / SFX toggles, volume, lifetime stats.
class SettingsScreen extends StatefulWidget {
  final RangeAudio audio;
  final RangeSettings settings;
  const SettingsScreen(
      {super.key, required this.audio, required this.settings});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  RangeThemeDef get _t => RangeThemes.byId(
        widget.settings.themeId,
        custom: widget.settings.customTheme,
      );

  @override
  Widget build(BuildContext context) {
    final t = _t;
    final s = widget.settings;
    final audio = widget.audio;
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
              audio.click();
              Navigator.of(context).pop();
            },
          ),
          title: Text('Settings', style: Range.display(22, theme: t)),
          centerTitle: true,
        ),
        body: SafeArea(
          child: ListenableBuilder(
            listenable: s,
            builder: (_, _) => ListView(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              children: [
                RangeCard(
                  title: 'Sound',
                  theme: t,
                  child: Column(
                    children: [
                      SettingRow(
                        label: '🎵 Music',
                        theme: t,
                        control: RangeToggle(
                          value: s.musicOn,
                          theme: t,
                          onChanged: (v) {
                            audio.click();
                            s.setMusic(v);
                            audio.configure(
                                musicOn: v,
                                sfxOn: s.sfxOn,
                                volume: s.volume);
                            if (v) {
                              audio.startMenuMusic();
                            } else {
                              audio.stopMusic();
                            }
                          },
                        ),
                      ),
                      SettingRow(
                        label: '🔔 Sound effects',
                        theme: t,
                        control: RangeToggle(
                          value: s.sfxOn,
                          theme: t,
                          onChanged: (v) {
                            s.setSfx(v);
                            audio.configure(
                                musicOn: s.musicOn,
                                sfxOn: v,
                                volume: s.volume);
                            audio.click();
                          },
                        ),
                      ),
                      SettingRow(
                        label: '🔊 Volume',
                        theme: t,
                        control: SizedBox(
                          width: 170,
                          child: BeadSlider(
                            value: s.volume,
                            theme: t,
                            onChanged: (v) {
                              s.setVolume(v);
                              audio.configure(
                                  musicOn: s.musicOn,
                                  sfxOn: s.sfxOn,
                                  volume: v);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                RangeCard(
                  title: 'Your Range Record',
                  theme: t,
                  child: Column(
                    children: [
                      _StatRow(
                          label: 'Matches played',
                          value: '${s.gamesPlayed}',
                          theme: t),
                      _StatRow(
                          label: 'Matches won', value: '${s.wins}', theme: t),
                      _StatRow(
                          label: 'Best score',
                          value: s.bestScore > 0
                              ? '${s.bestScore} pts'
                              : '—',
                          theme: t),
                      _StatRow(
                          label: 'Status',
                          value: s.isPro ? '✦ PRO' : 'Free',
                          theme: t),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Center(
                  child: Text(
                    'v2.0.0 • Made with 🏹 by WAJIHA',
                    style: Range.body(12,
                        theme: t,
                        color: t.ivory.withValues(alpha: 0.6)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final RangeThemeDef theme;
  const _StatRow(
      {required this.label, required this.value, required this.theme});

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: Range.body(15, theme: t))),
          Text(value, style: Range.label(15, theme: t)),
        ],
      ),
    );
  }
}
