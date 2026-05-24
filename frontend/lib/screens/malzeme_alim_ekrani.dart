// Flutter arayüz bileşenlerini kullanmak için import ediyoruz.
import 'package:flutter/material.dart';

import '../models/material_purchase_model.dart';
import '../services/api_service.dart';
import '../utils/app_theme_helper.dart';
import '../widgets/app_feedback_widgets.dart';
import '../widgets/app_themed_widgets.dart';

// Malzeme alım işlemleri ekranıdır (yönetici).
// Alınan malzemeler miktar, birim fiyat ve toplam tutar ile takip edilir.
class MalzemeAlimEkrani extends StatefulWidget {
  const MalzemeAlimEkrani({super.key});

  @override
  State<MalzemeAlimEkrani> createState() => _MalzemeAlimEkraniState();
}

class _MalzemeAlimEkraniState extends State<MalzemeAlimEkrani>
    with CafeThemeScreenMixin {
  late Future<List<MaterialPurchaseModel>> malzemelerFuture;
  String seciliDonem = 'all';

  static const List<String> _birimSecenekleri = [
    'adet',
    'kg',
    'gram',
    'litre',
    'paket',
    'koli',
    'şişe',
  ];

  @override
  void initState() {
    super.initState();
    initCafeThemeListener();
    verileriYukle();
  }

  @override
  void dispose() {
    disposeCafeThemeListener();
    super.dispose();
  }

  void verileriYukle() {
    malzemelerFuture =
        ApiService.getMaterialPurchases(period: seciliDonem);
  }

  void ekraniYenile() {
    setState(verileriYukle);
  }

  void donemDegistir(String yeniDonem) {
    setState(() {
      seciliDonem = yeniDonem;
      verileriYukle();
    });
  }

  String donemBasligi(String donem) {
    switch (donem) {
      case 'daily':
        return 'Günlük';
      case 'weekly':
        return 'Haftalık';
      case 'monthly':
        return 'Aylık';
      default:
        return 'Tüm';
    }
  }

  List<Widget> _ustAksiyonlar(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.refresh),
        tooltip: 'Yenile',
        onPressed: ekraniYenile,
      ),
      FilledButton.icon(
        style: themedElevatedButtonStyle(theme),
        onPressed: malzemeEklePenceresiAc,
        icon: const Icon(Icons.add, size: 20),
        label: const Text('Malzeme Ekle'),
      ),
      OutlinedButton.icon(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back),
        label: const Text('Geri Dön'),
      ),
    ];
  }

  Future<void> malzemeSilOnayi(MaterialPurchaseModel kayit) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: StitchKart(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Silme onay dialogu.
                  StitchBolumBasligi(
                    baslik: 'Malzeme Kaydını Sil',
                    ikon: Icons.delete_outline,
                    temaRengi: Colors.red.shade700,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '"${kayit.itemName}" kaydını silmek istediğinize emin misiniz?',
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: const Text('Vazgeç'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          icon: const Icon(Icons.delete),
                          label: const Text('Evet, Sil'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade100,
                            foregroundColor: Colors.red,
                          ),
                          onPressed: () => Navigator.pop(dialogContext, true),
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

    if (onay != true || !mounted) return;

    try {
      final response = await ApiService.deleteMaterialPurchase(id: kayit.id);
      if (!mounted) return;

      showAppSnackBar(
        context,
        response['message']?.toString() ?? 'Kayıt silindi.',
      );
      ekraniYenile();
    } catch (error) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        ApiService.kullaniciHataMesaji(error),
        hata: true,
      );
    }
  }

  Future<void> malzemeEklePenceresiAc() async {
    final malzemeAdiController = TextEditingController();
    final miktarController = TextEditingController(text: '1');
    final birimFiyatController = TextEditingController();
    final aciklamaController = TextEditingController();
    String seciliBirim = 'adet';
    DateTime seciliTarih = DateTime.now();
    final ekranBaglami = context;

    final sonuc = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, dialogState) {
            final miktar = double.tryParse(
                  miktarController.text.trim().replaceAll(',', '.'),
                ) ??
                0;
            final birimFiyat = double.tryParse(
                  birimFiyatController.text.trim().replaceAll(',', '.'),
                ) ??
                0;
            final hesaplananToplam = miktar > 0 && birimFiyat >= 0
                ? miktar * birimFiyat
                : 0.0;

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: StitchKart(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Malzeme ekleme dialog formu.
                        StitchBolumBasligi(
                          baslik: 'Malzeme Ekle',
                          ikon: Icons.add_shopping_cart,
                          temaRengi: theme.primary,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: malzemeAdiController,
                          decoration: stitchInputDekorasyonu(
                            labelText: 'Malzeme Adı',
                            hintText: 'Örn: Süt',
                            temaRengi: theme.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: miktarController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                decoration: stitchInputDekorasyonu(
                                  labelText: 'Miktar',
                                  temaRengi: theme.primary,
                                ),
                                onChanged: (_) => dialogState(() {}),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: seciliBirim,
                                decoration: stitchInputDekorasyonu(
                                  labelText: 'Birim',
                                  temaRengi: theme.primary,
                                ),
                                items: _birimSecenekleri
                                    .map(
                                      (birim) => DropdownMenuItem(
                                        value: birim,
                                        child: Text(birim),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (deger) {
                                  if (deger != null) {
                                    dialogState(() => seciliBirim = deger);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: birimFiyatController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: stitchInputDekorasyonu(
                            labelText: 'Birim Fiyat (TL)',
                            prefixIcon: Icons.payments_outlined,
                            temaRengi: theme.primary,
                          ),
                          onChanged: (_) => dialogState(() {}),
                        ),
                        const SizedBox(height: 12),
                        StitchVurguKart(
                          baslik: 'Hesaplanan Toplam',
                          deger: '${hesaplananToplam.toStringAsFixed(2)} TL',
                          tema: theme,
                          arkaPlan: theme.softCard.withValues(alpha: 0.35),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: aciklamaController,
                          maxLines: 2,
                          decoration: stitchInputDekorasyonu(
                            labelText: 'Açıklama',
                            temaRengi: theme.primary,
                            maxLines: 2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Alım Tarihi'),
                          subtitle: Text(
                            '${seciliTarih.day.toString().padLeft(2, '0')}.'
                            '${seciliTarih.month.toString().padLeft(2, '0')}.'
                            '${seciliTarih.year}',
                          ),
                          trailing: IconButton(
                            tooltip: 'Tarih seç',
                            icon: Icon(Icons.calendar_today, color: theme.primary),
                            onPressed: () async {
                              final tarih = await showDatePicker(
                                context: context,
                                initialDate: seciliTarih,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );
                              if (tarih != null) {
                                dialogState(() => seciliTarih = tarih);
                              }
                            },
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
                                icon: const Icon(Icons.save),
                                label: const Text('Kaydet'),
                                onPressed: () async {
                                  final ad = malzemeAdiController.text.trim();
                                  final miktar = double.tryParse(
                                    miktarController.text
                                        .trim()
                                        .replaceAll(',', '.'),
                                  );
                                  final birimFiyat = double.tryParse(
                                    birimFiyatController.text
                                        .trim()
                                        .replaceAll(',', '.'),
                                  );

                                  if (ad.isEmpty) {
                                    showAppSnackBar(
                                      dialogContext,
                                      'Malzeme adı boş bırakılamaz.',
                                      hata: true,
                                    );
                                    return;
                                  }
                                  if (miktar == null || miktar <= 0) {
                                    showAppSnackBar(
                                      dialogContext,
                                      'Miktar 0\'dan büyük olmalıdır.',
                                      hata: true,
                                    );
                                    return;
                                  }
                                  if (birimFiyat == null || birimFiyat < 0) {
                                    showAppSnackBar(
                                      dialogContext,
                                      'Birim fiyat negatif olamaz.',
                                      hata: true,
                                    );
                                    return;
                                  }

                                  try {
                                    final tarihStr =
                                        '${seciliTarih.year}-'
                                        '${seciliTarih.month.toString().padLeft(2, '0')}-'
                                        '${seciliTarih.day.toString().padLeft(2, '0')}';

                                    await ApiService.addMaterialPurchase(
                                      itemName: ad,
                                      quantity: miktar,
                                      unit: seciliBirim.isEmpty
                                          ? 'adet'
                                          : seciliBirim,
                                      unitPrice: birimFiyat,
                                      description:
                                          aciklamaController.text.trim().isEmpty
                                              ? null
                                              : aciklamaController.text.trim(),
                                      purchaseDate: tarihStr,
                                    );

                                    if (!ekranBaglami.mounted) return;
                                    Navigator.pop(dialogContext, true);
                                  } catch (error) {
                                    if (!dialogContext.mounted) return;
                                    showAppSnackBar(
                                      dialogContext,
                                      ApiService.kullaniciHataMesaji(error),
                                      hata: true,
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    malzemeAdiController.dispose();
    miktarController.dispose();
    birimFiyatController.dispose();
    aciklamaController.dispose();

    if (!mounted) return;

    if (sonuc == true) {
      showAppSnackBar(context, 'Malzeme alım kaydı eklendi.');
      ekraniYenile();
    }
  }

  Widget _donemFiltreleri() {
    return StitchKart(
      kenarlikRengi: theme.primary,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StitchBolumBasligi(
            baslik: 'Dönem Filtresi',
            ikon: Icons.date_range_outlined,
            temaRengi: theme.primary,
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _donemChip('Tümü', 'all'),
                _donemChip('Günlük', 'daily'),
                _donemChip('Haftalık', 'weekly'),
                _donemChip('Aylık', 'monthly'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _donemChip(String baslik, String deger) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: StitchFiltreChip(
        etiket: baslik,
        secili: seciliDonem == deger,
        temaRengi: theme.primary,
        onTap: () => donemDegistir(deger),
      ),
    );
  }

  List<MaterialPurchaseModel> _bugunkuKayitlar(
    List<MaterialPurchaseModel> liste,
  ) {
    final bugun = DateTime.now();
    return liste.where((k) {
      try {
        final tarih = DateTime.parse(k.purchaseDate).toLocal();
        return tarih.year == bugun.year &&
            tarih.month == bugun.month &&
            tarih.day == bugun.day;
      } catch (_) {
        return false;
      }
    }).toList();
  }

  // Bugünkü alım özeti — vurgulu kart.
  Widget _bugunkuAlimOzeti(List<MaterialPurchaseModel> liste) {
    final bugunku = _bugunkuKayitlar(liste);
    final toplam =
        bugunku.fold<double>(0, (sum, k) => sum + k.totalPrice);

    return StitchVurguKart(
      baslik: 'Bugünkü Alım',
      deger: '${toplam.toStringAsFixed(2)} TL',
      tema: theme,
      altSatir: '${bugunku.length} kayıt',
    );
  }

  Widget _ozetKartlari(List<MaterialPurchaseModel> liste) {
    final toplamGider =
        liste.fold<double>(0, (sum, k) => sum + k.totalPrice);
    final kayitSayisi = liste.length;
    final ortalama =
        kayitSayisi > 0 ? toplamGider / kayitSayisi : 0.0;

    return OzetKartSatiri(
      kartlar: [
        OzetKart(
          baslik: 'Toplam Malzeme Gideri',
          deger: '${toplamGider.toStringAsFixed(2)} TL',
          ikon: Icons.payments,
          tema: theme,
        ),
        OzetKart(
          baslik: 'Toplam Kayıt Sayısı',
          deger: kayitSayisi.toString(),
          ikon: Icons.inventory_2,
          tema: theme,
        ),
        OzetKart(
          baslik: 'Ortalama Alım Tutarı',
          deger: '${ortalama.toStringAsFixed(2)} TL',
          ikon: Icons.calculate,
          tema: theme,
        ),
      ],
    );
  }

  // Malzeme alım kaydı kartı — dengeli Stitch düzeni.
  Widget _malzemeKarti(MaterialPurchaseModel kayit) {
    final aciklama = kayit.description?.trim().isNotEmpty == true
        ? kayit.description!
        : 'Açıklama yok';

    return StitchKart(
      margin: const EdgeInsets.only(bottom: 12),
      kenarlikRengi: theme.primary,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.softCard,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.shopping_basket, color: theme.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kayit.itemName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FiyatEtiketi(
                    fiyat: kayit.totalPrice,
                    temaRengi: theme.primary,
                    buyuk: true,
                  ),
                ),
                const SizedBox(height: 10),
                StitchBilgiIzgarasi(
                  sutunSayisi: 2,
                  ogeler: [
                    (
                      etiket: 'Miktar',
                      deger: kayit.miktarBirimMetni(),
                      vurgu: null,
                    ),
                    (
                      etiket: 'Birim fiyat',
                      deger: '${kayit.unitPrice.toStringAsFixed(2)} TL',
                      vurgu: theme.primary,
                    ),
                    (
                      etiket: 'Tarih',
                      deger: kayit.tarihGosterimi(),
                      vurgu: null,
                    ),
                    (
                      etiket: 'Açıklama',
                      deger: aciklama,
                      vurgu: null,
                    ),
                  ],
                ),
              ],
            ),
          ),
          AppTooltip(
            message: 'Malzeme kaydını sil',
            child: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => malzemeSilOnayi(kayit),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return themedRoot(
      Scaffold(
        backgroundColor: AppThemeHelper.sayfaZemin,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PanelBaslikAlani(
                      baslik: 'Malzeme Alım İşlemleri',
                      altBaslik:
                          'Alınan malzemeleri miktar, birim fiyat ve toplam tutar bilgisiyle takip edin.',
                      tema: theme,
                      logoUrl: cafeLogoUrl,
                      aksiyonlar: _ustAksiyonlar(context),
                    ),
                    const SizedBox(height: 20),
                    _donemFiltreleri(),
                    const SizedBox(height: 20),
                    FutureBuilder<List<MaterialPurchaseModel>>(
                      future: malzemelerFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const AppLoadingView(
                            mesaj: 'Malzeme kayıtları yükleniyor...',
                          );
                        }

                        if (snapshot.hasError) {
                          return AppErrorView(
                            hataDetayi: snapshot.error.toString(),
                            tekrarDene: ekraniYenile,
                          );
                        }

                        final liste = snapshot.data ?? [];

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Bugünkü alım özeti her zaman görünür.
                            _bugunkuAlimOzeti(liste),
                            const SizedBox(height: 20),
                            if (liste.isEmpty)
                              AppEmptyView(
                                ikon: Icons.inventory_2_outlined,
                                baslik:
                                    '${donemBasligi(seciliDonem)} döneminde malzeme kaydı bulunmuyor.',
                                aciklama:
                                    'Yeni malzeme eklemek için üstteki Malzeme Ekle butonunu kullanın.',
                                aksiyonMetni: 'Malzeme Ekle',
                                aksiyon: malzemeEklePenceresiAc,
                              )
                            else ...[
                              _ozetKartlari(liste),
                              const SizedBox(height: 20),
                              StitchBolumBasligi(
                                baslik:
                                    'Malzeme Kayıtları (${donemBasligi(seciliDonem)})',
                                ikon: Icons.inventory_2_outlined,
                                temaRengi: theme.primary,
                              ),
                              const SizedBox(height: 12),
                              for (final kayit in liste) _malzemeKarti(kayit),
                            ],
                          ],
                        );
                      },
                    ),
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
