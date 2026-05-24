// Yönetici garson prim yönetimi ekranıdır.
import 'package:flutter/material.dart';

import '../models/commission_settings_model.dart';
import '../models/product_commission_rule_model.dart';
import '../models/urun_model.dart';
import '../models/waiter_commission_report_model.dart';
import '../models/courier_commission_report_model.dart';
import '../services/api_service.dart';
import '../utils/app_theme_helper.dart';
import '../widgets/app_feedback_widgets.dart';
import '../widgets/app_themed_widgets.dart';

class GarsonPrimYonetimiEkrani extends StatefulWidget {
  const GarsonPrimYonetimiEkrani({super.key});

  @override
  State<GarsonPrimYonetimiEkrani> createState() =>
      _GarsonPrimYonetimiEkraniState();
}

class _GarsonPrimYonetimiEkraniState extends State<GarsonPrimYonetimiEkrani>
    with CafeThemeScreenMixin {
  CommissionSettingsModel? ayarlar;
  bool ayarlarYukleniyor = true;
  bool kaydediliyor = false;

  String seciliDonem = 'monthly';
  String kuryeSeciliDonem = 'monthly';

  final TextEditingController oranController = TextEditingController();
  final TextEditingController ayinElemaniController = TextEditingController();
  final TextEditingController kuryeOranController = TextEditingController();
  final TextEditingController kuryeTeslimatController = TextEditingController();
  final TextEditingController hedefMiktarController = TextEditingController();
  final TextEditingController ekstraPrimController = TextEditingController();

  bool primAcik = true;
  bool kuryePrimAcik = true;
  bool kuryeKaydediliyor = false;
  bool kuralAktif = true;
  int? seciliUrunId;
  int? duzenlenenKuralId;
  List<UrunModel> urunler = [];

  // Rapor/kural verileri — FutureBuilder yerine önbellek (performans).
  bool _listelerYukleniyor = false;
  List<ProductCommissionRuleModel>? _kurallar;
  WaiterCommissionReportResponse? _garsonRapor;
  CourierCommissionReportResponse? _kuryeRapor;
  Object? _kurallarHata;
  Object? _garsonRaporHata;
  Object? _kuryeRaporHata;
  bool _garsonRaporYukleniyor = false;
  bool _kuryeRaporYukleniyor = false;

  @override
  void initState() {
    super.initState();
    initCafeThemeListener();
    _baslangicYukle();
  }

  @override
  void dispose() {
    disposeCafeThemeListener();
    oranController.dispose();
    ayinElemaniController.dispose();
    kuryeOranController.dispose();
    kuryeTeslimatController.dispose();
    hedefMiktarController.dispose();
    ekstraPrimController.dispose();
    super.dispose();
  }

  Future<void> _baslangicYukle() async {
    await Future.wait([
      _ayarlariYukle(),
      _urunleriYukle(),
    ]);
    if (mounted) await _listeleriYukle();
  }

  Future<void> _ayarlariYukle() async {
    setState(() => ayarlarYukleniyor = true);
    try {
      final settings = await ApiService.getCommissionSettings();
      if (!mounted) return;
      setState(() {
        ayarlar = settings;
        primAcik = settings.isEnabled;
        kuryePrimAcik = settings.courierCommissionEnabled;
        oranController.text = settings.defaultRate.toString();
        ayinElemaniController.text =
            settings.employeeOfMonthBonus.toString();
        kuryeOranController.text = settings.courierDefaultRate.toString();
        kuryeTeslimatController.text =
            settings.courierDeliveryBonus.toString();
        ayarlarYukleniyor = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => ayarlarYukleniyor = false);
      showAppSnackBar(context, ApiService.kullaniciHataMesaji(error), hata: true);
    }
  }

  Future<void> _listeleriYukle() async {
    setState(() {
      _listelerYukleniyor = true;
      _kurallarHata = null;
      _garsonRaporHata = null;
      _kuryeRaporHata = null;
    });

    await Future.wait([
      _kurallariYukle(),
      _garsonRaporunuYukle(),
      _kuryeRaporunuYukle(),
    ]);

    if (mounted) setState(() => _listelerYukleniyor = false);
  }

  Future<void> _garsonRaporunuYukle() async {
    if (_garsonRapor == null) {
      setState(() => _garsonRaporYukleniyor = true);
    }
    setState(() => _garsonRaporHata = null);
    try {
      final rapor =
          await ApiService.getWaiterCommissionReport(period: seciliDonem);
      if (!mounted) return;
      setState(() {
        _garsonRapor = rapor;
        _garsonRaporYukleniyor = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _garsonRaporHata = error;
        _garsonRaporYukleniyor = false;
      });
    }
  }

  Future<void> _kuryeRaporunuYukle() async {
    if (_kuryeRapor == null) {
      setState(() => _kuryeRaporYukleniyor = true);
    }
    setState(() => _kuryeRaporHata = null);
    try {
      final rapor = await ApiService.getCourierCommissionReport(
        period: kuryeSeciliDonem,
      );
      if (!mounted) return;
      setState(() {
        _kuryeRapor = rapor;
        _kuryeRaporYukleniyor = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _kuryeRaporHata = error;
        _kuryeRaporYukleniyor = false;
      });
    }
  }

  Future<void> _kurallariYukle() async {
    try {
      final liste = await ApiService.getProductCommissionRules();
      if (!mounted) return;
      setState(() {
        _kurallar = liste;
        _kurallarHata = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _kurallarHata = error);
    }
  }

  Future<void> _urunleriYukle() async {
    try {
      final liste = await ApiService.getProducts();
      if (!mounted) return;
      setState(() => urunler = liste.where((u) => u.isActive).toList());
    } catch (_) {}
  }

  Future<void> _ayarlariKaydet() async {
    final oran = double.tryParse(oranController.text.replaceAll(',', '.'));
    final ayinPrim =
        double.tryParse(ayinElemaniController.text.replaceAll(',', '.'));

    if (oran == null || oran < 0) {
      showAppSnackBar(context, 'Geçerli bir prim oranı giriniz.', hata: true);
      return;
    }
    if (ayinPrim == null || ayinPrim < 0) {
      showAppSnackBar(context, 'Ayın elemanı primi negatif olamaz.', hata: true);
      return;
    }

    setState(() => kaydediliyor = true);
    try {
      final guncel = await ApiService.updateCommissionSettings(
        isEnabled: primAcik,
        defaultRate: oran,
        employeeOfMonthBonus: ayinPrim,
        courierCommissionEnabled: kuryePrimAcik,
        courierDefaultRate:
            double.tryParse(kuryeOranController.text.replaceAll(',', '.')) ??
                ayarlar?.courierDefaultRate ??
                3,
        courierDeliveryBonus:
            double.tryParse(kuryeTeslimatController.text.replaceAll(',', '.')) ??
                ayarlar?.courierDeliveryBonus ??
                0,
      );
      if (!mounted) return;
      setState(() {
        ayarlar = guncel;
        kaydediliyor = false;
      });
      showAppSnackBar(context, 'Prim ayarları kaydedildi.');
      _listeleriYukle();
    } catch (error) {
      if (!mounted) return;
      setState(() => kaydediliyor = false);
      showAppSnackBar(context, ApiService.kullaniciHataMesaji(error), hata: true);
    }
  }

  // Kurye prim ayarlarını kaydeder (garson ayarları korunur).
  Future<void> _kuryeAyarlariKaydet() async {
    final kuryeOran =
        double.tryParse(kuryeOranController.text.replaceAll(',', '.'));
    final teslimatPrimi =
        double.tryParse(kuryeTeslimatController.text.replaceAll(',', '.'));

    if (kuryeOran == null || kuryeOran < 0) {
      showAppSnackBar(context, 'Geçerli bir kurye prim oranı giriniz.', hata: true);
      return;
    }
    if (teslimatPrimi == null || teslimatPrimi < 0) {
      showAppSnackBar(
        context,
        'Teslimat başı prim negatif olamaz.',
        hata: true,
      );
      return;
    }

    final garsonOran =
        double.tryParse(oranController.text.replaceAll(',', '.'));
    final ayinPrim =
        double.tryParse(ayinElemaniController.text.replaceAll(',', '.'));

    setState(() => kuryeKaydediliyor = true);
    try {
      final guncel = await ApiService.updateCommissionSettings(
        isEnabled: primAcik,
        defaultRate: garsonOran ?? ayarlar?.defaultRate ?? 5,
        employeeOfMonthBonus: ayinPrim ?? ayarlar?.employeeOfMonthBonus ?? 0,
        courierCommissionEnabled: kuryePrimAcik,
        courierDefaultRate: kuryeOran,
        courierDeliveryBonus: teslimatPrimi,
      );
      if (!mounted) return;
      setState(() {
        ayarlar = guncel;
        kuryeKaydediliyor = false;
      });
      showAppSnackBar(context, 'Kurye prim ayarları kaydedildi.');
      _listeleriYukle();
    } catch (error) {
      if (!mounted) return;
      setState(() => kuryeKaydediliyor = false);
      showAppSnackBar(context, ApiService.kullaniciHataMesaji(error), hata: true);
    }
  }

  void _kuralFormuTemizle() {
    setState(() {
      duzenlenenKuralId = null;
      seciliUrunId = null;
      hedefMiktarController.clear();
      ekstraPrimController.clear();
      kuralAktif = true;
    });
  }

  Future<void> _kuralKaydet() async {
    if (seciliUrunId == null) {
      showAppSnackBar(context, 'Lütfen ürün seçiniz.', hata: true);
      return;
    }

    final hedef =
        double.tryParse(hedefMiktarController.text.replaceAll(',', '.'));
    final prim =
        double.tryParse(ekstraPrimController.text.replaceAll(',', '.'));

    if (hedef == null || hedef <= 0) {
      showAppSnackBar(context, 'Hedef miktar 0\'dan büyük olmalı.', hata: true);
      return;
    }
    if (prim == null || prim < 0) {
      showAppSnackBar(context, 'Ekstra prim negatif olamaz.', hata: true);
      return;
    }

    try {
      if (duzenlenenKuralId != null) {
        await ApiService.updateProductCommissionRule(
          ruleId: duzenlenenKuralId!,
          productId: seciliUrunId!,
          targetQuantity: hedef,
          bonusAmount: prim,
          isActive: kuralAktif,
        );
      } else {
        await ApiService.addProductCommissionRule(
          productId: seciliUrunId!,
          targetQuantity: hedef,
          bonusAmount: prim,
          isActive: kuralAktif,
        );
      }

      if (!mounted) return;
      showAppSnackBar(context, 'Ürün prim kuralı kaydedildi.');
      _kuralFormuTemizle();
      await _kurallariYukle();
    } catch (error) {
      if (!mounted) return;
      showAppSnackBar(context, ApiService.kullaniciHataMesaji(error), hata: true);
    }
  }

  Future<void> _kuralSil(int ruleId) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kuralı Sil'),
        content: const Text('Bu ürün prim kuralını silmek istiyor musunuz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (onay != true || !mounted) return;

    try {
      await ApiService.deleteProductCommissionRule(ruleId: ruleId);
      showAppSnackBar(context, 'Kural silindi.');
      await _kurallariYukle();
    } catch (error) {
      showAppSnackBar(context, ApiService.kullaniciHataMesaji(error), hata: true);
    }
  }

  void _kuralDuzenle(ProductCommissionRuleModel kural) {
    setState(() {
      duzenlenenKuralId = kural.id;
      seciliUrunId = kural.productId;
      hedefMiktarController.text = kural.targetQuantity.toString();
      ekstraPrimController.text = kural.bonusAmount.toString();
      kuralAktif = kural.isActive;
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

  // Garson rapor dönem filtre chipleri.
  Widget _garsonDonemChip(String etiket, String deger) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: StitchFiltreChip(
        etiket: etiket,
        secili: seciliDonem == deger,
        temaRengi: theme.primary,
        onTap: () {
          setState(() => seciliDonem = deger);
          _garsonRaporunuYukle();
        },
      ),
    );
  }

  Widget _kuryeDonemChipStitch(String etiket, String deger) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: StitchFiltreChip(
        etiket: etiket,
        secili: kuryeSeciliDonem == deger,
        temaRengi: theme.primary,
        onTap: () {
          setState(() => kuryeSeciliDonem = deger);
          _kuryeRaporunuYukle();
        },
      ),
    );
  }

  List<Widget> _ustAksiyonlar(BuildContext context) {
    return [
      OutlinedButton.icon(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back, size: 18),
        label: const Text('Geri Dön'),
      ),
      FilledButton.icon(
        style: themedElevatedButtonStyle(theme),
        onPressed: () {
          _ayarlariYukle();
          _listeleriYukle();
        },
        icon: const Icon(Icons.refresh, size: 18),
        label: const Text('Yenile'),
      ),
    ];
  }

  String _guvenliMetin(String? deger, {String varsayilan = 'Belirtilmemiş'}) {
    final temiz = deger?.trim() ?? '';
    return temiz.isEmpty ? varsayilan : temiz;
  }

  String _tl(double deger) => '${deger.toStringAsFixed(2)} TL';

  IconData _metrikIkonu(String baslik) {
    switch (baslik) {
      case 'Kullanıcı':
        return Icons.person_outline;
      case 'Kapatılan sipariş':
        return Icons.receipt_long_outlined;
      case 'Toplam satış':
      case 'Teslim edilen satış':
        return Icons.payments_outlined;
      case 'Genel prim':
      case 'Satış primi':
        return Icons.percent;
      case 'Ürün ekstra primi':
        return Icons.star_outline;
      case 'Görünür toplam prim':
        return Icons.visibility_outlined;
      case 'Ayın elemanı özel primi':
      case 'Özel prim':
        return Icons.emoji_events_outlined;
      case 'Teslim edilen paket':
        return Icons.local_shipping_outlined;
      case 'Satış prim oranı':
        return Icons.trending_up;
      case 'Teslimat primi':
        return Icons.delivery_dining_outlined;
      case 'Hedef miktar':
        return Icons.flag_outlined;
      case 'Ekstra prim':
        return Icons.add_circle_outline;
      default:
        return Icons.insights_outlined;
    }
  }

  // Metrik kart helper — dashboard bilgi kutusu, input/field görünümü vermez.
  Widget _buildMetrikKarti({
    required String baslik,
    required String deger,
    IconData? ikon,
    Color? degerRengi,
    bool vurgulu = false,
  }) {
    final renk = degerRengi ?? theme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 11, 10, 12),
      decoration: BoxDecoration(
        color: AppThemeHelper.sayfaZemin,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: renk.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              ikon ?? _metrikIkonu(baslik),
              size: 14,
              color: renk,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            baslik,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              height: 1.2,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            deger,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: vurgulu ? 17 : 15,
              fontWeight: FontWeight.w700,
              height: 1.15,
              color: vurgulu ? renk : const Color(0xFF3E2723),
            ),
          ),
        ],
      ),
    );
  }

  // Performans için sade dashboard kart yapısı — ağır efekt yok.
  Widget _buildToplamVurguKarti({
    required String baslik,
    required String deger,
    Color? renk,
    IconData ikon = Icons.account_balance_wallet_outlined,
  }) {
    final vurguRengi = renk ?? theme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: vurguRengi.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: vurguRengi.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(ikon, size: 18, color: vurguRengi),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  baslik,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  deger,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: vurguRengi,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetrikIzgarasi(
    List<
            ({
              String etiket,
              String deger,
              Color? vurgu,
              bool vurgulu,
              IconData? ikon,
            })>
        satirlar, {
    int sutunSayisi = 3,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width - 40;
        final kolon = maxW >= 720 ? sutunSayisi : (maxW >= 480 ? 2 : 1);
        final kartGenisligi =
            kolon == 1 ? maxW : (maxW - (kolon - 1) * 8) / kolon;

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: satirlar
              .map(
                (s) => SizedBox(
                  width: kartGenisligi,
                  child: _buildMetrikKarti(
                    baslik: s.etiket,
                    deger: s.deger,
                    ikon: s.ikon,
                    degerRengi: s.vurgu,
                    vurgulu: s.vurgulu,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  // Bölüm kartı sarmalayıcı — performans için sade Stitch panel.
  Widget _bolumKarti({
    required String baslik,
    required IconData ikon,
    required Widget child,
    String? altBaslik,
  }) {
    return StitchKart(
      kenarlikRengi: theme.primary,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StitchBolumBasligi(
            baslik: baslik,
            ikon: ikon,
            temaRengi: theme.primary,
            altBaslik: altBaslik,
          ),
          const SizedBox(height: 12),
          child,
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
          child: ayarlarYukleniyor
              ? const AppLoadingView(mesaj: 'Ayarlar yükleniyor...')
              : _buildPersonelPrimDashboard(),
        ),
      ),
    );
  }

  // Aktif render yolu — Personel Prim Yönetimi dashboard gövdesi.
  Widget _buildPersonelPrimDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Üst özet kartları ve header bu blokta başlar.
              PanelBaslikAlani(
                baslik: 'Personel Prim Yönetimi',
                altBaslik:
                    'Garson ve kurye prim ayarlarını, raporları ve ürün bonuslarını yönetin.',
                tema: theme,
                logoUrl: cafeLogoUrl,
                aksiyonlar: _ustAksiyonlar(context),
              ),
              if (ayarlar != null) ...[
                const SizedBox(height: 14),
                OzetKartSatiri(
                  kartlar: [
                    OzetKart(
                      baslik: 'Prim Sistemi',
                      deger: primAcik ? 'Açık' : 'Kapalı',
                      altMetin: kuryePrimAcik
                          ? 'Garson + kurye aktif'
                          : 'Kurye kapalı',
                      ikon: Icons.toggle_on,
                      tema: theme,
                    ),
                    OzetKart(
                      baslik: 'Garson Prim Oranı',
                      deger: '%${ayarlar!.defaultRate}',
                      ikon: Icons.percent,
                      tema: theme,
                    ),
                    OzetKart(
                      baslik: 'Kurye Prim Oranı',
                      deger: '%${ayarlar!.courierDefaultRate}',
                      ikon: Icons.delivery_dining,
                      tema: theme,
                    ),
                    OzetKart(
                      baslik: 'Ayın Elemanı Bonusu',
                      deger:
                          '${ayarlar!.employeeOfMonthBonus.toStringAsFixed(0)} TL',
                      ikon: Icons.emoji_events,
                      tema: theme,
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              _ayarlarBolumu(),
              const SizedBox(height: 16),
              _urunKuralBolumu(),
              const SizedBox(height: 16),
              _raporBolumu(),
              const SizedBox(height: 16),
              _kuryeAyarBolumu(),
              const SizedBox(height: 16),
              _kuryeRaporBolumu(),
            ],
          ),
        ),
      ),
    );
  }

  // Garson prim ayarları — modern kart içinde form düzeni.
  Widget _ayarlarBolumu() {
    return _bolumKarti(
      baslik: 'Garson Prim Ayarları',
      ikon: Icons.settings_outlined,
      altBaslik: 'Genel oran ve ayın elemanı bonusunu yapılandırın.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppInfoCard(
            mesaj: 'Prim sistemi kapalıysa garsonlara prim hesaplanmaz.',
          ),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              color: theme.softCard.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.primary.withValues(alpha: 0.12)),
            ),
            child: SwitchListTile(
              title: const Text(
                'Prim Sistemi Açık',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                primAcik ? 'Garson primleri hesaplanıyor' : 'Sistem kapalı',
                style: const TextStyle(fontSize: 12),
              ),
              value: primAcik,
              activeThumbColor: theme.primary,
              onChanged: (deger) => setState(() => primAcik = deger),
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final genis = constraints.maxWidth >= 560;
              final alanlar = [
                TextField(
                  controller: oranController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: stitchInputDekorasyonu(
                    labelText: 'Genel Prim Oranı (%)',
                    prefixIcon: Icons.percent,
                    temaRengi: theme.primary,
                  ),
                ),
                TextField(
                  controller: ayinElemaniController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: stitchInputDekorasyonu(
                    labelText: 'Ayın Elemanı Özel Primi (TL)',
                    prefixIcon: Icons.emoji_events_outlined,
                    temaRengi: theme.primary,
                  ),
                ),
              ];

              if (!genis) {
                return Column(
                  children: [
                    alanlar[0],
                    const SizedBox(height: 12),
                    alanlar[1],
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: alanlar[0]),
                  const SizedBox(width: 12),
                  Expanded(child: alanlar[1]),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: kaydediliyor ? null : _ayarlariKaydet,
              style: themedElevatedButtonStyle(theme),
              icon: kaydediliyor
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(
                kaydediliyor ? 'Kaydediliyor...' : 'Garson Ayarlarını Kaydet',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Ürün bazlı ekstra prim kuralları — form + modern kural kartları.
  Widget _urunKuralBolumu() {
    return _bolumKarti(
      baslik: 'Ürün Bazlı Ekstra Prim Kuralları',
      ikon: Icons.star_outline,
      altBaslik: 'Belirli ürün satış hedeflerine ekstra prim tanımlayın.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.primary.withValues(alpha: 0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: seciliUrunId,
                  decoration: stitchInputDekorasyonu(
                    labelText: 'Ürün Seç',
                    prefixIcon: Icons.restaurant_menu,
                    temaRengi: theme.primary,
                  ),
                  items: urunler
                      .map(
                        (u) => DropdownMenuItem(
                          value: u.id,
                          child: Text('${u.name} (${u.categoryName})'),
                        ),
                      )
                      .toList(),
                  onChanged: (deger) => setState(() => seciliUrunId = deger),
                ),
                const SizedBox(height: 10),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final genis = constraints.maxWidth >= 520;
                    final satir = Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: hedefMiktarController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: stitchInputDekorasyonu(
                              labelText: 'Hedef Miktar',
                              temaRengi: theme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: ekstraPrimController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: stitchInputDekorasyonu(
                              labelText: 'Ekstra Prim (TL)',
                              temaRengi: theme.primary,
                            ),
                          ),
                        ),
                      ],
                    );
                    if (genis) return satir;
                    return Column(
                      children: [
                        TextField(
                          controller: hedefMiktarController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: stitchInputDekorasyonu(
                            labelText: 'Hedef Miktar',
                            temaRengi: theme.primary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: ekstraPrimController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: stitchInputDekorasyonu(
                            labelText: 'Ekstra Prim (TL)',
                            temaRengi: theme.primary,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 4),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Kural Aktif'),
                  value: kuralAktif,
                  activeThumbColor: theme.primary,
                  onChanged: (v) => setState(() => kuralAktif = v),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: FilledButton.icon(
                          onPressed: _kuralKaydet,
                          style: themedElevatedButtonStyle(theme),
                          icon: Icon(
                            duzenlenenKuralId == null
                                ? Icons.add
                                : Icons.check,
                          ),
                          label: Text(
                            duzenlenenKuralId == null
                                ? 'Kural Ekle'
                                : 'Güncelle',
                          ),
                        ),
                      ),
                    ),
                    if (duzenlenenKuralId != null) ...[
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: _kuralFormuTemizle,
                        child: const Text('İptal'),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _buildKuralListesi(),
        ],
      ),
    );
  }

  // Ürün bazlı prim kural kartları burada listelenir.
  Widget _buildKuralListesi() {
    if (_listelerYukleniyor && _kurallar == null) {
      return const AppLoadingView(kompakt: true);
    }
    if (_kurallarHata != null && _kurallar == null) {
      return AppErrorView(
        kompakt: true,
        hataDetayi: _kurallarHata.toString(),
        tekrarDene: _kurallariYukle,
      );
    }
    final kurallar = _kurallar ?? [];
    if (kurallar.isEmpty) {
      return const AppEmptyView(
        kompakt: true,
        baslik: 'Ürün prim kuralı yok',
        aciklama: 'Yukarıdan yeni kural ekleyebilirsiniz.',
      );
    }
    return Column(
      children: kurallar.map(_buildPrimKuralKarti).toList(),
    );
  }

  // Ürün bazlı prim kural kartı — hedef/prim bilgi kutuları input gibi görünmez.
  Widget _buildPrimKuralKarti(ProductCommissionRuleModel kural) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: kural.isActive
              ? theme.primary.withValues(alpha: 0.18)
              : Colors.grey.shade300,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _guvenliMetin(kural.productName, varsayilan: 'Ürün adı yok'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: theme.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        StitchEtiket(
                          metin: _guvenliMetin(
                            kural.categoryName,
                            varsayilan: 'Kategori yok',
                          ),
                          renk: theme.primary,
                        ),
                        StitchEtiket(
                          metin: kural.isActive ? 'Aktif' : 'Pasif',
                          renk: kural.isActive
                              ? Colors.green.shade700
                              : Colors.grey.shade600,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Kuralı düzenle',
                    icon: Icon(Icons.edit_outlined, color: theme.primary, size: 20),
                    onPressed: () => _kuralDuzenle(kural),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Kuralı sil',
                    icon: Icon(Icons.delete_outline, color: Colors.red.shade400, size: 20),
                    onPressed: () => _kuralSil(kural.id),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildMetrikIzgarasi([
            (
              etiket: 'Hedef miktar',
              deger: kural.targetQuantity > 0
                  ? kural.targetQuantity.toString()
                  : '0',
              vurgu: null,
              vurgulu: false,
              ikon: Icons.flag_outlined,
            ),
            (
              etiket: 'Ekstra prim',
              deger: _tl(kural.bonusAmount),
              vurgu: theme.primary,
              vurgulu: true,
              ikon: Icons.add_circle_outline,
            ),
          ], sutunSayisi: 2),
        ],
      ),
    );
  }

  // Garson prim raporu — filtre chipleri ve metrik kartları.
  Widget _raporBolumu() {
    return _bolumKarti(
      baslik: 'Garson Prim Raporu',
      ikon: Icons.bar_chart,
      altBaslik: 'Döneme göre personel prim performansını görüntüleyin.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _garsonDonemChip('Tümü', 'all'),
                _garsonDonemChip('Günlük', 'daily'),
                _garsonDonemChip('Haftalık', 'weekly'),
                _garsonDonemChip('Aylık', 'monthly'),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Seçili dönem: ${donemBasligi(seciliDonem)}',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 12),
          _buildGarsonRaporIcerigi(),
        ],
      ),
    );
  }

  // Garson prim raporu metrik kartları burada oluşturulur.
  Widget _buildGarsonRaporIcerigi() {
    if (_garsonRaporYukleniyor && _garsonRapor == null) {
      return const AppLoadingView(
        kompakt: true,
        mesaj: 'Prim raporu yükleniyor...',
      );
    }
    if (_garsonRaporHata != null && _garsonRapor == null) {
      return AppErrorView(
        kompakt: true,
        hataDetayi: _garsonRaporHata.toString(),
        tekrarDene: _garsonRaporunuYukle,
      );
    }

    final rapor = _garsonRapor;
    if (rapor == null) {
      return const AppLoadingView(kompakt: true);
    }

    if (rapor.waiters.isEmpty) {
      return AppEmptyView(
        kompakt: true,
        baslik: '${donemBasligi(seciliDonem)} prim verisi bulunmuyor.',
        aciklama: 'Garson satışı olmadığında prim hesaplanmaz.',
      );
    }

    final ayinElemani = rapor.ayinElemani;

    return Column(
      children: [
        if (!rapor.isEnabled)
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: AppInfoCard(
              mesaj: 'Prim sistemi kapalı. Tutarlar 0 gösterilir.',
            ),
          ),
        if (seciliDonem == 'monthly' && ayinElemani != null) ...[
          _buildAyinElemaniKarti(ayinElemani),
          const SizedBox(height: 10),
        ],
        ...rapor.waiters.map(_buildGarsonRaporKarti),
      ],
    );
  }

  Widget _buildAyinElemaniKarti(WaiterCommissionReportModel ayinElemani) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amber.shade700.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events, color: Colors.amber.shade800, size: 22),
              const SizedBox(width: 8),
              Text(
                'Ayın Elemanı',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _guvenliMetin(ayinElemani.fullName),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.primary,
            ),
          ),
          const SizedBox(height: 8),
          _buildMetrikIzgarasi([
            (
              etiket: 'Toplam satış',
              deger: _tl(ayinElemani.totalSales),
              vurgu: null,
              vurgulu: false,
              ikon: Icons.payments_outlined,
            ),
            (
              etiket: 'Özel prim',
              deger: _tl(ayinElemani.employeeOfMonthBonus),
              vurgu: Colors.amber.shade900,
              vurgulu: true,
              ikon: Icons.emoji_events_outlined,
            ),
          ], sutunSayisi: 2),
        ],
      ),
    );
  }

  // Garson rapor kartı — 3 kolonlu dashboard grid + alt toplam vurgusu.
  Widget _buildGarsonRaporKarti(WaiterCommissionReportModel g) {
    final metrikSatirlari = <
        ({
          String etiket,
          String deger,
          Color? vurgu,
          bool vurgulu,
          IconData? ikon,
        })>[
      (
        etiket: 'Kullanıcı',
        deger: _guvenliMetin(g.username),
        vurgu: null,
        vurgulu: false,
        ikon: Icons.person_outline,
      ),
      (
        etiket: 'Kapatılan sipariş',
        deger: g.closedOrderCount.toString(),
        vurgu: null,
        vurgulu: false,
        ikon: Icons.receipt_long_outlined,
      ),
      (
        etiket: 'Toplam satış',
        deger: _tl(g.totalSales),
        vurgu: null,
        vurgulu: false,
        ikon: Icons.payments_outlined,
      ),
      (
        etiket: 'Genel prim',
        deger: _tl(g.baseCommission),
        vurgu: theme.primary,
        vurgulu: true,
        ikon: Icons.percent,
      ),
      (
        etiket: 'Ürün ekstra primi',
        deger: _tl(g.productBonus),
        vurgu: null,
        vurgulu: false,
        ikon: Icons.star_outline,
      ),
      (
        etiket: 'Görünür toplam prim',
        deger: _tl(g.visibleTotalCommission),
        vurgu: theme.primary,
        vurgulu: true,
        ikon: Icons.visibility_outlined,
      ),
    ];

    if (g.isEmployeeOfMonth) {
      metrikSatirlari.add(
        (
          etiket: 'Ayın elemanı özel primi',
          deger: _tl(g.employeeOfMonthBonus),
          vurgu: Colors.amber.shade900,
          vurgulu: true,
          ikon: Icons.emoji_events_outlined,
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: g.isEmployeeOfMonth
              ? Colors.amber.shade700.withValues(alpha: 0.4)
              : theme.primary.withValues(alpha: 0.12),
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _guvenliMetin(g.fullName),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '@${_guvenliMetin(g.username)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              if (g.isEmployeeOfMonth)
                StitchEtiket(
                  metin: 'Ayın Elemanı',
                  renk: Colors.amber.shade800,
                ),
            ],
          ),
          const SizedBox(height: 10),
          _buildMetrikIzgarasi(metrikSatirlari, sutunSayisi: 3),
          const SizedBox(height: 8),
          _buildToplamVurguKarti(
            baslik: 'Yöneticiye Görünen Toplam',
            deger: _tl(g.managerTotalCommission),
            ikon: Icons.admin_panel_settings_outlined,
          ),
        ],
      ),
    );
  }

  // Kurye prim ayarları — kompakt modern form kartı.
  Widget _kuryeAyarBolumu() {
    return _bolumKarti(
      baslik: 'Kurye Prim Ayarları',
      ikon: Icons.delivery_dining_outlined,
      altBaslik: 'Kurye satış oranı ve teslimat başı primi.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              color: theme.softCard.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.primary.withValues(alpha: 0.12)),
            ),
            child: SwitchListTile(
              title: const Text(
                'Kurye Prim Sistemi Açık',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              value: kuryePrimAcik,
              activeThumbColor: theme.primary,
              onChanged: (v) => setState(() => kuryePrimAcik = v),
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final genis = constraints.maxWidth >= 560;
              final alanlar = [
                TextField(
                  controller: kuryeOranController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: stitchInputDekorasyonu(
                    labelText: 'Kurye Satış Prim Oranı (%)',
                    prefixIcon: Icons.percent,
                    temaRengi: theme.primary,
                  ),
                ),
                TextField(
                  controller: kuryeTeslimatController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: stitchInputDekorasyonu(
                    labelText: 'Teslimat Başı Prim (TL)',
                    prefixIcon: Icons.payments_outlined,
                    temaRengi: theme.primary,
                  ),
                ),
              ];
              if (!genis) {
                return Column(
                  children: [
                    alanlar[0],
                    const SizedBox(height: 12),
                    alanlar[1],
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: alanlar[0]),
                  const SizedBox(width: 12),
                  Expanded(child: alanlar[1]),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: kuryeKaydediliyor ? null : _kuryeAyarlariKaydet,
              style: themedElevatedButtonStyle(theme),
              icon: kuryeKaydediliyor
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(
                kuryeKaydediliyor
                    ? 'Kaydediliyor...'
                    : 'Kurye Ayarlarını Kaydet',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Kurye prim raporu — dönem filtreleri ve metrik kartları.
  Widget _kuryeRaporBolumu() {
    return _bolumKarti(
      baslik: 'Kurye Prim Raporu',
      ikon: Icons.local_shipping_outlined,
      altBaslik: 'Kurye teslimat performansı ve prim özeti.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _kuryeDonemChipStitch('Tümü', 'all'),
                _kuryeDonemChipStitch('Günlük', 'daily'),
                _kuryeDonemChipStitch('Haftalık', 'weekly'),
                _kuryeDonemChipStitch('Aylık', 'monthly'),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Seçili dönem: ${donemBasligi(kuryeSeciliDonem)}',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 12),
          _buildKuryeRaporIcerigi(),
        ],
      ),
    );
  }

  // Kurye rapor metrik kartları burada oluşturulur.
  Widget _buildKuryeRaporIcerigi() {
    if (_kuryeRaporYukleniyor && _kuryeRapor == null) {
      return const AppLoadingView(
        kompakt: true,
        mesaj: 'Kurye prim raporu yükleniyor...',
      );
    }
    if (_kuryeRaporHata != null && _kuryeRapor == null) {
      return AppErrorView(
        kompakt: true,
        hataDetayi: _kuryeRaporHata.toString(),
        tekrarDene: _kuryeRaporunuYukle,
      );
    }

    final rapor = _kuryeRapor;
    if (rapor == null) {
      return const AppLoadingView(kompakt: true);
    }

    if (rapor.couriers.isEmpty) {
      return AppEmptyView(
        kompakt: true,
        baslik: '${donemBasligi(kuryeSeciliDonem)} kurye prim verisi yok.',
        aciklama:
            'Teslim edilen paket siparişi olmadığında prim hesaplanmaz.',
      );
    }

    return Column(
      children: [
        if (!rapor.isEnabled)
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: AppInfoCard(
              mesaj: 'Kurye prim sistemi kapalı. Tutarlar 0 gösterilir.',
            ),
          ),
        ...rapor.couriers.map(_buildKuryeRaporKarti),
      ],
    );
  }

  // Kurye rapor kartı — 3 kolonlu metrik grid + vurgulu toplam satırı.
  Widget _buildKuryeRaporKarti(CourierCommissionItemModel k) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.primary.withValues(alpha: 0.12)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _guvenliMetin(k.fullName),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '@${_guvenliMetin(k.username)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              StitchEtiket(
                metin: _tl(k.visibleTotalCommission),
                renk: theme.primary,
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildMetrikIzgarasi([
            (
              etiket: 'Teslim edilen paket',
              deger: k.deliveredOrderCount.toString(),
              vurgu: null,
              vurgulu: false,
              ikon: Icons.local_shipping_outlined,
            ),
            (
              etiket: 'Teslim edilen satış',
              deger: _tl(k.deliveredSales),
              vurgu: null,
              vurgulu: false,
              ikon: Icons.payments_outlined,
            ),
            (
              etiket: 'Satış prim oranı',
              deger: '%${k.courierDefaultRate.toStringAsFixed(1)}',
              vurgu: null,
              vurgulu: false,
              ikon: Icons.trending_up,
            ),
            (
              etiket: 'Satış primi',
              deger: _tl(k.salesCommission),
              vurgu: theme.primary,
              vurgulu: true,
              ikon: Icons.percent,
            ),
            (
              etiket: 'Teslimat primi',
              deger: _tl(k.deliveryBonus),
              vurgu: null,
              vurgulu: false,
              ikon: Icons.delivery_dining_outlined,
            ),
          ], sutunSayisi: 3),
          const SizedBox(height: 8),
          _buildToplamVurguKarti(
            baslik: 'Toplam Kurye Primi',
            deger: _tl(k.visibleTotalCommission),
            ikon: Icons.account_balance_wallet_outlined,
          ),
        ],
      ),
    );
  }
}
