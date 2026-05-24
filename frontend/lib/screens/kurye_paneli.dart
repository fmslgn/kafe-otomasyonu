// Flutter arayüz bileşenlerini kullanmak için import ediyoruz.
import 'package:flutter/material.dart';

import '../models/app_user_model.dart';
import '../models/paket_siparis_model.dart';
import '../services/api_service.dart';
import '../utils/app_theme_helper.dart';
import '../widgets/app_feedback_widgets.dart';
import '../widgets/app_themed_widgets.dart';
import '../widgets/garson_islem_karti.dart';
import '../widgets/sifremi_degistir_dialog.dart';

import 'giris_ekrani.dart';
import 'kurye_primlerim_ekrani.dart';

// Kurye girişinden sonra açılan paneldir.
class KuryePaneli extends StatefulWidget {
  final AppUserModel kullanici;

  const KuryePaneli({
    super.key,
    required this.kullanici,
  });

  @override
  State<KuryePaneli> createState() => _KuryePaneliState();
}

class _KuryePaneliState extends State<KuryePaneli> with CafeThemeScreenMixin {
  bool? kuryePrimSistemiAcik;
  bool primAyariYukleniyor = false;
  final ScrollController _scrollController = ScrollController();

  // Kurye paketleri yükleme durumu — FutureBuilder yerine açık state.
  bool _yukleniyor = true;
  Object? _yuklemeHatasi;
  List<PaketSiparisModel> _paketler = [];

  @override
  void initState() {
    super.initState();
    initCafeThemeListener();
    _paketleriYukle();
    primAyariniYukle();
  }

  @override
  void dispose() {
    disposeCafeThemeListener();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> primAyariniYukle() async {
    if (primAyariYukleniyor) return;
    setState(() => primAyariYukleniyor = true);
    try {
      final settings = await ApiService.getCommissionSettings();
      if (!mounted) return;
      setState(() {
        kuryePrimSistemiAcik = settings.courierCommissionEnabled;
        primAyariYukleniyor = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        kuryePrimSistemiAcik = false;
        primAyariYukleniyor = false;
      });
    }
  }

  // Kurye paketleri yükleme — hata yakalama ve ekranda gösterme.
  Future<void> _paketleriYukle() async {
    debugPrint('Kurye paneli paket yükleme başladı');

    if (!mounted) return;
    setState(() {
      _yukleniyor = true;
      _yuklemeHatasi = null;
    });

    try {
      final paketler = await ApiService.getCourierPackageOrders(
        courierId: widget.kullanici.id,
      );

      debugPrint('Kurye paneli paket sayısı: ${paketler.length}');

      if (!mounted) return;
      setState(() {
        _paketler = paketler;
        _yukleniyor = false;
        _yuklemeHatasi = null;
      });
    } catch (e) {
      debugPrint('Kurye paneli hata: $e');

      if (!mounted) return;
      setState(() {
        _paketler = [];
        _yukleniyor = false;
        _yuklemeHatasi = e;
      });
    }
  }

  // Null veya boş metinler için güvenli gösterim metni.
  String _guvenliMetin(String? deger, {String varsayilan = 'Belirtilmemiş'}) {
    if (deger == null) return varsayilan;
    final metin = deger.trim();
    return metin.isEmpty ? varsayilan : metin;
  }

  void ekraniYenile() {
    _paketleriYukle();
    primAyariniYukle();
  }

  void cikisYap() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const GirisEkrani(),
      ),
      (route) => false,
    );
  }

  Future<void> teslimatDurumuGuncelle({
    required PaketSiparisModel siparis,
    required String deliveryStatus,
  }) async {
    try {
      final response = await ApiService.updatePackageDeliveryStatus(
        packageOrderId: siparis.id,
        deliveryStatus: deliveryStatus,
      );

      if (!mounted) return;

      showAppPopup(
        context,
        message: response['message']?.toString() ??
            'Teslimat durumu başarıyla güncellendi.',
        type: AppPopupType.success,
      );

      ekraniYenile();
    } catch (error) {
      if (!mounted) return;

      showAppPopup(
        context,
        message:
            'Teslimat durumu güncellenemedi: ${ApiService.kullaniciHataMesaji(error)}',
        type: AppPopupType.error,
      );
    }
  }

  String teslimatDurumuYazisi(String? status) {
    final deger = status?.trim() ?? '';
    if (deger.isEmpty) return 'Belirtilmemiş';
    if (deger == 'kuryeye_atandi') return 'Kuryeye Atandı';
    if (deger == 'yolda') return 'Yolda';
    if (deger == 'teslim_edildi') return 'Teslim Edildi';
    if (deger == 'iptal') return 'İptal';
    return 'Bekliyor';
  }

  String tarihFormatla(String? tarih) {
    final ham = tarih?.trim() ?? '';
    if (ham.isEmpty) return 'Tarih yok';

    final dateTime = DateTime.tryParse(ham);
    if (dateTime == null) {
      if (ham.contains('T')) return ham.split('T').first;
      return ham;
    }

    final yerel = dateTime.toLocal();
    final gun = yerel.day.toString().padLeft(2, '0');
    final ay = yerel.month.toString().padLeft(2, '0');
    final yil = yerel.year.toString();
    return '$gun.$ay.$yil';
  }

  String saatFormatla(String? tarih) {
    final ham = tarih?.trim() ?? '';
    if (ham.isEmpty) return 'Tarih yok';

    final dateTime = DateTime.tryParse(ham);
    if (dateTime == null) return '-';

    final yerel = dateTime.toLocal();
    final saat = yerel.hour.toString().padLeft(2, '0');
    final dakika = yerel.minute.toString().padLeft(2, '0');
    return '$saat:$dakika';
  }

  Color _teslimatDurumRengi(String? status) {
    final deger = status?.trim() ?? '';
    if (deger == 'teslim_edildi') return Colors.green.shade700;
    if (deger == 'yolda') return Colors.blue.shade700;
    if (deger == 'iptal') return Colors.red.shade700;
    if (deger == 'kuryeye_atandi') return theme.primary;
    return Colors.orange.shade800;
  }

  // Paket listesinden özet istatistikleri hesaplar.
  Map<String, String> _ozetDegerleri(List<PaketSiparisModel> paketler) {
    final bugun = DateTime.now();
    final yolda = paketler.where((p) => p.deliveryStatus == 'yolda').length;
    final teslim = paketler
        .where((p) => p.deliveryStatus == 'teslim_edildi')
        .length;
    final bugunkuTeslim = paketler.where((p) {
      if (p.deliveryStatus != 'teslim_edildi') return false;
      final dt = DateTime.tryParse(p.createdAt);
      if (dt == null) return false;
      final yerel = dt.toLocal();
      return yerel.year == bugun.year &&
          yerel.month == bugun.month &&
          yerel.day == bugun.day;
    }).length;

    return {
      'atanan': paketler.length.toString(),
      'yolda': yolda.toString(),
      'teslim': teslim.toString(),
      'bugun': bugunkuTeslim.toString(),
    };
  }

  List<Widget> _headerAksiyonlari() {
    return [
      OutlinedButton.icon(
        onPressed: () {
          ekraniYenile();
          primAyariniYukle();
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
        style: themedElevatedButtonStyle(theme),
        onPressed: cikisYap,
        icon: const Icon(Icons.logout, size: 18),
        label: const Text('Çıkış Yap'),
      ),
    ];
  }

  void _listeyeKaydir() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent * 0.35,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    }
  }

  // İşlem kartları bölümü — kompakt 2 sütun grid.
  Widget _islemKartlari(bool primAcik) {
    final kartlar = <Widget>[
      GarsonIslemKarti(
        icon: Icons.inbox,
        baslik: 'Atanan Paketler',
        aciklama: 'Size atanan paket siparişlerini görüntüle ve yenile.',
        onTap: () {
          ekraniYenile();
          _listeyeKaydir();
        },
      ),
      GarsonIslemKarti(
        icon: Icons.local_shipping,
        baslik: 'Teslimat Durumu',
        aciklama: 'Paketlerin teslimat durumunu güncelle.',
        onTap: _listeyeKaydir,
      ),
      if (primAcik)
        GarsonIslemKarti(
          icon: Icons.payments,
          baslik: 'Kendi Primlerim',
          aciklama: 'Teslim ettiğin paketlere göre primini gör.',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => KuryePrimlerimEkrani(
                  kullanici: widget.kullanici,
                ),
              ),
            );
          },
        ),
      GarsonIslemKarti(
        icon: Icons.lock_reset,
        baslik: 'Şifremi Değiştir',
        aciklama: 'Kendi şifreni değiştir.',
        onTap: () {
          sifremiDegistirDialogGoster(
            context,
            userId: widget.kullanici.id,
          );
        },
      ),
    ];

    return KompaktIslemGrid(kartlar: kartlar);
  }

  @override
  Widget build(BuildContext context) {
    return themedRoot(
      Scaffold(
        backgroundColor: AppThemeHelper.sayfaZemin,
        body: SafeArea(
          child: Builder(
            builder: (context) {
              // Build sırasında beklenmeyen hata — boş ekran yerine kritik hata göster.
              try {
                return _panelGovdesi();
              } catch (e, stack) {
                debugPrint('Kurye paneli build hatası: $e');
                debugPrint('$stack');
                return _kritikHataEkrani(e);
              }
            },
          ),
        ),
      ),
    );
  }

  // Kurye paneli ana gövdesi — header her zaman; liste alanı duruma göre.
  Widget _panelGovdesi() {
    final primAcik = kuryePrimSistemiAcik == true;
    final ozet = _yukleniyor || _yuklemeHatasi != null
        ? {
            'atanan': '—',
            'yolda': '—',
            'teslim': '—',
            'bugun': '—',
          }
        : _ozetDegerleri(_paketler);

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverToBoxAdapter(child: _headerBolumu(primAcik, ozet)),
        // Loading / error / empty — SliverFillRemaining kullanılmaz (layout çökmesini önler).
        if (_yukleniyor)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960, minHeight: 260),
                  child: const AppLoadingView(mesaj: 'Paketler yükleniyor...'),
                ),
              ),
            ),
          )
        else if (_yuklemeHatasi != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: _kuryePaketHataKarti(_yuklemeHatasi!),
                ),
              ),
            ),
          )
        else if (_paketler.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960, minHeight: 260),
                  // Boş paket durumu.
                  child: const AppEmptyView(
                    ikon: Icons.delivery_dining,
                    baslik: 'Size atanmış aktif paket sipariş bulunmuyor.',
                    aciklama:
                        'Yeni paket atandığında burada görüntülenecektir.',
                  ),
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  try {
                    return _paketKarti(_paketler[index]);
                  } catch (e) {
                    debugPrint('Paket kartı çizilirken hata: $e');
                    return _bozukPaketKarti(_paketler[index]);
                  }
                },
                childCount: _paketler.length,
              ),
            ),
          ),
      ],
    );
  }

  // Header — Kurye Paneli başlığı ve aksiyonlar (hata durumunda da görünür).
  Widget _headerBolumu(bool primAcik, Map<String, String> ozet) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PanelBaslikAlani(
                baslik: 'Kurye Paneli',
                altBaslik:
                    'Giriş yapan: ${widget.kullanici.fullName}\nSize atanan aktif paket siparişleri bu ekranda görüntülenir.',
                tema: theme,
                logoUrl: cafeLogoUrl,
                aksiyonlar: _headerAksiyonlari(),
              ),
              const SizedBox(height: 20),
              OzetKartSatiri(
                kartlar: [
                  OzetKart(
                    baslik: 'Atanan Paketler',
                    deger: ozet['atanan'] ?? '0',
                    ikon: Icons.inbox,
                    tema: theme,
                  ),
                  OzetKart(
                    baslik: 'Yolda Olanlar',
                    deger: ozet['yolda'] ?? '0',
                    ikon: Icons.local_shipping,
                    tema: theme,
                  ),
                  OzetKart(
                    baslik: 'Teslim Edilenler',
                    deger: ozet['teslim'] ?? '0',
                    ikon: Icons.check_circle_outline,
                    tema: theme,
                  ),
                  OzetKart(
                    baslik: 'Bugünkü Teslimat',
                    deger: ozet['bugun'] ?? '0',
                    ikon: Icons.today,
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
              _islemKartlari(primAcik),
              const SizedBox(height: 24),
              StitchBolumBasligi(
                baslik: 'Atanan Paket Siparişler',
                ikon: Icons.delivery_dining,
                temaRengi: theme.primary,
                altBaslik:
                    'Yolda, teslim ve detay işlemlerini kart üzerinden yapın.',
              ),
              const SizedBox(height: 14),
            ],
          ),
        ),
      ),
    );
  }

  // Hata yakalama — paket listesi yüklenemediğinde görünür kart.
  Widget _kuryePaketHataKarti(Object hata) {
    return AppErrorView(
      baslik: 'Kurye paketleri yüklenemedi',
      aciklama: ApiService.kullaniciHataMesaji(hata),
      hataDetayi: hata.toString(),
      tekrarDene: _paketleriYukle,
    );
  }

  Widget _kritikHataEkrani(Object hata) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: PanelBaslikAlani(
            baslik: 'Kurye Paneli',
            altBaslik: 'Giriş yapan: ${widget.kullanici.fullName}',
            tema: theme,
            logoUrl: cafeLogoUrl,
            aksiyonlar: _headerAksiyonlari(),
          ),
        ),
        Expanded(
          child: _kuryePaketHataKarti(hata),
        ),
      ],
    );
  }

  Widget _bozukPaketKarti(PaketSiparisModel siparis) {
    return StitchKart(
      margin: const EdgeInsets.only(bottom: 14),
      kenarlikRengi: theme.primary,
      padding: const EdgeInsets.all(16),
      child: Text(
        'Paket #${siparis.id} gösterilemedi.',
        style: const TextStyle(color: Colors.red),
      ),
    );
  }

  // Teslimat kartı — IntrinsicHeight kullanılmaz (SliverList ile uyumlu).
  Widget _paketKarti(PaketSiparisModel siparis) {
    final musteriAdi = _guvenliMetin(
      siparis.customerName,
      varsayilan: 'Belirtilmemiş',
    );

    final telefon = _guvenliMetin(siparis.customerPhone);

    final adres = _guvenliMetin(siparis.address);

    final not = _guvenliMetin(siparis.note, varsayilan: 'Not yok');

    final teslimEdildi = siparis.deliveryStatus == 'teslim_edildi';
    final durumRengi = _teslimatDurumRengi(siparis.deliveryStatus);

    // Teslimat kartları — sol şerit border; stretch Row kullanılmaz (liste layout hatası önlenir).
    return StitchKart(
      margin: const EdgeInsets.only(bottom: 14),
      kenarlikRengi: theme.primary,
      padding: const EdgeInsets.all(18),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: durumRengi, width: 5),
          ),
        ),
        padding: const EdgeInsets.only(left: 14),
        child: teslimEdildi
            ? _teslimEdildiPaketGovdesi(
                siparis: siparis,
                musteriAdi: musteriAdi,
                durumRengi: durumRengi,
              )
            : _aktifPaketKartGovdesi(
                siparis: siparis,
                musteriAdi: musteriAdi,
                telefon: telefon,
                adres: adres,
                not: not,
                durumRengi: durumRengi,
              ),
      ),
    );
  }

  Widget _teslimEdildiPaketGovdesi({
    required PaketSiparisModel siparis,
    required String musteriAdi,
    required Color durumRengi,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _paketBaslikSatiri(
          siparis: siparis,
          musteriAdi: musteriAdi,
          durumRengi: durumRengi,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Icon(Icons.schedule, size: 16, color: Colors.black45),
            const SizedBox(width: 6),
            Text(
              'Teslimat saati: ${saatFormatla(siparis.createdAt)}',
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _aktifPaketKartGovdesi({
    required PaketSiparisModel siparis,
    required String musteriAdi,
    required String telefon,
    required String adres,
    required String not,
    required Color durumRengi,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final darEkran = constraints.maxWidth < 720;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _paketBaslikSatiri(
              siparis: siparis,
              musteriAdi: musteriAdi,
              durumRengi: durumRengi,
            ),
            const SizedBox(height: 16),
            if (darEkran)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _iletisimAlani(telefon: telefon, adres: adres),
                  const SizedBox(height: 12),
                  _siparisIcerigiAlani(siparis),
                  const SizedBox(height: 12),
                  _musteriNotuAlani(not),
                ],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _iletisimAlani(telefon: telefon, adres: adres),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: _siparisIcerigiAlani(siparis)),
                  const SizedBox(width: 12),
                  Expanded(child: _musteriNotuAlani(not)),
                ],
              ),
            const SizedBox(height: 16),
            _paketAksiyonlari(siparis),
          ],
        );
      },
    );
  }

  Widget _paketBaslikSatiri({
    required PaketSiparisModel siparis,
    required String musteriAdi,
    required Color durumRengi,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Paket Sipariş #${siparis.id}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
              ),
              Text(
                musteriAdi,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.primary,
                ),
              ),
              StitchEtiket(
                metin: teslimatDurumuYazisi(siparis.deliveryStatus),
                renk: durumRengi,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        FiyatEtiketi(
          fiyat: siparis.totalPrice.isFinite ? siparis.totalPrice : 0,
          temaRengi: theme.primary,
          buyuk: true,
        ),
      ],
    );
  }

  Widget _iletisimAlani({
    required String telefon,
    required String adres,
  }) {
    return StitchBilgiIzgarasi(
      sutunSayisi: 1,
      ogeler: [
        (etiket: 'Telefon', deger: telefon, vurgu: theme.primary),
        (etiket: 'Adres', deger: adres, vurgu: null),
      ],
    );
  }

  // Sipariş içeriği bilgi kutusu.
  Widget _siparisIcerigiAlani(PaketSiparisModel siparis) {
    return StitchBilgiIzgarasi(
      sutunSayisi: 1,
      ogeler: [
        (
          etiket: 'Sipariş İçeriği',
          deger: '${siparis.itemCount} ürün',
          vurgu: theme.primary,
        ),
        (
          etiket: 'Siparişi alan',
          deger: _guvenliMetin(siparis.waiterName),
          vurgu: null,
        ),
        (
          etiket: 'Tarih',
          deger: tarihFormatla(siparis.createdAt),
          vurgu: null,
        ),
      ],
    );
  }

  // Müşteri notu bilgi kutusu.
  Widget _musteriNotuAlani(String not) {
    return StitchBilgiIzgarasi(
      sutunSayisi: 1,
      ogeler: [
        (etiket: 'Müşteri Notu', deger: '"$not"', vurgu: null),
      ],
    );
  }

  // Paket detay dialogu — Stitch kart stili.
  void _paketDetayDialogGoster({
    required PaketSiparisModel siparis,
    required String musteriAdi,
    required String telefon,
    required String adres,
    required String not,
  }) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final ekranYuksekligi = MediaQuery.sizeOf(dialogContext).height;
        final toplamTutar =
            siparis.totalPrice.isFinite ? siparis.totalPrice : 0.0;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 520,
              maxHeight: ekranYuksekligi * 0.8,
            ),
            child: StitchKart(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
              kenarlikRengi: theme.primary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Paket detayları taşma olmaması için kaydırılabilir dialog içinde gösterilir.
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          StitchBolumBasligi(
                            baslik: 'Paket Sipariş #${siparis.id}',
                            altBaslik: musteriAdi,
                            ikon: Icons.info_outline,
                            temaRengi: theme.primary,
                          ),
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: FiyatEtiketi(
                              fiyat: toplamTutar,
                              temaRengi: theme.primary,
                              buyuk: true,
                            ),
                          ),
                          const SizedBox(height: 12),
                          StitchBilgiIzgarasi(
                            ogeler: [
                              (etiket: 'Telefon', deger: telefon, vurgu: null),
                              (etiket: 'Adres', deger: adres, vurgu: null),
                              (etiket: 'Not', deger: not, vurgu: null),
                              (
                                etiket: 'Siparişi alan',
                                deger: _guvenliMetin(siparis.waiterName),
                                vurgu: null,
                              ),
                              (
                                etiket: 'Ürün adedi',
                                deger: '${siparis.itemCount}',
                                vurgu: theme.primary,
                              ),
                              (
                                etiket: 'Tarih',
                                deger: tarihFormatla(siparis.createdAt),
                                vurgu: null,
                              ),
                              (
                                etiket: 'Teslimat durumu',
                                deger: teslimatDurumuYazisi(
                                  siparis.deliveryStatus,
                                ),
                                vurgu: _teslimatDurumRengi(
                                  siparis.deliveryStatus,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      style: themedElevatedButtonStyle(theme),
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Kapat'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Teslimat durum güncelleme aksiyonları — Yolda, Teslim, Detay.
  Widget _paketAksiyonlari(PaketSiparisModel siparis) {
    final musteriAdi = _guvenliMetin(siparis.customerName);
    final telefon = _guvenliMetin(siparis.customerPhone);
    final adres = _guvenliMetin(siparis.address);
    final not = _guvenliMetin(siparis.note, varsayilan: 'Not yok');

    return LayoutBuilder(
      builder: (context, constraints) {
        final darEkran = constraints.maxWidth < 520;

        final yoldaButonu = AppTooltip(
          message: 'Teslimat durumunu yolda olarak işaretle',
          child: FilledButton.icon(
            style: themedElevatedButtonStyle(theme),
            icon: const Icon(Icons.local_shipping_outlined, size: 18),
            label: const Text('Yolda'),
            onPressed: siparis.deliveryStatus == 'yolda'
                ? null
                : () {
                    teslimatDurumuGuncelle(
                      siparis: siparis,
                      deliveryStatus: 'yolda',
                    );
                  },
          ),
        );

        final teslimButonu = AppTooltip(
          message: 'Paketi teslim edildi olarak işaretle',
          child: FilledButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: const Text('Teslim Edildi'),
            onPressed: () {
              teslimatDurumuGuncelle(
                siparis: siparis,
                deliveryStatus: 'teslim_edildi',
              );
            },
          ),
        );

        final detayButonu = AppTooltip(
          message: 'Sipariş detaylarını görüntüle',
          child: OutlinedButton.icon(
            icon: const Icon(Icons.info_outline, size: 18),
            label: const Text('Detay Gör'),
            onPressed: () {
              _paketDetayDialogGoster(
                siparis: siparis,
                musteriAdi: musteriAdi,
                telefon: telefon,
                adres: adres,
                not: not,
              );
            },
          ),
        );

        if (darEkran) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (siparis.deliveryStatus != 'yolda') ...[
                yoldaButonu,
                const SizedBox(height: 8),
              ],
              teslimButonu,
              const SizedBox(height: 8),
              detayButonu,
            ],
          );
        }

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.end,
          children: [
            if (siparis.deliveryStatus != 'yolda') yoldaButonu,
            teslimButonu,
            detayButonu,
          ],
        );
      },
    );
  }
}
