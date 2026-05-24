// Flutter arayüz bileşenlerini kullanmak için import ediyoruz.
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// Ürün ve kafe bilgi modelleri.
import '../models/cafe_event_model.dart';
import '../models/cafe_settings_model.dart';
import '../models/public_cafe_info_model.dart';
import '../models/urun_model.dart';

// Public menü verisini backend API'den çekmek için servis dosyasını kullanıyoruz.
import '../services/api_service.dart';
import '../utils/app_theme_helper.dart';

import '../widgets/app_feedback_widgets.dart';
import '../widgets/app_themed_widgets.dart';
import '../widgets/cafe_logo_widget.dart';

// Müşteri QR menü ekranıdır.
// Giriş yapmadan güncel menüyü görüntülemek için kullanılır.
class QrMenuEkrani extends StatefulWidget {
  const QrMenuEkrani({super.key});

  @override
  State<QrMenuEkrani> createState() => _QrMenuEkraniState();
}

class _QrMenuEkraniState extends State<QrMenuEkrani> {
  late Future<List<UrunModel>> urunlerFuture;
  late Future<PublicCafeInfoModel> kafeBilgiFuture;
  final TextEditingController aramaController = TextEditingController();
  String aramaMetni = '';
  String? seciliKategori;

  // Hash route içindeki masa parametresi QR menü bağlantılarından okunur.
  int? _masaNumarasiniOku([BuildContext? context]) {
    final kaynaklar = <String>[];

    if (context != null) {
      final rotaAdi = ModalRoute.of(context)?.settings.name;
      if (rotaAdi != null && rotaAdi.trim().isNotEmpty) {
        kaynaklar.add(rotaAdi.trim());
      }
    }

    final base = Uri.base;
    final tableFromPageQuery = base.queryParameters['table'];
    if (tableFromPageQuery != null && tableFromPageQuery.trim().isNotEmpty) {
      kaynaklar.add(tableFromPageQuery.trim());
    }

    final fragment = base.fragment.trim();
    if (fragment.isNotEmpty) {
      kaynaklar.add(fragment);
    }

    final tamUrl = base.toString();
    final hashIndex = tamUrl.indexOf('#');
    if (hashIndex >= 0 && hashIndex < tamUrl.length - 1) {
      kaynaklar.add(tamUrl.substring(hashIndex + 1));
    }

    for (final kaynak in kaynaklar) {
      final masa = _tableDegeriniAyikla(kaynak);
      if (masa != null) {
        return masa;
      }
    }

    return null;
  }

  // Fragment veya path metninden table= değerini güvenli şekilde çözer.
  int? _tableDegeriniAyikla(String hamKaynak) {
    var metin = hamKaynak.trim();
    if (metin.isEmpty) {
      return null;
    }

    if (metin.startsWith('#')) {
      metin = metin.substring(1).trim();
    }

    String? tableHam;

    if (metin.contains('?')) {
      var sorgu = metin.substring(metin.indexOf('?') + 1);
      final hashKes = sorgu.indexOf('#');
      if (hashKes >= 0) {
        sorgu = sorgu.substring(0, hashKes);
      }
      tableHam = Uri.splitQueryString(sorgu)['table'];
    }

    if (tableHam == null || tableHam.trim().isEmpty) {
      try {
        final yol = metin.startsWith('/') ? metin : '/$metin';
        final uri = Uri.parse('http://qr.local$yol');
        tableHam = uri.queryParameters['table'];
      } catch (_) {
        // Yedek: regex ile table değerini yakala.
      }
    }

    if (tableHam == null || tableHam.trim().isEmpty) {
      final eslesme = RegExp(
        r'(?:^|[?&])table=([^&#]+)',
        caseSensitive: false,
      ).firstMatch(metin);
      tableHam = eslesme?.group(1);
    }

    if (tableHam == null || tableHam.trim().isEmpty) {
      return null;
    }

    final cozulmus = Uri.decodeComponent(tableHam.trim());
    return int.tryParse(cozulmus);
  }

  @override
  void initState() {
    super.initState();
    verileriYukle();
    aramaController.addListener(() {
      setState(() => aramaMetni = aramaController.text.trim());
    });
  }

  @override
  void dispose() {
    aramaController.dispose();
    super.dispose();
  }

  void verileriYukle() {
    urunlerFuture = ApiService.getPublicMenuProducts();
    kafeBilgiFuture = ApiService.getPublicCafeInfo();
  }

  void menuyuYenile() {
    setState(verileriYukle);
  }

  // Ürün adı, kategori ve açıklamada arama yapar.
  List<UrunModel> urunleriFiltrele(List<UrunModel> urunler) {
    if (aramaMetni.isEmpty) return urunler;
    final q = aramaMetni.toLowerCase();
    return urunler.where((urun) {
      return urun.name.toLowerCase().contains(q) ||
          urun.categoryName.toLowerCase().contains(q) ||
          urun.description.toLowerCase().contains(q);
    }).toList();
  }

  // Kafe ayarlarından ana tema rengini çözer.
  Color _temaRengi(CafeSettingsModel? ayar) {
    if (ayar == null) {
      return AppThemeHelper.primaryFromThemeKey(AppThemeHelper.defaultThemeKey);
    }
    return AppThemeHelper.resolvePrimary(
      themeKey: ayar.themeKey,
      primaryColor: ayar.primaryColor,
    );
  }

  bool _yatayGorunum(CafeSettingsModel? ayar) {
    return AppThemeHelper.normalizeMenuLayout(ayar?.menuLayout) == 'horizontal';
  }

  Future<void> _hariciUrlAc(String? url, {required String hataMesaji}) async {
    final metin = url?.trim() ?? '';
    if (metin.isEmpty) return;
    final uri = Uri.tryParse(metin);
    if (uri == null) {
      if (!mounted) return;
      showAppPopup(context, message: hataMesaji, type: AppPopupType.error);
      return;
    }
    final acildi = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!acildi && mounted) {
      showAppPopup(context, message: hataMesaji, type: AppPopupType.error);
    }
  }

  // Geri bildirim API için masa numarası (table_number).
  int? get masaNumarasi => _masaNumarasiniOku();

  // Müşteri geri bildirim gönderme dialogunu açar.
  Future<void> mesajGonderDialogAc({required Color temaRengi}) async {
    String seciliTur = 'istek';
    final adController = TextEditingController();
    final telefonController = TextEditingController();
    final mesajController = TextEditingController();
    final ekranBaglami = context;
    bool gonderiliyor = false;

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return Dialog(
                backgroundColor: Colors.transparent,
                insetPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: StitchKart(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Geri bildirim formu/modal bölümü.
                          StitchBolumBasligi(
                            baslik: 'Mesaj Gönder',
                            ikon: Icons.send_outlined,
                            temaRengi: temaRengi,
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: seciliTur,
                            decoration: stitchInputDekorasyonu(
                              labelText: 'Mesaj Türü',
                              temaRengi: temaRengi,
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'istek',
                                child: Text('İstek'),
                              ),
                              DropdownMenuItem(
                                value: 'sikayet',
                                child: Text('Şikayet'),
                              ),
                              DropdownMenuItem(
                                value: 'oneri',
                                child: Text('Öneri'),
                              ),
                            ],
                            onChanged: (v) {
                              if (v != null) {
                                setDialogState(() => seciliTur = v);
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: adController,
                            decoration: stitchInputDekorasyonu(
                              labelText: 'Ad Soyad (opsiyonel)',
                              temaRengi: temaRengi,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: telefonController,
                            keyboardType: TextInputType.phone,
                            decoration: stitchInputDekorasyonu(
                              labelText: 'Telefon (opsiyonel)',
                              temaRengi: temaRengi,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: mesajController,
                            maxLines: 4,
                            decoration: stitchInputDekorasyonu(
                              labelText: 'Mesajınız',
                              hintText: masaNumarasi != null
                                  ? 'Masa $masaNumarasi için mesajınız...'
                                  : null,
                              temaRengi: temaRengi,
                            ),
                          ),
                          if (masaNumarasi != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Masa numarası otomatik: $masaNumarasi',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: gonderiliyor
                                      ? null
                                      : () => Navigator.pop(dialogContext),
                                  child: const Text('Vazgeç'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FilledButton.icon(
                                  icon: gonderiliyor
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.send),
                                  label: Text(
                                    gonderiliyor
                                        ? 'Gönderiliyor...'
                                        : 'Gönder',
                                  ),
                                  onPressed: gonderiliyor
                                      ? null
                                      : () async {
                            final mesaj = mesajController.text.trim();

                            if (mesaj.isEmpty) {
                              showAppPopup(
                                ekranBaglami,
                                message: 'Mesaj boş bırakılamaz.',
                                type: AppPopupType.warning,
                              );
                              return;
                            }

                            if (mesaj.length < 5) {
                              showAppPopup(
                                ekranBaglami,
                                message: 'Mesaj en az 5 karakter olmalıdır.',
                                type: AppPopupType.warning,
                              );
                              return;
                            }

                            setDialogState(() => gonderiliyor = true);

                            try {
                              final response =
                                  await ApiService.submitCustomerFeedback(
                                feedbackType: seciliTur,
                                customerName: adController.text.trim().isEmpty
                                    ? null
                                    : adController.text.trim(),
                                customerPhone:
                                    telefonController.text.trim().isEmpty
                                        ? null
                                        : telefonController.text.trim(),
                                tableNumber: masaNumarasi,
                                message: mesaj,
                              );

                              if (!ekranBaglami.mounted) return;

                              showAppPopup(
                                ekranBaglami,
                                message: response['message']?.toString() ??
                                    'Mesajınız başarıyla iletildi.',
                                type: AppPopupType.success,
                              );
                              Navigator.pop(dialogContext);
                            } catch (error) {
                              if (!ekranBaglami.mounted) return;

                              showAppPopup(
                                ekranBaglami,
                                message:
                                    'Mesaj gönderilemedi: ${ApiService.kullaniciHataMesaji(error)}',
                                type: AppPopupType.error,
                              );
                            setDialogState(() => gonderiliyor = false);
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
    } finally {
      adController.dispose();
      telefonController.dispose();
      mesajController.dispose();
    }
  }

  // İstek / şikayet / öneri bölümü kartı.
  Widget _geriBildirimBolumu(bool mobilGorunum, Color temaRengi) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        mobilGorunum ? 16 : 24,
        8,
        mobilGorunum ? 16 : 24,
        8,
      ),
      child: StitchKart(
        kenarlikRengi: temaRengi,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StitchBolumBasligi(
              baslik: 'İstek / Şikayet / Öneri',
              ikon: Icons.feedback_outlined,
              temaRengi: temaRengi,
              altBaslik:
                  'Kafe ile ilgili istek, şikayet veya önerinizi buradan iletebilirsiniz.',
            ),
            const SizedBox(height: 14),
            AppTooltip(
              message: 'Mesaj gönder',
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => mesajGonderDialogAc(temaRengi: temaRengi),
                  icon: const Icon(Icons.send),
                  label: const Text('Mesaj Gönder'),
                  style: FilledButton.styleFrom(
                    backgroundColor: temaRengi,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Kafe bilgi kartı — QR menü üst kısmında gösterilir.
  Widget _kafeBilgiKarti(
    CafeSettingsModel ayar,
    bool mobilGorunum,
    Color temaRengi, {
    int? masaNumarasi,
  }) {
    final haritaVar = (ayar.mapUrl ?? '').trim().isNotEmpty;
    final instagramVar = (ayar.instagramUrl ?? '').trim().isNotEmpty;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        mobilGorunum ? 16 : 24,
        12,
        mobilGorunum ? 16 : 24,
        4,
      ),
      child: StitchKart(
        kenarlikRengi: temaRengi,
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Kafe bilgi kartı — logo, durum ve iletişim üst bandı.
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppThemeHelper.lightTint(temaRengi),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CafeLogoWidget(
                  logoUrl: ayar.logoUrl,
                  size: mobilGorunum ? 56 : 64,
                  iconColor: temaRengi,
                  backgroundColor: AppThemeHelper.getSoftCardColor(temaRengi),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ayar.cafeName,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: temaRengi,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          StitchEtiket(
                            metin: ayar.isOpen ? 'Açık' : 'Kapalı',
                            renk: ayar.isOpen
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                          ),
                          if (masaNumarasi != null)
                            StitchEtiket(
                              metin: 'Masa $masaNumarasi',
                              renk: temaRengi,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              if ((ayar.openingHours ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.schedule, size: 18, color: temaRengi),
                    const SizedBox(width: 8),
                    Expanded(child: Text(ayar.openingHours!.trim())),
                  ],
                ),
              ],
              if ((ayar.address ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.location_on_outlined, size: 18, color: temaRengi),
                    const SizedBox(width: 8),
                    Expanded(child: Text(ayar.address!.trim())),
                  ],
                ),
              ],
              if ((ayar.phone ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.phone_outlined, size: 18, color: temaRengi),
                    const SizedBox(width: 8),
                    Text(ayar.phone!.trim()),
                  ],
                ),
              ],
              if (haritaVar || instagramVar) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (haritaVar)
                      AppTooltip(
                        message: 'Yol tarifi al',
                        child: OutlinedButton.icon(
                          onPressed: () => _hariciUrlAc(
                            ayar.mapUrl,
                            hataMesaji: 'Yol tarifi açılamadı.',
                          ),
                          style: OutlinedButton.styleFrom(foregroundColor: temaRengi),
                          icon: const Icon(Icons.map_outlined, size: 18),
                          label: const Text('Yol Tarifi Al'),
                        ),
                      ),
                    if (instagramVar)
                      AppTooltip(
                        message: 'Instagram hesabını aç',
                        child: OutlinedButton.icon(
                          onPressed: () => _hariciUrlAc(
                            ayar.instagramUrl,
                            hataMesaji: 'Instagram açılamadı.',
                          ),
                          style: OutlinedButton.styleFrom(foregroundColor: temaRengi),
                          icon: const Icon(Icons.camera_alt_outlined, size: 18),
                          label: const Text('Instagram'),
                        ),
                      ),
                  ],
                ),
              ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Aktif etkinlikler bölümü.
  Widget _etkinliklerBolumu(
    List<CafeEventModel> etkinlikler,
    bool mobilGorunum,
    Color temaRengi,
  ) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        mobilGorunum ? 16 : 24,
        8,
        mobilGorunum ? 16 : 24,
        4,
      ),
      child: StitchKart(
        kenarlikRengi: temaRengi,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StitchBolumBasligi(
              baslik: 'Duyurular / Etkinlikler',
              ikon: Icons.campaign_outlined,
              temaRengi: temaRengi,
            ),
            const SizedBox(height: 10),
            ...etkinlikler.map((e) {
              final tarih = e.eventDate?.split('T').first;
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppThemeHelper.lightTint(temaRengi),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (tarih != null && tarih.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        tarih,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                    if ((e.description ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        e.description!.trim(),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // Arama alanı — geniş, yuvarlatılmış modern giriş.
  Widget _aramaAlani(bool mobilGorunum, Color temaRengi) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        mobilGorunum ? 16 : 24,
        12,
        mobilGorunum ? 16 : 24,
        4,
      ),
      child: StitchKart(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        kenarlikRengi: temaRengi,
        child: TextField(
          controller: aramaController,
          decoration: stitchInputDekorasyonu(
            hintText: 'Menüde ara...',
            prefixIcon: Icons.search,
            temaRengi: temaRengi,
            suffixIcon: aramaMetni.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => aramaController.clear(),
                  )
                : null,
          ),
        ),
      ),
    );
  }

  // Kategori filtreleri — yatay kaydırmalı chip satırı.
  Widget _kategoriFiltreSatiri(
    List<String> kategoriler,
    bool mobilGorunum,
    Color temaRengi,
  ) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        mobilGorunum ? 16 : 24,
        8,
        mobilGorunum ? 16 : 24,
        4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'Kategoriler',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: temaRengi,
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: kategoriler.length,
              itemBuilder: (context, index) {
                final kategori = kategoriler[index];
                final secili =
                    kategori == (seciliKategori ?? kategoriler.first);

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: StitchFiltreChip(
                    etiket: kategori,
                    secili: secili,
                    temaRengi: temaRengi,
                    onTap: () {
                      setState(() => seciliKategori = kategori);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Dikey görünüm — modern liste kartı.
  Widget _urunKartiDikey(UrunModel urun, Color temaRengi) {
    final aciklama = urun.description.trim();
    return StitchKart(
      margin: const EdgeInsets.only(bottom: 14),
      kenarlikRengi: temaRengi,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: urunGorseli(
              urun,
              temaRengi: temaRengi,
              genislik: 88,
              yukseklik: 88,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        urun.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    FiyatEtiketi(fiyat: urun.price, temaRengi: temaRengi),
                  ],
                ),
                const SizedBox(height: 6),
                StitchEtiket(metin: urun.categoryName, renk: temaRengi),
                if (aciklama.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    aciklama,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Yatay görünüm — görsel ağırlıklı grid kartı.
  Widget _urunKartiYatay(UrunModel urun, Color temaRengi) {
    final aciklama = urun.description.trim();
    return StitchKart(
      padding: EdgeInsets.zero,
      kenarlikRengi: temaRengi,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 140,
            width: double.infinity,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: urunGorseli(
                urun,
                temaRengi: temaRengi,
                genislik: double.infinity,
                yukseklik: 140,
                yuvarlak: false,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  urun.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                StitchEtiket(metin: urun.categoryName, renk: temaRengi),
                if (aciklama.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    aciklama,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                      height: 1.35,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FiyatEtiketi(
                    fiyat: urun.price,
                    temaRengi: temaRengi,
                    buyuk: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Ürün görseli yoksa placeholder ikon gösterilir.
  Widget urunGorseli(
    UrunModel urun, {
    required Color temaRengi,
    double genislik = 72,
    double yukseklik = 72,
    bool yuvarlak = true,
  }) {
    final gorselUrl = ApiService.getProductImageUrl(urun.imageUrl);
    final kenar = yuvarlak ? BorderRadius.circular(12) : BorderRadius.zero;

    Widget placeholder() {
      return Container(
        width: genislik,
        height: yukseklik,
        decoration: BoxDecoration(
          color: AppThemeHelper.lightTint(temaRengi),
          borderRadius: kenar,
        ),
        child: Icon(
          Icons.local_cafe,
          color: temaRengi.withValues(alpha: 0.5),
          size: yuvarlak ? 36 : 48,
        ),
      );
    }

    if (gorselUrl.isEmpty) return placeholder();

    return ClipRRect(
      borderRadius: kenar,
      child: Image.network(
        gorselUrl,
        width: genislik,
        height: yukseklik,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: genislik,
            height: yukseklik,
            decoration: BoxDecoration(
              color: AppThemeHelper.lightTint(temaRengi),
              borderRadius: kenar,
            ),
            child: Icon(
              Icons.broken_image_outlined,
              color: temaRengi.withValues(alpha: 0.5),
              size: 32,
            ),
          );
        },
      ),
    );
  }

  // Ürün listesi: menu_layout vertical → liste, horizontal → grid.
  Widget _urunListesiSliver({
    required List<UrunModel> urunler,
    required bool yatayGorunum,
    required bool mobilGorunum,
    required double ekranGenisligi,
    required Color temaRengi,
  }) {
    final yatayKenar = mobilGorunum ? 16.0 : 24.0;

    if (yatayGorunum) {
      final sutunSayisi = mobilGorunum ? 1 : (ekranGenisligi < 900 ? 2 : 3);
      return SliverPadding(
        padding: EdgeInsets.fromLTRB(yatayKenar, 8, yatayKenar, 24),
        sliver: SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: sutunSayisi,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: mobilGorunum ? 0.72 : 0.68,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) => _urunKartiYatay(urunler[index], temaRengi),
            childCount: urunler.length,
          ),
        ),
      );
    }

    // Dikey görünüm — liste kartları.
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(yatayKenar, 8, yatayKenar, 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _urunKartiDikey(urunler[index], temaRengi),
          childCount: urunler.length,
        ),
      ),
    );
  }

  List<Widget> _menuSliverlari({
    required PublicCafeInfoModel? kafe,
    required List<UrunModel> tumUrunler,
    required List<UrunModel> gosterilecekUrunler,
    required List<String> kategoriler,
    required bool aramaAktif,
    required bool yatayGorunum,
    required bool mobilGorunum,
    required double ekranGenisligi,
    required Color temaRengi,
    int? masaNumarasi,
  }) {
    return [
      if (kafe != null)
        SliverToBoxAdapter(
          child: _kafeBilgiKarti(
            kafe.settings,
            mobilGorunum,
            temaRengi,
            masaNumarasi: masaNumarasi,
          ),
        ),
      if (kafe != null && kafe.events.isNotEmpty)
        SliverToBoxAdapter(
          child: _etkinliklerBolumu(kafe.events, mobilGorunum, temaRengi),
        ),
      SliverToBoxAdapter(child: _aramaAlani(mobilGorunum, temaRengi)),
      if (!aramaAktif && kategoriler.isNotEmpty)
        SliverToBoxAdapter(
          child: _kategoriFiltreSatiri(kategoriler, mobilGorunum, temaRengi),
        ),
      if (tumUrunler.isEmpty && !aramaAktif)
        const SliverFillRemaining(
          hasScrollBody: false,
          child: AppEmptyView(
            ikon: Icons.restaurant_menu,
            baslik: 'Menüde gösterilecek ürün bulunmuyor.',
            aciklama:
                'Yönetici menü yönetiminden ürün ekleyip görünür yapabilir.',
          ),
        )
      else if (aramaAktif && gosterilecekUrunler.isEmpty)
        const SliverFillRemaining(
          hasScrollBody: false,
          child: AppEmptyView(
            baslik: 'Aramanıza uygun ürün bulunamadı.',
            aciklama: 'Farklı bir arama terimi deneyin.',
          ),
        )
      else
        _urunListesiSliver(
          urunler: gosterilecekUrunler,
          yatayGorunum: yatayGorunum,
          mobilGorunum: mobilGorunum,
          ekranGenisligi: ekranGenisligi,
          temaRengi: temaRengi,
        ),
      SliverToBoxAdapter(
        child: _geriBildirimBolumu(mobilGorunum, temaRengi),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 20)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final okunanMasa = _masaNumarasiniOku(context);
    final ekranGenisligi = MediaQuery.of(context).size.width;
    final mobilGorunum = ekranGenisligi < 700;

    return FutureBuilder<PublicCafeInfoModel>(
      future: kafeBilgiFuture,
      builder: (context, kafeSnap) {
        final ayar = kafeSnap.data?.settings;
        final temaRengi = _temaRengi(ayar);
        final yatayGorunum = _yatayGorunum(ayar);

        return Scaffold(
          appBar: AppBar(
            title: Text(
              okunanMasa != null
                  ? 'Masa $okunanMasa QR Menüsü'
                  : 'Kafe Menüsü',
            ),
            elevation: 0,
            scrolledUnderElevation: 2,
            backgroundColor: AppThemeHelper.lightTint(temaRengi),
            foregroundColor: temaRengi,
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Menüyü Yenile',
                onPressed: menuyuYenile,
              ),
            ],
          ),
          backgroundColor: AppThemeHelper.sayfaZemin,
          body: FutureBuilder<List<UrunModel>>(
            future: urunlerFuture,
            builder: (context, urunSnap) {
              // Boş/hata/loading durumları — tam ekran modern görünüm.
              if (urunSnap.connectionState == ConnectionState.waiting) {
                return const AppLoadingView(mesaj: 'Menü yükleniyor...');
              }

              if (urunSnap.hasError) {
                return AppErrorView(
                  hataDetayi: urunSnap.error.toString(),
                  tekrarDene: menuyuYenile,
                );
              }

              final tumUrunler = urunSnap.data ?? [];
              final aramaAktif = aramaMetni.isNotEmpty;
              final kafe = kafeSnap.data;
              final kategoriler = tumUrunler
                  .map((urun) => urun.categoryName)
                  .toSet()
                  .toList()
                ..sort();

              List<UrunModel> gosterilecekUrunler;
              if (aramaAktif) {
                gosterilecekUrunler = urunleriFiltrele(tumUrunler);
              } else if (tumUrunler.isEmpty) {
                gosterilecekUrunler = [];
              } else {
                final aktifKategori = seciliKategori ?? kategoriler.first;
                gosterilecekUrunler = tumUrunler
                    .where((urun) => urun.categoryName == aktifKategori)
                    .toList();
              }

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: CustomScrollView(
                    slivers: _menuSliverlari(
                      kafe: kafe,
                      tumUrunler: tumUrunler,
                      gosterilecekUrunler: gosterilecekUrunler,
                      kategoriler: kategoriler,
                      aramaAktif: aramaAktif,
                      yatayGorunum: yatayGorunum,
                      mobilGorunum: mobilGorunum,
                      ekranGenisligi: ekranGenisligi,
                      temaRengi: temaRengi,
                      masaNumarasi: okunanMasa,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
