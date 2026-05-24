// Flutter arayüz bileşenlerini kullanmak için import ediyoruz.
import 'package:flutter/material.dart';

// Giriş yapan kullanıcı modelini kullanıyoruz.
import '../models/app_user_model.dart';
import '../models/aktif_siparis_model.dart';
import '../models/my_commission_report_model.dart';
import '../models/paket_siparis_model.dart';

// Giriş ekranına geri dönmek için kullanıyoruz.
import 'giris_ekrani.dart';

// Masa seçimi ekranını kullanıyoruz.
import 'masa_secim_ekrani.dart';

// Hesap işlemleri ekranını kullanıyoruz.
import 'hesap_islemleri_ekrani.dart';

// Paket sipariş alma ekranını kullanıyoruz.
import 'paket_siparis_ekrani.dart';

// Paket sipariş listesi ekranını kullanıyoruz.
import 'paket_siparis_listesi_ekrani.dart';

import 'garson_primlerim_ekrani.dart';

import '../services/api_service.dart';
import '../utils/app_theme_helper.dart';
import '../widgets/app_feedback_widgets.dart';
import '../widgets/app_themed_widgets.dart';
import '../widgets/garson_islem_karti.dart';
import '../widgets/sifremi_degistir_dialog.dart';

// Garson girişinden sonra açılan ana paneldir.
class GarsonPaneli extends StatefulWidget {
  // Giriş yapan garson bilgisidir.
  final AppUserModel kullanici;

  const GarsonPaneli({
    super.key,
    required this.kullanici,
  });

  @override
  State<GarsonPaneli> createState() => _GarsonPaneliState();
}

class _GarsonPaneliState extends State<GarsonPaneli> with CafeThemeScreenMixin {
  // Prim sistemi açık mı bilgisi; null iken ayar yükleniyor demektir.
  bool? primSistemiAcik;
  bool primAyariYukleniyor = false;

  // Garson paneli üst özet kartları için veriler burada yüklenir.
  bool _ozetYukleniyor = true;
  int _bugunkuSiparis = 0;
  int _aktifMasalar = 0;
  int _paketSiparis = 0;
  double _toplamSatis = 0;

  @override
  void initState() {
    super.initState();
    initCafeThemeListener();
    primAyariniYukle();
    _ozetVerileriniYukle();
  }

  @override
  void dispose() {
    disposeCafeThemeListener();
    super.dispose();
  }

  // Yönetici panelindeki prim aç/kapa durumunu backend'den çeker.
  Future<void> primAyariniYukle() async {
    if (primAyariYukleniyor) return;

    setState(() {
      primAyariYukleniyor = true;
    });

    try {
      final settings = await ApiService.getCommissionSettings();
      if (!mounted) return;

      setState(() {
        primSistemiAcik = settings.isEnabled;
        primAyariYukleniyor = false;
      });
    } catch (_) {
      if (!mounted) return;

      // Ayar alınamazsa güvenli tarafta kal: prim kartını gösterme.
      setState(() {
        primSistemiAcik = false;
        primAyariYukleniyor = false;
      });
    }
  }

  // Bugünkü sipariş ve satış bilgileri mevcut API verilerinden hesaplanır.
  Future<void> _ozetVerileriniYukle() async {
    setState(() => _ozetYukleniyor = true);

    try {
      final sonuclar = await Future.wait([
        ApiService.getMyCommissionReport(
          userId: widget.kullanici.id,
          period: 'daily',
        ),
        ApiService.getActiveOrders(),
        ApiService.getActivePackageOrders(),
      ]);

      if (!mounted) return;

      final gunlukRapor = sonuclar[0] as MyCommissionReportModel;
      final aktifMasaSiparisleri = sonuclar[1] as List<AktifSiparisModel>;
      final paketler = sonuclar[2] as List<PaketSiparisModel>;

      final garsonunAktifPaketleri = paketler
          .where((p) => p.status == 'aktif' && _buGarsonunPaketi(p))
          .length;

      setState(() {
        _bugunkuSiparis =
            gunlukRapor.closedOrderCount + garsonunAktifPaketleri;
        _aktifMasalar = aktifMasaSiparisleri.length;
        _paketSiparis = garsonunAktifPaketleri;
        _toplamSatis = gunlukRapor.totalSales;
        _ozetYukleniyor = false;
      });
    } catch (_) {
      if (!mounted) return;
      // Veri gelmezse kartlarda güvenli varsayılan değerler gösterilir.
      setState(() {
        _bugunkuSiparis = 0;
        _aktifMasalar = 0;
        _paketSiparis = 0;
        _toplamSatis = 0;
        _ozetYukleniyor = false;
      });
    }
  }

  bool _buGarsonunPaketi(PaketSiparisModel paket) {
    final garsonAdi = (paket.waiterName ?? '').trim().toLowerCase();
    if (garsonAdi.isEmpty) return false;

    final tamAd = widget.kullanici.fullName.trim().toLowerCase();
    final kullaniciAdi = widget.kullanici.username.trim().toLowerCase();

    return garsonAdi == tamAd ||
        garsonAdi == kullaniciAdi ||
        garsonAdi.contains(kullaniciAdi);
  }

  String _sayiMetni(int deger) {
    if (_ozetYukleniyor) return '...';
    return '$deger';
  }

  String _toplamSatisMetni() {
    if (_ozetYukleniyor) return '...';
    return '${_toplamSatis.toStringAsFixed(2)} TL';
  }

  void _paneliYenile() {
    primAyariniYukle();
    _ozetVerileriniYukle();
  }

  // Çıkış yapma işlemidir.
  void cikisYap(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const GirisEkrani(),
      ),
      (route) => false,
    );
  }

  // Panel üst kısmındaki hızlı aksiyon butonları.
  List<Widget> _headerAksiyonlari(BuildContext context) {
    return [
      OutlinedButton.icon(
        onPressed: _paneliYenile,
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
        style: themedElevatedButtonStyle(theme),
        onPressed: () => cikisYap(context),
        icon: const Icon(Icons.logout, size: 18),
        label: const Text('Çıkış Yap'),
      ),
    ];
  }

  // İşlem kartları bölümü — kompakt 2 sütun grid.
  Widget _islemKartlariGrid(List<Widget> kartlar) {
    return KompaktIslemGrid(kartlar: kartlar);
  }

  @override
  Widget build(BuildContext context) {
  // Prim kartı görünürlük kontrolü — sadece sistem açıkken gösterilir.
    final primAcik = primSistemiAcik == true;

    return themedRoot(
      Scaffold(
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
                      baslik: 'Garson Paneli',
                      altBaslik:
                          'Giriş yapan: ${widget.kullanici.fullName}\nMasa siparişi, hesap kapatma ve paket sipariş işlemleri bu panel üzerinden yapılır.',
                      tema: theme,
                      logoUrl: cafeLogoUrl,
                      aksiyonlar: _headerAksiyonlari(context),
                    ),
                    const SizedBox(height: 20),

                    // Özet kartları bölümü.
                    OzetKartSatiri(
                      kartlar: [
                        OzetKart(
                          baslik: 'Bugünkü Siparişler',
                          deger: _sayiMetni(_bugunkuSiparis),
                          ikon: Icons.receipt_long,
                          tema: theme,
                        ),
                        OzetKart(
                          baslik: 'Aktif Masalar',
                          deger: _sayiMetni(_aktifMasalar),
                          ikon: Icons.table_restaurant,
                          tema: theme,
                        ),
                        OzetKart(
                          baslik: 'Paket Siparişler',
                          deger: _sayiMetni(_paketSiparis),
                          ikon: Icons.delivery_dining,
                          tema: theme,
                        ),
                        OzetKart(
                          baslik: 'Toplam Satış',
                          deger: _toplamSatisMetni(),
                          ikon: Icons.payments,
                          tema: theme,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'İşlemler',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.primary,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // İşlem kartları bölümü — mevcut yönlendirmeler korunur.
                    _islemKartlariGrid([
                      GarsonIslemKarti(
                        icon: Icons.table_restaurant,
                        baslik: 'Masa Siparişi Al',
                        aciklama:
                            'Masa seçerek sipariş oluştur, ürün ekle ve masa notu gir.',
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MasaSecimEkrani(
                                kullanici: widget.kullanici,
                              ),
                            ),
                          );
                          if (mounted) _ozetVerileriniYukle();
                        },
                      ),
                      GarsonIslemKarti(
                        icon: Icons.receipt_long,
                        baslik: 'Hesap İşlemleri',
                        aciklama:
                            'Aktif masa hesaplarını görüntüle ve hesabı kapat.',
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const HesapIslemleriEkrani(),
                            ),
                          );
                          if (mounted) _ozetVerileriniYukle();
                        },
                      ),
                      GarsonIslemKarti(
                        icon: Icons.delivery_dining,
                        baslik: 'Paket Sipariş Al',
                        aciklama:
                            'Dışarıdan gelen paket sipariş için müşteri, adres, not ve ürün bilgisi gir.',
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PaketSiparisEkrani(
                                kullanici: widget.kullanici,
                              ),
                            ),
                          );
                          if (mounted) _ozetVerileriniYukle();
                        },
                      ),
                      GarsonIslemKarti(
                        icon: Icons.list_alt,
                        baslik: 'Paket Sipariş Listesi',
                        aciklama:
                            'Aktif, tamamlanan ve iptal edilen paket siparişleri görüntüle.',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const PaketSiparisListesiEkrani(),
                            ),
                          );
                        },
                      ),
                      if (primAcik)
                        GarsonIslemKarti(
                          icon: Icons.payments,
                          baslik: 'Kendi Primlerim',
                          aciklama:
                              'Satış toplamı ve kazandığın primleri görüntüle.',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => GarsonPrimlerimEkrani(
                                  kullanici: widget.kullanici,
                                ),
                              ),
                            );
                          },
                        ),
                      AppTooltip(
                        message: 'Kendi şifreni değiştir',
                        child: GarsonIslemKarti(
                          icon: Icons.lock_reset,
                          baslik: 'Şifremi Değiştir',
                          aciklama:
                              'Hesap şifreni güvenli şekilde güncelle.',
                          onTap: () {
                            sifremiDegistirDialogGoster(
                              context,
                              userId: widget.kullanici.id,
                            );
                          },
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
