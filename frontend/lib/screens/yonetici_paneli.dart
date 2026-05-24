// Flutter arayüz bileşenlerini kullanmak için import ediyoruz.
import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/cafe_theme_controller.dart';
import '../utils/app_theme_helper.dart';
import '../widgets/app_themed_widgets.dart';
import '../widgets/sifremi_degistir_dialog.dart';

// Giriş yapan kullanıcı modelini kullanıyoruz.
import '../models/app_user_model.dart';
import '../models/aktif_siparis_model.dart';
import '../models/customer_feedback_model.dart';
import '../models/paket_siparis_model.dart';
import '../models/report_summary_model.dart';

// Giriş ekranına geri dönebilmek için import ediyoruz.
import 'giris_ekrani.dart';

import 'menu_yonetim_ekrani.dart';
import 'masa_yonetimi_ekrani.dart';
import 'gelir_gider_ekrani.dart';
import 'malzeme_alim_ekrani.dart';
import 'garson_prim_yonetimi_ekrani.dart';
import 'kullanici_yonetimi_ekrani.dart';
import 'raporlama_ekrani.dart';
import 'qr_menu_yonetimi_ekrani.dart';
import 'musteri_geri_bildirim_ekrani.dart';
import 'kafe_bilgi_yonetimi_ekrani.dart';

// Yönetici girişinden sonra açılan ana paneldir.
class YoneticiPaneli extends StatefulWidget {
  final AppUserModel kullanici;

  const YoneticiPaneli({
    super.key,
    required this.kullanici,
  });

  @override
  State<YoneticiPaneli> createState() => _YoneticiPaneliState();
}

class _YoneticiPaneliState extends State<YoneticiPaneli> {
  // Yönetici paneli üst özet kartları için veriler burada yüklenir.
  bool _ozetYukleniyor = true;
  double _gunlukSatis = 0;
  int _aktifSiparis = 0;
  int _paketSiparis = 0;
  int _bekleyenGeriBildirim = 0;

  @override
  void initState() {
    super.initState();
    _ozetVerileriniYukle();
  }

  // Günlük satış ve aktif sipariş bilgileri mevcut API verilerinden hesaplanır.
  Future<void> _ozetVerileriniYukle() async {
    setState(() => _ozetYukleniyor = true);

    try {
      final sonuclar = await Future.wait([
        ApiService.getReportSummary(period: 'daily'),
        ApiService.getActiveOrders(),
        ApiService.getActivePackageOrders(),
        ApiService.getCustomerFeedback(status: 'all'),
      ]);

      if (!mounted) return;

      final gunlukOzet = sonuclar[0] as ReportSummaryModel;
      final aktifMasalar = sonuclar[1] as List<AktifSiparisModel>;
      final aktifPaketler = sonuclar[2] as List<PaketSiparisModel>;
      final geriBildirimler = sonuclar[3] as List<CustomerFeedbackModel>;

      setState(() {
        _gunlukSatis = gunlukOzet.totalSales;
        _aktifSiparis = aktifMasalar.length + aktifPaketler.length;
        _paketSiparis = aktifPaketler.length;
        _bekleyenGeriBildirim =
            geriBildirimler.where((k) => k.status == 'bekliyor').length;
        _ozetYukleniyor = false;
      });
    } catch (_) {
      if (!mounted) return;
      // Veri gelmezse kartlarda güvenli varsayılan değerler gösterilir.
      setState(() {
        _gunlukSatis = 0;
        _aktifSiparis = 0;
        _paketSiparis = 0;
        _bekleyenGeriBildirim = 0;
        _ozetYukleniyor = false;
      });
    }
  }

  String _gunlukSatisMetni() {
    if (_ozetYukleniyor) return '...';
    return '${_gunlukSatis.toStringAsFixed(2)} TL';
  }

  String _sayiMetni(int deger) {
    if (_ozetYukleniyor) return '...';
    return '$deger';
  }

  void cikisYap(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const GirisEkrani(),
      ),
      (route) => false,
    );
  }

  List<Widget> _headerAksiyonlari(BuildContext context, AppThemePalette tema) {
    return [
      OutlinedButton.icon(
        onPressed: () {
          CafeThemeController.instance.refresh(zorla: true);
          _ozetVerileriniYukle();
        },
        icon: const Icon(Icons.refresh, size: 18),
        label: const Text('Yenile'),
      ),
      OutlinedButton.icon(
        onPressed: () {
          sifremiDegistirDialogGoster(
            context,
            userId: widget.kullanici.id,
          );
        },
        icon: const Icon(Icons.lock_reset, size: 18),
        label: const Text('Şifremi Değiştir'),
      ),
      FilledButton.icon(
        style: themedElevatedButtonStyle(tema),
        onPressed: () => cikisYap(context),
        icon: const Icon(Icons.logout, size: 18),
        label: const Text('Çıkış Yap'),
      ),
    ];
  }

  // Modül kartları bölümü — kompakt 2 sütun grid.
  Widget _modulGrid(List<Widget> kartlar) {
    return KompaktIslemGrid(kartlar: kartlar);
  }

  @override
  Widget build(BuildContext context) {
    return CafeThemeLoader(
      builder: (context, theme) {
        return Scaffold(
          backgroundColor: AppThemeHelper.sayfaZemin,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Sayfa başlığı/header bölümü — logo ve tema rengi uygulama alanı.
                      PanelBaslikAlani(
                        baslik: 'Yönetici Paneli',
                        altBaslik:
                            'Giriş yapan: ${widget.kullanici.fullName}\nMenü, masa, gelir-gider, kullanıcı ve raporlama işlemleri bu panel üzerinden yönetilir.',
                        tema: theme,
                        logoUrl: CafeThemeController.instance.logoUrl,
                        aksiyonlar: _headerAksiyonlari(context, theme),
                      ),
                      const SizedBox(height: 20),

                      // Özet kartları bölümü.
                      OzetKartSatiri(
                        kartlar: [
                          OzetKart(
                            baslik: 'Günlük Satış',
                            deger: _gunlukSatisMetni(),
                            ikon: Icons.trending_up,
                            tema: theme,
                          ),
                          OzetKart(
                            baslik: 'Aktif Siparişler',
                            deger: _sayiMetni(_aktifSiparis),
                            ikon: Icons.receipt_long,
                            tema: theme,
                          ),
                          OzetKart(
                            baslik: 'Paket Siparişler',
                            deger: _sayiMetni(_paketSiparis),
                            ikon: Icons.delivery_dining,
                            tema: theme,
                          ),
                          OzetKart(
                            baslik: 'Bekleyen Geri Bildirimler',
                            deger: _sayiMetni(_bekleyenGeriBildirim),
                            ikon: Icons.rate_review,
                            tema: theme,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      Text(
                        'Yönetim Modülleri',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: theme.primary,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Modül kartları — mevcut Navigator.push yönlendirmeleri korunur.
                      _modulGrid([
                        YoneticiIslemKarti(
                          icon: Icons.people,
                          baslik: 'Kullanıcı Yönetimi',
                          aciklama:
                              'Garson, yönetici ve kurye hesaplarını, rollerini ve şifrelerini yönet.',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const KullaniciYonetimiEkrani(),
                              ),
                            );
                          },
                        ),
                        YoneticiIslemKarti(
                          icon: Icons.restaurant_menu,
                          baslik: 'Menü Yönetimi',
                          aciklama:
                              'Ürünleri, kategorileri ve menü içeriklerini yönet.',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const MenuYonetimEkrani(),
                              ),
                            );
                          },
                        ),
                        YoneticiIslemKarti(
                          icon: Icons.table_restaurant,
                          baslik: 'Masa Yönetimi',
                          aciklama:
                              'Masa ekle, sil ve masaları bölümlere göre yönet.',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const MasaYonetimiEkrani(),
                              ),
                            );
                          },
                        ),
                        YoneticiIslemKarti(
                          icon: Icons.qr_code_2,
                          baslik: 'QR Menü Yönetimi',
                          aciklama:
                              'Müşteri QR menü linki ve QR kodu oluştur.',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const QrMenuYonetimiEkrani(),
                              ),
                            );
                          },
                        ),
                        YoneticiIslemKarti(
                          icon: Icons.store,
                          baslik: 'Kafe Bilgi Yönetimi',
                          aciklama:
                              'Açık saatleri, yol tarifi, etkinlikleri ve kafe bilgilerini yönet.',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const KafeBilgiYonetimiEkrani(),
                              ),
                            );
                          },
                        ),
                        YoneticiIslemKarti(
                          icon: Icons.rate_review,
                          baslik: 'Müşteri Geri Bildirimleri',
                          aciklama:
                              'QR menüden gelen istek, şikayet ve önerileri görüntüle.',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const MusteriGeriBildirimEkrani(),
                              ),
                            );
                          },
                       
                        ),
                        YoneticiIslemKarti(
                          icon: Icons.inventory_2,
                          baslik: 'Malzeme Alım İşlemleri',
                          aciklama:
                              'Alınan malzemeleri adet ve fiyat bilgisiyle takip et.',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const MalzemeAlimEkrani(),
                              ),
                            );
                          },
                        ),
                        YoneticiIslemKarti(
                          icon: Icons.account_balance_wallet,
                          baslik: 'Gelir-Gider İşlemleri',
                          aciklama:
                              'Toplam gelir, gider ve net kazanç bilgilerini görüntüle.',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const GelirGiderEkrani(),
                              ),
                            );
                          },
                        ),
                        YoneticiIslemKarti(
                          icon: Icons.bar_chart,
                          baslik: 'Raporlama',
                          aciklama:
                              'Satış raporlarını, en çok satılan ürünleri ve kapanan hesapları görüntüle.',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const RaporlamaEkrani(),
                              ),
                            );
                          },
                        ),
                        YoneticiIslemKarti(
                          icon: Icons.emoji_events,
                          baslik: 'Personel Prim Yönetimi',
                          aciklama:
                              'Garson ve kurye prim ayarlarını, raporları ve ürün bonuslarını yönet.',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const GarsonPrimYonetimiEkrani(),
                              ),
                            );
                          },
                        ),
                        YoneticiIslemKarti(
                          icon: Icons.palette_outlined,
                          baslik: 'Tema ve Menü Görünümü',
                          aciklama:
                              'Tema rengi, logo ve QR menü görünüm ayarlarını düzenle.',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const KafeBilgiYonetimiEkrani(),
                              ),
                            );
                          },
                        ),
                      ]),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Yönetici panelindeki ortak işlem kartı — ModernIslemKarti sarmalayıcısı.
class YoneticiIslemKarti extends StatelessWidget {
  final IconData icon;
  final String baslik;
  final String aciklama;
  final VoidCallback onTap;

  const YoneticiIslemKarti({
    super.key,
    required this.icon,
    required this.baslik,
    required this.aciklama,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ModernIslemKarti(
      ikon: icon,
      baslik: baslik,
      aciklama: aciklama,
      onTap: onTap,
    );
  }
}
