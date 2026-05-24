// Flutter arayüz bileşenlerini kullanmak için import ediyoruz.
import 'package:flutter/material.dart';

import 'app_themed_widgets.dart';

// Uygulama genelinde kullanılan ortak geri bildirim widget'larıdır.
// Yükleme, hata, boş veri, tooltip ve validasyon görünümlerini sağlar.

const Color _varsayilanTooltipArkaPlan = Color(0xFF4E342E);

/// Ortak tooltip tasarımı (web: hover, mobil: uzun basma).
class AppTooltip extends StatelessWidget {
  const AppTooltip({
    super.key,
    required this.message,
    required this.child,
    this.waitDuration = const Duration(milliseconds: 350),
  });

  final String message;
  final Widget child;
  final Duration waitDuration;

  @override
  Widget build(BuildContext context) {
    final tooltipRenk =
        CafeThemeScope.maybeOf(context)?.tooltipBackground ??
            _varsayilanTooltipArkaPlan;

    return Tooltip(
      message: message,
      waitDuration: waitDuration,
      showDuration: const Duration(seconds: 3),
      decoration: BoxDecoration(
        color: tooltipRenk,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      textStyle: const TextStyle(
        color: Colors.white,
        fontSize: 13,
        height: 1.3,
      ),
      child: child,
    );
  }
}

/// Form alanı altında gösterilen validasyon uyarı baloncuğu.
class AppValidationBubble extends StatelessWidget {
  const AppValidationBubble({
    super.key,
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3F0),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: Colors.red.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: Colors.red.shade900,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Giriş kartı içinde gösterilen tasarımlı hata kutusu.
class AppLoginErrorBanner extends StatelessWidget {
  const AppLoginErrorBanner({
    super.key,
    required this.mesaj,
  });

  final String mesaj;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0EB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              mesaj,
              style: TextStyle(
                fontSize: 14,
                color: Colors.red.shade900,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Üst bildirim türleri (kafe temasına uygun popup).
enum AppPopupType {
  success,
  error,
  warning,
  info,
}

// Aynı anda tek popup göstermek için aktif overlay kaydı.
OverlayEntry? _aktifPopupOverlay;

/// Ekranın üst kısmında kısa süreli kafe temalı bildirim gösterir.
void showAppPopup(
  BuildContext context, {
  required String message,
  AppPopupType type = AppPopupType.info,
  Duration duration = const Duration(seconds: 3),
  Color? temaRengi,
}) {
  // Önceki popup varsa kaldırılır; üst üste birikme olmaz.
  _aktifPopupOverlay?.remove();
  _aktifPopupOverlay = null;

  final overlay = Overlay.of(context, rootOverlay: true);
  if (overlay == null) return;

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (overlayContext) {
      final topPadding = MediaQuery.of(overlayContext).padding.top;
      final primary =
          temaRengi ?? CafeThemeScope.maybeOf(overlayContext)?.primary;
      final renkler = _popupRenkleri(type, primary: primary);

      return Positioned(
        top: topPadding + 16,
        left: 24,
        right: 24,
        child: Material(
          color: Colors.transparent,
          child: SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: renkler.arkaPlan,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.22),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(renkler.ikon, color: renkler.yazi, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            message,
                            style: TextStyle(
                              color: renkler.yazi,
                              fontSize: 14,
                              height: 1.35,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );

  _aktifPopupOverlay = entry;
  overlay.insert(entry);

  Future.delayed(duration, () {
    if (_aktifPopupOverlay == entry) {
      entry.remove();
      _aktifPopupOverlay = null;
    }
  });
}

class _PopupRenkSeti {
  const _PopupRenkSeti({
    required this.arkaPlan,
    required this.yazi,
    required this.ikon,
  });

  final Color arkaPlan;
  final Color yazi;
  final IconData ikon;
}

_PopupRenkSeti _popupRenkleri(AppPopupType type, {Color? primary}) {
  final vurgu = primary ?? const Color(0xFF795548);
  final vurguKoyu = Color.alphaBlend(Colors.black.withValues(alpha: 0.25), vurgu);

  switch (type) {
    case AppPopupType.success:
      return _PopupRenkSeti(
        arkaPlan: vurguKoyu,
        yazi: Colors.white,
        ikon: Icons.check_circle_outline,
      );
    case AppPopupType.error:
      return const _PopupRenkSeti(
        arkaPlan: Color(0xFF8D2B2B),
        yazi: Colors.white,
        ikon: Icons.error_outline,
      );
    case AppPopupType.warning:
      return const _PopupRenkSeti(
        arkaPlan: Color(0xFFFFF3E0),
        yazi: Color(0xFF5D4037),
        ikon: Icons.warning_amber_rounded,
      );
    case AppPopupType.info:
      return _PopupRenkSeti(
        arkaPlan: vurguKoyu,
        yazi: Colors.white,
        ikon: Icons.info_outline,
      );
  }
}

/// Geriye dönük uyumluluk: SnackBar yerine üst popup kullanır.
void showAppSnackBar(
  BuildContext context,
  String mesaj, {
  bool hata = false,
}) {
  showAppPopup(
    context,
    message: mesaj,
    type: hata ? AppPopupType.error : AppPopupType.success,
  );
}

/// Giriş ekranı için kullanıcı dostu hata metni üretir.
String appGirisHataMesaji(Object error) {
  final ham = error.toString().toLowerCase();

  if (ham.contains('socket') ||
      ham.contains('connection') ||
      ham.contains('failed host') ||
      ham.contains('network') ||
      ham.contains('bağlantı')) {
    return 'Backend bağlantısı kurulamadı. Sunucunun çalıştığından emin olun.';
  }

  if (ham.contains('401') ||
      ham.contains('yetkisiz') ||
      ham.contains('unauthorized') ||
      ham.contains('şifre') ||
      ham.contains('password') ||
      ham.contains('kullanıcı adı')) {
    return 'Giriş yapılamadı. Kullanıcı adı veya şifre hatalı.';
  }

  return appKullaniciHataMesaji(error);
}

/// Veri yüklenirken gösterilen ortak yükleme görünümüdür.
class AppLoadingView extends StatelessWidget {
  const AppLoadingView({
    super.key,
    this.mesaj = 'Veriler yükleniyor...',
    this.kompakt = false,
  });

  final String mesaj;
  final bool kompakt;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(kompakt ? 16 : 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.brown),
            SizedBox(height: kompakt ? 10 : 18),
            Text(
              mesaj,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: kompakt ? 14 : 16,
                color: Colors.brown.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Hata durumunda gösterilen ortak hata görünümüdür.
class AppErrorView extends StatelessWidget {
  const AppErrorView({
    super.key,
    this.baslik = 'Bir sorun oluştu',
    this.aciklama = 'İşlem tamamlanamadı. Backend bağlantısını kontrol edin.',

    this.hataDetayi,
    this.tekrarDene,
    this.kompakt = false,
  });

  final String baslik;
  final String aciklama;
  final String? hataDetayi;
  final VoidCallback? tekrarDene;
  final bool kompakt;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(kompakt ? 12 : 28),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: kompakt ? 320 : 420),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 56,
                    color: Colors.red.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    baslik,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    aciklama,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  if (hataDetayi != null && hataDetayi!.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      _kisaltHataDetayi(hataDetayi!),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                  if (tekrarDene != null) ...[
                    const SizedBox(height: 18),
                    ElevatedButton.icon(
                      onPressed: tekrarDene,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tekrar Dene'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.brown,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _kisaltHataDetayi(String detay) {
    final temiz = detay.replaceFirst('Exception: ', '').trim();
    if (temiz.length <= 160) {
      return temiz;
    }
    return '${temiz.substring(0, 157)}...';
  }
}

/// Boş veri durumunda gösterilen ortak görünümdür.
class AppEmptyView extends StatelessWidget {
  const AppEmptyView({
    super.key,
    required this.baslik,
    this.aciklama,
    this.ikon = Icons.inbox_outlined,
    this.aksiyonMetni,
    this.aksiyon,
    this.kompakt = false,
  });

  final String baslik;
  final String? aciklama;
  final IconData ikon;
  final String? aksiyonMetni;
  final VoidCallback? aksiyon;
  final bool kompakt;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(kompakt ? 12 : 28),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: kompakt ? 320 : 420),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    ikon,
                    size: 56,
                    color: Colors.brown.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    baslik,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown,
                    ),
                  ),
                  if (aciklama != null && aciklama!.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      aciklama!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                  if (aksiyon != null && aksiyonMetni != null) ...[
                    const SizedBox(height: 18),
                    OutlinedButton(
                      onPressed: aksiyon,
                      child: Text(aksiyonMetni!),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bölüm başlığı için ortak widget.
class AppSectionTitle extends StatelessWidget {
  const AppSectionTitle({
    super.key,
    required this.baslik,
    this.altBaslik,
  });

  final String baslik;
  final String? altBaslik;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          baslik,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.brown,
          ),
        ),
        if (altBaslik != null && altBaslik!.trim().isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            altBaslik!,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ],
    );
  }
}

/// Bilgilendirme kartı için ortak widget.
class AppInfoCard extends StatelessWidget {
  const AppInfoCard({
    super.key,
    required this.mesaj,
    this.ikon = Icons.info_outline,
  });

  final String mesaj;
  final IconData ikon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.brown.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.brown.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(ikon, color: Colors.brown.shade400, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              mesaj,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// SnackBar için kullanıcı dostu hata mesajı üretir.
String appKullaniciHataMesaji(Object error) {
  final ham = error.toString().replaceFirst('Exception: ', '').trim();

  if (ham.isEmpty) {
    return 'İşlem başarısız oldu. Backend bağlantısını kontrol edin.';
  }

  if (ham.length > 140) {
    return '${ham.substring(0, 137)}...';
  }

  return ham;
}
