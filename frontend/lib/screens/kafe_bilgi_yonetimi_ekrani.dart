// Yönetici kafe bilgileri ve etkinlik yönetimi ekranıdır.
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/cafe_event_model.dart';
import '../models/cafe_settings_model.dart';
import '../services/api_service.dart';
import '../services/cafe_theme_controller.dart';
import '../utils/app_theme_helper.dart';
import '../widgets/app_feedback_widgets.dart';
import '../widgets/app_themed_widgets.dart';
import '../widgets/cafe_logo_widget.dart';

class KafeBilgiYonetimiEkrani extends StatefulWidget {
  const KafeBilgiYonetimiEkrani({super.key});

  @override
  State<KafeBilgiYonetimiEkrani> createState() =>
      _KafeBilgiYonetimiEkraniState();
}

class _KafeBilgiYonetimiEkraniState extends State<KafeBilgiYonetimiEkrani>
    with CafeThemeScreenMixin {
  late Future<CafeSettingsModel> ayarlarFuture;
  late Future<List<CafeEventModel>> etkinliklerFuture;

  final kafeAdiController = TextEditingController();
  final acikSaatController = TextEditingController();
  final adresController = TextEditingController();
  final telefonController = TextEditingController();
  final haritaController = TextEditingController();
  final instagramController = TextEditingController();

  final etkinlikBaslikController = TextEditingController();
  final etkinlikAciklamaController = TextEditingController();
  final etkinlikTarihController = TextEditingController();

  bool kafeAcik = true;
  bool etkinlikAktif = true;
  bool ayarKaydediliyor = false;
  bool ayarFormuDolduruldu = false;
  int? duzenlenenEtkinlikId;
  String seciliThemeKey = AppThemeHelper.defaultThemeKey;
  String seciliMenuLayout = AppThemeHelper.defaultMenuLayout;
  String? kayitliLogoUrl;
  PlatformFile? seciliLogoDosyasi;
  bool logoYukleniyor = false;

  @override
  void initState() {
    super.initState();
    initCafeThemeListener();
    verileriYukle();
  }

  @override
  void dispose() {
    disposeCafeThemeListener();
    kafeAdiController.dispose();
    acikSaatController.dispose();
    adresController.dispose();
    telefonController.dispose();
    haritaController.dispose();
    instagramController.dispose();
    etkinlikBaslikController.dispose();
    etkinlikAciklamaController.dispose();
    etkinlikTarihController.dispose();
    super.dispose();
  }

  void verileriYukle() {
    ayarlarFuture = ApiService.getCafeSettings();
    etkinliklerFuture = ApiService.getCafeEvents();
  }

  void ekraniYenile() {
    setState(() {
      ayarFormuDolduruldu = false;
      verileriYukle();
    });
  }

  void _ayarlariFormaYaz(CafeSettingsModel ayar) {
    kafeAdiController.text = ayar.cafeName;
    acikSaatController.text = ayar.openingHours ?? '';
    adresController.text = ayar.address ?? '';
    telefonController.text = ayar.phone ?? '';
    haritaController.text = ayar.mapUrl ?? '';
    instagramController.text = ayar.instagramUrl ?? '';
    setState(() {
      kafeAcik = ayar.isOpen;
      seciliThemeKey = AppThemeHelper.normalizeThemeKey(ayar.themeKey);
      seciliMenuLayout = AppThemeHelper.normalizeMenuLayout(ayar.menuLayout);
      kayitliLogoUrl = ayar.logoUrl;
    });
    CafeThemeController.instance.setLogoUrl(ayar.logoUrl);
  }

  Future<void> _logoDosyasiSec() async {
    const izinli = ['jpg', 'jpeg', 'png', 'webp'];
    try {
      FocusManager.instance.primaryFocus?.unfocus();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final sonuc = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: izinli,
        withData: true,
        allowMultiple: false,
      );
      if (sonuc == null || sonuc.files.isEmpty) return;
      final dosya = sonuc.files.first;
      if (dosya.bytes == null) {
        if (!mounted) return;
        showAppPopup(context, message: 'Dosya okunamadı.', type: AppPopupType.error);
        return;
      }
      setState(() => seciliLogoDosyasi = dosya);
    } catch (error) {
      if (!mounted) return;
      showAppPopup(
        context,
        message: ApiService.kullaniciHataMesaji(error),
        type: AppPopupType.error,
      );
    }
  }

  Future<void> _logoYukle() async {
    if (seciliLogoDosyasi == null) {
      showAppPopup(
        context,
        message: 'Lütfen önce bir görsel seçin.',
        type: AppPopupType.warning,
      );
      return;
    }

    setState(() => logoYukleniyor = true);
    try {
      final yanit = await ApiService.uploadCafeLogo(file: seciliLogoDosyasi!);
      final yeniUrl = yanit['logo_url']?.toString();
      setState(() {
        kayitliLogoUrl = yeniUrl;
        seciliLogoDosyasi = null;
      });
      CafeThemeController.instance.setLogoUrl(yeniUrl);
      if (!mounted) return;
      showAppPopup(
        context,
        message: 'Logo başarıyla yüklendi.',
        type: AppPopupType.success,
        temaRengi: theme.primary,
      );
    } catch (error) {
      if (!mounted) return;
      showAppPopup(
        context,
        message: 'Logo yüklenemedi: ${ApiService.kullaniciHataMesaji(error)}',
        type: AppPopupType.error,
      );
    } finally {
      if (mounted) setState(() => logoYukleniyor = false);
    }
  }

  Future<void> _logoKaldir() async {
    setState(() => logoYukleniyor = true);
    try {
      await ApiService.deleteCafeLogo();
      setState(() {
        kayitliLogoUrl = null;
        seciliLogoDosyasi = null;
      });
      CafeThemeController.instance.setLogoUrl(null);
      if (!mounted) return;
      showAppPopup(
        context,
        message: 'Logo kaldırıldı.',
        type: AppPopupType.success,
        temaRengi: theme.primary,
      );
    } catch (error) {
      if (!mounted) return;
      showAppPopup(
        context,
        message: ApiService.kullaniciHataMesaji(error),
        type: AppPopupType.error,
      );
    } finally {
      if (mounted) setState(() => logoYukleniyor = false);
    }
  }

  Widget _logoOnizleme() {
    if (seciliLogoDosyasi?.bytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(60),
        child: Image.memory(
          seciliLogoDosyasi!.bytes!,
          width: 120,
          height: 120,
          fit: BoxFit.cover,
        ),
      );
    }
    return CafeLogoWidget(
      logoUrl: kayitliLogoUrl,
      size: 120,
      iconColor: theme.primary,
      backgroundColor: theme.softCard,
    );
  }

  Widget _kafeLogosuBolumu() {
    final logoVar = (kayitliLogoUrl ?? '').trim().isNotEmpty;

    return StitchKart(
      kenarlikRengi: theme.primary,
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StitchBolumBasligi(
              baslik: 'Kafe Logosu',
              ikon: Icons.image_outlined,
              temaRengi: theme.primary,
              altBaslik:
                  'Logoyu yükleyerek giriş ekranında ve QR menüde görünmesini sağlayın.',
            ),
            const SizedBox(height: 16),
            Center(child: _logoOnizleme()),
            const SizedBox(height: 10),
            Center(
              child: Text(
                seciliLogoDosyasi != null
                    ? 'Seçilen logo yüklenebilir.'
                    : logoVar
                        ? 'Logo yüklendi.'
                        : 'Henüz logo yüklenmedi.',
                style: TextStyle(
                  fontSize: 14,
                  color: seciliLogoDosyasi != null || logoVar
                      ? Colors.green.shade700
                      : Colors.black54,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                AppTooltip(
                  message: 'Logo dosyası seç',
                  child: OutlinedButton.icon(
                    onPressed: logoYukleniyor ? null : _logoDosyasiSec,
                    icon: const Icon(Icons.image_outlined),
                    label: const Text('Logo Seç'),
                  ),
                ),
                AppTooltip(
                  message: 'Seçilen logoyu yükle',
                  child: ElevatedButton.icon(
                    onPressed: logoYukleniyor ? null : _logoYukle,
                    style: themedElevatedButtonStyle(theme),
                    icon: logoYukleniyor
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cloud_upload_outlined),
                    label: Text(logoYukleniyor ? 'Yükleniyor...' : 'Logo Yükle'),
                  ),
                ),
                if (logoVar)
                  AppTooltip(
                    message: 'Logoyu kaldır',
                    child: OutlinedButton.icon(
                      onPressed: logoYukleniyor ? null : _logoKaldir,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Logoyu Kaldır'),
                    ),
                  ),
              ],
            ),
          ],
        ),
    );
  }

  void _etkinlikFormuTemizle() {
    setState(() {
      duzenlenenEtkinlikId = null;
      etkinlikBaslikController.clear();
      etkinlikAciklamaController.clear();
      etkinlikTarihController.clear();
      etkinlikAktif = true;
    });
  }

  void _etkinlikDuzenle(CafeEventModel e) {
    setState(() {
      duzenlenenEtkinlikId = e.id;
      etkinlikBaslikController.text = e.title;
      etkinlikAciklamaController.text = e.description ?? '';
      etkinlikTarihController.text = e.eventDate?.split('T').first ?? '';
      etkinlikAktif = e.isActive;
    });
  }

  Future<void> _ayarlariKaydet() async {
    final ad = kafeAdiController.text.trim();
    if (ad.isEmpty) {
      showAppPopup(context, message: 'Kafe adı boş bırakılamaz.', type: AppPopupType.warning);
      return;
    }

    setState(() => ayarKaydediliyor = true);
    try {
      final guncel = await ApiService.updateCafeSettings(
        cafeName: ad,
        openingHours: acikSaatController.text.trim(),
        address: adresController.text.trim(),
        phone: telefonController.text.trim(),
        mapUrl: haritaController.text.trim(),
        instagramUrl: instagramController.text.trim(),
        isOpen: kafeAcik,
        themeKey: seciliThemeKey,
        primaryColor: AppThemeHelper.hexFromThemeKey(seciliThemeKey),
        menuLayout: seciliMenuLayout,
      );
      CafeThemeController.instance.applySettings(guncel);
      setState(() => kayitliLogoUrl = guncel.logoUrl);
      if (!mounted) return;
      showAppPopup(
        context,
        message: 'Tema ayarları güncellendi.',
        type: AppPopupType.success,
        temaRengi: theme.primary,
      );
      ekraniYenile();
    } catch (error) {
      if (!mounted) return;
      showAppPopup(context, message: ApiService.kullaniciHataMesaji(error), type: AppPopupType.error);
    } finally {
      if (mounted) setState(() => ayarKaydediliyor = false);
    }
  }

  Future<void> _etkinlikKaydet() async {
    final baslik = etkinlikBaslikController.text.trim();
    if (baslik.isEmpty) {
      showAppPopup(context, message: 'Etkinlik başlığı boş bırakılamaz.', type: AppPopupType.warning);
      return;
    }

    final tarih = etkinlikTarihController.text.trim();
    try {
      if (duzenlenenEtkinlikId != null) {
        await ApiService.updateCafeEvent(
          id: duzenlenenEtkinlikId!,
          title: baslik,
          description: etkinlikAciklamaController.text.trim(),
          eventDate: tarih.isEmpty ? null : tarih,
          isActive: etkinlikAktif,
        );
        if (!mounted) return;
        showAppPopup(context, message: 'Etkinlik güncellendi.', type: AppPopupType.success);
      } else {
        await ApiService.addCafeEvent(
          title: baslik,
          description: etkinlikAciklamaController.text.trim(),
          eventDate: tarih.isEmpty ? null : tarih,
          isActive: etkinlikAktif,
        );
        if (!mounted) return;
        showAppPopup(context, message: 'Etkinlik eklendi.', type: AppPopupType.success);
      }
      _etkinlikFormuTemizle();
      ekraniYenile();
    } catch (error) {
      if (!mounted) return;
      showAppPopup(context, message: ApiService.kullaniciHataMesaji(error), type: AppPopupType.error);
    }
  }

  Future<void> _etkinlikSil(CafeEventModel e) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Etkinliği Sil'),
        content: Text('"${e.title}" silinsin mi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Vazgeç')),
          ElevatedButton(onPressed: () => Navigator.pop(c, true), child: const Text('Sil')),
        ],
      ),
    );
    if (onay != true || !mounted) return;

    try {
      await ApiService.deleteCafeEvent(id: e.id);
      if (!mounted) return;
      showAppPopup(context, message: 'Etkinlik silindi.', type: AppPopupType.success);
      ekraniYenile();
    } catch (error) {
      if (!mounted) return;
      showAppPopup(context, message: ApiService.kullaniciHataMesaji(error), type: AppPopupType.error);
    }
  }

  String _tarihGoster(String? tarih) {
    if (tarih == null || tarih.isEmpty) return 'Tarih belirtilmedi';
    return tarih.split('T').first;
  }

  List<Widget> _ustAksiyonlar(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.refresh),
        tooltip: 'Yenile',
        onPressed: ekraniYenile,
      ),
      OutlinedButton.icon(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back),
        label: const Text('Geri Dön'),
      ),
    ];
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
            // Sayfa başlığı/header bölümü.
            PanelBaslikAlani(
              baslik: 'Kafe Bilgi Yönetimi',
              altBaslik:
                  'Kafe logosu, açık saatleri, yol tarifi, sosyal medya, tema rengi ve QR menü görünümünü buradan yönetin.',
              tema: theme,
              logoUrl: cafeLogoUrl,
              aksiyonlar: _ustAksiyonlar(context),
            ),
            const SizedBox(height: 20),
            _kafeLogosuBolumu(),
            const SizedBox(height: 16),
            FutureBuilder<CafeSettingsModel>(
              future: ayarlarFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const AppLoadingView(kompakt: true, mesaj: 'Ayarlar yükleniyor...');
                }
                if (snapshot.hasError) {
                  return AppErrorView(kompakt: true, hataDetayi: snapshot.error.toString(), tekrarDene: ekraniYenile);
                }
                final ayar = snapshot.data!;
                if (!ayarFormuDolduruldu) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!ayarFormuDolduruldu && mounted) {
                      _ayarlariFormaYaz(ayar);
                      ayarFormuDolduruldu = true;
                    }
                  });
                }

                return StitchKart(
                  kenarlikRengi: theme.primary,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StitchBolumBasligi(
                          baslik: 'Kafe Bilgileri',
                          ikon: Icons.storefront_outlined,
                          temaRengi: theme.primary,
                        ),
                        const SizedBox(height: 14),
                        const SizedBox(height: 14),
                        TextField(controller: kafeAdiController, decoration: stitchInputDekorasyonu(labelText: 'Kafe Adı', temaRengi: theme.primary)),
                        const SizedBox(height: 10),
                        TextField(controller: acikSaatController, maxLines: 2, decoration: stitchInputDekorasyonu(labelText: 'Açık Saatleri', temaRengi: theme.primary)),
                        const SizedBox(height: 10),
                        TextField(controller: adresController, maxLines: 2, decoration: stitchInputDekorasyonu(labelText: 'Adres', temaRengi: theme.primary)),
                        const SizedBox(height: 10),
                        TextField(controller: telefonController, decoration: stitchInputDekorasyonu(labelText: 'Telefon', temaRengi: theme.primary)),
                        const SizedBox(height: 10),
                        TextField(controller: haritaController, decoration: stitchInputDekorasyonu(labelText: 'Google Maps / Yol Tarifi URL', temaRengi: theme.primary)),
                        const SizedBox(height: 10),
                        TextField(controller: instagramController, decoration: stitchInputDekorasyonu(labelText: 'Instagram URL', temaRengi: theme.primary)),
                        SwitchListTile(
                          title: const Text('Kafe Açık'),
                          value: kafeAcik,
                          onChanged: (v) => setState(() => kafeAcik = v),
                        ),
                        const SizedBox(height: 16),
                        StitchBolumBasligi(
                          baslik: 'Tema ve Menü Görünümü',
                          ikon: Icons.palette_outlined,
                          temaRengi: theme.primary,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Tema Rengi',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: seciliThemeKey,
                          decoration: stitchInputDekorasyonu(
                            labelText: 'Tema seçin',
                            temaRengi: theme.primary,
                          ),
                          items: AppThemeHelper.temaSecenekleri
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e.key,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 18,
                                        height: 18,
                                        decoration: BoxDecoration(
                                          color: AppThemeHelper.primaryFromThemeKey(e.key),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(e.value),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            if (v == null) return;
                            setState(() => seciliThemeKey = v);
                          },
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'QR Menü Görünümü',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Bu ayar QR menüde müşterinin gördüğü ürün listeleme tasarımını değiştirir.',
                          style: TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                        const SizedBox(height: 8),
                        SegmentedButton<String>(
                          segments: AppThemeHelper.menuLayoutSecenekleri
                              .map(
                                (e) => ButtonSegment<String>(
                                  value: e.key,
                                  label: Text(e.value),
                                ),
                              )
                              .toList(),
                          selected: {seciliMenuLayout},
                          onSelectionChanged: (secim) {
                            setState(() => seciliMenuLayout = secim.first);
                          },
                        ),
                        const SizedBox(height: 14),
                        AppTooltip(
                          message: 'Kafe bilgilerini kaydet',
                          child: ElevatedButton.icon(
                            style: themedElevatedButtonStyle(theme),
                            onPressed: ayarKaydediliyor ? null : _ayarlariKaydet,
                            icon: ayarKaydediliyor ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save),
                            label: Text(ayarKaydediliyor ? 'Kaydediliyor...' : 'Bilgileri Kaydet'),
                          ),
                        ),
                      ],
                    ),
                );
              },
            ),
            const SizedBox(height: 24),
            StitchKart(
              kenarlikRengi: theme.primary,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StitchBolumBasligi(
                      baslik: 'Etkinlik / Duyuru Yönetimi',
                      ikon: Icons.campaign_outlined,
                      temaRengi: theme.primary,
                    ),
                    const SizedBox(height: 12),
                    TextField(controller: etkinlikBaslikController, decoration: stitchInputDekorasyonu(labelText: 'Başlık', temaRengi: theme.primary)),
                    const SizedBox(height: 10),
                    TextField(controller: etkinlikAciklamaController, maxLines: 3, decoration: stitchInputDekorasyonu(labelText: 'Açıklama', temaRengi: theme.primary)),
                    const SizedBox(height: 10),
                    TextField(
                      controller: etkinlikTarihController,
                      decoration: stitchInputDekorasyonu(
                        labelText: 'Tarih (YYYY-MM-DD, opsiyonel)',
                        hintText: '2026-05-20',
                        temaRengi: theme.primary,
                      ),
                    ),
                    SwitchListTile(
                      title: const Text('Aktif'),
                      value: etkinlikAktif,
                      onChanged: (v) => setState(() => etkinlikAktif = v),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: AppTooltip(
                            message: duzenlenenEtkinlikId == null ? 'Etkinlik ekle' : 'Etkinlik güncelle',
                            child: ElevatedButton.icon(
                              style: themedElevatedButtonStyle(theme),
                              onPressed: _etkinlikKaydet,
                              icon: Icon(duzenlenenEtkinlikId == null ? Icons.add : Icons.save),
                              label: Text(duzenlenenEtkinlikId == null ? 'Ekle' : 'Güncelle'),
                            ),
                          ),
                        ),
                        if (duzenlenenEtkinlikId != null) ...[
                          const SizedBox(width: 8),
                          TextButton(onPressed: _etkinlikFormuTemizle, child: const Text('İptal')),
                        ],
                      ],
                    ),
                  ],
                ),
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<CafeEventModel>>(
              future: etkinliklerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const AppLoadingView(kompakt: true);
                }
                if (snapshot.hasError) {
                  return AppErrorView(kompakt: true, hataDetayi: snapshot.error.toString());
                }
                final liste = snapshot.data ?? [];
                if (liste.isEmpty) {
                  return const AppEmptyView(kompakt: true, baslik: 'Etkinlik yok', aciklama: 'Yukarıdan yeni etkinlik ekleyebilirsiniz.');
                }
                return Column(
                  children: liste.map((e) {
                    return StitchKart(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(e.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text('${_tarihGoster(e.eventDate)}${e.description != null && e.description!.isNotEmpty ? '\n${e.description}' : ''}'),
                                const SizedBox(height: 4),
                                StitchEtiket(
                                  metin: e.isActive ? 'Aktif' : 'Pasif',
                                  renk: e.isActive ? Colors.green.shade700 : Colors.orange.shade800,
                                ),
                              ],
                            ),
                          ),
                          AppTooltip(
                            message: 'Etkinlik düzenle',
                            child: IconButton(icon: const Icon(Icons.edit), onPressed: () => _etkinlikDuzenle(e)),
                          ),
                          AppTooltip(
                            message: 'Etkinlik sil',
                            child: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _etkinlikSil(e)),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
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
