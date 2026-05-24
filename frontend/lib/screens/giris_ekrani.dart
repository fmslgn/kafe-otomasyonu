// Flutter arayüz bileşenlerini kullanmak için import ediyoruz.
import 'package:flutter/material.dart';

// Backend API servis dosyasını kullanıyoruz.
import '../services/api_service.dart';
import '../services/cafe_theme_controller.dart';
import '../utils/app_theme_helper.dart';

// Ortak geri bildirim ve validasyon widget'ları.
import '../widgets/app_feedback_widgets.dart';
import '../widgets/app_themed_widgets.dart';
import '../widgets/cafe_logo_widget.dart';

// Garson paneli ekranını kullanıyoruz.
import 'garson_paneli.dart';

// Yönetici paneli ekranını kullanıyoruz.
import 'yonetici_paneli.dart';

// Kurye paneli ekranını kullanıyoruz.
import 'kurye_paneli.dart';

// Kullanıcı giriş ekranıdır.
// Garson, yönetici ve kurye girişlerini ayrı butonlar halinde gösterir.
class GirisEkrani extends StatefulWidget {
  const GirisEkrani({super.key});

  @override
  State<GirisEkrani> createState() => _GirisEkraniState();
}

class _GirisEkraniState extends State<GirisEkrani> with CafeThemeScreenMixin {
  final TextEditingController kullaniciAdiController = TextEditingController();
  final TextEditingController sifreController = TextEditingController();

  String? seciliRol;
  bool sifreGizliMi = true;
  bool yukleniyorMu = false;

  // Alan bazlı validasyon hataları.
  String? kullaniciAdiHatasi;
  String? sifreHatasi;

  // Giriş kartı içinde gösterilen genel hata mesajı.
  String? girisHatasi;

  @override
  void initState() {
    super.initState();
    initCafeThemeListener();
    // Çıkış sonrası veya uygulama açılışında güncel tema rengi alınır.
    CafeThemeController.instance.refresh(zorla: true);
    kullaniciAdiController.addListener(_kullaniciAdiYazildi);
    sifreController.addListener(_sifreYazildi);
  }

  @override
  void dispose() {
    disposeCafeThemeListener();
    kullaniciAdiController.removeListener(_kullaniciAdiYazildi);
    sifreController.removeListener(_sifreYazildi);
    kullaniciAdiController.dispose();
    sifreController.dispose();
    super.dispose();
  }

  void _kullaniciAdiYazildi() {
    if (kullaniciAdiHatasi != null) {
      setState(() => kullaniciAdiHatasi = null);
    }
  }

  void _sifreYazildi() {
    if (sifreHatasi != null) {
      setState(() => sifreHatasi = null);
    }
  }

  String rolBasligi(String role) {
    if (role == 'yonetici') return 'Yönetici';
    if (role == 'kurye') return 'Kurye';
    return 'Garson';
  }

  IconData rolIkonu(String role) {
    if (role == 'yonetici') return Icons.admin_panel_settings;
    if (role == 'kurye') return Icons.delivery_dining;
    return Icons.room_service;
  }

  void roleGeriDon() {
    setState(() {
      seciliRol = null;
      kullaniciAdiController.clear();
      sifreController.clear();
      kullaniciAdiHatasi = null;
      sifreHatasi = null;
      girisHatasi = null;
    });
  }

  // Boş alan kontrolü; hata varsa API isteği gönderilmez.
  bool _formuDogrula() {
    final kullaniciAdi = kullaniciAdiController.text.trim();
    final sifre = sifreController.text.trim();

    String? kHata;
    String? sHata;

    if (kullaniciAdi.isEmpty) {
      kHata = 'Kullanıcı adı boş bırakılamaz.';
    }
    if (sifre.isEmpty) {
      sHata = 'Şifre boş bırakılamaz.';
    }

    setState(() {
      kullaniciAdiHatasi = kHata;
      sifreHatasi = sHata;
      girisHatasi = null;
    });

    return kHata == null && sHata == null;
  }

  Future<void> girisYap() async {
    if (seciliRol == null) {
      showAppSnackBar(context, 'Lütfen giriş türü seçiniz.', hata: true);
      return;
    }

    if (!_formuDogrula()) {
      return;
    }

    final kullaniciAdi = kullaniciAdiController.text.trim();
    final sifre = sifreController.text.trim();

    setState(() {
      yukleniyorMu = true;
      girisHatasi = null;
    });

    try {
      final kullanici = await ApiService.login(
        username: kullaniciAdi,
        password: sifre,
      );

      if (!mounted) return;

      if (kullanici.role != seciliRol) {
        setState(() {
          girisHatasi =
              'Bu kullanıcı ${rolBasligi(seciliRol!)} girişi için yetkili değil.';
        });
        return;
      }

      if (kullanici.role == 'garson') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => GarsonPaneli(kullanici: kullanici),
          ),
        );
      } else if (kullanici.role == 'yonetici') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => YoneticiPaneli(kullanici: kullanici),
          ),
        );
      } else if (kullanici.role == 'kurye') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => KuryePaneli(kullanici: kullanici),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;

      setState(() {
        girisHatasi = appGirisHataMesaji(error);
      });
    } finally {
      if (mounted) {
        setState(() => yukleniyorMu = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return themedRoot(
      Scaffold(
        backgroundColor: AppThemeHelper.sayfaZemin,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: seciliRol == null ? _rolSecimAlani() : _girisFormuAlani(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _anaKart({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      decoration: stitchKartDekorasyonu(),
      child: child,
    );
  }

  // Logo/kafe ikonu — yuvarlak soft kutu içinde dengeli boyut.
  Widget _logoAlani() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: theme.primary.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: theme.lightBackground),
      ),
      child: CafeLogoWidget(
        logoUrl: cafeLogoUrl,
        size: 72,
        iconColor: theme.primary,
        backgroundColor: theme.softCard,
      ),
    );
  }

  Widget _rolSecimAlani() {
    return Column(
      children: [
        // Sayfa başlığı — logo ve tema rengi uygulama alanı.
        _logoAlani(),
        const SizedBox(height: 16),
        Text(
          'Kafe Otomasyonu',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: theme.primary,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'İşlemlerinize devam etmek için giriş türünüzü seçin.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
        const SizedBox(height: 24),
        _anaKart(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Masa siparişleri, paket servis, menü yönetimi, raporlama ve personel işlemlerini tek sistem üzerinden yönetin.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.black87, height: 1.45),
              ),
              const SizedBox(height: 18),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ozellikChip('Hızlı Sipariş'),
                  _ozellikChip('QR Menü'),
                  _ozellikChip('Paket Servis'),
                  _ozellikChip('Raporlama'),
                ],
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  final genis = constraints.maxWidth >= 680;
                  if (genis) {
                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: _rolKarti('garson', esitYukseklik: true)),
                          const SizedBox(width: 12),
                          Expanded(child: _rolKarti('yonetici', esitYukseklik: true)),
                          const SizedBox(width: 12),
                          Expanded(child: _rolKarti('kurye', esitYukseklik: true)),
                        ],
                      ),
                    );
                  }
                  return Column(
                    children: [
                      _rolKarti('garson'),
                      const SizedBox(height: 12),
                      _rolKarti('yonetici'),
                      const SizedBox(height: 12),
                      _rolKarti('kurye'),
                    ],
                  );
                },
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.softCard,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: theme.primary, size: 20),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Test kullanıcıları: garson / yonetici / kurye',
                        style: TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Yetkili personel kullanımı içindir.',
          style: TextStyle(fontSize: 13, color: Colors.black45),
        ),
      ],
    );
  }

  Widget _ozellikChip(String metin) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: theme.softCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.lightBackground),
      ),
      child: Text(
        metin,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: theme.primary,
        ),
      ),
    );
  }

  Widget _rolKarti(String role, {bool esitYukseklik = false}) {
    final basliklar = {
      'garson': 'Garson Girişi',
      'yonetici': 'Yönetici Girişi',
      'kurye': 'Kurye Girişi',
    };
    final aciklamalar = {
      'garson': 'Masa siparişi, hesap ve paket sipariş işlemleri',
      'yonetici': 'Menü, kullanıcı, raporlama ve sistem yönetimi',
      'kurye': 'Atanan paket siparişleri görüntüleme ve teslim etme',
    };

    return AppTooltip(
      message: '${basliklar[role]} ile devam et',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          hoverColor: theme.softCard,
          splashColor: theme.primary.withValues(alpha: 0.08),
          onTap: () {
            setState(() {
              seciliRol = role;
              kullaniciAdiController.clear();
              sifreController.clear();
              kullaniciAdiHatasi = null;
              sifreHatasi = null;
              girisHatasi = null;
            });
          },
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.primary.withValues(alpha: 0.14),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.softCard,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(rolIkonu(role), size: 28, color: theme.primary),
                    ),
                    const Spacer(),
                    Icon(Icons.arrow_forward, color: theme.primary, size: 20),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  basliklar[role]!,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: theme.primary,
                  ),
                ),
                const SizedBox(height: 6),
                if (esitYukseklik)
                  Expanded(
                    child: Text(
                      aciklamalar[role]!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                        height: 1.35,
                      ),
                    ),
                  )
                else
                  Text(
                    aciklamalar[role]!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                      height: 1.35,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _girisFormuAlani() {
    return _anaKart(
      child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _logoAlani(),
        const SizedBox(height: 16),
        Text(
          '${rolBasligi(seciliRol!)} Girişi',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: theme.primary,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '${rolBasligi(seciliRol!)} hesabınızla giriş yapın.',
          style: const TextStyle(fontSize: 16, color: Colors.black54),
        ),
        const SizedBox(height: 22),

        if (girisHatasi != null) AppLoginErrorBanner(mesaj: girisHatasi!),

        TextField(
          controller: kullaniciAdiController,
          decoration: InputDecoration(
            labelText: 'Kullanıcı Adı',
            prefixIcon: Icon(Icons.person, color: theme.primary),
            errorText: null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: theme.primary, width: 2),
            ),
          ),
          onSubmitted: (_) => girisYap(),
        ),
        if (kullaniciAdiHatasi != null)
          AppValidationBubble(message: kullaniciAdiHatasi!),

        const SizedBox(height: 14),

        TextField(
          controller: sifreController,
          obscureText: sifreGizliMi,
          decoration: InputDecoration(
            labelText: 'Şifre',
            prefixIcon: Icon(Icons.lock, color: theme.primary),
            suffixIcon: IconButton(
              tooltip: sifreGizliMi ? 'Şifreyi göster' : 'Şifreyi gizle',
              icon: Icon(
                sifreGizliMi ? Icons.visibility : Icons.visibility_off,
                color: theme.primary,
              ),
              onPressed: () {
                setState(() => sifreGizliMi = !sifreGizliMi);
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: theme.primary, width: 2),
            ),
          ),
          onSubmitted: (_) => girisYap(),
        ),
        if (sifreHatasi != null) AppValidationBubble(message: sifreHatasi!),

        const SizedBox(height: 22),

        AppTooltip(
          message: 'Giriş yap',
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              icon: yukleniyorMu
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.onPrimary,
                      ),
                    )
                  : const Icon(Icons.login),
              label: Text(
                yukleniyorMu ? 'Giriş Yapılıyor...' : 'Giriş Yap',
              ),
              style: themedElevatedButtonStyle(theme),
              onPressed: yukleniyorMu ? null : girisYap,
            ),
          ),
        ),

        const SizedBox(height: 14),

        AppTooltip(
          message: 'Giriş türü seçimine dön',
          child: TextButton.icon(
            icon: Icon(Icons.arrow_back, color: theme.primary),
            label: Text(
              'Giriş Türünü Değiştir',
              style: TextStyle(color: theme.primary),
            ),
            onPressed: roleGeriDon,
          ),
        ),

        const SizedBox(height: 10),
        Text(
          'Test kullanıcısı: ${seciliRol == 'yonetici' ? 'yonetici' : seciliRol == 'kurye' ? 'kurye' : 'garson'}',
          style: const TextStyle(color: Colors.black45),
        ),
      ],
      ),
    );
  }
}
