// Flutter arayüz bileşenlerini kullanmak için import ediyoruz.
import 'package:flutter/material.dart';

// Kullanıcı modelini kullanıyoruz.
// Kurye seçme penceresinde aktif kuryeleri listelemek için kullanılır.
import '../models/app_user_model.dart';

// Paket sipariş modelini kullanıyoruz.
import '../models/paket_siparis_model.dart';

// Backend API servis dosyasını kullanıyoruz.
import '../services/api_service.dart';
import '../utils/app_theme_helper.dart';

import '../widgets/app_feedback_widgets.dart';
import '../widgets/app_themed_widgets.dart';

// Paket siparişlerin listelendiği ekrandır.
// Garson veya yönetici bu ekranda paket siparişleri görüntüler,
// paket siparişe kurye atar, siparişi tamamlar veya iptal eder.
class PaketSiparisListesiEkrani extends StatefulWidget {
  // Constructor yapısıdır.
  const PaketSiparisListesiEkrani({super.key});

  @override
  State<PaketSiparisListesiEkrani> createState() =>
      _PaketSiparisListesiEkraniState();
}

// Paket sipariş listesi ekranının State sınıfıdır.
class _PaketSiparisListesiEkraniState extends State<PaketSiparisListesiEkrani>
    with CafeThemeScreenMixin {
  // Backend'den gelecek paket sipariş listesini tutar.
  late Future<List<PaketSiparisModel>> paketSiparislerFuture;

  // Seçili durum filtresidir.
  // all, aktif, kapandi, iptal değerlerini alabilir.
  String seciliDurum = 'aktif';

  @override
  void initState() {
    super.initState();
    initCafeThemeListener();

    // Sayfa açıldığında aktif paket siparişler yüklenir.
    verileriYukle();
  }

  @override
  void dispose() {
    disposeCafeThemeListener();
    super.dispose();
  }

  List<Widget> _ustAksiyonlar() {
    return [
      IconButton(
        icon: const Icon(Icons.refresh),
        tooltip: 'Yenile',
        onPressed: ekraniYenile,
      ),
    ];
  }

  // Paket siparişleri backend'den yükler.
  void verileriYukle() {
    paketSiparislerFuture = ApiService.getPackageOrders(
      status: seciliDurum,
    );
  }

  // Ekranı yeniler.
  void ekraniYenile() {
    setState(() {
      verileriYukle();
    });
  }

  // Durum filtresini değiştirir.
  void durumDegistir(String yeniDurum) {
    setState(() {
      seciliDurum = yeniDurum;
      verileriYukle();
    });
  }

  // Paket siparişe kurye atama penceresini açar.
  Future<void> kuryeAtaDialogu(PaketSiparisModel siparis) async {
    try {
      // Aktif kuryeler backend API'den çekilir.
      final List<AppUserModel> kuryeler = await ApiService.getCouriers();

      if (!mounted) return;

      // Kurye yoksa uyarı verilir.
      if (kuryeler.isEmpty) {
        showAppPopup(
          context,
          message: 'Aktif kurye bulunamadı.',
          type: AppPopupType.warning,
        );
        return;
      }

      // Kurye seçim dialogu — Stitch kart stili.
      showDialog(
        context: context,
        builder: (dialogContext) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: StitchKart(
                padding: const EdgeInsets.all(22),
                kenarlikRengi: theme.primary,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    StitchBolumBasligi(
                      baslik: 'Kurye Ata',
                      altBaslik:
                          'Paket Sipariş #${siparis.id} için kurye seçiniz.',
                      ikon: Icons.delivery_dining,
                      temaRengi: theme.primary,
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          children: kuryeler.map((kurye) {
                            final seciliMi = siparis.courierId == kurye.id;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () async {
                                    Navigator.pop(dialogContext);
                                    await kuryeAta(
                                      siparis: siparis,
                                      courierId: kurye.id,
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(14),
                                  child: Ink(
                                    decoration: BoxDecoration(
                                      color: seciliMi
                                          ? theme.primary
                                              .withValues(alpha: 0.08)
                                          : Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: seciliMi
                                            ? theme.primary
                                                .withValues(alpha: 0.35)
                                            : Colors.black12,
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: theme.softCard,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Icon(
                                            Icons.delivery_dining,
                                            color: theme.primary,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                kurye.fullName,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                ),
                                              ),
                                              Text(
                                                'Kullanıcı: ${kurye.username}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (seciliMi)
                                          Icon(
                                            Icons.check_circle,
                                            color: theme.primary,
                                          )
                                        else
                                          Icon(
                                            Icons.arrow_forward_ios,
                                            size: 16,
                                            color: theme.primary
                                                .withValues(alpha: 0.6),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                        },
                        child: const Text('Vazgeç'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    } catch (error) {
      if (!mounted) return;

      showAppPopup(
        context,
        message:
            'Kuryeler getirilemedi: ${ApiService.kullaniciHataMesaji(error)}',
        type: AppPopupType.error,
      );
    }
  }

  // Seçilen kuryeyi paket siparişe atar.
  Future<void> kuryeAta({
    required PaketSiparisModel siparis,
    required int courierId,
  }) async {
    try {
      final response = await ApiService.assignCourierToPackageOrder(
        packageOrderId: siparis.id,
        courierId: courierId,
      );

      if (!mounted) return;

      showAppPopup(
        context,
        message: response['message']?.toString() ??
            'Paket sipariş kuryeye atandı.',
        type: AppPopupType.success,
      );

      ekraniYenile();
    } catch (error) {
      if (!mounted) return;

      showAppPopup(
        context,
        message: 'Kurye atanamadı: ${ApiService.kullaniciHataMesaji(error)}',
        type: AppPopupType.error,
      );
    }
  }

  // Paket siparişi tamamlar.
  Future<void> paketSiparisiTamamla(PaketSiparisModel siparis) async {
    try {
      final response = await ApiService.closePackageOrder(
        packageOrderId: siparis.id,
      );

      if (!mounted) return;

      showAppPopup(
        context,
        message:
            response['message']?.toString() ?? 'Paket sipariş tamamlandı.',
        type: AppPopupType.success,
      );

      ekraniYenile();
    } catch (error) {
      if (!mounted) return;

      showAppPopup(
        context,
        message:
            'Paket sipariş tamamlanamadı: ${ApiService.kullaniciHataMesaji(error)}',
        type: AppPopupType.error,
      );
    }
  }

  // Paket siparişi iptal eder.
  Future<void> paketSiparisiIptalEt(PaketSiparisModel siparis) async {
    try {
      final response = await ApiService.cancelPackageOrder(
        packageOrderId: siparis.id,
      );

      if (!mounted) return;

      showAppPopup(
        context,
        message:
            response['message']?.toString() ?? 'Paket sipariş iptal edildi.',
        type: AppPopupType.success,
      );

      ekraniYenile();
    } catch (error) {
      if (!mounted) return;

      showAppPopup(
        context,
        message:
            'Paket sipariş iptal edilemedi: ${ApiService.kullaniciHataMesaji(error)}',
        type: AppPopupType.error,
      );
    }
  }

  // Sipariş durumunu Türkçe gösterir.
  String durumYazisi(String status) {
    if (status == 'kapandi') {
      return 'Tamamlandı';
    }

    if (status == 'iptal') {
      return 'İptal';
    }

    return 'Aktif';
  }

  // Filtre başlığını Türkçe gösterir.
  String filtreBasligi(String status) {
    if (status == 'all') {
      return 'Tüm';
    }

    return durumYazisi(status);
  }

  // Teslimat durumunu Türkçe gösterir.
  String teslimatDurumuYazisi(String status) {
    if (status == 'kuryeye_atandi') {
      return 'Kuryeye Atandı';
    }

    if (status == 'yolda') {
      return 'Yolda';
    }

    if (status == 'teslim_edildi') {
      return 'Teslim Edildi';
    }

    if (status == 'iptal') {
      return 'İptal';
    }

    return 'Bekliyor';
  }

  // Tarihi düzgün formatta gösterir.
  String tarihFormatla(String tarih) {
    try {
      final dateTime = DateTime.parse(tarih).toLocal();

      final gun = dateTime.day.toString().padLeft(2, '0');
      final ay = dateTime.month.toString().padLeft(2, '0');
      final yil = dateTime.year.toString();

      return '$gun.$ay.$yil';
    } catch (_) {
      if (tarih.contains('T')) {
        return tarih.split('T').first;
      }

      return tarih;
    }
  }

  // Durum rengine karar verir.
  Color durumRengi(String status) {
    if (status == 'kapandi') {
      return Colors.green;
    }

    if (status == 'iptal') {
      return Colors.red;
    }

    return Colors.orange;
  }

  // Teslimat durum rengine karar verir.
  Color teslimatDurumRengi(String status) {
    if (status == 'teslim_edildi') {
      return Colors.green;
    }

    if (status == 'yolda') {
      return Colors.orange;
    }

    if (status == 'iptal') {
      return Colors.red;
    }

    return Colors.brown;
  }

  Widget _ozetKartlari(List<PaketSiparisModel> siparisler) {
    final toplamTutar = siparisler.fold<double>(
      0,
      (sum, s) => sum + s.totalPrice,
    );
    final urunAdedi = siparisler.fold<int>(
      0,
      (sum, s) => sum + s.itemCount,
    );

    return OzetKartSatiri(
      kartlar: [
        OzetKart(
          baslik: 'Listelenen Sipariş',
          deger: '${siparisler.length}',
          ikon: Icons.shopping_bag_outlined,
          tema: theme,
          altMetin: filtreBasligi(seciliDurum),
        ),
        OzetKart(
          baslik: 'Toplam Tutar',
          deger: '${toplamTutar.toStringAsFixed(2)} TL',
          ikon: Icons.payments_outlined,
          tema: theme,
        ),
        OzetKart(
          baslik: 'Ürün Adedi',
          deger: '$urunAdedi',
          ikon: Icons.inventory_2_outlined,
          tema: theme,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return themedRoot(
      Scaffold(
        backgroundColor: AppThemeHelper.sayfaZemin,
        body: SafeArea(
          child: FutureBuilder<List<PaketSiparisModel>>(
            future: paketSiparislerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const AppLoadingView(
                  mesaj: 'Paket siparişler yükleniyor...',
                );
              }

              if (snapshot.hasError) {
                return AppErrorView(
                  hataDetayi: snapshot.error.toString(),
                  tekrarDene: ekraniYenile,
                );
              }

              final siparisler = snapshot.data ?? [];

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        PanelBaslikAlani(
                          baslik: 'Paket Sipariş Listesi',
                          altBaslik:
                              'Paket siparişleri görüntüleyin, kurye atayın, tamamlayın veya iptal edin.',
                          tema: theme,
                          logoUrl: cafeLogoUrl,
                          aksiyonlar: _ustAksiyonlar(),
                        ),
                        const SizedBox(height: 20),
                        if (siparisler.isNotEmpty) ...[
                          _ozetKartlari(siparisler),
                          const SizedBox(height: 20),
                        ],
                        StitchKart(
                          kenarlikRengi: theme.primary,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              StitchBolumBasligi(
                                baslik: 'Durum Filtresi',
                                ikon: Icons.filter_list,
                                temaRengi: theme.primary,
                              ),
                              const SizedBox(height: 12),
                              _durumFiltreleri(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (siparisler.isEmpty)
                          AppEmptyView(
                            ikon: Icons.shopping_bag_outlined,
                            baslik: seciliDurum == 'aktif'
                                ? 'Aktif paket sipariş bulunmuyor.'
                                : 'Paket sipariş bulunmuyor.',
                            aciklama:
                                'Yeni paket sipariş oluşturulduğunda burada listelenir.',
                          )
                        else
                          ...siparisler.map(_paketSiparisKarti),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _durumFiltreleri() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _durumButonu('Tümü', 'all'),
          const SizedBox(width: 8),
          _durumButonu('Aktif', 'aktif'),
          const SizedBox(width: 8),
          _durumButonu('Tamamlandı', 'kapandi'),
          const SizedBox(width: 8),
          _durumButonu('İptal', 'iptal'),
        ],
      ),
    );
  }

  Widget _durumButonu(String baslik, String deger) {
    final seciliMi = seciliDurum == deger;

    final tooltipMesaj = switch (deger) {
      'aktif' => 'Aktif paket siparişleri göster',
      'kapandi' => 'Tamamlanan paket siparişleri göster',
      'iptal' => 'İptal edilen paket siparişleri göster',
      _ => '$baslik paket siparişlerini göster',
    };

    return AppTooltip(
      message: tooltipMesaj,
      child: StitchFiltreChip(
        etiket: baslik,
        secili: seciliMi,
        temaRengi: theme.primary,
        onTap: () {
          durumDegistir(deger);
        },
      ),
    );
  }

  // Paket sipariş kartı — bilgi ızgarası ve aksiyon butonları.
  Widget _paketSiparisKarti(PaketSiparisModel siparis) {
    final musteriAdi = siparis.customerName?.trim().isNotEmpty == true
        ? siparis.customerName!
        : 'Müşteri adı yok';

    final telefon = siparis.customerPhone?.trim().isNotEmpty == true
        ? siparis.customerPhone!
        : 'Telefon yok';

    final adres = siparis.address?.trim().isNotEmpty == true
        ? siparis.address!
        : 'Adres yok';

    final not = siparis.note?.trim().isNotEmpty == true
        ? siparis.note!
        : 'Not yok';

    final kuryeAdi = siparis.courierName?.trim().isNotEmpty == true
        ? siparis.courierName!
        : 'Kurye atanmadı';

    return StitchKart(
      margin: const EdgeInsets.only(bottom: 14),
      kenarlikRengi: theme.primary,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final darEkran = constraints.maxWidth < 720;

          final bilgiAlani = Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Paket Sipariş #${siparis.id}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (darEkran)
                      FiyatEtiketi(
                        fiyat: siparis.totalPrice,
                        temaRengi: theme.primary,
                        buyuk: true,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                StitchBilgiIzgarasi(
                  sutunSayisi: darEkran ? 1 : 2,
                  ogeler: [
                    (etiket: 'Müşteri', deger: musteriAdi, vurgu: null),
                    (etiket: 'Telefon', deger: telefon, vurgu: null),
                    (etiket: 'Adres', deger: adres, vurgu: null),
                    (etiket: 'Not', deger: not, vurgu: null),
                    (
                      etiket: 'Siparişi alan',
                      deger: siparis.waiterName ?? '-',
                      vurgu: null,
                    ),
                    (etiket: 'Kurye', deger: kuryeAdi, vurgu: theme.primary),
                    (
                      etiket: 'Ürün adedi',
                      deger: '${siparis.itemCount}',
                      vurgu: null,
                    ),
                    (
                      etiket: 'Tarih',
                      deger: tarihFormatla(siparis.createdAt),
                      vurgu: null,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    StitchEtiket(
                      metin: durumYazisi(siparis.status),
                      renk: durumRengi(siparis.status),
                    ),
                    StitchEtiket(
                      metin: teslimatDurumuYazisi(siparis.deliveryStatus),
                      renk: teslimatDurumRengi(siparis.deliveryStatus),
                    ),
                  ],
                ),
              ],
            ),
          );

          final aksiyonAlani = Column(
            crossAxisAlignment: darEkran
                ? CrossAxisAlignment.stretch
                : CrossAxisAlignment.end,
            children: [
              if (!darEkran)
                FiyatEtiketi(
                  fiyat: siparis.totalPrice,
                  temaRengi: theme.primary,
                  buyuk: true,
                ),
              if (siparis.status == 'aktif') ...[
                if (!darEkran) const SizedBox(height: 12),
                AppTooltip(
                  message: siparis.courierId == null
                      ? 'Pakete kurye ata'
                      : 'Kurye değiştir',
                  child: FilledButton.icon(
                    style: themedElevatedButtonStyle(theme),
                    icon: const Icon(Icons.delivery_dining),
                    label: Text(
                      siparis.courierId == null
                          ? 'Kurye Ata'
                          : 'Kurye Değiştir',
                    ),
                    onPressed: () {
                      kuryeAtaDialogu(siparis);
                    },
                  ),
                ),
                const SizedBox(height: 8),
                AppTooltip(
                  message: 'Paket siparişi tamamla',
                  child: FilledButton.icon(
                    style: themedElevatedButtonStyle(theme),
                    icon: const Icon(Icons.check),
                    label: const Text('Tamamla'),
                    onPressed: () {
                      paketSiparisiTamamla(siparis);
                    },
                  ),
                ),
                const SizedBox(height: 8),
                AppTooltip(
                  message: 'Paket siparişi iptal et',
                  child: OutlinedButton.icon(
                    onPressed: () {
                      paketSiparisiIptalEt(siparis);
                    },
                    icon: const Icon(Icons.close),
                    label: const Text('İptal'),
                  ),
                ),
              ],
            ],
          );

          if (darEkran) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.softCard,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.delivery_dining,
                        size: 32,
                        color: theme.primary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    bilgiAlani,
                  ],
                ),
                const SizedBox(height: 14),
                aksiyonAlani,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.softCard,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.delivery_dining,
                  size: 32,
                  color: theme.primary,
                ),
              ),
              const SizedBox(width: 18),
              bilgiAlani,
              const SizedBox(width: 18),
              aksiyonAlani,
            ],
          );
        },
      ),
    );
  }
}