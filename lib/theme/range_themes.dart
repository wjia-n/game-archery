import 'package:flutter/material.dart';

/// Theme, bow, arrow and target style catalogs for Archery.
///
/// Every theme stays inside the real archery-range material world: open
/// skies, meadows, wooden target stands, brass fittings, leather quivers.
/// No neon, no cyberpunk, no generic AI-dashboard aesthetics.
class RangeThemeDef {
  final String id;
  final String name;
  final Color skyTop;
  final Color skyBottom;
  final Color sun;
  final Color grassLight;
  final Color grassDark;
  final Color wood;
  final Color woodDeep;
  final Color accent;
  final Color accentLight;
  final Color accentDark;
  final Color ivory;
  final Color ink; // deep shadow / outline color
  final List<Color> playerColors; // 2 side colors

  const RangeThemeDef({
    required this.id,
    required this.name,
    required this.skyTop,
    required this.skyBottom,
    required this.sun,
    required this.grassLight,
    required this.grassDark,
    required this.wood,
    required this.woodDeep,
    required this.accent,
    required this.accentLight,
    required this.accentDark,
    required this.ivory,
    required this.ink,
    required this.playerColors,
  });
}

class RangeThemes {
  /// First 4 are the FREE starter themes. The rest are PRO.
  static const List<String> freeThemeIds = [
    'classic',
    'golden',
    'misty',
    'dusk',
  ];

  static const List<RangeThemeDef> all = [
    RangeThemeDef(
      id: 'classic',
      name: 'Classic Range',
      skyTop: Color(0xFF7FB2D9),
      skyBottom: Color(0xFFD9EAF5),
      sun: Color(0xFFFFF3C4),
      grassLight: Color(0xFF7CB342),
      grassDark: Color(0xFF33691E),
      wood: Color(0xFF6D4C2F),
      woodDeep: Color(0xFF3E2A17),
      accent: Color(0xFFB8860B),
      accentLight: Color(0xFFE8C66A),
      accentDark: Color(0xFF7A5A08),
      ivory: Color(0xFFFBF6E9),
      ink: Color(0xFF1D1408),
      playerColors: [Color(0xFFB71C1C), Color(0xFF1565C0)],
    ),
    RangeThemeDef(
      id: 'golden',
      name: 'Golden Meadow',
      skyTop: Color(0xFF8FBFE8),
      skyBottom: Color(0xFFFFE9B8),
      sun: Color(0xFFFFE08A),
      grassLight: Color(0xFFA8B545),
      grassDark: Color(0xFF5C6420),
      wood: Color(0xFF7A5230),
      woodDeep: Color(0xFF46301A),
      accent: Color(0xFFC9962E),
      accentLight: Color(0xFFFFD98A),
      accentDark: Color(0xFF8A6310),
      ivory: Color(0xFFFFFAEC),
      ink: Color(0xFF241A08),
      playerColors: [Color(0xFFC0392B), Color(0xFF1D6F42)],
    ),
    RangeThemeDef(
      id: 'misty',
      name: 'Misty Morning',
      skyTop: Color(0xFF9DB3C4),
      skyBottom: Color(0xFFE8EEF2),
      sun: Color(0xFFFFF6DE),
      grassLight: Color(0xFF8AA87B),
      grassDark: Color(0xFF41584A),
      wood: Color(0xFF5E4A35),
      woodDeep: Color(0xFF352818),
      accent: Color(0xFF8C7B4F),
      accentLight: Color(0xFFD9C78E),
      accentDark: Color(0xFF5E5230),
      ivory: Color(0xFFF6F4EC),
      ink: Color(0xFF1E1A12),
      playerColors: [Color(0xFF8E2434), Color(0xFF2F5D7A)],
    ),
    RangeThemeDef(
      id: 'dusk',
      name: 'Dusk Amber',
      skyTop: Color(0xFF4A3A6E),
      skyBottom: Color(0xFFF2A35E),
      sun: Color(0xFFFFB35C),
      grassLight: Color(0xFF6E7A3A),
      grassDark: Color(0xFF2E3318),
      wood: Color(0xFF5A3B22),
      woodDeep: Color(0xFF33200F),
      accent: Color(0xFFD08030),
      accentLight: Color(0xFFFFBE78),
      accentDark: Color(0xFF8A4F1A),
      ivory: Color(0xFFFFF3E0),
      ink: Color(0xFF1C1008),
      playerColors: [Color(0xFFD64545), Color(0xFF2E7BB8)],
    ),
    RangeThemeDef(
      id: 'alpine',
      name: 'Alpine Peaks',
      skyTop: Color(0xFF5E8FC4),
      skyBottom: Color(0xFFDCEBF7),
      sun: Color(0xFFFFFFFF),
      grassLight: Color(0xFF6FA35C),
      grassDark: Color(0xFF2F4A2E),
      wood: Color(0xFF6B4A2C),
      woodDeep: Color(0xFF3A2812),
      accent: Color(0xFF3E6B8C),
      accentLight: Color(0xFF8FC3E8),
      accentDark: Color(0xFF24465E),
      ivory: Color(0xFFF4F8FC),
      ink: Color(0xFF10161D),
      playerColors: [Color(0xFFA31621), Color(0xFF1D4E9E)],
    ),
    RangeThemeDef(
      id: 'orchard',
      name: 'Autumn Orchard',
      skyTop: Color(0xFF7FA8C9),
      skyBottom: Color(0xFFF7DFA8),
      sun: Color(0xFFFFE3A1),
      grassLight: Color(0xFFB5893B),
      grassDark: Color(0xFF5E4420),
      wood: Color(0xFF5E3A20),
      woodDeep: Color(0xFF33200F),
      accent: Color(0xFFB4551F),
      accentLight: Color(0xFFE89A5C),
      accentDark: Color(0xFF7A3812),
      ivory: Color(0xFFFFF6E8),
      ink: Color(0xFF221206),
      playerColors: [Color(0xFF9C2B1E), Color(0xFF3F6B2A)],
    ),
    RangeThemeDef(
      id: 'desert',
      name: 'Desert Dunes',
      skyTop: Color(0xFF6FA8D8),
      skyBottom: Color(0xFFFFE0A8),
      sun: Color(0xFFFFF0B8),
      grassLight: Color(0xFFD9B36A),
      grassDark: Color(0xFF8A6526),
      wood: Color(0xFF6E4A26),
      woodDeep: Color(0xFF3D2812),
      accent: Color(0xFFC07A2A),
      accentLight: Color(0xFFEFB96A),
      accentDark: Color(0xFF7E4F16),
      ivory: Color(0xFFFFF8E8),
      ink: Color(0xFF241708),
      playerColors: [Color(0xFFB23A1D), Color(0xFF1F6E7A)],
    ),
    RangeThemeDef(
      id: 'fen',
      name: 'Rainy Fen',
      skyTop: Color(0xFF5E7484),
      skyBottom: Color(0xFFBFCBD2),
      sun: Color(0xFFF0EFE8),
      grassLight: Color(0xFF6E8C5A),
      grassDark: Color(0xFF33402C),
      wood: Color(0xFF4E3D2A),
      woodDeep: Color(0xFF2A2012),
      accent: Color(0xFF6E8C9A),
      accentLight: Color(0xFFAED2DE),
      accentDark: Color(0xFF41585F),
      ivory: Color(0xFFF2F4F0),
      ink: Color(0xFF141A14),
      playerColors: [Color(0xFF7A2430), Color(0xFF2A5E7A)],
    ),
    RangeThemeDef(
      id: 'campfire',
      name: 'Night Campfire',
      skyTop: Color(0xFF0E1428),
      skyBottom: Color(0xFF3A2A4E),
      sun: Color(0xFFFF9A3C),
      grassLight: Color(0xFF3E4A2E),
      grassDark: Color(0xFF151A0E),
      wood: Color(0xFF4A3220),
      woodDeep: Color(0xFF241608),
      accent: Color(0xFFE07830),
      accentLight: Color(0xFFFFB86A),
      accentDark: Color(0xFF8A4A18),
      ivory: Color(0xFFFFF0DC),
      ink: Color(0xFF0E0802),
      playerColors: [Color(0xFFD64545), Color(0xFF3FA7D6)],
    ),
    RangeThemeDef(
      id: 'riverside',
      name: 'Riverside',
      skyTop: Color(0xFF6FAFD8),
      skyBottom: Color(0xFFD8F0F2),
      sun: Color(0xFFFFF6C4),
      grassLight: Color(0xFF5EA86A),
      grassDark: Color(0xFF2A5E38),
      wood: Color(0xFF6B4A2C),
      woodDeep: Color(0xFF38260F),
      accent: Color(0xFF2E7A8C),
      accentLight: Color(0xFF7AC4D4),
      accentDark: Color(0xFF1A4E5A),
      ivory: Color(0xFFF2FAF6),
      ink: Color(0xFF0E1C16),
      playerColors: [Color(0xFFC0392B), Color(0xFF2471A3)],
    ),
    RangeThemeDef(
      id: 'moor',
      name: 'Highland Moor',
      skyTop: Color(0xFF7A8BA8),
      skyBottom: Color(0xFFD8DCC8),
      sun: Color(0xFFFFF0C8),
      grassLight: Color(0xFF8C9A5C),
      grassDark: Color(0xFF434A26),
      wood: Color(0xFF54402A),
      woodDeep: Color(0xFF2E2212),
      accent: Color(0xFF7A5E8C),
      accentLight: Color(0xFFB89AD4),
      accentDark: Color(0xFF4E3A5E),
      ivory: Color(0xFFF6F4EA),
      ink: Color(0xFF181410),
      playerColors: [Color(0xFF8E2434), Color(0xFF2F6B4A)],
    ),
    RangeThemeDef(
      id: 'blossom',
      name: 'Cherry Blossom',
      skyTop: Color(0xFF8FB8DE),
      skyBottom: Color(0xFFFBE4EE),
      sun: Color(0xFFFFF0F4),
      grassLight: Color(0xFF7CB342),
      grassDark: Color(0xFF3E5E26),
      wood: Color(0xFF6D4C38),
      woodDeep: Color(0xFF3A2818),
      accent: Color(0xFFC46A8C),
      accentLight: Color(0xFFEFAEC4),
      accentDark: Color(0xFF8C3A58),
      ivory: Color(0xFFFFF4F6),
      ink: Color(0xFF201014),
      playerColors: [Color(0xFFB23A5E), Color(0xFF2A6E8C)],
    ),
  ];

  static bool isProTheme(String id) =>
      !freeThemeIds.contains(id) && id != 'custom';

  static RangeThemeDef byId(String id, {RangeThemeDef? custom}) {
    if (id == 'custom' && custom != null) return custom;
    for (final t in all) {
      if (t.id == id) return t;
    }
    return all.first;
  }
}

// ---------------------------------------------------------------------------
// Bow styles: wood/grip colorways for the hand-drawn bow.
// First 4 free, rest PRO.
// ---------------------------------------------------------------------------
class BowStyle {
  final String name;
  final Color limb;
  final Color limbDark;
  final Color grip;
  const BowStyle(
      {required this.name,
      required this.limb,
      required this.limbDark,
      required this.grip});
}

class BowStyles {
  static const List<BowStyle> all = [
    BowStyle(
        name: 'Yew Classic',
        limb: Color(0xFF8B5A2B),
        limbDark: Color(0xFF5C3A1A),
        grip: Color(0xFF3E2A17)),
    BowStyle(
        name: 'Hickory Plain',
        limb: Color(0xFFA8763E),
        limbDark: Color(0xFF6E4E24),
        grip: Color(0xFF4A2E14)),
    BowStyle(
        name: 'Oaken Veteran',
        limb: Color(0xFF7A5E3A),
        limbDark: Color(0xFF4E3C22),
        grip: Color(0xFF2E2012)),
    BowStyle(
        name: 'Birch Scout',
        limb: Color(0xFFC4A06A),
        limbDark: Color(0xFF8A6E42),
        grip: Color(0xFF5C4226)),
    BowStyle(
        name: 'Walnut Royale',
        limb: Color(0xFF5E3B22),
        limbDark: Color(0xFF38220F),
        grip: Color(0xFF1F1206)),
    BowStyle(
        name: 'Cherry Hunter',
        limb: Color(0xFF8C3A22),
        limbDark: Color(0xFF5E2412),
        grip: Color(0xFF331208)),
    BowStyle(
        name: 'Ebony Master',
        limb: Color(0xFF3A2E24),
        limbDark: Color(0xFF1F1712),
        grip: Color(0xFFB8860B)),
    BowStyle(
        name: 'Elderwood Sage',
        limb: Color(0xFF4E6E42),
        limbDark: Color(0xFF2E4226),
        grip: Color(0xFF8C6A3A)),
  ];

  static const List<String> names = [
    'Yew Classic',
    'Hickory Plain',
    'Oaken Veteran',
    'Birch Scout',
    'Walnut Royale',
    'Cherry Hunter',
    'Ebony Master',
    'Elderwood Sage',
  ];

  static bool isPro(int i) => i >= 4;
}

// ---------------------------------------------------------------------------
// Arrow styles: shaft wood + fletching color.
// First 4 free, rest PRO.
// ---------------------------------------------------------------------------
class ArrowStyle {
  final String name;
  final Color shaft;
  final Color fletch;
  const ArrowStyle(
      {required this.name, required this.shaft, required this.fletch});
}

class ArrowStyles {
  static const List<ArrowStyle> all = [
    ArrowStyle(
        name: 'Cedar Classic',
        shaft: Color(0xFFB08954),
        fletch: Color(0xFFD64545)),
    ArrowStyle(
        name: 'Pine Scout',
        shaft: Color(0xFFC9A86A),
        fletch: Color(0xFF2E7BB8)),
    ArrowStyle(
        name: 'Bamboo Swift',
        shaft: Color(0xFFD4BC7A),
        fletch: Color(0xFF3FA75F)),
    ArrowStyle(
        name: 'Ash Standard',
        shaft: Color(0xFF9A7E56),
        fletch: Color(0xFFE8C66A)),
    ArrowStyle(
        name: 'Oak Heavy',
        shaft: Color(0xFF7A5E3A),
        fletch: Color(0xFF8C3A5E)),
    ArrowStyle(
        name: 'Ironwood Pro',
        shaft: Color(0xFF4E3B2A),
        fletch: Color(0xFFD9D2C4)),
    ArrowStyle(
        name: 'Willow Whisper',
        shaft: Color(0xFF8C9A6A),
        fletch: Color(0xFF7AC4D4)),
    ArrowStyle(
        name: 'Ember Flight',
        shaft: Color(0xFF6E3A1E),
        fletch: Color(0xFFFF9A3C)),
  ];

  static const List<String> names = [
    'Cedar Classic',
    'Pine Scout',
    'Bamboo Swift',
    'Ash Standard',
    'Oak Heavy',
    'Ironwood Pro',
    'Willow Whisper',
    'Ember Flight',
  ];

  static bool isPro(int i) => i >= 4;
}

// ---------------------------------------------------------------------------
// Target face styles: ring palettes for the target face.
// First 4 free, rest PRO.
// ---------------------------------------------------------------------------
class TargetStyle {
  final String name;
  final List<Color> rings; // 10 entries, outer (1) .. inner (10)
  const TargetStyle({required this.name, required this.rings});
}

const _fitaRings = [
  Color(0xFFF5F5F5),
  Color(0xFFF5F5F5),
  Color(0xFF2B2B2B),
  Color(0xFF2B2B2B),
  Color(0xFF29B6F6),
  Color(0xFF29B6F6),
  Color(0xFFEF5350),
  Color(0xFFEF5350),
  Color(0xFFFFD54F),
  Color(0xFFFFD54F),
];

class TargetStyles {
  static const List<TargetStyle> all = [
    TargetStyle(name: 'FITA Classic', rings: _fitaRings),
    TargetStyle(
      name: 'Straw Roundel',
      rings: [
        Color(0xFFD9B36A),
        Color(0xFFD9B36A),
        Color(0xFF8A6526),
        Color(0xFF8A6526),
        Color(0xFFB08954),
        Color(0xFFB08954),
        Color(0xFF6E3A1E),
        Color(0xFF6E3A1E),
        Color(0xFFFFD54F),
        Color(0xFFFFD54F),
      ],
    ),
    TargetStyle(
      name: 'Vintage Field',
      rings: [
        Color(0xFFE8DCC0),
        Color(0xFFE8DCC0),
        Color(0xFF4A4438),
        Color(0xFF4A4438),
        Color(0xFF6E8CA8),
        Color(0xFF6E8CA8),
        Color(0xFFA85E52),
        Color(0xFFA85E52),
        Color(0xFFE8C66A),
        Color(0xFFE8C66A),
      ],
    ),
    TargetStyle(
      name: 'Highland Cloth',
      rings: [
        Color(0xFFDCD4BC),
        Color(0xFFDCD4BC),
        Color(0xFF2E2E2E),
        Color(0xFF2E2E2E),
        Color(0xFF3E6B8C),
        Color(0xFF3E6B8C),
        Color(0xFF8E2434),
        Color(0xFF8E2434),
        Color(0xFFD9A83C),
        Color(0xFFD9A83C),
      ],
    ),
    TargetStyle(
      name: 'Royal Tournament',
      rings: [
        Color(0xFFF8F1E2),
        Color(0xFFF8F1E2),
        Color(0xFF1F1F1F),
        Color(0xFF1F1F1F),
        Color(0xFF1D4E9E),
        Color(0xFF1D4E9E),
        Color(0xFFA31621),
        Color(0xFFA31621),
        Color(0xFFC9A227),
        Color(0xFFC9A227),
      ],
    ),
    TargetStyle(
      name: 'Forest Trial',
      rings: [
        Color(0xFFD8DCC8),
        Color(0xFFD8DCC8),
        Color(0xFF33402C),
        Color(0xFF33402C),
        Color(0xFF2A5E38),
        Color(0xFF2A5E38),
        Color(0xFF7A3A22),
        Color(0xFF7A3A22),
        Color(0xFFE8C66A),
        Color(0xFFE8C66A),
      ],
    ),
    TargetStyle(
      name: 'Desert Clay',
      rings: [
        Color(0xFFF0E0C0),
        Color(0xFFF0E0C0),
        Color(0xFF5E4420),
        Color(0xFF5E4420),
        Color(0xFF2E7A8C),
        Color(0xFF2E7A8C),
        Color(0xFFB23A1D),
        Color(0xFFB23A1D),
        Color(0xFFFFD54F),
        Color(0xFFFFD54F),
      ],
    ),
    TargetStyle(
      name: 'Ember Night',
      rings: [
        Color(0xFFD8CFC0),
        Color(0xFFD8CFC0),
        Color(0xFF1A1410),
        Color(0xFF1A1410),
        Color(0xFF3A5E7A),
        Color(0xFF3A5E7A),
        Color(0xFFC45E2A),
        Color(0xFFC45E2A),
        Color(0xFFFFB35C),
        Color(0xFFFFB35C),
      ],
    ),
  ];

  static const List<String> names = [
    'FITA Classic',
    'Straw Roundel',
    'Vintage Field',
    'Highland Cloth',
    'Royal Tournament',
    'Forest Trial',
    'Desert Clay',
    'Ember Night',
  ];

  static bool isPro(int i) => i >= 4;
}
