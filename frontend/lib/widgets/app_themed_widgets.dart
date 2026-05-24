// Tüm panellerde ortak tema uygulaması.
import 'package:flutter/material.dart';

import '../services/cafe_theme_controller.dart';
import '../utils/app_theme_helper.dart';
import 'cafe_logo_widget.dart';

/// InheritedWidget ile alt widget'lara tema paleti verir.
class CafeThemeScope extends InheritedWidget {
  const CafeThemeScope({
    super.key,
    required this.palette,
    required super.child,
  });

  final AppThemePalette palette;

  static AppThemePalette of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<CafeThemeScope>();
    return scope?.palette ?? CafeThemeController.instance.palette;
  }

  static AppThemePalette? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<CafeThemeScope>()
        ?.palette;
  }

  @override
  bool updateShouldNotify(CafeThemeScope oldWidget) {
    return oldWidget.palette.primary != palette.primary ||
        oldWidget.palette.themeKey != palette.themeKey;
  }
}

extension CafeThemeContext on BuildContext {
  AppThemePalette get cafeTheme => CafeThemeScope.of(this);
}

/// Ekran açılışında temayı yükler ve güncellemeleri dinler.
/// initState içinde [initCafeThemeListener], dispose içinde [disposeCafeThemeListener] çağırın.
mixin CafeThemeScreenMixin<T extends StatefulWidget> on State<T> {
  AppThemePalette get theme => CafeThemeController.instance.palette;

  String? get cafeLogoUrl => CafeThemeController.instance.logoUrl;

  void _temaDegisti() {
    if (mounted) setState(() {});
  }

  void initCafeThemeListener() {
    CafeThemeController.instance.addListener(_temaDegisti);
    CafeThemeController.instance.refresh();
  }

  void disposeCafeThemeListener() {
    CafeThemeController.instance.removeListener(_temaDegisti);
  }

  /// Alt widget'ların context.cafeTheme kullanması için sarmalayıcı.
  Widget themedRoot(Widget child) {
    return CafeThemeScope(
      palette: theme,
      child: child,
    );
  }
}

/// Tema ile AppBar oluşturur.
PreferredSizeWidget themedAppBar({
  required BuildContext context,
  required String title,
  List<Widget>? actions,
  bool centerTitle = true,
}) {
  final t = context.cafeTheme;
  return AppBar(
    title: Text(title),
    backgroundColor: t.appBarBackground,
    foregroundColor: t.primary,
    centerTitle: centerTitle,
    actions: actions,
  );
}

/// ElevatedButton için tema stili.
ButtonStyle themedElevatedButtonStyle(AppThemePalette t) {
  return ElevatedButton.styleFrom(
    backgroundColor: t.primary,
    foregroundColor: t.onPrimary,
  );
}

/// Seçili chip rengi.
Color themedChipColor(AppThemePalette t, {required bool secili}) {
  return secili ? t.chipSelected : Colors.grey.shade200;
}

/// Stitch tasarımına uygun beyaz kart dekorasyonu.
BoxDecoration stitchKartDekorasyonu({Color? kenarlikRengi}) {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    border: kenarlikRengi != null
        ? Border.all(color: kenarlikRengi.withValues(alpha: 0.15))
        : null,
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.06),
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
    ],
  );
}

/// Panel üst kısmındaki özet istatistik kartı.
class OzetKart extends StatelessWidget {
  const OzetKart({
    super.key,
    required this.baslik,
    required this.deger,
    required this.ikon,
    required this.tema,
    this.altMetin,
  });

  final String baslik;
  final String deger;
  final IconData ikon;
  final AppThemePalette tema;
  final String? altMetin;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: stitchKartDekorasyonu(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: tema.softCard,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(ikon, color: tema.primary, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  baslik,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 3),
                Text(
                  deger,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                    color: tema.primary,
                  ),
                ),
                if (altMetin != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    altMetin!,
                    style: const TextStyle(fontSize: 11, color: Colors.black45),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Özet kartları yatay kaydırmalı satır.
class OzetKartSatiri extends StatelessWidget {
  const OzetKartSatiri({super.key, required this.kartlar});

  final List<Widget> kartlar;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 720) {
          return Row(
            children: [
              for (var i = 0; i < kartlar.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                Expanded(child: kartlar[i]),
              ],
            ],
          );
        }
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var i = 0; i < kartlar.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                SizedBox(width: 200, child: kartlar[i]),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Rapor kartlarında etiket + değer alanı (Stitch bilgi kutusu).
class StitchBilgiKutu extends StatelessWidget {
  const StitchBilgiKutu({
    super.key,
    required this.etiket,
    required this.deger,
    this.vurguRengi,
  });

  final String etiket;
  final String deger;
  final Color? vurguRengi;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            etiket,
            style: const TextStyle(fontSize: 11, color: Colors.black45),
          ),
          const SizedBox(height: 4),
          Text(
            deger,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: vurguRengi ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

/// Stitch rapor kartlarında çoklu bilgi alanı ızgarası.
class StitchBilgiIzgarasi extends StatelessWidget {
  const StitchBilgiIzgarasi({
    super.key,
    required this.ogeler,
    this.sutunSayisi = 2,
  });

  final List<({String etiket, String deger, Color? vurgu})> ogeler;
  final int sutunSayisi;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final kolon = constraints.maxWidth >= 520 ? sutunSayisi : 1;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: ogeler.map((o) {
            final genislik = kolon == 1
                ? constraints.maxWidth
                : (constraints.maxWidth - (kolon - 1) * 10) / kolon;
            return SizedBox(
              width: genislik,
              child: StitchBilgiKutu(
                etiket: o.etiket,
                deger: o.deger,
                vurguRengi: o.vurgu,
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

/// Toplam prim gibi merkezi vurgulu özet kartı.
class StitchVurguKart extends StatelessWidget {
  const StitchVurguKart({
    super.key,
    required this.baslik,
    required this.deger,
    required this.tema,
    this.altSatir,
    this.arkaPlan,
  });

  final String baslik;
  final String deger;
  final AppThemePalette tema;
  final String? altSatir;
  final Color? arkaPlan;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: stitchKartDekorasyonu(kenarlikRengi: tema.primary).copyWith(
        color: arkaPlan ?? tema.softCard.withValues(alpha: 0.45),
      ),
      child: Column(
        children: [
          Text(
            baslik,
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          Text(
            deger,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: tema.primary,
            ),
          ),
          if (altSatir != null) ...[
            const SizedBox(height: 8),
            Text(
              altSatir!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
        ],
      ),
    );
  }
}

/// Panellerde ortak modern işlem kartı — kompakt düzen.
class ModernIslemKarti extends StatelessWidget {
  const ModernIslemKarti({
    super.key,
    required this.ikon,
    required this.baslik,
    required this.aciklama,
    required this.onTap,
    this.aksiyonMetni,
    this.tooltipGoster = false,
  });

  final IconData ikon;
  final String baslik;
  final String aciklama;
  final VoidCallback onTap;
  final String? aksiyonMetni;
  final bool tooltipGoster;

  Widget _kartGovdesi(AppThemePalette tema) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        hoverColor: tema.softCard,
        splashColor: tema.primary.withValues(alpha: 0.08),
        child: Ink(
          decoration: stitchKartDekorasyonu(
            kenarlikRengi: tema.primary.withValues(alpha: 0.08),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: tema.softCard,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(ikon, size: 22, color: tema.primary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          baslik,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          aciklama,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Devam et aksiyonu — buton hissi veren kompakt chip.
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: tema.softCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: tema.primary.withValues(alpha: 0.18),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      aksiyonMetni ?? 'Devam et',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: tema.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward, size: 16, color: tema.primary),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = context.cafeTheme;
    final kart = _kartGovdesi(tema);

    if (!tooltipGoster) return kart;

    return Tooltip(
      message: aciklama,
      waitDuration: const Duration(milliseconds: 600),
      child: kart,
    );
  }
}

/// İşlem/modül kartları için 2 sütunlu kompakt grid.
class KompaktIslemGrid extends StatelessWidget {
  const KompaktIslemGrid({
    super.key,
    required this.kartlar,
    this.genislikEsigi = 680,
  });

  final List<Widget> kartlar;
  final double genislikEsigi;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sutun = constraints.maxWidth >= genislikEsigi ? 2 : 1;
        return GridView.count(
          crossAxisCount: sutun,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: sutun == 2 ? 2.55 : 2.75,
          children: kartlar,
        );
      },
    );
  }
}

/// Yuvarlatılmış modern form alanı dekorasyonu.
InputDecoration stitchInputDekorasyonu({
  String? labelText,
  String? hintText,
  IconData? prefixIcon,
  Color? temaRengi,
  Widget? suffixIcon,
  int maxLines = 1,
}) {
  final odak = temaRengi ?? const Color(0xFF795548);
  return InputDecoration(
    labelText: labelText,
    hintText: hintText,
    prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: odak) : null,
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: odak, width: 2),
    ),
  );
}

/// Tema uyumlu filtre chip'i.
class StitchFiltreChip extends StatelessWidget {
  const StitchFiltreChip({
    super.key,
    required this.etiket,
    required this.secili,
    required this.temaRengi,
    required this.onTap,
  });

  final String etiket;
  final bool secili;
  final Color temaRengi;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: secili
                ? temaRengi.withValues(alpha: 0.15)
                : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: secili
                  ? temaRengi.withValues(alpha: 0.45)
                  : Colors.grey.shade300,
            ),
          ),
          child: Text(
            etiket,
            style: TextStyle(
              fontSize: 13,
              fontWeight: secili ? FontWeight.w600 : FontWeight.w500,
              color: secili ? temaRengi : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}

/// Durum/tür/rol etiketi.
class StitchEtiket extends StatelessWidget {
  const StitchEtiket({
    super.key,
    required this.metin,
    required this.renk,
  });

  final String metin;
  final Color renk;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: renk.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: renk.withValues(alpha: 0.25)),
      ),
      child: Text(
        metin,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: renk,
        ),
      ),
    );
  }
}

/// Bölüm başlığı — ikon ve tema rengi ile.
class StitchBolumBasligi extends StatelessWidget {
  const StitchBolumBasligi({
    super.key,
    required this.baslik,
    this.ikon,
    this.temaRengi,
    this.altBaslik,
  });

  final String baslik;
  final IconData? ikon;
  final Color? temaRengi;
  final String? altBaslik;

  @override
  Widget build(BuildContext context) {
    final renk = temaRengi ?? context.cafeTheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (ikon != null) ...[
              Icon(ikon, color: renk, size: 22),
              const SizedBox(width: 8),
            ],
            Text(
              baslik,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: renk,
              ),
            ),
          ],
        ),
        if (altBaslik != null) ...[
          const SizedBox(height: 4),
          Text(
            altBaslik!,
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ],
      ],
    );
  }
}

/// Beyaz kart sarmalayıcı — Stitch stilinde içerik kutusu.
class StitchKart extends StatelessWidget {
  const StitchKart({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.kenarlikRengi,
    this.margin,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? kenarlikRengi;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: stitchKartDekorasyonu(kenarlikRengi: kenarlikRengi),
      child: child,
    );
  }
}

/// Ürün fiyat etiketi — tema renginde vurgulu.
class FiyatEtiketi extends StatelessWidget {
  const FiyatEtiketi({
    super.key,
    required this.fiyat,
    required this.temaRengi,
    this.buyuk = false,
  });

  final double fiyat;
  final Color temaRengi;
  final bool buyuk;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: buyuk ? 10 : 8,
        vertical: buyuk ? 5 : 4,
      ),
      decoration: BoxDecoration(
        color: temaRengi.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${fiyat.toStringAsFixed(2)} TL',
        style: TextStyle(
          fontSize: buyuk ? 17 : 15,
          fontWeight: FontWeight.bold,
          color: temaRengi,
        ),
      ),
    );
  }
}

/// Panel sayfa başlığı — logo, başlık ve kullanıcı bilgisi alanı.
class PanelBaslikAlani extends StatelessWidget {
  const PanelBaslikAlani({
    super.key,
    required this.baslik,
    required this.altBaslik,
    required this.tema,
    this.logoUrl,
    this.aksiyonlar,
  });

  final String baslik;
  final String altBaslik;
  final AppThemePalette tema;
  final String? logoUrl;
  final List<Widget>? aksiyonlar;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: stitchKartDekorasyonu(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CafeLogoWidget(
                logoUrl: logoUrl,
                size: 64,
                iconColor: tema.primary,
                backgroundColor: tema.softCard,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      baslik,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: tema.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      altBaslik,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black54,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              if (aksiyonlar != null) ...[
                const SizedBox(width: 8),
                Wrap(spacing: 8, runSpacing: 8, children: aksiyonlar!),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Tema yükleyerek builder çalıştırır (Stateless ekranlar için).
class CafeThemeLoader extends StatefulWidget {
  const CafeThemeLoader({
    super.key,
    required this.builder,
  });

  final Widget Function(BuildContext context, AppThemePalette theme) builder;

  @override
  State<CafeThemeLoader> createState() => _CafeThemeLoaderState();
}

class _CafeThemeLoaderState extends State<CafeThemeLoader> {
  @override
  void initState() {
    super.initState();
    CafeThemeController.instance.addListener(_yenile);
    CafeThemeController.instance.refresh();
  }

  @override
  void dispose() {
    CafeThemeController.instance.removeListener(_yenile);
    super.dispose();
  }

  void _yenile() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final palette = CafeThemeController.instance.palette;
    return CafeThemeScope(
      palette: palette,
      child: widget.builder(context, palette),
    );
  }
}

/// Ortak sayfa iskeleti — AppBar + krem zemin.
class ThemedScaffold extends StatelessWidget {
  const ThemedScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.centerTitle = true,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool centerTitle;

  @override
  Widget build(BuildContext context) {
    return CafeThemeLoader(
      builder: (context, theme) {
        return Scaffold(
          appBar: themedAppBar(
            context: context,
            title: title,
            actions: actions,
            centerTitle: centerTitle,
          ),
          backgroundColor: AppThemeHelper.sayfaZemin,
          floatingActionButton: floatingActionButton,
          body: body,
        );
      },
    );
  }
}
