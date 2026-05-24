// Flutter arayüz bileşenlerini kullanmak için import ediyoruz.
import 'package:flutter/material.dart';

// Birleşik gider kaydı modelini kullanıyoruz (genel gider + malzeme alımı).
import '../models/expense_record_model.dart';

// Gelir-gider özet modelini kullanıyoruz.
// Toplam gelir, toplam gider ve net kazanç bilgilerini tutar.
import '../models/finance_summary_model.dart';

// Backend API servis dosyasını kullanıyoruz.
import '../services/api_service.dart';

import '../utils/app_theme_helper.dart';
import '../widgets/app_feedback_widgets.dart';
import '../widgets/app_themed_widgets.dart';

// Gelir-Gider İşlemleri ekranıdır.
// Yönetici bu ekranda gelir, gider ve net kazanç bilgilerini görür.
// Ayrıca günlük, haftalık, aylık ve tüm dönem filtreleriyle gider kayıtlarını listeler.
class GelirGiderEkrani extends StatefulWidget {
  // Constructor yapısıdır.
  const GelirGiderEkrani({super.key});

  @override
  State<GelirGiderEkrani> createState() => _GelirGiderEkraniState();
}

// Gelir-gider ekranındaki değişen verileri yöneten State sınıfıdır.
class _GelirGiderEkraniState extends State<GelirGiderEkrani>
    with CafeThemeScreenMixin {
  // Backend'den gelecek gelir-gider özetini tutar.
  late Future<FinanceSummaryModel> summaryFuture;

  // Backend'den gelecek birleşik gider listesini tutar.
  late Future<List<ExpenseRecordModel>> expenseRecordsFuture;

  // Seçili dönem bilgisidir.
  // all: tümü, daily: günlük, weekly: haftalık, monthly: aylık.
  String seciliDonem = 'all';

  @override
  void initState() {
    super.initState();
    initCafeThemeListener();
    // Sayfa açıldığında veriler yüklenir.
    verileriYukle();
  }

  @override
  void dispose() {
    disposeCafeThemeListener();
    super.dispose();
  }

  // Seçili döneme göre gelir-gider özetini ve gider kayıtlarını backend API'den yükler.
  void verileriYukle() {
    summaryFuture = ApiService.getFinanceSummary(period: seciliDonem);
    expenseRecordsFuture =
        ApiService.getFinanceExpenseRecords(period: seciliDonem);
  }

  // Ekranı yeniler.
  void ekraniYenile() {
    setState(() {
      verileriYukle();
    });
  }

  // Dönem filtresini değiştirir.
  void donemDegistir(String yeniDonem) {
    setState(() {
      seciliDonem = yeniDonem;
      verileriYukle();
    });
  }

  // Dönem değerini ekranda görünecek Türkçe metne dönüştürür.
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

  // Döneme göre boş liste mesajı.
  String bosKayitMesaji() {
    switch (seciliDonem) {
      case 'daily':
        return 'Günlük gider kaydı bulunmuyor.';
      case 'weekly':
        return 'Haftalık gider kaydı bulunmuyor.';
      case 'monthly':
        return 'Aylık gider kaydı bulunmuyor.';
      default:
        return 'Gider kaydı bulunmuyor.';
    }
  }

  // Tarihi gün.ay.yıl formatında gösterir.
  // ExpenseModel içindeki expenseDate DateTime ya da String olsa da çalışır.
  String tarihFormatla(dynamic tarih) {
    try {
      DateTime dateTime;

      if (tarih is DateTime) {
        dateTime = tarih.toLocal();
      } else {
        dateTime = DateTime.parse(tarih.toString()).toLocal();
      }

      final gun = dateTime.day.toString().padLeft(2, '0');
      final ay = dateTime.month.toString().padLeft(2, '0');
      final yil = dateTime.year.toString();

      return '$gun.$ay.$yil';
    } catch (_) {
      final text = tarih.toString();

      if (text.contains('T')) {
        return text.split('T').first;
      }

      return text;
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
        onPressed: giderEklePenceresiAc,
        icon: const Icon(Icons.add, size: 20),
        label: const Text('Gider Ekle'),
      ),
      OutlinedButton.icon(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back),
        label: const Text('Geri Dön'),
      ),
    ];
  }

  // Gider ekleme penceresini açar.
  Future<void> giderEklePenceresiAc() async {
    final TextEditingController baslikController = TextEditingController();
    final TextEditingController tutarController = TextEditingController();
    final TextEditingController aciklamaController = TextEditingController();
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
              constraints: const BoxConstraints(maxWidth: 460),
              child: StitchKart(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Gider ekleme dialog başlığı.
                      StitchBolumBasligi(
                        baslik: 'Gider Ekle',
                        ikon: Icons.add_card_outlined,
                        temaRengi: theme.primary,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: baslikController,
                        decoration: stitchInputDekorasyonu(
                          labelText: 'Gider Başlığı',
                          hintText: 'Örn: Günlük malzeme alımı',
                          temaRengi: theme.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: tutarController,
                        keyboardType: TextInputType.number,
                        decoration: stitchInputDekorasyonu(
                          labelText: 'Tutar (TL)',
                          hintText: 'Örn: 1500',
                          prefixIcon: Icons.payments_outlined,
                          temaRengi: theme.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: aciklamaController,
                        maxLines: 3,
                        decoration: stitchInputDekorasyonu(
                          labelText: 'Açıklama',
                          hintText: 'Örn: Mutfak ve servis malzemeleri alındı.',
                          temaRengi: theme.primary,
                          maxLines: 3,
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
                                final baslik = baslikController.text.trim();
                                final tutarText = tutarController.text.trim();
                                final aciklama = aciklamaController.text.trim();
                                final tutar = double.tryParse(
                                  tutarText.replaceAll(',', '.'),
                                );

                                if (baslik.isEmpty) {
                                  showAppPopup(
                                    dialogContext,
                                    message: 'Gider başlığı boş bırakılamaz.',
                                    type: AppPopupType.warning,
                                  );
                                  return;
                                }

                                if (tutar == null || tutar <= 0) {
                                  showAppPopup(
                                    dialogContext,
                                    message:
                                        'Geçerli bir gider tutarı giriniz.',
                                    type: AppPopupType.warning,
                                  );
                                  return;
                                }

                                try {
                                  final response = await ApiService.addExpense(
                                    title: baslik,
                                    amount: tutar,
                                    description: aciklama,
                                  );

                                  if (!ekranBaglami.mounted) return;

                                  showAppPopup(
                                    ekranBaglami,
                                    message: response['message']?.toString() ??
                                        'Gider başarıyla eklendi.',
                                    type: AppPopupType.success,
                                  );

                                  Navigator.pop(dialogContext, true);
                                } catch (error) {
                                  if (!dialogContext.mounted) return;

                                  showAppPopup(
                                    dialogContext,
                                    message:
                                        'Gider eklenemedi: ${ApiService.kullaniciHataMesaji(error)}',
                                    type: AppPopupType.error,
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

      if (!mounted) return;

      if (sonuc == true) {
        ekraniYenile();
      }
    } finally {
      baslikController.dispose();
      tutarController.dispose();
      aciklamaController.dispose();
    }
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
                      baslik: 'Gelir-Gider İşlemleri',
                      altBaslik:
                          'Gelir, gider ve net kazanç bilgilerini dönem filtreleriyle takip edin.',
                      tema: theme,
                      logoUrl: cafeLogoUrl,
                      aksiyonlar: _ustAksiyonlar(context),
                    ),
                    const SizedBox(height: 20),
                    _donemFiltreleri(),
                    const SizedBox(height: 20),
                    FutureBuilder<FinanceSummaryModel>(
                      future: summaryFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const AppLoadingView(
                            kompakt: true,
                            mesaj: 'Özet yükleniyor...',
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

                        final summary = snapshot.data!;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _ozetKartlari(summary),
                            if (summary.materialExpense > 0 ||
                                summary.normalExpense > 0) ...[
                              const SizedBox(height: 12),
                              _giderDetayBilgisi(summary),
                            ],
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    StitchBolumBasligi(
                      baslik: 'Gider Kayıtları (${donemBasligi(seciliDonem)})',
                      ikon: Icons.receipt_long_outlined,
                      temaRengi: theme.primary,
                    ),
                    const SizedBox(height: 14),
                    FutureBuilder<List<ExpenseRecordModel>>(
                      future: expenseRecordsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const AppLoadingView(
                            mesaj: 'Gider kayıtları yükleniyor...',
                          );
                        }

                        if (snapshot.hasError) {
                          return AppErrorView(
                            hataDetayi: snapshot.error.toString(),
                            tekrarDene: ekraniYenile,
                          );
                        }

                        final kayitlar = snapshot.data ?? [];

                        if (kayitlar.isEmpty) {
                          return AppEmptyView(
                            ikon: Icons.receipt_long_outlined,
                            baslik: bosKayitMesaji(),
                            aciklama:
                                'Genel gider eklemek için üstteki butonu, malzeme '
                                'alımı için Malzeme Alım İşlemleri ekranını kullanın.',
                          );
                        }

                        return Column(
                          children: [
                            for (final kayit in kayitlar) _giderKayitKarti(kayit),
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

  // Dönem filtre chip'leri — Stitch kart içinde.
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

  // Tek bir gider kaydı kartı (genel gider veya malzeme alımı).
  Widget _giderKayitKarti(ExpenseRecordModel kayit) {
    final aciklama = kayit.description?.trim().isNotEmpty == true
        ? kayit.description!
        : 'Açıklama bulunmuyor.';
    final malzeme = kayit.malzemeKaydi;
    final ikon = malzeme ? Icons.shopping_basket : Icons.receipt_long;
    final etiketRengi =
        malzeme ? Colors.orange.shade800 : theme.primary;

    final bilgiOgeleri = <({String etiket, String deger, Color? vurgu})>[
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
    ];

    if (malzeme && kayit.miktarBirimMetni() != null) {
      bilgiOgeleri.insert(
        0,
        (
          etiket: 'Miktar',
          deger: kayit.miktarBirimMetni()!,
          vurgu: null,
        ),
      );
    }
    if (malzeme && kayit.unitPrice != null) {
      bilgiOgeleri.insert(
        malzeme && kayit.miktarBirimMetni() != null ? 1 : 0,
        (
          etiket: 'Birim fiyat',
          deger: '${kayit.unitPrice!.toStringAsFixed(2)} TL',
          vurgu: etiketRengi,
        ),
      );
    }

    return StitchKart(
      margin: const EdgeInsets.only(bottom: 12),
      kenarlikRengi: etiketRengi,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Gider kaydı üst başlık satırı.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.softCard,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(ikon, color: etiketRengi, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  kayit.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              StitchEtiket(
                metin: kayit.etiketMetni(),
                renk: etiketRengi,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: FiyatEtiketi(
              fiyat: kayit.amount,
              temaRengi: etiketRengi,
              buyuk: true,
            ),
          ),
          const SizedBox(height: 10),
          StitchBilgiIzgarasi(
            sutunSayisi: 2,
            ogeler: bilgiOgeleri,
          ),
        ],
      ),
    );
  }

  // Gider türüne göre detay dağılımı — bilgi ızgarası.
  Widget _giderDetayBilgisi(FinanceSummaryModel summary) {
    return StitchKart(
      padding: const EdgeInsets.all(14),
      kenarlikRengi: theme.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StitchBolumBasligi(
            baslik: 'Gider Dağılımı',
            ikon: Icons.pie_chart_outline,
            temaRengi: theme.primary,
          ),
          const SizedBox(height: 10),
          StitchBilgiIzgarasi(
            ogeler: [
              (
                etiket: 'Diğer giderler',
                deger: '${summary.normalExpense.toStringAsFixed(2)} TL',
                vurgu: theme.primary,
              ),
              (
                etiket: 'Malzeme giderleri',
                deger: '${summary.materialExpense.toStringAsFixed(2)} TL',
                vurgu: Colors.orange.shade800,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ozetKartlari(FinanceSummaryModel summary) {
    return OzetKartSatiri(
      kartlar: [
        OzetKart(
          baslik: 'Toplam Gelir',
          deger: '${summary.totalIncome.toStringAsFixed(2)} TL',
          ikon: Icons.trending_up,
          tema: theme,
        ),
        OzetKart(
          baslik: 'Toplam Gider',
          deger: '${summary.totalExpense.toStringAsFixed(2)} TL',
          ikon: Icons.trending_down,
          tema: theme,
        ),
        OzetKart(
          baslik: 'Net Kazanç',
          deger: '${summary.netProfit.toStringAsFixed(2)} TL',
          ikon: Icons.account_balance_wallet,
          tema: theme,
        ),
      ],
    );
  }
}
