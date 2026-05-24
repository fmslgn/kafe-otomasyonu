// Kafe tema ayarlarını uygulama genelinde paylaşır.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/cafe_settings_model.dart';
import '../services/api_service.dart';
import '../utils/app_theme_helper.dart';

/// Tema renk paleti — ekranlarda vurgu ve AppBar için kullanılır.
class AppThemePalette {
  final Color primary;
  final Color appBarBackground;
  final Color softCard;
  final Color lightBackground;
  final Color onPrimary;
  final Color chipSelected;
  final Color tooltipBackground;
  final String themeKey;

  const AppThemePalette({
    required this.primary,
    required this.appBarBackground,
    required this.softCard,
    required this.lightBackground,
    required this.onPrimary,
    required this.chipSelected,
    required this.tooltipBackground,
    required this.themeKey,
  });

  factory AppThemePalette.fromSettings(CafeSettingsModel? ayar) {
    final key = AppThemeHelper.normalizeThemeKey(ayar?.themeKey);
    final primary = ayar == null
        ? AppThemeHelper.primaryFromThemeKey(AppThemeHelper.defaultThemeKey)
        : AppThemeHelper.resolvePrimary(
            themeKey: key,
            primaryColor: ayar.primaryColor,
          );

    return AppThemePalette(
      primary: primary,
      appBarBackground: AppThemeHelper.getLightBackground(primary),
      softCard: AppThemeHelper.getSoftCardColor(primary),
      lightBackground: AppThemeHelper.getLightBackground(primary),
      onPrimary: AppThemeHelper.getThemeTextColor(primary),
      chipSelected: primary.withValues(alpha: 0.22),
      tooltipBackground: AppThemeHelper.getTooltipBackground(primary),
      themeKey: key,
    );
  }

  factory AppThemePalette.defaults() => AppThemePalette.fromSettings(null);
}

/// Backend'den tema çeker ve dinleyicilere bildirir.
class CafeThemeController extends ChangeNotifier {
  CafeThemeController._();

  static final CafeThemeController instance = CafeThemeController._();

  AppThemePalette _palette = AppThemePalette.defaults();
  String? _logoUrl;
  DateTime? _sonYukleme;
  static const _onbellekSuresi = Duration(seconds: 15);

  AppThemePalette get palette => _palette;
  String? get logoUrl => _logoUrl;

  /// Public API ile güncel tema yüklenir (giriş gerektirmez).
  Future<void> refresh({bool zorla = false}) async {
    if (!zorla &&
        _sonYukleme != null &&
        DateTime.now().difference(_sonYukleme!) < _onbellekSuresi) {
      return;
    }

    try {
      final bilgi = await ApiService.getPublicCafeInfo();
      applySettings(bilgi.settings);
    } catch (_) {
      _palette = AppThemePalette.defaults();
      notifyListeners();
    }
  }

  /// Ayar kaydı sonrası anında günceller.
  void applySettings(CafeSettingsModel ayar) {
    _palette = AppThemePalette.fromSettings(ayar);
    _logoUrl = ayar.logoUrl;
    _sonYukleme = DateTime.now();
    notifyListeners();
  }

  void setLogoUrl(String? url) {
    _logoUrl = url;
    notifyListeners();
  }
}
