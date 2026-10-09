import 'dart:async';

import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/range_art.dart';
import '../theme/range_themes.dart';

/// PRO: custom range theme creator — pick sky, meadow, wood and accent
/// colors. Live preview, persisted per color.
class CustomThemeScreen extends StatefulWidget {
  final RangeAudio audio;
  final RangeSettings settings;

  const CustomThemeScreen(
      {super.key, required this.audio, required this.settings});

  @override
  State<CustomThemeScreen> createState() => _CustomThemeScreenState();
}

class _CustomThemeScreenState extends State<CustomThemeScreen> {
  RangeThemeDef get _t => RangeThemes.byId(
        widget.settings.themeId,
        custom: widget.settings.customTheme,
      );

  // Curated range-friendly palette choices.
  static const List<Color> palette = [
    Color(0xFF7FB2D9), Color(0xFF5E8FC4), Color(0xFF4A3A6E),
    Color(0xFF0E1428), Color(0xFF3A2A4E), Color(0xFF5E7484),
    Color(0xFFD9EAF5), Color(0xFFFFE9B8), Color(0xFFF2A35E),
    Color(0xFFFFF3C4), Color(0xFFFFB35C), Color(0xFFFF9A3C),
    Color(0xFF7CB342), Color(0xFF33691E), Color(0xFF2A5E38),
    Color(0xFFA8B545), Color(0xFF6E7A3A), Color(0xFFD9B36A),
    Color(0xFF6D4C2F), Color(0xFF3E2A17), Color(0xFF4A3220),
    Color(0xFF8B5A2B), Color(0xFF5E3B22), Color(0xFF241608),
    Color(0xFFB8860B), Color(0xFFE8C66A), Color(0xFF7A5A08),
    Color(0xFFC46A8C), Color(0xFFEFAEC4), Color(0xFF8C3A58),
    Color(0xFF2E7A8C), Color(0xFF7AC4D4), Color(0xFF1A4E5A),
    Color(0xFFB71C1C), Color(0xFF1565C0), Color(0xFF1D6F42),
    Color(0xFFFBF6E9), Color(0xFFFFF6E8), Color(0xFF1D1408),
  ];

  static const rows = [
    ('Sky top', 'skyTop'),
    ('Sky bottom', 'skyBottom'),
    ('Sun', 'sun'),
    ('Meadow light', 'grassLight'),
    ('Meadow dark', 'grassDark'),
    ('Wood', 'wood'),
    ('Wood deep', 'woodDeep'),
    ('Accent', 'accent'),
    ('Accent light', 'accentLight'),
    ('Accent dark', 'accentDark'),
    ('Ivory text', 'ivory'),
    ('Deep ink', 'ink'),
  ];

  Future<void> _pick(String key, String label) async {
    final s = widget.settings;
    final current = Color(s.customColors[key]!);
    final chosen = await showDialog<Color>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(colors: [
              _t.wood,
              _t.woodDeep,
            ]),
            border: Border.all(color: _t.accent, width: 2.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Pick $label', style: Range.display(20, theme: _t)),
              const SizedBox(height: 14),
              SizedBox(
                width: 300,
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: palette.length,
                  itemBuilder: (_, i) {
                    final c = palette[i];
                    final selected = c.value == current.value;
                    return GestureDetector(
                      onTap: () {
                        widget.audio.click();
                        Navigator.of(context).pop(c);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: c,
                          border: Border.all(
                            color: selected
                                ? _t.accentLight
                                : Colors.black.withValues(alpha: 0.4),
                            width: selected ? 3 : 1.5,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              RangeButton(
                label: 'Cancel',
                width: 160,
                fontSize: 15,
                theme: _t,
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
    if (chosen != null && mounted) {
      unawaited(widget.audio.click());
      await s.setCustomColor(key, chosen.value);
      // Selecting a custom color auto-applies the custom theme.
      await s.setTheme('custom');
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    final s = widget.settings;
    final preview = s.customTheme;
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
          title: Text('My Range', style: Range.display(22, theme: t)),
          centerTitle: true,
          actions: [
            TextButton(
              onPressed: () async {
                unawaited(widget.audio.click());
                await s.resetCustomColors();
                if (mounted) setState(() {});
              },
              child: Text('Reset', style: Range.label(13, theme: t)),
            ),
          ],
        ),
        body: SafeArea(
          child: ListenableBuilder(
            listenable: s,
            builder: (_, _) => ListView(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              children: [
                // Live preview of the custom theme.
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: t.accent, width: 2),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        preview.skyTop,
                        preview.skyBottom,
                        preview.grassLight,
                      ],
                      stops: const [0.0, 0.55, 0.56],
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: preview.woodDeep, width: 5),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                              child: Container(color: preview.accentLight)),
                          Expanded(child: Container(color: preview.accent)),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text('Live preview',
                      style: Range.body(12,
                          theme: t,
                          color: t.ivory.withValues(alpha: 0.65))),
                ),
                const SizedBox(height: 12),
                for (final r in rows)
                  GestureDetector(
                    onTap: () => _pick(r.$2, r.$1),
                    child: SettingRow(
                      label: r.$1,
                      theme: t,
                      control: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(s.customColors[r.$2]!),
                          border: Border.all(
                              color: t.accentLight, width: 2),
                          boxShadow: [
                            BoxShadow(
                                color:
                                    Colors.black.withValues(alpha: 0.4),
                                offset: const Offset(0, 2),
                                blurRadius: 4),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                Center(
                  child: RangeButton(
                    label: s.themeId == 'custom'
                        ? '✓  Using My Creation'
                        : 'Use My Creation',
                    width: 240,
                    fontSize: 17,
                    theme: t,
                    onTap: s.themeId == 'custom'
                        ? null
                        : () async {
                            unawaited(widget.audio.click());
                            await s.setTheme('custom');
                            if (mounted) setState(() {});
                          },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
