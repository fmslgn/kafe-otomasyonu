// Flutter arayüz bileşenlerini kullanmak için import ediyoruz.
import 'package:flutter/material.dart';

import '../models/aktif_siparis_model.dart';
import '../models/app_user_model.dart';
import '../models/masa_model.dart';
import '../services/api_service.dart';
import '../utils/app_theme_helper.dart';
import '../widgets/app_feedback_widgets.dart';
import '../widgets/app_themed_widgets.dart';
import 'siparis_ekrani.dart';

/// Masa listesi ve aktif sipariş özetini birlikte taşır.
class _MasaSecimVerisi {
  const _MasaSecimVerisi({
    required this.masalar,
    required this.aktifSiparisler,
  });

  final List<MasaModel> masalar;
  final Map<int, AktifSiparisModel> aktifSiparisler;
}

// Masa seçim ekranıdır.
class MasaSecimEkrani extends StatefulWidget {
  const MasaSecimEkrani({
    super.key,
    required this.kullanici,
  });

  final AppUserModel kullanici;

  @override
  State<MasaSecimEkrani> createState() => _MasaSecimEkraniState();
}

class _MasaSecimEkraniState extends State<MasaSecimEkrani>
    with CafeThemeScreenMixin {
  late Future<_MasaSecimVerisi> veriFuture;
  String seciliBolum = 'Tümü';
  String seciliDurumFiltre = 'Tümü';

  static const _bolumFiltreleri = [
    'Tümü',
    'Bahçe',
    'İç Alan',
    'Teras',
  ];

  @override
  void initState() {
    super.initState();
    initCafeThemeListener();
    veriFuture = _verileriYukle();
  }

  @override
  void dispose() {
    disposeCafeThemeListener();
    super.dispose();
  }

  Future<_MasaSecimVerisi> _verileriYukle() async {
    final sonuclar = await Future.wait([
      ApiService.getTables(),
      ApiService.getActiveOrders(),
    ]);
    final masalar = sonuclar[0] as List<MasaModel>;
    final aktifListe = sonuclar[1] as List<AktifSiparisModel>;
    final aktifHarita = {
      for (final siparis in aktifListe) siparis.tableNo: siparis,
    };
    return _MasaSecimVerisi(
      masalar: masalar,
      aktifSiparisler: aktifHarita,
    );
  }

  void masalariYenile() {
    setState(() {
      veriFuture = _verileriYukle();
    });
  }

  String durumYazisi(String status) {
    switch (status.toLowerCase()) {
      case 'dolu':
        return 'Dolu';
      case 'rezerve':
        return 'Rezerve';
      default:
        return 'Boş';
    }
  }

  Color durumRengi(String status) {
    switch (status.toLowerCase()) {
      case 'dolu':
        return Colors.red.shade700;
      case 'rezerve':
        return Colors.orange.shade800;
      default:
        return Colors.green.shade700;
    }
  }

  void siparisEkraninaGit(MasaModel masa) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SiparisEkrani(
          masaNo: masa.tableNo,
          kullanici: widget.kullanici,
        ),
      ),
    );
    masalariYenile();
  }

  // Sayfa üst header aksiyonları.
  List<Widget> _ustAksiyonlar(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.refresh),
        tooltip: 'Yenile',
        onPressed: masalariYenile,
      ),
      FilledButton.icon(
        style: themedElevatedButtonStyle(theme),
        onPressed: masaEklePenceresiAc,
        icon: const Icon(Icons.add, size: 20),
        label: const Text('Masa Ekle'),
      ),
      OutlinedButton.icon(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back),
        label: const Text('Geri Dön'),
      ),
    ];
  }

  Future<void> masaEklePenceresiAc() async {
    final masaNoController = TextEditingController();
    final bolumController = TextEditingController(text: 'Genel');
    final ekranBaglami = context;

    try {
      final sonuc = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 24,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: StitchKart(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    StitchBolumBasligi(
                      baslik: 'Yeni Masa Ekle',
                      ikon: Icons.table_restaurant,
                      temaRengi: theme.primary,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: masaNoController,
                      keyboardType: TextInputType.number,
                      decoration: stitchInputDekorasyonu(
                        labelText: 'Masa Numarası',
                        temaRengi: theme.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: bolumController,
                      decoration: stitchInputDekorasyonu(
                        labelText: 'Bölüm / Kategori',
                        hintText: 'Genel, Salon, Bahçe, Teras',
                        temaRengi: theme.primary,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () =>
                                Navigator.pop(dialogContext, false),
                            child: const Text('Vazgeç'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton.icon(
                            style: themedElevatedButtonStyle(theme),
                            onPressed: () async {
                              final masaNo =
                                  int.tryParse(masaNoController.text.trim());
                              final bolum = bolumController.text.trim();
                              if (masaNo == null || masaNo <= 0) {
                                showAppPopup(
                                  dialogContext,
                                  message:
                                      'Geçerli bir masa numarası giriniz.',
                                  type: AppPopupType.warning,
                                );
                                return;
                              }
                              if (bolum.isEmpty) {
                                showAppPopup(
                                  dialogContext,
                                  message: 'Bölüm adı boş bırakılamaz.',
                                  type: AppPopupType.warning,
                                );
                                return;
                              }
                              try {
                                final response = await ApiService.addTable(
                                  tableNo: masaNo,
                                  section: bolum,
                                );
                                if (!ekranBaglami.mounted) return;
                                showAppPopup(
                                  ekranBaglami,
                                  message: response['message']?.toString() ??
                                      'Masa eklendi.',
                                  type: AppPopupType.success,
                                );
                                if (dialogContext.mounted) {
                                  Navigator.pop(dialogContext, true);
                                }
                              } catch (error) {
                                if (!dialogContext.mounted) return;
                                showAppPopup(
                                  dialogContext,
                                  message: ApiService.kullaniciHataMesaji(
                                    error,
                                  ),
                                  type: AppPopupType.error,
                                );
                              }
                            },
                            icon: const Icon(Icons.save),
                            label: const Text('Kaydet'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
      if (sonuc == true) {
        masalariYenile();
      }
    } finally {
      masaNoController.dispose();
      bolumController.dispose();
    }
  }

  Widget _durumChip(String etiket, String deger) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: StitchFiltreChip(
        etiket: etiket,
        secili: seciliDurumFiltre == deger,
        temaRengi: theme.primary,
        onTap: () => setState(() => seciliDurumFiltre = deger),
      ),
    );
  }

  Widget _bolumChip(String etiket) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: StitchFiltreChip(
        etiket: etiket,
        secili: seciliBolum == etiket,
        temaRengi: theme.primary,
        onTap: () => setState(() => seciliBolum = etiket),
      ),
    );
  }

  List<MasaModel> _filtrelenmisMasalar(
    List<MasaModel> masalar,
    Map<int, AktifSiparisModel> aktifSiparisler,
  ) {
    var sonuc = masalar;

    if (seciliDurumFiltre == 'Boş') {
      sonuc = sonuc
          .where((m) => m.status.toLowerCase() != 'dolu' && m.status != 'rezerve')
          .toList();
    } else if (seciliDurumFiltre == 'Dolu') {
      sonuc = sonuc.where((m) => m.status.toLowerCase() == 'dolu').toList();
    } else if (seciliDurumFiltre == 'Rezerve') {
      sonuc = sonuc.where((m) => m.status.toLowerCase() == 'rezerve').toList();
    }

    if (seciliBolum != 'Tümü') {
      sonuc = sonuc
          .where(
            (m) => m.section.toLowerCase().contains(
                  seciliBolum.toLowerCase(),
                ),
          )
          .toList();
    }

    return sonuc;
  }

  // Filtre chipleri bölümü.
  Widget _filtreAlani(List<String> ekBolumler) {
    final bolumSecenekleri = <String>{
      ..._bolumFiltreleri,
      ...ekBolumler,
    }.toList();

    return StitchKart(
      kenarlikRengi: theme.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Durum',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _durumChip('Tümü', 'Tümü'),
                _durumChip('Boş', 'Boş'),
                _durumChip('Dolu', 'Dolu'),
                _durumChip('Rezerve', 'Rezerve'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Bölüm / Kategori',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: bolumSecenekleri.map(_bolumChip).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // Masa kartları — Stitch 21 grid kart düzeni.
  Widget _masaKarti(
    MasaModel masa,
    AktifSiparisModel? aktifSiparis,
  ) {
    final renk = durumRengi(masa.status);
    final doluMu = masa.status.toLowerCase() == 'dolu';
    final rezerveMi = masa.status.toLowerCase() == 'rezerve';
    final aktifTutar = aktifSiparis?.totalPrice ?? 0;
    final urunAdedi = aktifSiparis?.itemCount ?? 0;

    return StitchKart(
      padding: const EdgeInsets.all(14),
      kenarlikRengi: doluMu ? theme.primary : renk,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Masa ${masa.tableNo}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                aktifTutar > 0
                    ? '${aktifTutar.toStringAsFixed(0)} TL'
                    : '— TL',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: aktifTutar > 0 ? theme.primary : Colors.black38,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              StitchEtiket(metin: masa.section, renk: theme.primary),
              const SizedBox(width: 8),
              StitchEtiket(metin: durumYazisi(masa.status), renk: renk),
            ],
          ),
          if (urunAdedi > 0) ...[
            const SizedBox(height: 8),
            Text(
              '$urunAdedi ürün • aktif sipariş',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
          const Spacer(),
          if (rezerveMi)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Rezerve masa — sipariş için uygun olmayabilir.',
                style: TextStyle(fontSize: 11, color: Colors.orange.shade800),
              ),
            ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: doluMu ? theme.primary : Colors.green.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 11),
            ),
            onPressed: () => siparisEkraninaGit(masa),
            icon: Icon(doluMu ? Icons.edit_note : Icons.add_shopping_cart),
            label: Text(
              doluMu ? 'Siparişe Devam' : 'Sipariş Al (Yeni)',
            ),
          ),
        ],
      ),
    );
  }

  Widget _ozetSatir(_MasaSecimVerisi veri) {
    final masalar = veri.masalar;
    final bosSayisi = masalar
        .where(
          (m) =>
              m.status.toLowerCase() != 'dolu' &&
              m.status.toLowerCase() != 'rezerve',
        )
        .length;
    final doluSayisi =
        masalar.where((m) => m.status.toLowerCase() == 'dolu').length;
    final aktifSiparisSayisi = veri.aktifSiparisler.length;

    return OzetKartSatiri(
      kartlar: [
        OzetKart(
          baslik: 'Toplam Masa',
          deger: '${masalar.length}',
          ikon: Icons.table_restaurant,
          tema: theme,
        ),
        OzetKart(
          baslik: 'Boş Masalar',
          deger: '$bosSayisi',
          ikon: Icons.event_available,
          tema: theme,
        ),
        OzetKart(
          baslik: 'Dolu Masalar',
          deger: '$doluSayisi',
          ikon: Icons.event_busy,
          tema: theme,
        ),
        OzetKart(
          baslik: 'Aktif Siparişler',
          deger: '$aktifSiparisSayisi',
          ikon: Icons.receipt_long,
          tema: theme,
        ),
      ],
    );
  }

  Widget _masaGridIcerigi(
    List<MasaModel> filtrelenmis,
    Map<int, AktifSiparisModel> aktifSiparisler,
  ) {
    if (filtrelenmis.isEmpty) {
      return const StitchKart(
        child: AppEmptyView(
          kompakt: true,
          baslik: 'Filtreye uygun masa bulunamadı.',
          aciklama: 'Farklı bir durum veya bölüm filtresi deneyin.',
        ),
      );
    }

    final gruplu = <String, List<MasaModel>>{};
    for (final masa in filtrelenmis) {
      gruplu.putIfAbsent(masa.section, () => []);
      gruplu[masa.section]!.add(masa);
    }
    final bolumAdlari = gruplu.keys.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: bolumAdlari.expand((bolumAdi) {
        final liste = gruplu[bolumAdi]!
          ..sort((a, b) => a.tableNo.compareTo(b.tableNo));
        return [
          StitchBolumBasligi(
            baslik: bolumAdi,
            ikon: Icons.place_outlined,
            temaRengi: theme.primary,
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: liste.length,
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 320,
              mainAxisExtent: 200,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
            ),
            itemBuilder: (context, index) {
              final masa = liste[index];
              return _masaKarti(masa, aktifSiparisler[masa.tableNo]);
            },
          ),
          const SizedBox(height: 20),
        ];
      }).toList(),
    );
  }

  // Gerçek sayfa gövdesi — header her zaman görünür.
  Widget _sayfaGovdesi({
    required Widget altIcerik,
    _MasaSecimVerisi? veri,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PanelBaslikAlani(
                baslik: 'Masa Seçimi',
                altBaslik:
                    'Sipariş almak veya hesap işlemi yapmak için masa seçin.',
                tema: theme,
                logoUrl: cafeLogoUrl,
                aksiyonlar: _ustAksiyonlar(context),
              ),
              if (veri != null) ...[
                const SizedBox(height: 20),
                _ozetSatir(veri),
                const SizedBox(height: 20),
                _filtreAlani(
                  veri.masalar.map((m) => m.section).toSet().toList(),
                ),
                const SizedBox(height: 20),
              ],
              altIcerik,
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return themedRoot(
      Scaffold(
        backgroundColor: AppThemeHelper.sayfaZemin,
        body: SafeArea(
          child: FutureBuilder<_MasaSecimVerisi>(
            future: veriFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _sayfaGovdesi(
                  altIcerik: const StitchKart(
                    child: AppLoadingView(
                      kompakt: true,
                      mesaj: 'Masalar yükleniyor...',
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                return _sayfaGovdesi(
                  altIcerik: StitchKart(
                    child: AppErrorView(
                      kompakt: true,
                      hataDetayi: snapshot.error.toString(),
                      tekrarDene: masalariYenile,
                    ),
                  ),
                );
              }

              final veri = snapshot.data!;
              if (veri.masalar.isEmpty) {
                return _sayfaGovdesi(
                  veri: veri,
                  altIcerik: const AppEmptyView(
                    ikon: Icons.table_restaurant_outlined,
                    baslik: 'Masa bulunmuyor.',
                    aciklama:
                        'Masa Ekle ile yeni masa oluşturabilir veya yönetici panelinden ekleyebilirsiniz.',
                  ),
                );
              }

              final filtrelenmis = _filtrelenmisMasalar(
                veri.masalar,
                veri.aktifSiparisler,
              );

              return _sayfaGovdesi(
                veri: veri,
                altIcerik: _masaGridIcerigi(
                  filtrelenmis,
                  veri.aktifSiparisler,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
