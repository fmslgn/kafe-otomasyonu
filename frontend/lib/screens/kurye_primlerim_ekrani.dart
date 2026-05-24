// Kuryenin kendi prim bilgilerini gösteren ekrandır.
import 'package:flutter/material.dart';

import '../models/app_user_model.dart';
import '../models/courier_commission_report_model.dart';
import '../services/api_service.dart';
import '../utils/app_theme_helper.dart';
import '../widgets/app_feedback_widgets.dart';
import '../widgets/app_themed_widgets.dart';

class KuryePrimlerimEkrani extends StatefulWidget {
  const KuryePrimlerimEkrani({
    super.key,
    required this.kullanici,
  });

  final AppUserModel kullanici;

  @override
  State<KuryePrimlerimEkrani> createState() => _KuryePrimlerimEkraniState();
}

class _KuryePrimlerimEkraniState extends State<KuryePrimlerimEkrani>
    with CafeThemeScreenMixin {
  late Future<MyCourierCommissionReportModel> raporFuture;
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
    raporFuture = ApiService.getMyCourierCommissionReport(
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

  @override
  Widget build(BuildContext context) {
    return themedRoot(
      Scaffold(
        backgroundColor: AppThemeHelper.sayfaZemin,
        body: SafeArea(
          child: FutureBuilder<MyCourierCommissionReportModel>(
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
                        baslik: 'Kurye Primlerim',
                        altBaslik:
                            'Teslim ettiğiniz paket siparişlere göre kazandığınız primleri buradan takip edin.',
                        tema: theme,
                        logoUrl: cafeLogoUrl,
                        aksiyonlar: _ustAksiyonlar(context),
                      ),
                      const SizedBox(height: 24),
                      const AppEmptyView(
                        ikon: Icons.payments_outlined,
                        baslik: 'Kurye prim sistemi kapalı',
                        aciklama:
                            'Kurye prim sistemi şu anda yönetici tarafından kapalıdır.',
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
                        PanelBaslikAlani(
                          baslik: 'Kurye Primlerim',
                          altBaslik:
                              'Teslim ettiğiniz paket siparişlere göre kazandığınız primleri buradan takip edin.',
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
                        OzetKartSatiri(
                          kartlar: [
                            OzetKart(
                              baslik: 'Teslim Edilen Paket',
                              deger: rapor.deliveredOrderCount.toString(),
                              ikon: Icons.delivery_dining,
                              tema: theme,
                            ),
                            OzetKart(
                              baslik: 'Teslim Edilen Satış',
                              deger:
                                  '${rapor.deliveredSales.toStringAsFixed(2)} TL',
                              ikon: Icons.receipt_long,
                              tema: theme,
                            ),
                            OzetKart(
                              baslik: 'Satış Primi',
                              deger:
                                  '${rapor.salesCommission.toStringAsFixed(2)} TL',
                              ikon: Icons.trending_up,
                              tema: theme,
                            ),
                            OzetKart(
                              baslik: 'Teslimat Primi',
                              deger:
                                  '${rapor.deliveryBonus.toStringAsFixed(2)} TL',
                              ikon: Icons.local_shipping,
                              tema: theme,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        StitchVurguKart(
                          baslik: 'Toplam Prim',
                          deger:
                              '${rapor.visibleTotalCommission.toStringAsFixed(2)} TL',
                          tema: theme,
                          altSatir:
                              'Satış prim oranı: %${rapor.courierDefaultRate}',
                        ),
                        if (rapor.deliveredOrderCount == 0) ...[
                          const SizedBox(height: 16),
                          const StitchKart(
                            child: AppEmptyView(
                              kompakt: true,
                              ikon: Icons.delivery_dining_outlined,
                              baslik: 'Bu dönemde teslimat yok',
                              aciklama:
                                  'Teslim ettiğiniz paket siparişler burada listelenir.',
                            ),
                          ),
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
