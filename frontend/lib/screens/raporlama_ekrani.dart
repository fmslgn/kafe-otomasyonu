// Flutter arayüz bileşenlerini kullanmak için import ediyoruz.
import 'package:flutter/material.dart';

// Kapanan hesaplar modelini kullanıyoruz.
import '../models/closed_order_model.dart';

// Garson satış raporu modelini kullanıyoruz.
import '../models/garson_satis_model.dart';

// Rapor özet modelini kullanıyoruz.
import '../models/report_summary_model.dart';

// En çok satılan ürünler modelini kullanıyoruz.
import '../models/top_product_model.dart';

// Backend API servis dosyasını kullanıyoruz.
import '../services/api_service.dart';

import '../utils/app_theme_helper.dart';
import '../widgets/app_feedback_widgets.dart';
import '../widgets/app_themed_widgets.dart';

// Raporlama ekranıdır.
// Yönetici bu ekranda genel satış raporlarını, masa satışlarını,
// paket satışlarını, en çok satılan ürünleri, kapanan hesapları
// ve personel satış performansını görür.
class RaporlamaEkrani extends StatefulWidget {
  // Constructor yapısıdır.
  const RaporlamaEkrani({super.key});

  @override
  State<RaporlamaEkrani> createState() => _RaporlamaEkraniState();
}

// Raporlama ekranındaki değişen verileri yöneten State sınıfıdır.
class _RaporlamaEkraniState extends State<RaporlamaEkrani>
    with CafeThemeScreenMixin {
  // Backend'den gelecek rapor özetini tutar.
  late Future<ReportSummaryModel> reportSummaryFuture;

  // Backend'den gelecek en çok satılan ürünleri tutar.
  late Future<List<TopProductModel>> topProductsFuture;

  // Backend'den gelecek kapanan masa hesaplarını tutar.
  late Future<List<ClosedOrderModel>> closedOrdersFuture;

  // Backend'den gelecek personel satış raporunu tutar.
  late Future<List<GarsonSatisModel>> garsonSatisRaporuFuture;

  // Seçili dönem filtresidir.
  // all: tümü, daily: günlük, weekly: haftalık, monthly: aylık.
  String seciliDonem = 'all';

  @override
  void initState() {
    super.initState();
    initCafeThemeListener();
    // Sayfa açıldığında rapor verileri yüklenir.
    verileriYukle();
  }

  @override
  void dispose() {
    disposeCafeThemeListener();
    super.dispose();
  }

  // Seçili döneme göre rapor verilerini backend API'den yükler.
  void verileriYukle() {
    reportSummaryFuture = ApiService.getReportSummary(period: seciliDonem);
    topProductsFuture = ApiService.getTopProducts(period: seciliDonem);
    closedOrdersFuture = ApiService.getClosedOrders(period: seciliDonem);

    // Personel satış performansı da seçili döneme göre yüklenir.
    // Backend artık masa + paket satışlarını birlikte döndürür.
    garsonSatisRaporuFuture = ApiService.getUserSalesReport(
      period: seciliDonem,
    );
  }

  // Ekranı yenileyen fonksiyondur.
  void ekraniYenile() {
    setState(() {
      verileriYukle();
    });
  }

  // Dönem filtresini değiştirir ve verileri yeniden çeker.
  void donemDegistir(String yeniDonem) {
    setState(() {
      seciliDonem = yeniDonem;
      verileriYukle();
    });
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

  // Dönem değerini kullanıcıya okunabilir başlık olarak döndürür.
  String donemBasligi(String deger) {
    switch (deger) {
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

  // Rol kodunu model/username verisinden güvenli şekilde çözümler.
  String _normalizeRole(String role, {String? username}) {
    final temiz = role.trim().toLowerCase();
    if (temiz.isNotEmpty && temiz != 'null') {
      return temiz;
    }

    final kullanici = (username ?? '').trim().toLowerCase();
    if (kullanici.contains('kurye')) {
      return 'kurye';
    }
    if (kullanici.contains('yonetici') || kullanici.contains('admin')) {
      return 'yonetici';
    }

    return 'garson';
  }

  // Rol bilgisini Türkçe göstermek için kullanılır.
  String rolYazisi(String role, {String? username}) {
    switch (_normalizeRole(role, username: username)) {
      case 'yonetici':
        return 'Yönetici';
      case 'kurye':
        return 'Kurye';
      case 'garson':
      default:
        return 'Garson';
    }
  }

  IconData rolIkonu(String role, {String? username}) {
    switch (_normalizeRole(role, username: username)) {
      case 'yonetici':
        return Icons.admin_panel_settings;
      case 'kurye':
        return Icons.delivery_dining;
      case 'garson':
      default:
        return Icons.room_service;
    }
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

  // Rapor özet kartlarının bulunduğu alan.
  // Burada masa satışı ve paket satışı ayrı ayrı gösterilir.
  Widget _raporOzetiAlani(ReportSummaryModel summary) {
    return Column(
      children: [
        OzetKartSatiri(
          kartlar: [
            OzetKart(
              baslik: 'Toplam Satış',
              deger: '${summary.totalSales.toStringAsFixed(2)} TL',
              ikon: Icons.point_of_sale,
              tema: theme,
            ),
            OzetKart(
              baslik: 'Masa Satışı',
              deger: '${summary.tableSales.toStringAsFixed(2)} TL',
              ikon: Icons.table_restaurant,
              tema: theme,
            ),
            OzetKart(
              baslik: 'Paket Satışı',
              deger: '${summary.packageSales.toStringAsFixed(2)} TL',
              ikon: Icons.delivery_dining,
              tema: theme,
            ),
          ],
        ),
        const SizedBox(height: 12),
        OzetKartSatiri(
          kartlar: [
            OzetKart(
              baslik: 'Kapanan Sipariş',
              deger:
                  '${summary.closedOrderCount} '
                  '(M: ${summary.tableOrderCount}, P: ${summary.packageOrderCount})',
              ikon: Icons.receipt_long,
              tema: theme,
            ),
            OzetKart(
              baslik: 'Ortalama Sipariş',
              deger: '${summary.averageOrderAmount.toStringAsFixed(2)} TL',
              ikon: Icons.calculate,
              tema: theme,
            ),
            OzetKart(
              baslik: 'Satılan Ürün',
              deger: '${summary.totalItemsSold}',
              ikon: Icons.restaurant_menu,
              tema: theme,
            ),
          ],
        ),
      ],
    );
  }

  // En çok satılan ürünler seçili döneme göre listelenir.
  Widget _enCokSatilanUrunlerAlani() {
    return StitchKart(
      kenarlikRengi: theme.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StitchBolumBasligi(
            baslik: 'En Çok Satılan Ürünler (${donemBasligi(seciliDonem)})',
            ikon: Icons.bar_chart,
            temaRengi: theme.primary,
            altBaslik: 'Masa ve paket siparişleri birlikte hesaplanır.',
          ),
          const SizedBox(height: 14),
          FutureBuilder<List<TopProductModel>>(
            future: topProductsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const AppLoadingView(
                  mesaj: 'Ürün raporu yükleniyor...',
                  kompakt: true,
                );
              }

              if (snapshot.hasError) {
                return AppErrorView(
                  kompakt: true,
                  hataDetayi: snapshot.error.toString(),
                  tekrarDene: ekraniYenile,
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const AppEmptyView(
                  kompakt: true,
                  ikon: Icons.bar_chart_outlined,
                  baslik: 'Bu dönem için rapor verisi bulunmuyor.',
                  aciklama: 'Farklı bir dönem filtresi deneyebilirsiniz.',
                );
              }

              final urunler = snapshot.data!;

              return Column(
                children: [
                  for (var index = 0; index < urunler.length; index++)
                    _topUrunKarti(
                      urunler[index],
                      index + 1,
                      son: index == urunler.length - 1,
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // Kompakt ürün satırı — panel kartı içinde.
  Widget _topUrunKarti(TopProductModel urun, int sira, {bool son = false}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: theme.softCard,
                foregroundColor: theme.primary,
                child: Text(
                  '$sira',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      urun.productName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    StitchBilgiIzgarasi(
                      sutunSayisi: 2,
                      ogeler: [
                        (
                          etiket: 'Kategori',
                          deger: urun.categoryName,
                          vurgu: null,
                        ),
                        (
                          etiket: 'Satış adedi',
                          deger: '${urun.totalQuantity}',
                          vurgu: theme.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FiyatEtiketi(
                fiyat: urun.totalRevenue,
                temaRengi: theme.primary,
              ),
            ],
          ),
        ),
        if (!son) Divider(height: 1, color: Colors.grey.shade200),
      ],
    );
  }

  // Personel satış performansı kartları burada oluşturulur.
  Widget _personelSatisPerformansiAlani() {
    return StitchKart(
      kenarlikRengi: theme.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StitchBolumBasligi(
            baslik:
                'Personel Satış Performansı (${donemBasligi(seciliDonem)})',
            ikon: Icons.people_outline,
            temaRengi: theme.primary,
            altBaslik:
                'Masa ve paket siparişlerine göre toplam satış bilgisi.',
          ),
          const SizedBox(height: 14),
          FutureBuilder<List<GarsonSatisModel>>(
            future: garsonSatisRaporuFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const AppLoadingView(
                  mesaj: 'Personel raporu yükleniyor...',
                  kompakt: true,
                );
              }

              if (snapshot.hasError) {
                return AppErrorView(
                  kompakt: true,
                  hataDetayi: snapshot.error.toString(),
                  tekrarDene: ekraniYenile,
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const AppEmptyView(
                  kompakt: true,
                  ikon: Icons.people_outline,
                  baslik: 'Personel satış verisi bulunmuyor.',
                  aciklama: 'Bu dönemde kapanan sipariş olmayabilir.',
                );
              }

              final satislar = List<GarsonSatisModel>.from(snapshot.data!);

              satislar.sort(
                (a, b) => b.totalSales.compareTo(a.totalSales),
              );

              return Column(
                children: [
                  for (var i = 0; i < satislar.length; i++)
                    _personelSatisKarti(
                      satislar[i],
                      son: i == satislar.length - 1,
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // Kompakt personel satırı — panel kartı içinde.
  Widget _personelSatisKarti(GarsonSatisModel satis, {bool son = false}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: theme.softCard,
                foregroundColor: theme.primary,
                child: Icon(
                  rolIkonu(satis.role, username: satis.username),
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      satis.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    StitchBilgiIzgarasi(
                      sutunSayisi: 2,
                      ogeler: [
                        (
                          etiket: 'Kullanıcı',
                          deger: satis.username,
                          vurgu: null,
                        ),
                        (
                          etiket: 'Rol',
                          deger: rolYazisi(satis.role, username: satis.username),
                          vurgu: null,
                        ),
                        (
                          etiket: 'Kapanan sipariş',
                          deger: '${satis.closedOrderCount}',
                          vurgu: theme.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FiyatEtiketi(
                fiyat: satis.totalSales,
                temaRengi: theme.primary,
              ),
            ],
          ),
        ),
        if (!son) Divider(height: 1, color: Colors.grey.shade200),
      ],
    );
  }

  // Kapanan masa hesapları rapor detayında gösterilir.
  Widget _kapananHesaplarAlani() {
    return StitchKart(
      kenarlikRengi: theme.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StitchBolumBasligi(
            baslik: 'Kapanan Masa Hesapları (${donemBasligi(seciliDonem)})',
            ikon: Icons.receipt_long_outlined,
            temaRengi: theme.primary,
            altBaslik: 'Bu bölüm sadece masa hesaplarını listeler.',
          ),
          const SizedBox(height: 14),
          FutureBuilder<List<ClosedOrderModel>>(
            future: closedOrdersFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const AppLoadingView(
                  mesaj: 'Hesaplar yükleniyor...',
                  kompakt: true,
                );
              }

              if (snapshot.hasError) {
                return AppErrorView(
                  kompakt: true,
                  hataDetayi: snapshot.error.toString(),
                  tekrarDene: ekraniYenile,
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const AppEmptyView(
                  kompakt: true,
                  ikon: Icons.receipt_long_outlined,
                  baslik: 'Kapanan masa hesabı bulunmuyor.',
                  aciklama: 'Seçili dönemde kapanan masa hesabı yok.',
                );
              }

              final hesaplar = snapshot.data!;

              return Column(
                children: [
                  for (var i = 0; i < hesaplar.length; i++)
                    _kapananHesapKarti(
                      hesaplar[i],
                      son: i == hesaplar.length - 1,
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // Kompakt kapanan masa satırı — panel kartı içinde.
  Widget _kapananHesapKarti(ClosedOrderModel hesap, {bool son = false}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.receipt, color: theme.primary, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Masa ${hesap.tableNo}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    StitchBilgiIzgarasi(
                      sutunSayisi: 2,
                      ogeler: [
                        (
                          etiket: 'Tarih',
                          deger: tarihFormatla(hesap.createdAt),
                          vurgu: null,
                        ),
                        (
                          etiket: 'Ürün adedi',
                          deger: '${hesap.itemCount}',
                          vurgu: theme.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FiyatEtiketi(
                fiyat: hesap.totalPrice,
                temaRengi: theme.primary,
              ),
            ],
          ),
        ),
        if (!son) Divider(height: 1, color: Colors.grey.shade200),
      ],
    );
  }

  // Raporlama ekranındaki detay panelleri üst özetlerden sonra gösterilir.
  Widget _raporPanelleri() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final genis = constraints.maxWidth >= 900;

        if (genis) {
          // Geniş ekranda 3 kolon — IntrinsicHeight kullanılmaz (scroll içinde çöker).
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _enCokSatilanUrunlerAlani()),
              const SizedBox(width: 16),
              Expanded(child: _personelSatisPerformansiAlani()),
              const SizedBox(width: 16),
              Expanded(child: _kapananHesaplarAlani()),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _enCokSatilanUrunlerAlani(),
            const SizedBox(height: 16),
            _personelSatisPerformansiAlani(),
            const SizedBox(height: 16),
            _kapananHesaplarAlani(),
          ],
        );
      },
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
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PanelBaslikAlani(
                      baslik: 'Raporlama',
                      altBaslik:
                          'Satış özetleri, en çok satılan ürünler, personel performansı ve kapanan hesapları görüntüleyin.',
                      tema: theme,
                      logoUrl: cafeLogoUrl,
                      aksiyonlar: _ustAksiyonlar(context),
                    ),
                    const SizedBox(height: 20),
                    _donemFiltreleri(),
                    const SizedBox(height: 20),
                    FutureBuilder<ReportSummaryModel>(
                      future: reportSummaryFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const AppLoadingView(
                            kompakt: true,
                            mesaj: 'Rapor özeti yükleniyor...',
                          );
                        }

                        if (snapshot.hasError) {
                          return AppErrorView(
                            kompakt: true,
                            hataDetayi: snapshot.error.toString(),
                            tekrarDene: ekraniYenile,
                          );
                        }

                        if (!snapshot.hasData) {
                          return const SizedBox();
                        }

                        return _raporOzetiAlani(snapshot.data!);
                      },
                    ),
                    const SizedBox(height: 20),
                    // Detay rapor panelleri — özet kartlarının hemen altında.
                    _raporPanelleri(),
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
