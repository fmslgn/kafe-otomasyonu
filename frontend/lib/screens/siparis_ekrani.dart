// Flutter arayüz bileşenlerini kullanmak için import ediyoruz.
import 'package:flutter/material.dart';

// Giriş yapan kullanıcı modelini kullanıyoruz.
// Sipariş kaydedilirken gerçek garson id bilgisini göndermek için gereklidir.
import '../models/app_user_model.dart';

// Ürün modelini kullanıyoruz.
import '../models/urun_model.dart';

// Backend API'den ürün ve aktif sipariş çekmek için servis dosyasını kullanıyoruz.
import '../services/api_service.dart';
import '../utils/app_theme_helper.dart';

import '../widgets/app_feedback_widgets.dart';
import '../widgets/app_themed_widgets.dart';

// Seçilen masaya ait sipariş ekranıdır.
// StatefulWidget kullanıyoruz çünkü kategori seçimi, sepet, not ve toplam tutar değişiyor.
class SiparisEkrani extends StatefulWidget {
  // Seçilen masa numarasıdır.
  final int masaNo;

  // Giriş yapan garson bilgisidir.
  // Sipariş kaydedilirken userId olarak bu kullanıcının id değeri gönderilir.
  final AppUserModel kullanici;

  // Constructor yapısıdır.
  const SiparisEkrani({
    super.key,
    required this.masaNo,
    required this.kullanici,
  });

  @override
  State<SiparisEkrani> createState() => _SiparisEkraniState();
}

// Sipariş ekranındaki değişen verileri yöneten State sınıfıdır.
class _SiparisEkraniState extends State<SiparisEkrani>
    with CafeThemeScreenMixin {
  // API'den gelecek ürün listesini tutar.
  late Future<List<UrunModel>> urunlerFuture;

  // Seçili kategori bilgisidir.
  String? seciliKategori;

  // Masa sipariş notu için controller.
  // Örnek: "Acısız olsun", "Soğansız", "Paket yapılacak".
  final TextEditingController siparisNotuController =
      TextEditingController();

  // Sepetteki ürünleri ve adetlerini tutar.
  // Key: Ürün
  // Value: Adet
  final Map<UrunModel, int> sepet = {};

  @override
  void initState() {
    super.initState();
    initCafeThemeListener();

    // Sayfa açıldığında hem ürünleri hem de varsa aktif masa siparişini yüklüyoruz.
    urunlerFuture = urunleriVeAktifSiparisiYukle();
  }

  @override
  void dispose() {
    disposeCafeThemeListener();
    // Not controller temizlenir.
    siparisNotuController.dispose();

    super.dispose();
  }

  // Ürünleri ve seçilen masanın aktif siparişini backend'den yükler.
  Future<List<UrunModel>> urunleriVeAktifSiparisiYukle() async {
    // Önce ürün listesi backend API'den çekilir.
    final urunler = await ApiService.getProducts();

    // Sonra seçili masanın aktif siparişi backend API'den çekilir.
    final aktifSiparis = await ApiService.getActiveOrder(widget.masaNo);

    // Sepet önce temizlenir.
    // Eğer aktif sipariş varsa tekrar doldurulur.
    sepet.clear();

    // Aktif sipariş yoksa not alanı temizlenir.
    if (aktifSiparis == null) {
      siparisNotuController.clear();
      return urunler;
    }

    // Aktif sipariş notu varsa not alanına yazılır.
    siparisNotuController.text = aktifSiparis['note']?.toString() ?? '';

    // Eğer masaya ait aktif sipariş varsa sepet doldurulur.
    if (aktifSiparis['items'] != null) {
      // Aktif siparişteki ürünler alınır.
      final List<dynamic> items = aktifSiparis['items'];

      // Her sipariş ürünü sepete eklenir.
      for (final item in items) {
        // Backend'den gelen ürün id değeri alınır.
        final int productId = int.parse(item['product_id'].toString());

        // Backend'den gelen adet bilgisi alınır.
        final int quantity = int.parse(item['quantity'].toString());

        // Ürün listesinde bu id'ye sahip ürün aranır.
        final bulunanUrunler =
            urunler.where((urun) => urun.id == productId).toList();

        // Ürün bulunursa sepete eklenir.
        if (bulunanUrunler.isNotEmpty) {
          sepet[bulunanUrunler.first] = quantity;
        }
      }
    }

    // FutureBuilder'a ürün listesi döndürülür.
    return urunler;
  }

  // Sepetin toplam tutarını hesaplar.
  double get toplamTutar {
    double toplam = 0;

    // Sepetteki her ürün için fiyat * adet hesabı yapılır.
    sepet.forEach((urun, adet) {
      toplam += urun.price * adet;
    });

    return toplam;
  }

  // Sepete ürün ekleyen fonksiyondur.
  void sepeteEkle(UrunModel urun) {
    setState(() {
      // Ürün sepette varsa adeti artırılır.
      // Yoksa 1 adet olarak sepete eklenir.
      sepet[urun] = (sepet[urun] ?? 0) + 1;
    });
  }

  // Sepetteki ürün adetini azaltan fonksiyondur.
  void adetAzalt(UrunModel urun) {
    setState(() {
      // Ürün sepette yoksa işlem yapılmaz.
      if (!sepet.containsKey(urun)) return;

      // Adet 1'den büyükse adet azaltılır.
      if (sepet[urun]! > 1) {
        sepet[urun] = sepet[urun]! - 1;
      } else {
        // Adet 1 ise ürün sepetten tamamen kaldırılır.
        sepet.remove(urun);
      }
    });
  }

  // Siparişi veritabanına kaydeden fonksiyondur.
  Future<void> siparisiKaydet() async {
    // Sepet boşsa kullanıcıya uyarı verilir.
    if (sepet.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sipariş kaydetmek için sepete ürün eklemelisiniz.'),
        ),
      );
      return;
    }

    try {
      // Sepetteki ürünler backend'in istediği formata çevrilir.
      final List<Map<String, dynamic>> items = sepet.entries.map((entry) {
        return {
          'productId': entry.key.id,
          'quantity': entry.value,
        };
      }).toList();

      // Sipariş notu alınır.
      final siparisNotu = siparisNotuController.text.trim();

      // Sipariş backend API'ye gönderilir.
      // userId giriş yapan garsonun gerçek id değeridir.
      // note alanı masa sipariş notunu gönderir.
      final response = await ApiService.createOrder(
        tableNo: widget.masaNo,
        userId: widget.kullanici.id,
        items: items,
        note: siparisNotu.isEmpty ? null : siparisNotu,
      );

      if (!mounted) return;

      // Sipariş başarılı kaydedilirse kullanıcıya mesaj gösterilir.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${response['message']} Toplam: ${response['totalPrice']} TL',
          ),
        ),
      );

      // Sipariş kaydedildikten sonra aktif sipariş tekrar yüklenir.
      // Böylece masa içinde kayıtlı ürünler ve not görünmeye devam eder.
      setState(() {
        urunlerFuture = urunleriVeAktifSiparisiYukle();
      });
    } catch (error) {
      if (!mounted) return;

      // Hata olursa kullanıcıya hata mesajı gösterilir.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ApiService.kullaniciHataMesaji(error)),
        ),
      );
    }
  }

  // Üst başlık aksiyonları — geri dön ve menüyü yenile.
  List<Widget> _ustAksiyonlar() {
    return [
      OutlinedButton.icon(
        onPressed: () {
          Navigator.pop(context);
        },
        icon: const Icon(Icons.arrow_back, size: 18),
        label: const Text('Geri Dön'),
      ),
      FilledButton.icon(
        style: themedElevatedButtonStyle(theme),
        onPressed: () {
          setState(() {
            urunlerFuture = urunleriVeAktifSiparisiYukle();
          });
        },
        icon: const Icon(Icons.refresh, size: 18),
        label: const Text('Yenile'),
      ),
    ];
  }

  // Responsive web / mobil düzen ayrımı için geniş ekran eşiği.
  static const double _genisEkranEsigi = 900;

  // Sayfanın ana iki kolonlu düzeni: sol ~%58 ürünler, sağ ~%42 sepet.
  static const int _solKolonFlex = 12;
  static const int _sagKolonFlex = 8;

  // Sayfanın ana iki kolonlu düzeni burada oluşturulur.
  Widget _anaDuzen(
    List<String> kategoriler,
    String aktifKategori,
    List<UrunModel> filtrelenmisUrunler,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final genisEkran = constraints.maxWidth >= _genisEkranEsigi;

        if (genisEkran) {
          // Web geniş ekran: sol ürünler ve sağ alınan siparişler yan yana.
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: _solKolonFlex,
                  child: _buildUrunAlani(
                    kategoriler,
                    aktifKategori,
                    filtrelenmisUrunler,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: _sagKolonFlex,
                  child: _buildSepetPaneli(),
                ),
              ],
            ),
          );
        }

        // Mobil / dar ekran: önce ürünler, altta sepet paneli (alt alta).
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            children: [
              _buildKategoriChipSatiri(kategoriler, aktifKategori),
              const SizedBox(height: 12),
              Expanded(
                flex: _solKolonFlex,
                child: _buildUrunAlani(
                  kategoriler,
                  aktifKategori,
                  filtrelenmisUrunler,
                  kategoriChipleriGoster: false,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                flex: _sagKolonFlex,
                child: _buildSepetPaneli(),
              ),
            ],
          ),
        );
      },
    );
  }

  // Header / üst başlık alanı ve ana içerik iskeleti.
  Widget _sayfaGovdesi({required Widget altIcerik}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1320),
              child: PanelBaslikAlani(
                baslik: 'Masa ${widget.masaNo} Siparişleri',
                altBaslik:
                    'Garson: ${widget.kullanici.fullName}\nÜrün seçip sepete ekleyin, not yazın ve siparişi kaydedin.',
                tema: theme,
                logoUrl: cafeLogoUrl,
                aksiyonlar: _ustAksiyonlar(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(child: altIcerik),
      ],
    );
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
                return _sayfaGovdesi(
                  altIcerik: const Center(
                    child: AppLoadingView(mesaj: 'Menü yükleniyor...'),
                  ),
                );
              }

              if (snapshot.hasError) {
                return _sayfaGovdesi(
                  altIcerik: Center(
                    child: AppErrorView(
                      hataDetayi: snapshot.error.toString(),
                      tekrarDene: () {
                        setState(() {
                          urunlerFuture = urunleriVeAktifSiparisiYukle();
                        });
                      },
                    ),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _sayfaGovdesi(
                  altIcerik: const Center(
                    child: AppEmptyView(
                      ikon: Icons.restaurant_menu,
                      baslik: 'Menüde ürün bulunamadı.',
                      aciklama: 'Yönetici menüden ürün eklemelidir.',
                    ),
                  ),
                );
              }

              final urunler = snapshot.data!;
              final kategoriler =
                  urunler.map((urun) => urun.categoryName).toSet().toList();
              final aktifKategori = seciliKategori ?? kategoriler.first;
              final filtrelenmisUrunler = urunler
                  .where((urun) => urun.categoryName == aktifKategori)
                  .toList();

              return _sayfaGovdesi(
                altIcerik: _anaDuzen(
                  kategoriler,
                  aktifKategori,
                  filtrelenmisUrunler,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // Kategori filtre chipleri — yatay kaydırılabilir satır.
  Widget _buildKategoriChipSatiri(
    List<String> kategoriler,
    String aktifKategori,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          for (var i = 0; i < kategoriler.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            AppTooltip(
              message: '${kategoriler[i]} kategorisini göster',
              child: StitchFiltreChip(
                etiket: kategoriler[i],
                secili: kategoriler[i] == aktifKategori,
                temaRengi: theme.primary,
                onTap: () {
                  setState(() {
                    seciliKategori = kategoriler[i];
                  });
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Sol tarafta kategoriye göre filtrelenen ürün listesi gösterilir.
  Widget _buildUrunAlani(
    List<String> kategoriler,
    String aktifKategori,
    List<UrunModel> filtrelenmisUrunler, {
    bool kategoriChipleriGoster = true,
  }) {
    return StitchKart(
      kenarlikRengi: theme.primary,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StitchBolumBasligi(
            baslik: 'Ürünler',
            altBaslik:
                '$aktifKategori · ${filtrelenmisUrunler.length} ürün',
            ikon: Icons.restaurant_menu,
            temaRengi: theme.primary,
          ),
          if (kategoriChipleriGoster) ...[
            const SizedBox(height: 14),
            _buildKategoriChipSatiri(kategoriler, aktifKategori),
          ],
          const SizedBox(height: 14),
          Expanded(
            child: filtrelenmisUrunler.isEmpty
                ? const AppEmptyView(
                    kompakt: true,
                    ikon: Icons.search_off,
                    baslik: 'Bu kategoride ürün yok.',
                    aciklama: 'Başka bir kategori seçin.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.only(bottom: 4),
                    itemCount: filtrelenmisUrunler.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      return _buildUrunKarti(filtrelenmisUrunler[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // Tek ürün satırı — ikon, ad, fiyat ve belirgin Ekle butonu.
  Widget _buildUrunKarti(UrunModel urun) {
    return StitchKart(
      kenarlikRengi: theme.primary.withValues(alpha: 0.35),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.softCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: theme.primary.withValues(alpha: 0.15),
              ),
            ),
            child: Icon(Icons.restaurant_menu, color: theme.primary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  urun.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                FiyatEtiketi(
                  fiyat: urun.price,
                  temaRengi: theme.primary,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          AppTooltip(
            message: 'Ürünü sepete ekle',
            child: FilledButton.icon(
              style: themedElevatedButtonStyle(theme).copyWith(
                minimumSize: const WidgetStatePropertyAll(
                  Size(96, 44),
                ),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Ekle'),
              onPressed: () {
                sepeteEkle(urun);
              },
            ),
          ),
        ],
      ),
    );
  }

  // Sağ tarafta alınan siparişler ve toplam tutar bilgisi yer alır.
  Widget _buildSepetPaneli() {
    return StitchKart(
      kenarlikRengi: theme.primary,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSepetUstBilgiBandi(),
          const SizedBox(height: 8),
          _buildSiparisNotuKarti(),
          const SizedBox(height: 8),
          _buildAlinanSiparislerBasligi(),
          const SizedBox(height: 6),
          // Sepet ürünleri fazla olursa sadece bu alan kendi içinde kaydırılır.
          Expanded(
            child: _buildAlinanSiparislerKutusu(),
          ),
          const SizedBox(height: 8),
          _buildAltOzetAlani(),
        ],
      ),
    );
  }

  // Sepet başlık alanı — masa ve kalem özeti.
  Widget _buildSepetUstBilgiBandi() {
    final toplamAdet =
        sepet.values.fold<int>(0, (onceki, adet) => onceki + adet);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.softCard.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sepet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Masa ${widget.masaNo} · ${sepet.length} kalem · $toplamAdet adet',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: theme.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.receipt_long_outlined, color: theme.primary, size: 18),
                const SizedBox(width: 6),
                Text(
                  '${sepet.length}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Sipariş notu alanı — kompakt kart içinde.
  Widget _buildSiparisNotuKarti() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.note_alt_outlined, size: 18, color: theme.primary),
              const SizedBox(width: 6),
              Text(
                'Sipariş Notu',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: siparisNotuController,
            minLines: 1,
            maxLines: 2,
            style: const TextStyle(fontSize: 13),
            decoration: stitchInputDekorasyonu(
              labelText: 'Masa notu',
              hintText: 'Örn: Acısız, soğansız...',
              prefixIcon: Icons.edit_note,
              temaRengi: theme.primary,
            ).copyWith(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Alınan siparişler bölüm başlığı.
  Widget _buildAlinanSiparislerBasligi() {
    return Row(
      children: [
        Icon(Icons.list_alt, size: 18, color: theme.primary),
        const SizedBox(width: 6),
        Text(
          'Alınan Siparişler',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: theme.primary,
          ),
        ),
        const Spacer(),
        if (sepet.isNotEmpty)
          StitchEtiket(
            metin: '${sepet.length} kalem',
            renk: theme.primary,
          ),
      ],
    );
  }

  // Alınan siparişler listesinin çerçeveli ve scroll edilebilir kutusu.
  Widget _buildAlinanSiparislerKutusu() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.softCard.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.primary.withValues(alpha: 0.15)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _buildSepetUrunListesi(),
      ),
    );
  }

  // Sepet ürün listesi — boş veya dolu duruma göre içerik değişir.
  Widget _buildSepetUrunListesi() {
    if (sepet.isEmpty) {
      return _buildSepetBosDurumu();
    }

    return ListView.separated(
      padding: const EdgeInsets.all(8),
      itemCount: sepet.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final entry = sepet.entries.elementAt(index);
        return _buildSepetUrunKarti(entry.key, entry.value);
      },
    );
  }

  // Sepet boş olduğunda taşma olmaması için kompakt boş durum kartı gösterilir.
  Widget _buildSepetBosDurumu() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: 28,
                      color: theme.primary.withValues(alpha: 0.45),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Sepet boş',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Soldan ürün ekleyin.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
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
  }

  // Sepetteki tek ürün satırı — ad, fiyat, adet ve silme kontrolleri.
  Widget _buildSepetUrunKarti(UrunModel urun, int adet) {
    final araToplam = urun.price * adet;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.primary.withValues(alpha: 0.22)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final darSatir = constraints.maxWidth < 340;

          if (darSatir) {
            return _buildSepetUrunKartiDikey(urun, adet, araToplam);
          }

          return _buildSepetUrunKartiYatay(urun, adet, araToplam);
        },
      ),
    );
  }

  // Geniş panelde yatay ürün satırı düzeni.
  Widget _buildSepetUrunKartiYatay(UrunModel urun, int adet, double araToplam) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                urun.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${urun.price.toStringAsFixed(2)} TL / adet',
                style: const TextStyle(fontSize: 11, color: Colors.black54),
              ),
            ],
          ),
        ),
        _buildSepetAdetKontrolleri(urun, adet),
        const SizedBox(width: 8),
        FiyatEtiketi(
          fiyat: araToplam,
          temaRengi: theme.primary,
        ),
        _buildSepetSilButonu(urun),
      ],
    );
  }

  // Dar panelde dikey ürün satırı düzeni (taşmayı önler).
  Widget _buildSepetUrunKartiDikey(UrunModel urun, int adet, double araToplam) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                urun.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            _buildSepetSilButonu(urun),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            StitchEtiket(metin: '$adet adet', renk: theme.primary),
            const SizedBox(width: 8),
            FiyatEtiketi(fiyat: araToplam, temaRengi: theme.primary),
          ],
        ),
        const SizedBox(height: 8),
        Center(child: _buildSepetAdetKontrolleri(urun, adet)),
      ],
    );
  }

  // Adet artır / azalt kontrol grubu.
  Widget _buildSepetAdetKontrolleri(UrunModel urun, int adet) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSepetAdetButonu(
          ikon: Icons.remove,
          arkaPlan: Colors.white,
          onPressed: () => adetAzalt(urun),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            '$adet',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: theme.primary,
            ),
          ),
        ),
        _buildSepetAdetButonu(
          ikon: Icons.add,
          arkaPlan: theme.primary,
          ikonRengi: Colors.white,
          onPressed: () => sepeteEkle(urun),
        ),
      ],
    );
  }

  // Ürünü sepetten tamamen kaldıran sil butonu.
  Widget _buildSepetSilButonu(UrunModel urun) {
    return IconButton(
      tooltip: 'Ürünü sepetten kaldır',
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      icon: Icon(Icons.delete_outline, color: Colors.red.shade400, size: 20),
      onPressed: () {
        setState(() {
          sepet.remove(urun);
        });
      },
    );
  }

  // Sepet adet artır/azalt yuvarlak butonları.
  Widget _buildSepetAdetButonu({
    required IconData ikon,
    required Color arkaPlan,
    required VoidCallback onPressed,
    Color? ikonRengi,
  }) {
    return Material(
      color: arkaPlan,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: theme.primary.withValues(alpha: 0.25)),
          ),
          child: Icon(ikon, size: 18, color: ikonRengi ?? theme.primary),
        ),
      ),
    );
  }

  // Toplam tutar kartı ve Siparişi Kaydet butonu — panel altında sabit kalır.
  Widget _buildAltOzetAlani() {
    final toplamAdet =
        sepet.values.fold<int>(0, (onceki, adet) => onceki + adet);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      decoration: BoxDecoration(
        color: theme.softCard.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Toplam Tutar',
                      style: TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sepet.isEmpty
                          ? 'Sepete ürün ekleyin'
                          : '${sepet.length} kalem · $toplamAdet adet',
                      style: const TextStyle(fontSize: 11, color: Colors.black45),
                    ),
                  ],
                ),
              ),
              Text(
                '${toplamTutar.toStringAsFixed(2)} TL',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AppTooltip(
            message: 'Siparişi kaydet',
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                style: themedElevatedButtonStyle(theme),
                icon: const Icon(Icons.save_outlined, size: 20),
                label: const Text(
                  'Siparişi Kaydet',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                onPressed: siparisiKaydet,
              ),
            ),
          ),
        ],
      ),
    );
  }
}