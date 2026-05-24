// QR menü ve tüm paneller için tema renk yardımcısı.
import 'package:flutter/material.dart';

class AppThemeHelper {
  static const String defaultThemeKey = 'brown';
  static const String defaultPrimaryHex = '#795548';
  static const String defaultMenuLayout = 'vertical';

  static const Color _kremZemin = Color(0xFFF8F1E7);

  // Yönetici panelinde seçilebilir tema listesi.
  static const List<MapEntry<String, String>> temaSecenekleri = [
    MapEntry('brown', 'Kahverengi / Kafe'),
    MapEntry('blue', 'Mavi'),
    MapEntry('green', 'Yeşil'),
    MapEntry('purple', 'Mor'),
    MapEntry('red', 'Kırmızı'),
    MapEntry('dark', 'Siyah / Modern'),
  ];

  static const List<MapEntry<String, String>> menuLayoutSecenekleri = [
    MapEntry('vertical', 'Dikey Liste'),
    MapEntry('horizontal', 'Yatay Kart Görünümü'),
  ];

  static Color colorFromHex(String hex) {
    var temiz = hex.trim().replaceAll('#', '');
    if (temiz.length == 6) {
      temiz = 'FF$temiz';
    }
    if (temiz.length != 8) {
      return primaryFromThemeKey(defaultThemeKey);
    }
    return Color(int.parse(temiz, radix: 16));
  }

  static Color primaryFromThemeKey(String themeKey) {
    switch (themeKey) {
      case 'blue':
        return const Color(0xFF1976D2);
      case 'green':
        return const Color(0xFF388E3C);
      case 'purple':
        return const Color(0xFF7B1FA2);
      case 'red':
        return const Color(0xFFD32F2F);
      case 'dark':
        return const Color(0xFF212121);
      case 'brown':
      default:
        return const Color(0xFF795548);
    }
  }

  static String hexFromThemeKey(String themeKey) {
    final renk = primaryFromThemeKey(themeKey);
    final argb = renk.toARGB32() & 0xFFFFFF;
    return '#${argb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  static Color resolvePrimary({
    required String themeKey,
    required String primaryColor,
  }) {
    final hex = primaryColor.trim();
    if (hex.isNotEmpty && hex.startsWith('#')) {
      try {
        return colorFromHex(hex);
      } catch (_) {
        return primaryFromThemeKey(themeKey);
      }
    }
    return primaryFromThemeKey(themeKey);
  }

  static String normalizeThemeKey(String? value) {
    final v = (value ?? '').trim().toLowerCase();
    const gecerli = ['brown', 'blue', 'green', 'purple', 'red', 'dark'];
    if (gecerli.contains(v)) return v;
    return defaultThemeKey;
  }

  static String normalizeMenuLayout(String? value) {
    final v = (value ?? '').trim().toLowerCase();
    if (v == 'horizontal') return 'horizontal';
    return defaultMenuLayout;
  }

  /// Buton ve AppBar üzerindeki yazı rengi.
  static Color getThemeTextColor(Color primaryColor) {
    final luminance = primaryColor.computeLuminance();
    return luminance > 0.45 ? Colors.black87 : Colors.white;
  }

  /// AppBar ve hafif vurgu alanları.
  static Color getLightBackground(Color primaryColor) {
    return Color.alphaBlend(primaryColor.withValues(alpha: 0.12), _kremZemin);
  }

  /// Bilgi kartları ve yumuşak kutular.
  static Color getSoftCardColor(Color primaryColor) {
    return Color.alphaBlend(primaryColor.withValues(alpha: 0.08), Colors.white);
  }

  /// Tooltip arka planı — primary koyulaştırılmış.
  static Color getTooltipBackground(Color primaryColor) {
    final hsl = HSLColor.fromColor(primaryColor);
    return hsl.withLightness((hsl.lightness * 0.55).clamp(0.15, 0.45)).toColor();
  }

  /// Eski ad — geriye uyumluluk.
  static Color lightTint(Color primary) => getLightBackground(primary);

  static const Color sayfaZemin = _kremZemin;
}
