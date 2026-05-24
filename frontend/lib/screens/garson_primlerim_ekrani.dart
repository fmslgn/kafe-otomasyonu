// Garsonun kendi prim bilgilerini gösteren ekrandır.
import 'package:flutter/material.dart';

import '../models/app_user_model.dart';
import '../models/my_commission_report_model.dart';
import '../services/api_service.dart';
import '../utils/app_theme_helper.dart';
import '../widgets/app_feedback_widgets.dart';
import '../widgets/app_themed_widgets.dart';

class GarsonPrimlerimEkrani extends StatefulWidget {
  const GarsonPrimlerimEkrani({
    super.key,
    required this.kullanici,
  });

  final AppUserModel kullanici;

  @override
  State<GarsonPrimlerimEkrani> createState() => _GarsonPrimlerimEkraniState();
}

class _GarsonPrimlerimEkraniState extends State<GarsonPrimlerimEkrani>
    with CafeThemeScreenMixin {
  late Future<MyCommissionReportModel> raporFuture;
  String seciliDonem = 'monthly';

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
    raporFuture = ApiService.getMyCommissionReport(
      userId: widget.kullanici.id,
      period: seciliDonem,
    );
  }

  void ekraniYenile() => setState(verileriYukle);

  void donemDegistir(String donem) {
    setState(() {
      seciliDonem = donem;
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
        return 'Tümü';
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

  // Filtre chipleri bölümü — dönem seçimi.
  Widget _donemFiltreleri() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          StitchFiltreChip(
            etiket: 'Tümü',
            secili: seciliDonem == 'all',
            temaRengi: theme.primary,
            onTap: () => donemDegistir('all'),
          ),
          const SizedBox(width: 8),
          StitchFiltreChip(
            etiket: 'Günlük',
            secili: seciliDonem == 'daily',
            temaRengi: theme.primary,
            onTap: () => donemDegistir('daily'),
          ),
          const SizedBox(width: 8),
          StitchFiltreChip(
            etiket: 'Haftalık',
            secili: seciliDonem == 'weekly',
            temaRengi: theme.primary,
            onTap: () => donemDegistir('weekly'),
          ),
          const SizedBox(width: 8),
          StitchFiltreChip(
            etiket: 'Aylık',
            secili: seciliDonem == 'monthly',
            temaRengi: theme.primary,
            onTap: () => donemDegistir('monthly'),
          ),
        ],
      ),
    );
  }

  // Ürün bazlı prim detay kartı.
  Widget _primDetayKarti(ProductBonusDetailModel detay) {
    return StitchKart(
      margin: const EdgeInsets.only(bottom: 10),
      kenarlikRengi:
          detay.earned ? Colors.green.shade600 : theme.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  detay.productName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              if (detay.earned)
                StitchEtiket(
                  metin: 'Hedef tamamlandı',
                  renk: Colors.green.shade700,
                ),
            ],
          ),
          const SizedBox(height: 10),
          StitchBilgiIzgarasi(
            ogeler: [
              (
                etiket: 'Satılan / Hedef',
                deger: '${detay.soldQuantity} / ${detay.targetQuantity}',
                vurgu: null,
              ),
              (
                etiket: 'Ekstra prim',
                deger: '${detay.bonusAmount.toStringAsFixed(2)} TL',
                vurgu: theme.primary,
              ),
            ],
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
          child: FutureBuilder<MyCommissionReportModel>(
            future: raporFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const AppLoadingView(
                  mesaj: 'Prim bilgileri yükleniyor...',
                );
              }

              if (snapshot.hasError) {
                return AppErrorView(
                  hataDetayi: snapshot.error.toString(),
                  tekrarDene: ekraniYenile,
                );
              }

              final rapor = snapshot.data!;

              if (!rapor.isEnabled) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      PanelBaslikAlani(
                        baslik: 'Kendi Primlerim',
                        altBaslik:
                            'Satış toplamınızı, ürün bazlı primlerinizi ve toplam görünür priminizi buradan takip edin.',
                        tema: theme,
                        logoUrl: cafeLogoUrl,
                        aksiyonlar: _ustAksiyonlar(context),
                      ),
                      const SizedBox(height: 24),
                      const AppEmptyView(
                        ikon: Icons.payments_outlined,
                        baslik: 'Prim sistemi kapalı',
                        aciklama:
                            'Prim sistemi şu anda yönetici tarafından kapalıdır.',
                      ),
                    ],
                  ),
                );
              }

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
                          baslik: 'Kendi Primlerim',
                          altBaslik:
                              'Satış toplamınızı, ürün bazlı primlerinizi ve toplam görünür priminizi buradan takip edin.',
                          tema: theme,
                          logoUrl: cafeLogoUrl,
                          aksiyonlar: _ustAksiyonlar(context),
                        ),
                        const SizedBox(height: 20),
                        StitchKart(
                          kenarlikRengi: theme.primary,
                          child: _donemFiltreleri(),
                        ),
                        const SizedBox(height: 20),
                        // Özet kartları bölümü.
                        OzetKartSatiri(
                          kartlar: [
                            OzetKart(
                              baslik: 'Toplam Satış',
                              deger:
                                  '${rapor.totalSales.toStringAsFixed(2)} TL',
                              ikon: Icons.trending_up,
                              tema: theme,
                            ),
                            OzetKart(
                              baslik: 'Kapatılan Sipariş',
                              deger: rapor.closedOrderCount.toString(),
                              ikon: Icons.receipt_long,
                              tema: theme,
                            ),
                            OzetKart(
                              baslik: 'Genel Prim',
                              deger:
                                  '${rapor.baseCommission.toStringAsFixed(2)} TL',
                              ikon: Icons.account_balance_wallet,
                              tema: theme,
                            ),
                            OzetKart(
                              baslik: 'Ürün Primi',
                              deger:
                                  '${rapor.productBonus.toStringAsFixed(2)} TL',
                              ikon: Icons.star,
                              tema: theme,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Toplam görünür prim vurgu kartı.
                        StitchVurguKart(
                          baslik: 'Toplam Görünür Prim',
                          deger:
                              '${rapor.visibleTotalCommission.toStringAsFixed(2)} TL',
                          tema: theme,
                          altSatir:
                              'Dönem: ${donemBasligi(seciliDonem)} — ayın elemanı özel primi bu ekranda gösterilmez.',
                        ),
                        const SizedBox(height: 24),
                        StitchBolumBasligi(
                          baslik:
                              'Ürün Bazlı Prim Detayları (${donemBasligi(seciliDonem)})',
                          ikon: Icons.inventory_2_outlined,
                          temaRengi: theme.primary,
                        ),
                        const SizedBox(height: 12),
                        if (rapor.productBonusDetails.isEmpty)
                          const AppInfoCard(
                            mesaj:
                                'Bu dönem için tanımlı ürün prim kuralı yok veya hedefe ulaşılmadı.',
                          )
                        else
                          ...rapor.productBonusDetails.map(_primDetayKarti),
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
