// Flutter arayüz bileşenlerini kullanmak için import ediyoruz.
import 'package:flutter/material.dart';

// Giriş yapan kullanıcı modelini kullanıyoruz.
import '../models/app_user_model.dart';

// Ürün modelini kullanıyoruz.
import '../models/urun_model.dart';

// Backend API servis dosyasını kullanıyoruz.
import '../services/api_service.dart';
import '../utils/app_theme_helper.dart';

import '../widgets/app_feedback_widgets.dart';
import '../widgets/app_themed_widgets.dart';

// Dışarıdan gelen paket sipariş alma ekranıdır.
class PaketSiparisEkrani extends StatefulWidget {
  // Giriş yapan garson bilgisidir.
  final AppUserModel kullanici;

  // Constructor yapısıdır.
  const PaketSiparisEkrani({
    super.key,
    required this.kullanici,
  });

  @override
  State<PaketSiparisEkrani> createState() => _PaketSiparisEkraniState();
}

// Paket sipariş ekranındaki değişen verileri yöneten State sınıfıdır.
class _PaketSiparisEkraniState extends State<PaketSiparisEkrani>
    with CafeThemeScreenMixin {
  // API'den gelecek ürün listesini tutar.
  late Future<List<UrunModel>> urunlerFuture;

  // Seçili kategori bilgisidir.
  String? seciliKategori;

  // Müşteri adı controller.
  final TextEditingController musteriAdiController = TextEditingController();

  // Müşteri telefon controller.
  final TextEditingController telefonController = TextEditingController();

  // Adres controller.
  final TextEditingController adresController = TextEditingController();

  // Paket sipariş notu controller.
  final TextEditingController notController = TextEditingController();

  // Sepetteki ürünleri ve adetlerini tutar.
  final Map<UrunModel, int> sepet = {};

  @override
  void initState() {
    super.initState();
    initCafeThemeListener();

    // Sayfa açıldığında ürünler backend'den çekilir.
    urunlerFuture = ApiService.getProducts();
  }

  @override
  void dispose() {
    disposeCafeThemeListener();
    // Controller nesneleri temizlenir.
    musteriAdiController.dispose();
    telefonController.dispose();
    adresController.dispose();
    notController.dispose();

    super.dispose();
  }

  // Sepetin toplam tutarını hesaplar.
  double get toplamTutar {
    double toplam = 0;

    sepet.forEach((urun, adet) {
      toplam += urun.price * adet;
    });

    return toplam;
  }

  // Sepete ürün ekler.
  void sepeteEkle(UrunModel urun) {
    setState(() {
      sepet[urun] = (sepet[urun] ?? 0) + 1;
    });
  }

  // Sepetten ürün adetini azaltır.
  void adetAzalt(UrunModel urun) {
    setState(() {
      if (!sepet.containsKey(urun)) return;

      if (sepet[urun]! > 1) {
        sepet[urun] = sepet[urun]! - 1;
      } else {
        sepet.remove(urun);
      }
    });
  }

  // Paket siparişi backend'e kaydeder.
  Future<void> paketSiparisiKaydet() async {
    // Sepet boşsa uyarı gösterilir.
    if (sepet.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Paket sipariş kaydetmek için sepete ürün eklemelisiniz.'),
        ),
      );
      return;
    }

    try {
      // Sepetteki ürünler backend formatına çevrilir.
      final List<Map<String, dynamic>> items = sepet.entries.map((entry) {
        return {
          'productId': entry.key.id,
          'quantity': entry.value,
        };
      }).toList();

      // Paket sipariş backend API'ye gönderilir.
      final response = await ApiService.createPackageOrder(
        userId: widget.kullanici.id,
        customerName: musteriAdiController.text.trim().isEmpty
            ? null
            : musteriAdiController.text.trim(),
        customerPhone: telefonController.text.trim().isEmpty
            ? null
            : telefonController.text.trim(),
        address:
            adresController.text.trim().isEmpty ? null : adresController.text,
        note: notController.text.trim().isEmpty ? null : notController.text,
        items: items,
      );

      if (!mounted) return;

      // Başarı mesajı gösterilir.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${response['message']} Toplam: ${response['totalPrice']} TL',
          ),
        ),
      );

      // Form ve sepet temizlenir.
      setState(() {
        musteriAdiController.clear();
        telefonController.clear();
        adresController.clear();
        notController.clear();
        sepet.clear();
      });
    } catch (error) {
      if (!mounted) return;

      // Hata mesajı gösterilir.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Paket sipariş kaydedilemedi: $error'),
        ),
      );
    }
  }

  // Üst başlık aksiyonları.
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
            urunlerFuture = ApiService.getProducts();
          });
        },
        icon: const Icon(Icons.refresh, size: 18),
        label: const Text('Yenile'),
      ),
    ];
  }

  // Web: sol ürünler, sağ müşteri formu + sepet özeti.
  Widget _anaDuzen(
    List<String> kategoriler,
    String aktifKategori,
    List<UrunModel> filtrelenmisUrunler,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final genisEkran = constraints.maxWidth >= 900;

        if (genisEkran) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Row(
              // Responsive düzen: sağ panel tam yükseklik alsın, overflow olmasın.
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: _urunListesiAlani(
                    kategoriler,
                    aktifKategori,
                    filtrelenmisUrunler,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 2,
                  child: _paketSepetAlani(),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            children: [
              _kategoriChipSatiri(kategoriler, aktifKategori),
              const SizedBox(height: 12),
              Expanded(
                flex: 3,
                child: _urunListesiAlani(
                  kategoriler,
                  aktifKategori,
                  filtrelenmisUrunler,
                  kategoriChipleriGoster: false,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                flex: 2,
                child: _paketSepetAlani(),
              ),
            ],
          ),
        );
      },
    );
  }

  // Sayfa iskeleti — PanelBaslikAlani + içerik alanı.
  Widget _sayfaGovdesi({required Widget altIcerik}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: PanelBaslikAlani(
                baslik: 'Paket Sipariş Oluştur',
                altBaslik:
                    'Garson: ${widget.kullanici.fullName}\nMüşteri bilgilerini girin, ürün seçin ve paket siparişi kaydedin.',
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
                    child: AppLoadingView(mesaj: 'Ürünler yükleniyor...'),
                  ),
                );
              }

              if (snapshot.hasError) {
                return _sayfaGovdesi(
                  altIcerik: Center(
                    child: AppErrorView(
                      hataDetayi: snapshot.error.toString(),
                      tekrarDene: () => setState(() {
                        urunlerFuture = ApiService.getProducts();
                      }),
                    ),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _sayfaGovdesi(
                  altIcerik: const Center(
                    child: AppEmptyView(
                      ikon: Icons.inventory_2_outlined,
                      baslik: 'Paket sipariş için ürün bulunmuyor.',
                      aciklama:
                          'Menü yönetiminden ürün ekleyip aktif hale getirin.',
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

  // Yatay kategori filtre chip satırı.
  Widget _kategoriChipSatiri(
    List<String> kategoriler,
    String aktifKategori,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < kategoriler.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
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

  // Sol sütun — kategori chip'leri ve ürün kartları.
  Widget _urunListesiAlani(
    List<String> kategoriler,
    String aktifKategori,
    List<UrunModel> filtrelenmisUrunler, {
    bool kategoriChipleriGoster = true,
  }) {
    return StitchKart(
      kenarlikRengi: theme.primary,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StitchBolumBasligi(
            baslik: 'Ürünler',
            altBaslik: aktifKategori,
            ikon: Icons.restaurant_menu,
            temaRengi: theme.primary,
          ),
          if (kategoriChipleriGoster) ...[
            const SizedBox(height: 12),
            _kategoriChipSatiri(kategoriler, aktifKategori),
          ],
          const SizedBox(height: 12),
          Expanded(
            child: filtrelenmisUrunler.isEmpty
                ? const AppEmptyView(
                    kompakt: true,
                    ikon: Icons.search_off,
                    baslik: 'Bu kategoride ürün yok.',
                    aciklama: 'Başka bir kategori seçin.',
                  )
                : ListView.builder(
                    itemCount: filtrelenmisUrunler.length,
                    itemBuilder: (context, index) {
                      return _urunKarti(filtrelenmisUrunler[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // Tek ürün kartı.
  Widget _urunKarti(UrunModel urun) {
    return StitchKart(
      margin: const EdgeInsets.only(bottom: 10),
      kenarlikRengi: theme.primary,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.softCard,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.restaurant_menu, color: theme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  urun.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                FiyatEtiketi(
                  fiyat: urun.price,
                  temaRengi: theme.primary,
                ),
              ],
            ),
          ),
          AppTooltip(
            message: 'Ürünü sepete ekle',
            child: FilledButton.icon(
              style: themedElevatedButtonStyle(theme),
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

  // Sağ müşteri & özet paneli — form, sepet listesi ve alt özet.
  Widget _paketSepetAlani() {
    return StitchKart(
      kenarlikRengi: theme.primary,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StitchBolumBasligi(
            baslik: 'Müşteri & Özet',
            ikon: Icons.delivery_dining,
            temaRengi: theme.primary,
            altBaslik: '${sepet.length} ürün kalemi seçildi',
          ),
          const SizedBox(height: 8),
          _buildMusteriBilgileriFormu(),
          const SizedBox(height: 8),
          // Paket sepeti / seçilen ürünler listesi — kalan yüksekliği kullanır.
          Expanded(child: _buildPaketSepetiAlani()),
          const SizedBox(height: 8),
          _buildPaketAltOzetAlani(),
        ],
      ),
    );
  }

  // Müşteri bilgileri form alanı — kompakt ve okunaklı.
  Widget _buildMusteriBilgileriFormu() {
    final kompaktDekor = (InputDecoration decoration) => decoration.copyWith(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: musteriAdiController,
          style: const TextStyle(fontSize: 14),
          decoration: kompaktDekor(
            stitchInputDekorasyonu(
              labelText: 'Müşteri Adı',
              prefixIcon: Icons.person,
              temaRengi: theme.primary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: telefonController,
          style: const TextStyle(fontSize: 14),
          decoration: kompaktDekor(
            stitchInputDekorasyonu(
              labelText: 'Telefon',
              prefixIcon: Icons.phone,
              temaRengi: theme.primary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: adresController,
          minLines: 1,
          maxLines: 2,
          style: const TextStyle(fontSize: 14),
          decoration: kompaktDekor(
            stitchInputDekorasyonu(
              labelText: 'Adres',
              prefixIcon: Icons.location_on,
              temaRengi: theme.primary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: notController,
          minLines: 1,
          maxLines: 2,
          style: const TextStyle(fontSize: 14),
          decoration: kompaktDekor(
            stitchInputDekorasyonu(
              labelText: 'Paket Notu',
              hintText: 'Örn: Kapıya bırak, nakit...',
              prefixIcon: Icons.note_alt,
              temaRengi: theme.primary,
            ),
          ),
        ),
      ],
    );
  }

  // Paket sepeti kutusu — boş veya dolu duruma göre içerik değişir.
  Widget _buildPaketSepetiAlani() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.softCard.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.primary.withValues(alpha: 0.15)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: sepet.isEmpty
            ? _buildPaketSepetiBosDurumu()
            : ListView.separated(
                padding: const EdgeInsets.all(8),
                itemCount: sepet.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final entry = sepet.entries.elementAt(index);
                  return _sepetKalemi(entry.key, entry.value);
                },
              ),
      ),
    );
  }

  // Boş ürün durumu — taşma yapmayan kompakt görünüm.
  Widget _buildPaketSepetiBosDurumu() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.shopping_bag_outlined,
                      size: 28,
                      color: theme.primary.withValues(alpha: 0.45),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Paket sepeti boş',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
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

  // Toplam tutar alanı ve Paket siparişi kaydet butonu — panel altında sabit.
  Widget _buildPaketAltOzetAlani() {
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
                          : '${sepet.length} ürün kalemi',
                      style: const TextStyle(fontSize: 11, color: Colors.black45),
                    ),
                  ],
                ),
              ),
              Text(
                '${toplamTutar.toStringAsFixed(2)} TL',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: theme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AppTooltip(
            message: 'Paket siparişi kaydet',
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                style: themedElevatedButtonStyle(theme),
                icon: const Icon(Icons.save_outlined, size: 20),
                label: const Text(
                  'Paket Siparişi Kaydet',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                onPressed: paketSiparisiKaydet,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Sepetteki tek ürün satırı.
  Widget _sepetKalemi(UrunModel urun, int adet) {
    final araToplam = urun.price * adet;

    return StitchKart(
      margin: const EdgeInsets.only(bottom: 8),
      kenarlikRengi: theme.primary,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  urun.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    StitchEtiket(
                      metin: '$adet adet',
                      renk: theme.primary,
                    ),
                    const SizedBox(width: 8),
                    FiyatEtiketi(
                      fiyat: araToplam,
                      temaRengi: theme.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Ürün adedini azalt',
            icon: Icon(Icons.remove_circle_outline, color: theme.primary),
            onPressed: () {
              adetAzalt(urun);
            },
          ),
          IconButton(
            tooltip: 'Ürün adedini artır',
            icon: Icon(Icons.add_circle_outline, color: theme.primary),
            onPressed: () {
              sepeteEkle(urun);
            },
          ),
        ],
      ),
    );
  }
}