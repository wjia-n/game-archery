import 'package:flutter/material.dart';
import 'range_themes.dart';

/// Range Craft — the design system for Archery.
/// A real archery range: open sky, meadow grass, wooden stands, brass
/// fittings, leather. No neon, no cyberpunk, no generic Material look.
///
/// All widgets accept an optional [RangeThemeDef]; they default to the
/// Classic Range theme.
class Range {
  static const displayFont = 'serif';

  static TextStyle display(double size, {Color? color, RangeThemeDef? theme}) =>
      TextStyle(
        fontFamily: displayFont,
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color ?? theme?.accentLight ?? const Color(0xFFE8C66A),
        letterSpacing: 1.2,
        shadows: [
          Shadow(
              color: (theme?.ink ?? const Color(0xFF1D1408))
                  .withValues(alpha: 0.75),
              offset: const Offset(0, 2),
              blurRadius: 4),
        ],
      );

  static TextStyle body(double size, {Color? color, RangeThemeDef? theme}) =>
      TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: color ?? theme?.ivory ?? const Color(0xFFFBF6E9),
        height: 1.35,
      );

  static TextStyle label(double size, {Color? color, RangeThemeDef? theme}) =>
      TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color ?? theme?.accentLight ?? const Color(0xFFE8C66A),
        letterSpacing: 0.8,
      );

  static ThemeData theme([RangeThemeDef? t]) {
    t ??= RangeThemes.byId('classic');
    final dark = t.id == 'campfire';
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: t.woodDeep,
      colorScheme: ColorScheme(
        brightness: dark ? Brightness.dark : Brightness.light,
        primary: t.accent,
        onPrimary: t.ink,
        secondary: t.accentLight,
        onSecondary: t.ink,
        surface: t.wood,
        onSurface: t.ivory,
        error: t.playerColors[0],
        onError: t.ivory,
      ),
      textTheme: TextTheme(
        displayLarge: display(34, theme: t),
        displayMedium: display(26, theme: t),
        titleLarge: display(22, theme: t),
        bodyLarge: body(16, theme: t),
        bodyMedium: body(14, theme: t),
        labelLarge: label(14, theme: t),
      ),
      dialogTheme: DialogThemeData(backgroundColor: t.wood),
    );
  }
}

/// Sky + meadow background with sun and soft vignette, theme-aware.
class RangeBackdrop extends StatelessWidget {
  final Widget child;
  final RangeThemeDef? theme;
  const RangeBackdrop({super.key, required this.child, this.theme});

  @override
  Widget build(BuildContext context) {
    final t = theme ?? RangeThemes.byId('classic');
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [t.skyTop, t.skyBottom],
        ),
      ),
      child: CustomPaint(
        painter: _RangeBackdropPainter(t),
        child: child,
      ),
    );
  }
}

class _RangeBackdropPainter extends CustomPainter {
  final RangeThemeDef t;
  _RangeBackdropPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    // Sun glow.
    final sunC = Offset(size.width * 0.82, size.height * 0.12);
    final sunR = size.width * 0.16;
    canvas.drawCircle(
      sunC,
      sunR * 1.9,
      Paint()..color = t.sun.withValues(alpha: 0.18),
    );
    canvas.drawCircle(sunC, sunR, Paint()..color = t.sun.withValues(alpha: 0.9));

    // Meadow band at the bottom.
    final meadowTop = size.height * 0.62;
    final meadow = Path()
      ..moveTo(0, meadowTop)
      ..quadraticBezierTo(size.width * 0.5, meadowTop - 18, size.width, meadowTop)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      meadow,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [t.grassLight, t.grassDark],
        ).createShader(Rect.fromLTWH(0, meadowTop, size.width, size.height - meadowTop)),
    );
    // Grass blades.
    final blade = Paint()
      ..color = t.grassDark.withValues(alpha: 0.5)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 26; i++) {
      final x = size.width * (i + 0.5) / 26;
      final y = size.height * (0.86 + (i % 5) * 0.028);
      canvas.drawLine(Offset(x, y), Offset(x + (i % 3 - 1) * 4.0, y - 14), blade);
    }
    // Vignette.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.2),
          radius: 1.25,
          colors: [
            Colors.transparent,
            t.ink.withValues(alpha: 0.28),
          ],
          stops: const [0.55, 1.0],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A chunky wooden button with brass trim — looks physically pressable.
class RangeButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final double width;
  final double fontSize;
  final RangeThemeDef? theme;

  const RangeButton({
    super.key,
    required this.label,
    required this.onTap,
    this.width = 240,
    this.fontSize = 19,
    this.theme,
  });

  @override
  State<RangeButton> createState() => _RangeButtonState();
}

class _RangeButtonState extends State<RangeButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.theme ?? RangeThemes.byId('classic');
    final enabled = widget.onTap != null;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled
          ? (_) {
              setState(() => _pressed = false);
              widget.onTap!();
            }
          : null,
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        width: widget.width,
        padding: const EdgeInsets.symmetric(vertical: 15),
        transform: Matrix4.translationValues(0, _pressed ? 3 : 0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: enabled
                ? [t.wood, t.woodDeep, t.woodDeep]
                : [
                    t.woodDeep.withValues(alpha: 0.7),
                    t.woodDeep.withValues(alpha: 0.5)
                  ],
          ),
          border: Border.all(color: t.accent, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: t.accentLight.withValues(alpha: _pressed ? 0.05 : 0.22),
              offset: const Offset(0, -2),
              blurRadius: 2,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              offset: Offset(0, _pressed ? 2 : 6),
              blurRadius: _pressed ? 4 : 10,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          widget.label,
          style: Range.display(widget.fontSize,
              theme: t,
              color:
                  enabled ? t.ivory : t.ivory.withValues(alpha: 0.45)),
        ),
      ),
    );
  }
}

/// An engraved brass plaque for titles.
class RangePlaque extends StatelessWidget {
  final String title;
  final String? subtitle;
  final RangeThemeDef? theme;
  const RangePlaque(
      {super.key, required this.title, this.subtitle, this.theme});

  @override
  Widget build(BuildContext context) {
    final t = theme ?? RangeThemes.byId('classic');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [t.woodDeep, t.ink.withValues(alpha: 0.92)],
        ),
        border: Border.all(color: t.accent, width: 3),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              offset: const Offset(0, 6),
              blurRadius: 12),
          BoxShadow(
              color: t.accentLight.withValues(alpha: 0.7),
              offset: const Offset(0, -1),
              blurRadius: 1),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title,
              style: Range.display(30, theme: t),
              textAlign: TextAlign.center),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(subtitle!,
                style: Range.body(14,
                    theme: t, color: t.ivory.withValues(alpha: 0.78)),
                textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }
}

/// A brass lever toggle for settings.
class RangeToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final RangeThemeDef? theme;
  const RangeToggle(
      {super.key, required this.value, required this.onChanged, this.theme});

  @override
  Widget build(BuildContext context) {
    final t = theme ?? RangeThemes.byId('classic');
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 64,
        height: 34,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(17),
          color: value ? t.accentDark : t.woodDeep,
          border: Border.all(color: t.accent, width: 2),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                offset: const Offset(0, 3),
                blurRadius: 5),
          ],
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 160),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 26,
            height: 26,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [t.accentLight, t.accent, t.accentDark],
              ),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    offset: const Offset(0, 2),
                    blurRadius: 3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A wooden-bead volume slider on a brass rail.
class BeadSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final RangeThemeDef? theme;
  const BeadSlider(
      {super.key, required this.value, required this.onChanged, this.theme});

  @override
  Widget build(BuildContext context) {
    final t = theme ?? RangeThemes.byId('classic');
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 6,
        activeTrackColor: t.accent,
        inactiveTrackColor: t.woodDeep,
        thumbShape: _BeadThumb(t),
        overlayShape: SliderComponentShape.noOverlay,
      ),
      child: Slider(value: value, onChanged: onChanged),
    );
  }
}

class _BeadThumb extends SliderComponentShape {
  final RangeThemeDef t;
  const _BeadThumb(this.t);

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      const Size(26, 26);

  @override
  void paint(PaintingContext context, Offset center,
      {required Animation<double> activationAnimation,
      required Animation<double> enableAnimation,
      required bool isDiscrete,
      required TextPainter labelPainter,
      required RenderBox parentBox,
      required SliderThemeData sliderTheme,
      required TextDirection textDirection,
      required double value,
      required double textScaleFactor,
      required Size sizeWithOverflow}) {
    final canvas = context.canvas;
    canvas.drawCircle(
        center + const Offset(0, 2), 12, Paint()..color = Colors.black.withValues(alpha: 0.6));
    canvas.drawCircle(
        center,
        11,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.4, -0.5),
            radius: 1.0,
            colors: [t.accentLight, t.accent, t.accentDark],
          ).createShader(Rect.fromCircle(center: center, radius: 11)));
  }
}

/// Small helper: a labeled settings row.
class SettingRow extends StatelessWidget {
  final String label;
  final Widget control;
  final RangeThemeDef? theme;
  const SettingRow(
      {super.key, required this.label, required this.control, this.theme});

  @override
  Widget build(BuildContext context) {
    final t = theme ?? RangeThemes.byId('classic');
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 7),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      decoration: BoxDecoration(
        color: t.woodDeep.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.accent.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: Range.body(16, theme: t))),
          control,
        ],
      ),
    );
  }
}

/// A section card for menu screens.
class RangeCard extends StatelessWidget {
  final String title;
  final Widget child;
  final RangeThemeDef? theme;
  const RangeCard(
      {super.key, required this.title, required this.child, this.theme});

  @override
  Widget build(BuildContext context) {
    final t = theme ?? RangeThemes.byId('classic');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: t.woodDeep.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.accent.withValues(alpha: 0.55), width: 2),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              offset: const Offset(0, 5),
              blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Range.label(16, theme: t)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
