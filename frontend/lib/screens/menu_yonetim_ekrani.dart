// Flutter arayüz bileşenlerini kullanmak için import ediyoruz.
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

// Kategori modelini kullanıyoruz.
import '../models/kategori_model.dart';

// Ürün modelini kullanıyoruz.
import '../models/urun_model.dart';

// Backend API servis dosyasını kullanıyoruz.
import '../services/api_service.dart';

import '../utils/app_theme_helper.dart';
import '../widgets/app_themed_widgets.dart';
import '../widgets/app_feedback_widgets.dart';

// Menü yönetimi ekranıdır.
// Yönetici bu ekranda ürünleri listeler, yeni ürün ekler ve yeni kategori oluşturur.
class MenuYonetimEkrani extends StatefulWidget {
  // Constructor yapısıdır.
  const MenuYonetimEkrani({super.key});

  @override
  State<MenuYonetimEkrani> createState() => _MenuYonetimEkraniState();
}

// Menü yönetimi ekranındaki değişen verileri yöneten State sınıfıdır.
class _MenuYonetimEkraniState extends State<MenuYonetimEkrani>
    with CafeThemeScreenMixin {
  late Future<List<UrunModel>> urunlerFuture;
  final TextEditingController aramaController = TextEditingController();
  String aramaMetni = '';
  String? seciliKategoriFiltre;
  String urunDurumFiltre = 'all';

  @override
  void initState() {
    super.initState();
    initCafeThemeListener();
    urunlerFuture = ApiService.getProducts();
    aramaController.addListener(() {
      setState(() => aramaMetni = aramaController.text.trim());
    });
  }

  @override
  void dispose() {
    disposeCafeThemeListener();
    aramaController.dispose();
    super.dispose();
  }

  // Ürün listesini yeniden yükleyen fonksiyondur.
  void urunleriYenile() {
    setState(() {
      urunlerFuture = ApiService.getProducts();
    });
  }

  // Sayfa üst header aksiyonları — yenile, ürün ekle, geri dön.
  List<Widget> _ustAksiyonlar(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.refresh),
        tooltip: 'Yenile',
        onPressed: urunleriYenile,
      ),
      FilledButton.icon(
        style: themedElevatedButtonStyle(theme),
        onPressed: urunEklePenceresiAc,
        icon: const Icon(Icons.add, size: 20),
        label: const Text('Ürün Ekle'),
      ),
      OutlinedButton.icon(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back),
        label: const Text('Geri Dön'),
      ),
    ];
  }

  List<UrunModel> _urunleriFiltrele(List<UrunModel> urunler) {
    var sonuc = urunler;

    if (seciliKategoriFiltre != null && seciliKategoriFiltre!.isNotEmpty) {
      sonuc = sonuc
          .where((u) => u.categoryName == seciliKategoriFiltre)
          .toList();
    }

    if (aramaMetni.isNotEmpty) {
      final q = aramaMetni.toLowerCase();
      sonuc = sonuc.where((u) {
        return u.name.toLowerCase().contains(q) ||
            u.categoryName.toLowerCase().contains(q) ||
            u.description.toLowerCase().contains(q);
      }).toList();
    }

    switch (urunDurumFiltre) {
      case 'aktif':
        sonuc = sonuc.where((u) => u.isActive).toList();
        break;
      case 'pasif':
        sonuc = sonuc.where((u) => !u.isActive).toList();
        break;
      case 'qr_goster':
        sonuc = sonuc.where((u) => u.isVisible).toList();
        break;
      case 'qr_gizli':
        sonuc = sonuc.where((u) => !u.isVisible).toList();
        break;
    }

    sonuc.sort((a, b) {
      final k = a.categoryName.compareTo(b.categoryName);
      if (k != 0) return k;
      return a.name.compareTo(b.name);
    });

    return sonuc;
  }

  Widget _durumFiltreChip(String etiket, String deger) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: StitchFiltreChip(
        etiket: etiket,
        secili: urunDurumFiltre == deger,
        temaRengi: theme.primary,
        onTap: () => setState(() => urunDurumFiltre = deger),
      ),
    );
  }

  Future<void> urunHizliGuncelle(
    UrunModel urun, {
    bool? yeniAktif,
    bool? yeniGorunur,
  }) async {
    try {
      final kategoriler = await ApiService.getCategories();
      final kategori = kategoriler.firstWhere(
        (k) => k.name == urun.categoryName,
        orElse: () => kategoriler.first,
      );

      await ApiService.updateProduct(
        productId: urun.id,
        name: urun.name,
        price: urun.price,
        categoryId: kategori.id,
        description: urun.description,
        isActive: yeniAktif ?? urun.isActive,
        isVisible: yeniGorunur ?? urun.isVisible,
      );

      if (!mounted) return;
      showAppPopup(
        context,
        message: 'Ürün güncellendi.',
        type: AppPopupType.success,
      );
      urunleriYenile();
    } catch (error) {
      if (!mounted) return;
      showAppPopup(
        context,
        message: ApiService.kullaniciHataMesaji(error),
        type: AppPopupType.error,
      );
    }
  }

  Future<void> urunGorselPenceresiAc(UrunModel urun) async {
    PlatformFile? seciliDosya;
    String? mevcutGorselUrl = urun.imageUrl;
    final mesajBaglami = context;

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
                constraints: const BoxConstraints(maxWidth: 520),
                child: StitchKart(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        StitchBolumBasligi(
                          baslik: 'Görsel Yönetimi',
                          ikon: Icons.image_outlined,
                          temaRengi: theme.primary,
                          altBaslik: urun.name,
                        ),
                        const SizedBox(height: 14),
                        gorselYonetimPaneli(
                          mesajBaglami: mesajBaglami,
                          productId: urun.id,
                          mevcutImageUrl: mevcutGorselUrl,
                          seciliDosya: seciliDosya,
                          onDosyaDegisti: (dosya) {
                            seciliDosya = dosya;
                          },
                          onMevcutGorselDegisti: (url) {
                            mevcutGorselUrl = url;
                          },
                          dialogStateGuncelle: () => setDialogState(() {}),
                          onListeYenile: urunleriYenile,
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text('Kapat'),
                          ),
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
  }

  // Ürün kartları bölümü — liste içinde render edilir.
  Widget _urunKarti(UrunModel urun) {
    final aciklama = urun.description.trim().isEmpty
        ? 'Açıklama yok'
        : urun.description.trim();

    return StitchKart(
      margin: const EdgeInsets.only(bottom: 12),
      kenarlikRengi: theme.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 88,
                  height: 88,
                  child: urunGorselOnizleme(urun.imageUrl, boyut: 88),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      urun.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    StitchEtiket(
                      metin: urun.categoryName,
                      renk: theme.primary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      aciklama,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FiyatEtiketi(fiyat: urun.price, temaRengi: theme.primary),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        StitchEtiket(
                          metin: urun.isActive ? 'Aktif' : 'Pasif',
                          renk: urun.isActive
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                        ),
                        StitchEtiket(
                          metin: urun.isVisible
                              ? 'QR Menüde Görünür'
                              : 'QR Menüde Gizli',
                          renk: urun.isVisible
                              ? theme.primary
                              : Colors.orange.shade800,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Düzenle'),
                onPressed: () => urunDuzenlePenceresiAc(urun),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.image_outlined, size: 18),
                label: const Text('Görsel Yönetimi'),
                onPressed: () => urunGorselPenceresiAc(urun),
              ),
              OutlinedButton.icon(
                icon: Icon(
                  urun.isVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 18,
                ),
                label: Text(urun.isVisible ? 'Gizle' : 'Göster'),
                onPressed: () => urunHizliGuncelle(
                  urun,
                  yeniGorunur: !urun.isVisible,
                ),
              ),
              OutlinedButton.icon(
                icon: Icon(
                  urun.isActive ? Icons.block : Icons.check_circle_outline,
                  size: 18,
                ),
                label: Text(urun.isActive ? 'Pasif Yap' : 'Aktif Yap'),
                onPressed: () => urunHizliGuncelle(
                  urun,
                  yeniAktif: !urun.isActive,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _aramaVeFiltreAlani(List<String> kategoriler) {
    return StitchKart(
      kenarlikRengi: theme.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filtre/arama bölümü.
          TextField(
            controller: aramaController,
            decoration: stitchInputDekorasyonu(
              hintText: 'Ürün adı, kategori veya açıklama ara...',
              prefixIcon: Icons.search,
              temaRengi: theme.primary,
              suffixIcon: aramaMetni.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => aramaController.clear(),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Durum',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _durumFiltreChip('Tümü', 'all'),
                _durumFiltreChip('Aktif', 'aktif'),
                _durumFiltreChip('Pasif', 'pasif'),
                _durumFiltreChip('QR Görünür', 'qr_goster'),
                _durumFiltreChip('QR Gizli', 'qr_gizli'),
              ],
            ),
          ),
          if (kategoriler.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text(
              'Kategori',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: StitchFiltreChip(
                      etiket: 'Tümü',
                      secili: seciliKategoriFiltre == null,
                      temaRengi: theme.primary,
                      onTap: () =>
                          setState(() => seciliKategoriFiltre = null),
                    ),
                  ),
                  ...kategoriler.map(
                    (k) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: StitchFiltreChip(
                        etiket: k,
                        secili: seciliKategoriFiltre == k,
                        temaRengi: theme.primary,
                        onTap: () =>
                            setState(() => seciliKategoriFiltre = k),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Yeni kategori ekleme penceresini açan fonksiyondur.
  Future<KategoriModel?> kategoriEklePenceresiAc() async {
    // Kategori adı için controller oluşturulur.
    final TextEditingController kategoriAdiController =
        TextEditingController();

    try {
      // Yeni kategori ekleme dialogu açılır.
      final yeniKategori = await showDialog<KategoriModel>(
        context: context,
        builder: (context) {
          return AlertDialog(
            // Dialog başlığıdır.
            title: const Text('Yeni Kategori Ekle'),

            // Dialog içeriğidir.
            content: SizedBox(
              width: 380,
              child: TextField(
                controller: kategoriAdiController,
                decoration: const InputDecoration(
                  labelText: 'Kategori Adı',
                  border: OutlineInputBorder(),
                ),
              ),
            ),

            // Dialog butonlarıdır.
            actions: [
              AppTooltip(
                message: 'İşlemi iptal et',
                child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Vazgeç'),
              ),
              ),

              AppTooltip(
                message: 'Kategoriyi kaydet',
                child: ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Kaydet'),
                onPressed: () async {
                  // Girilen kategori adı alınır.
                  final kategoriAdi = kategoriAdiController.text.trim();

                  // Kategori adı boşsa kullanıcı uyarılır.
                  if (kategoriAdi.isEmpty) {
                    showAppPopup(
                      context,
                      message: 'Kategori adı boş bırakılamaz.',
                      type: AppPopupType.warning,
                    );
                    return;
                  }

                  try {
                    final kategori = await ApiService.addCategory(
                      name: kategoriAdi,
                    );

                    showAppPopup(
                      context,
                      message: 'Kategori başarıyla eklendi.',
                      type: AppPopupType.success,
                    );

                    Navigator.pop(context, kategori);
                  } catch (error) {
                    showAppPopup(
                      context,
                      message: 'Kategori eklenemedi: $error',
                      type: AppPopupType.error,
                    );
                  }
                },
              ),
              ),
            ],
          );
        },
      );

      // Eklenen kategori geri döndürülür.
      return yeniKategori;
    } finally {
      // Controller bellekten temizlenir.
      kategoriAdiController.dispose();
    }
  }

  // Dosya uzantısını extension alanından veya dosya adından okur.
  String? dosyaUzantisiAl(PlatformFile dosya) {
    if (dosya.extension != null && dosya.extension!.trim().isNotEmpty) {
      return dosya.extension!.toLowerCase();
    }

    final dosyaAdi = dosya.name.toLowerCase();
    final noktaIndex = dosyaAdi.lastIndexOf('.');

    if (noktaIndex != -1 && noktaIndex < dosyaAdi.length - 1) {
      return dosyaAdi.substring(noktaIndex + 1);
    }

    return null;
  }

  // Bilgisayardan ürün görseli seçer (Flutter Web + dialog uyumlu).
  Future<PlatformFile?> gorselDosyasiSec(
    BuildContext mesajBaglami,
  ) async {
    const izinliUzantilar = ['jpg', 'jpeg', 'png', 'webp'];

    try {
      // Dialog açıkken Web'de dosya seçicinin açılması için odak kaldırılır.
      FocusManager.instance.primaryFocus?.unfocus();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final sonuc = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: izinliUzantilar,
        withData: true,
        allowMultiple: false,
      );

      if (sonuc == null || sonuc.files.isEmpty) {
        return null;
      }

      final dosya = sonuc.files.first;
      final uzanti = dosyaUzantisiAl(dosya);

      if (uzanti == null || !izinliUzantilar.contains(uzanti)) {
        showAppPopup(
          mesajBaglami,
          message: 'Sadece JPG, JPEG, PNG veya WEBP dosyaları seçilebilir.',
          type: AppPopupType.warning,
        );
        return null;
      }

      if (dosya.bytes == null) {
        showAppPopup(
          mesajBaglami,
          message: 'Dosya okunamadı. Lütfen tekrar seçiniz.',
          type: AppPopupType.warning,
        );
        return null;
      }

      return dosya;
    } catch (error) {
      showAppPopup(
        mesajBaglami,
        message: 'Görsel seçilemedi: $error',
        type: AppPopupType.error,
      );
      return null;
    }
  }

  // Ürün görsel önizlemesi (sunucu yolu veya tam URL).
  Widget urunGorselOnizleme(String? imageUrl, {double boyut = 56}) {
    final gorselUrl = ApiService.getProductImageUrl(imageUrl);

    if (gorselUrl.isEmpty) {
      return Icon(
        Icons.image_not_supported_outlined,
        color: Colors.brown.shade300,
        size: boyut * 0.85,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        gorselUrl,
        width: boyut,
        height: boyut,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            Icons.broken_image_outlined,
            color: Colors.brown.shade300,
            size: boyut * 0.7,
          );
        },
      ),
    );
  }

  // Seçilen dosya veya mevcut ürün görseli için önizleme kutusu.
  Widget gorselOnizlemeKutusu({
    required String? mevcutImageUrl,
    required PlatformFile? seciliDosya,
    double boyut = 80,
  }) {
    if (seciliDosya != null && seciliDosya.bytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.memory(
          seciliDosya.bytes!,
          width: boyut,
          height: boyut,
          fit: BoxFit.cover,
        ),
      );
    }

    return SizedBox(
      width: boyut,
      height: boyut,
      child: urunGorselOnizleme(mevcutImageUrl, boyut: boyut),
    );
  }

  // Dialog içinde görsel seç / yükle / kaldır butonları.
  Widget gorselYonetimPaneli({
    required BuildContext mesajBaglami,
    required int? productId,
    required String? mevcutImageUrl,
    required PlatformFile? seciliDosya,
    required void Function(PlatformFile?) onDosyaDegisti,
    required void Function(String?) onMevcutGorselDegisti,
    required VoidCallback dialogStateGuncelle,
    required VoidCallback onListeYenile,
  }) {
    final mevcutGorselVar =
        mevcutImageUrl != null && mevcutImageUrl.trim().isNotEmpty;
    final seciliGorselVar = seciliDosya != null;
    final yuklemeYapilabilir = productId != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ürün Görseli',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.brown,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            gorselOnizlemeKutusu(
              mevcutImageUrl: mevcutImageUrl,
              seciliDosya: seciliDosya,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTooltip(
                    message: 'Bilgisayardan görsel seç',
                    child: OutlinedButton.icon(
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Görsel Seç'),
                    onPressed: () async {
                      final dosya =
                          await gorselDosyasiSec(mesajBaglami);
                      if (dosya != null) {
                        onDosyaDegisti(dosya);
                        dialogStateGuncelle();
                      }
                    },
                  ),
                  ),
                  const SizedBox(height: 8),
                  AppTooltip(
                    message: 'Seçilen görseli sunucuya yükle',
                    child: ElevatedButton.icon(
                    icon: const Icon(Icons.cloud_upload_outlined),
                    label: const Text('Görsel Yükle'),
                    onPressed: !yuklemeYapilabilir
                        ? null
                        : () async {
                            if (!seciliGorselVar) {
                              showAppPopup(
                                mesajBaglami,
                                message: 'Lütfen önce görsel seçiniz.',
                                type: AppPopupType.warning,
                              );
                              return;
                            }

                            try {
                              final response =
                                  await ApiService.uploadProductImage(
                                productId: productId!,
                                file: seciliDosya!,
                              );

                              onDosyaDegisti(null);
                              onMevcutGorselDegisti(
                                response['imageUrl']?.toString(),
                              );
                              dialogStateGuncelle();
                              onListeYenile();

                              showAppPopup(
                                mesajBaglami,
                                message: response['message']?.toString() ??
                                    'Ürün görseli başarıyla yüklendi.',
                                type: AppPopupType.success,
                              );
                            } catch (error) {
                              showAppPopup(
                                mesajBaglami,
                                message: ApiService.kullaniciHataMesaji(error),
                                type: AppPopupType.error,
                              );
                            }
                          },
                  ),
                  ),
                  const SizedBox(height: 8),
                  AppTooltip(
                    message: 'Ürün görselini kaldır',
                    child: TextButton.icon(
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Görseli Kaldır'),
                    onPressed: !yuklemeYapilabilir || !mevcutGorselVar
                        ? null
                        : () async {
                            try {
                              final response =
                                  await ApiService.deleteProductImage(
                                productId: productId!,
                              );

                              onDosyaDegisti(null);
                              onMevcutGorselDegisti(null);
                              dialogStateGuncelle();
                              onListeYenile();

                              showAppPopup(
                                mesajBaglami,
                                message: response['message']?.toString() ??
                                    'Ürün görseli kaldırıldı.',
                                type: AppPopupType.success,
                              );
                            } catch (error) {
                              showAppPopup(
                                mesajBaglami,
                                message: ApiService.kullaniciHataMesaji(error),
                                type: AppPopupType.error,
                              );
                            }
                          },
                  ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Ürün düzenleme penceresini açan fonksiyondur.
  Future<void> urunDuzenlePenceresiAc(UrunModel urun) async {
    final TextEditingController urunAdiController =
        TextEditingController(text: urun.name);
    final TextEditingController fiyatController =
        TextEditingController(text: urun.price.toStringAsFixed(2));
    final TextEditingController aciklamaController =
        TextEditingController(text: urun.description);

    bool musteriMenudeGorunsun = urun.isVisible;
    bool urunAktif = urun.isActive;
    KategoriModel? seciliKategori;
    PlatformFile? seciliGorselDosyasi;
    String? mevcutGorselUrl = urun.imageUrl;

    try {
      final List<KategoriModel> kategoriler = await ApiService.getCategories();

      seciliKategori = kategoriler.firstWhere(
        (kategori) => kategori.name == urun.categoryName,
        orElse: () => kategoriler.first,
      );


      final sonuc = await showDialog<bool>(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text('Ürün Düzenle'),
                content: SizedBox(
                  width: 480,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: urunAdiController,
                          decoration: const InputDecoration(
                            labelText: 'Ürün Adı',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: fiyatController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Fiyat',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<KategoriModel>(
                          value: seciliKategori,
                          decoration: const InputDecoration(
                            labelText: 'Kategori',
                            border: OutlineInputBorder(),
                          ),
                          items: kategoriler.map((kategori) {
                            return DropdownMenuItem<KategoriModel>(
                              value: kategori,
                              child: Text(kategori.name),
                            );
                          }).toList(),
                          onChanged: (yeniKategori) {
                            setDialogState(() {
                              seciliKategori = yeniKategori;
                            });
                          },
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: aciklamaController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Açıklama',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 14),
                        gorselYonetimPaneli(
                          mesajBaglami: context,
                          productId: urun.id,
                          mevcutImageUrl: mevcutGorselUrl,
                          seciliDosya: seciliGorselDosyasi,
                          onDosyaDegisti: (dosya) {
                            seciliGorselDosyasi = dosya;
                          },
                          onMevcutGorselDegisti: (yeniUrl) {
                            mevcutGorselUrl = yeniUrl;
                          },
                          dialogStateGuncelle: () {
                            setDialogState(() {});
                          },
                          onListeYenile: urunleriYenile,
                        ),
                        const SizedBox(height: 10),
                        SwitchListTile(
                          title: const Text('Müşteri menüsünde görünsün'),
                          value: musteriMenudeGorunsun,
                          onChanged: (deger) {
                            setDialogState(() {
                              musteriMenudeGorunsun = deger;
                            });
                          },
                        ),
                        SwitchListTile(
                          title: const Text('Aktif ürün'),
                          value: urunAktif,
                          onChanged: (deger) {
                            setDialogState(() {
                              urunAktif = deger;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  AppTooltip(
                    message: 'İşlemi iptal et',
                    child: TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Vazgeç'),
                  ),
                  ),
                  AppTooltip(
                    message: 'Ürün değişikliklerini kaydet',
                    child: ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('Kaydet'),
                    onPressed: () async {
                      final urunAdi = urunAdiController.text.trim();
                      final fiyatText = fiyatController.text
                          .trim()
                          .replaceAll(',', '.');
                      final fiyat = double.tryParse(fiyatText);

                      if (urunAdi.isEmpty) {
                        showAppPopup(
                          context,
                          message: 'Ürün adı boş bırakılamaz.',
                          type: AppPopupType.warning,
                        );
                        return;
                      }

                      if (fiyat == null || fiyat <= 0) {
                        showAppPopup(
                          context,
                          message: 'Geçerli bir fiyat giriniz.',
                          type: AppPopupType.warning,
                        );
                        return;
                      }

                      if (seciliKategori == null) {
                        showAppPopup(
                          context,
                          message: 'Kategori seçiniz.',
                          type: AppPopupType.warning,
                        );
                        return;
                      }

                      try {
                        final response = await ApiService.updateProduct(
                          productId: urun.id,
                          name: urunAdi,
                          price: fiyat,
                          categoryId: seciliKategori!.id,
                          description: aciklamaController.text.trim(),
                          isVisible: musteriMenudeGorunsun,
                          isActive: urunAktif,
                        );

                        if (seciliGorselDosyasi != null) {
                          await ApiService.uploadProductImage(
                            productId: urun.id,
                            file: seciliGorselDosyasi!,
                          );
                        }

                        if (!context.mounted) return;

                        showAppPopup(
                          context,
                          message: response['message']?.toString() ??
                              'Ürün güncellendi.',
                          type: AppPopupType.success,
                        );

                        Navigator.pop(context, true);
                      } catch (error) {
                        if (!context.mounted) return;

                        showAppPopup(
                          context,
                          message: 'Ürün güncellenemedi: $error',
                          type: AppPopupType.error,
                        );
                      }
                    },
                  ),
                  ),
                ],
              );
            },
          );
        },
      );

      if (sonuc == true) {
        urunleriYenile();
      }
    } catch (error) {
      showAppPopup(
        context,
        message: 'Kategoriler yüklenemedi: $error',
        type: AppPopupType.error,
      );
    } finally {
      urunAdiController.dispose();
      fiyatController.dispose();
      aciklamaController.dispose();
    }
  }

  // Ürün ekleme penceresini açan fonksiyondur.
  Future<void> urunEklePenceresiAc() async {
    // Ürün adı input alanını kontrol etmek için controller kullanılır.
    final TextEditingController urunAdiController = TextEditingController();

    // Fiyat input alanını kontrol etmek için controller kullanılır.
    final TextEditingController fiyatController = TextEditingController();

    // Açıklama alanı.
    final TextEditingController aciklamaController = TextEditingController();

    // Seçilen kategori bilgisini tutar.
    KategoriModel? seciliKategori;

    // Yeni ürün varsayılan olarak müşteri menüsünde görünür.
    bool musteriMenudeGorunsun = true;

    // Ürün oluşturulduktan sonra yüklenecek görsel dosyası.
    PlatformFile? seciliGorselDosyasi;

    try {
      // Kategoriler backend API'den çekilir.
      List<KategoriModel> kategoriler = await ApiService.getCategories();

      // Eğer kategori varsa ilk kategori varsayılan olarak seçilir.
      if (kategoriler.isNotEmpty) {
        seciliKategori = kategoriler.first;
      }


      // Ürün ekleme dialogu açılır.
      final sonuc = await showDialog<bool>(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                // Dialog başlığıdır.
                title: const Text('Yeni Ürün Ekle'),

                // Dialog içeriğidir.
                content: SizedBox(
                  width: 440,

                  // İçerik küçük ekranlarda taşmasın diye kaydırılabilir yapılır.
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Ürün adı input alanı.
                        TextField(
                          controller: urunAdiController,
                          decoration: const InputDecoration(
                            labelText: 'Ürün Adı',
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Fiyat input alanı.
                        TextField(
                          controller: fiyatController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Fiyat',
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Kategori seçme alanı.
                        DropdownButtonFormField<KategoriModel>(
                          value: seciliKategori,
                          decoration: const InputDecoration(
                            labelText: 'Kategori',
                            border: OutlineInputBorder(),
                          ),

                          // Kategoriler dropdown itemlarına çevrilir.
                          items: kategoriler.map((kategori) {
                            return DropdownMenuItem<KategoriModel>(
                              value: kategori,
                              child: Text(kategori.name),
                            );
                          }).toList(),

                          // Kategori değiştirildiğinde seçili kategori güncellenir.
                          onChanged: (yeniKategori) {
                            setDialogState(() {
                              seciliKategori = yeniKategori;
                            });
                          },
                        ),

                        const SizedBox(height: 14),

                        TextField(
                          controller: aciklamaController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Açıklama',
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 14),

                        gorselYonetimPaneli(
                          mesajBaglami: context,
                          productId: null,
                          mevcutImageUrl: null,
                          seciliDosya: seciliGorselDosyasi,
                          onDosyaDegisti: (dosya) {
                            seciliGorselDosyasi = dosya;
                          },
                          onMevcutGorselDegisti: (_) {},
                          dialogStateGuncelle: () {
                            setDialogState(() {});
                          },
                          onListeYenile: urunleriYenile,
                        ),

                        const SizedBox(height: 8),

                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Müşteri menüsünde görünsün'),
                          value: musteriMenudeGorunsun,
                          onChanged: (deger) {
                            setDialogState(() {
                              musteriMenudeGorunsun = deger;
                            });
                          },
                        ),

                        // Yeni kategori ekleme butonu.
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Yeni Kategori Ekle'),
                            onPressed: () async {
                              // Yeni kategori ekleme penceresi açılır.
                              final yeniKategori =
                                  await kategoriEklePenceresiAc();

                              // Yeni kategori başarıyla eklendiyse dropdown listesine eklenir.
                              if (yeniKategori != null) {
                                setDialogState(() {
                                  kategoriler = [
                                    ...kategoriler,
                                    yeniKategori,
                                  ];

                                  // Yeni eklenen kategori otomatik seçili hale getirilir.
                                  seciliKategori = yeniKategori;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Dialog alt butonlarıdır.
                actions: [
                  AppTooltip(
                    message: 'İşlemi iptal et',
                    child: TextButton(
                    onPressed: () {
                      Navigator.pop(context, false);
                    },
                    child: const Text('Vazgeç'),
                  ),
                  ),

                  AppTooltip(
                    message: 'Yeni ürünü kaydet',
                    child: ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('Kaydet'),
                    onPressed: () async {
                      // Ürün adı alınır.
                      final urunAdi = urunAdiController.text.trim();

                      // Fiyat değeri alınır.
                      // Kullanıcı virgül girerse noktaya çevrilir.
                      final fiyatText =
                          fiyatController.text.trim().replaceAll(',', '.');

                      // Fiyat double türüne çevrilir.
                      final fiyat = double.tryParse(fiyatText);

                      // Ürün adı boşsa uyarı verilir.
                      if (urunAdi.isEmpty) {
                        showAppPopup(
                          context,
                          message: 'Ürün adı boş bırakılamaz.',
                          type: AppPopupType.warning,
                        );
                        return;
                      }

                      if (fiyat == null || fiyat <= 0) {
                        showAppPopup(
                          context,
                          message: 'Geçerli bir fiyat giriniz.',
                          type: AppPopupType.warning,
                        );
                        return;
                      }

                      if (seciliKategori == null) {
                        showAppPopup(
                          context,
                          message:
                              'Kategori seçiniz veya yeni kategori ekleyiniz.',
                          type: AppPopupType.warning,
                        );
                        return;
                      }

                      try {
                        // Ürün backend API'ye gönderilir.
                        final response = await ApiService.addProduct(
                          categoryId: seciliKategori!.id,
                          name: urunAdi,
                          price: fiyat,
                          description: aciklamaController.text.trim(),
                          isVisible: musteriMenudeGorunsun,
                        );

                        final yeniUrunId = response['product']?['id'];

                        if (seciliGorselDosyasi != null && yeniUrunId != null) {
                          await ApiService.uploadProductImage(
                            productId: yeniUrunId as int,
                            file: seciliGorselDosyasi!,
                          );
                        }

                        if (!context.mounted) return;

                        showAppPopup(
                          context,
                          message: response['message']?.toString() ??
                              'Ürün başarıyla eklendi.',
                          type: AppPopupType.success,
                        );

                        Navigator.pop(context, true);
                      } catch (error) {
                        showAppPopup(
                          context,
                          message: 'Ürün eklenemedi: $error',
                          type: AppPopupType.error,
                        );
                      }
                    },
                  ),
                  ),
                ],
              );
            },
          );
        },
      );

      // Ürün başarıyla eklendiyse ürün listesi yenilenir.
      if (sonuc == true) {
        urunleriYenile();
      }
    } catch (error) {
      showAppPopup(
        context,
        message: 'Kategoriler yüklenemedi: $error',
        type: AppPopupType.error,
      );
    } finally {
      // Controller nesneleri temizlenir.
      urunAdiController.dispose();
      fiyatController.dispose();
      aciklamaController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return themedRoot(
      Scaffold(
        backgroundColor: AppThemeHelper.sayfaZemin,
        body: SafeArea(
          child: FutureBuilder<List<UrunModel>>(
            future: urunlerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const AppLoadingView(mesaj: 'Ürünler yükleniyor...');
              }

              if (snapshot.hasError) {
                return AppErrorView(
                  hataDetayi: snapshot.error.toString(),
                  tekrarDene: urunleriYenile,
                );
              }

              final tumUrunler = snapshot.data ?? [];
              final kategoriAdlari = tumUrunler
                  .map((u) => u.categoryName)
                  .toSet()
                  .toList()
                ..sort();
              final filtrelenmis = _urunleriFiltrele(tumUrunler);

              final aktifSayisi =
                  tumUrunler.where((u) => u.isActive).length;
              final qrGorunen =
                  tumUrunler.where((u) => u.isVisible).length;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 960),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Sayfa başlığı/header bölümü.
                        PanelBaslikAlani(
                          baslik: 'Menü Yönetimi',
                          altBaslik:
                              'Ürünleri, kategorileri ve QR menü görünürlüğünü buradan yönetin.',
                          tema: theme,
                          logoUrl: cafeLogoUrl,
                          aksiyonlar: _ustAksiyonlar(context),
                        ),
                        const SizedBox(height: 20),
                        if (tumUrunler.isNotEmpty) ...[
                          OzetKartSatiri(
                            kartlar: [
                              OzetKart(
                                baslik: 'Toplam Ürün',
                                deger: '${tumUrunler.length}',
                                ikon: Icons.restaurant_menu,
                                tema: theme,
                              ),
                              OzetKart(
                                baslik: 'Aktif Ürün',
                                deger: '$aktifSayisi',
                                ikon: Icons.check_circle_outline,
                                tema: theme,
                              ),
                              OzetKart(
                                baslik: 'QR Menüde Görünen',
                                deger: '$qrGorunen',
                                ikon: Icons.qr_code_2,
                                tema: theme,
                              ),
                              OzetKart(
                                baslik: 'Kategori Sayısı',
                                deger: '${kategoriAdlari.length}',
                                ikon: Icons.category_outlined,
                                tema: theme,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _aramaVeFiltreAlani(kategoriAdlari),
                          const SizedBox(height: 20),
                        ],
                        if (tumUrunler.isEmpty)
                          AppEmptyView(
                            ikon: Icons.restaurant_menu,
                            baslik: 'Menüde ürün bulunmuyor.',
                            aciklama:
                                'Üstteki Ürün Ekle ile yeni ürün ekleyebilirsiniz.',
                            aksiyonMetni: 'Ürün Ekle',
                            aksiyon: urunEklePenceresiAc,
                          )
                        else if (filtrelenmis.isEmpty)
                          const AppEmptyView(
                            baslik: 'Filtreye uygun ürün bulunamadı.',
                            aciklama:
                                'Arama veya filtreleri değiştirerek tekrar deneyin.',
                          )
                        else ...[
                          OutlinedButton.icon(
                            onPressed: () => kategoriEklePenceresiAc(),
                            icon: const Icon(Icons.create_new_folder_outlined),
                            label: const Text('Kategori Yönetimi / Yeni Kategori'),
                          ),
                          const SizedBox(height: 16),
                          ...() {
                            final Map<String, List<UrunModel>> gruplu = {};
                            for (final urun in filtrelenmis) {
                              gruplu.putIfAbsent(urun.categoryName, () => []);
                              gruplu[urun.categoryName]!.add(urun);
                            }
                            final siraliKategoriler = gruplu.keys.toList()
                              ..sort();
                            return siraliKategoriler.expand((kategoriAdi) {
                              return [
                                StitchBolumBasligi(
                                  baslik: kategoriAdi,
                                  ikon: Icons.category_outlined,
                                  temaRengi: theme.primary,
                                ),
                                const SizedBox(height: 10),
                                ...gruplu[kategoriAdi]!.map(_urunKarti),
                                const SizedBox(height: 8),
                              ];
                            });
                          }(),
                        ],
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
}