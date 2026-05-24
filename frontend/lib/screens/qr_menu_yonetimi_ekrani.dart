// PNG byte verisi için kullanıyoruz.
import 'dart:typed_data';

// Yüksek çözünürlüklü görüntü dönüşümü için kullanıyoruz.
import 'dart:ui' as ui;

// Flutter arayüz bileşenlerini kullanmak için import ediyoruz.
import 'package:flutter/material.dart';

// RepaintBoundary yakalama işlemi için kullanıyoruz.
import 'package:flutter/rendering.dart';

// Panoya kopyalama işlemi için kullanıyoruz.
import 'package:flutter/services.dart';

// QR kod PNG indirme (Flutter Web uyumlu) için kullanıyoruz.
import 'package:file_saver/file_saver.dart';

// QR kod önizlemesi için kullanıyoruz.
import 'package:qr_flutter/qr_flutter.dart';

// Masa modelini kullanıyoruz.
import '../models/masa_model.dart';

// Masaları ve API işlemlerini kullanıyoruz.
import '../services/api_service.dart';
import '../utils/app_theme_helper.dart';
import '../widgets/app_feedback_widgets.dart';
import '../widgets/app_themed_widgets.dart';

// QR menü linki ve QR kod yönetim ekranıdır (sadece yönetici).
class QrMenuYonetimiEkrani extends StatefulWidget {
  const QrMenuYonetimiEkrani({super.key});

  @override
  State<QrMenuYonetimiEkrani> createState() => _QrMenuYonetimiEkraniState();
}

class _QrMenuYonetimiEkraniState extends State<QrMenuYonetimiEkrani>
    with CafeThemeScreenMixin {
  // QR kod alanını PNG olarak yakalamak için kullanılır.
  final GlobalKey qrKey = GlobalKey();

  // Bilgisayar IP adresi giriş alanı.
  final TextEditingController ipController =
      TextEditingController(text: '127.0.0.1');

  // Flutter web port giriş alanı.
  final TextEditingController portController =
      TextEditingController(text: '8080');

  // Menü yolu giriş alanı (hash route).
  final TextEditingController menuYoluController =
      TextEditingController(text: '/#/menu');

  // Masalar backend'den çekilir.
  late Future<List<MasaModel>> masalarFuture;

  // Genel menü QR veya masa bazlı QR seçimi.
  bool genelMenuQr = true;

  // Masa bazlı QR için seçilen masa numarası.
  int? seciliMasaNo;

  // QR kod yenileme anahtarı (aynı linkte bile yeniden çizim için).
  int qrYenilemeAnahtari = 0;

  // PNG indirme işlemi sürerken butonları kilitlemek için kullanılır.
  bool indirmeYapiliyor = false;

  @override
  void initState() {
    super.initState();
    initCafeThemeListener();
    masalarFuture = ApiService.getTables();
  }

  @override
  void dispose() {
    disposeCafeThemeListener();
    ipController.dispose();
    portController.dispose();
    menuYoluController.dispose();
    super.dispose();
  }

  // Girilen bilgilere göre müşteri QR menü linkini üretir.
  String qrMenuLinkiOlustur() {
    final ip = ipController.text.trim();
    final port = portController.text.trim();
    var menuYolu = menuYoluController.text.trim();

    if (ip.isEmpty || port.isEmpty || menuYolu.isEmpty) {
      return '';
    }

    if (!menuYolu.startsWith('/')) {
      menuYolu = '/$menuYolu';
    }

    final masaNo = seciliMasaNo;

    if (!genelMenuQr && masaNo != null) {
      final masaParametresi = 'table=$masaNo';
      menuYolu = menuYolu.contains('?')
          ? '$menuYolu&$masaParametresi'
          : '$menuYolu?$masaParametresi';
    }

    return 'http://$ip:$port$menuYolu';
  }

  // İndirilecek PNG dosya adını üretir.
  String pngDosyaAdiOlustur() {
    if (genelMenuQr) {
      return 'qr_menu_genel';
    }

    final masaNo = seciliMasaNo;
    if (masaNo != null) {
      return 'qr_menu_masa_$masaNo';
    }

    return 'qr_menu_masa';
  }

  // RepaintBoundary üzerinden QR kod PNG byte verisi oluşturur.
  Future<Uint8List?> qrKoduPngOlustur() async {
    final renderObject = qrKey.currentContext?.findRenderObject();

    if (renderObject is! RenderRepaintBoundary) {
      return null;
    }

    final image = await renderObject.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return byteData?.buffer.asUint8List();
  }

  // Linki panoya kopyalar.
  Future<void> linkiKopyala(String link) async {
    if (link.isEmpty) {
      showAppPopup(
        context,
        message: 'Önce geçerli bir link oluşturunuz.',
        type: AppPopupType.warning,
      );
      return;
    }

    await Clipboard.setData(ClipboardData(text: link));

    if (!mounted) return;

    showAppPopup(
      context,
      message: 'QR menü linki kopyalandı.',
      type: AppPopupType.success,
    );
  }

  // QR kodu PNG olarak indirir (Flutter Web uyumlu).
  Future<void> qrKoduIndir() async {
    final link = qrMenuLinkiOlustur();

    if (link.isEmpty) {
      showAppPopup(
        context,
        message: 'Önce QR menü linki oluşturulmalıdır.',
        type: AppPopupType.warning,
      );
      return;
    }

    setState(() {
      indirmeYapiliyor = true;
    });

    try {
      // QR widget'ının ekrana çizilmesi için kısa bekleme.
      await Future<void>.delayed(const Duration(milliseconds: 120));

      final pngBytes = await qrKoduPngOlustur();

      if (pngBytes == null || pngBytes.isEmpty) {
        throw Exception('QR kod görüntüsü oluşturulamadı.');
      }

      final dosyaAdi = pngDosyaAdiOlustur();

      await FileSaver.instance.saveFile(
        name: dosyaAdi,
        bytes: pngBytes,
        ext: 'png',
        mimeType: MimeType.png,
      );

      if (!mounted) return;

      showAppPopup(
        context,
        message: 'QR kod başarıyla indirildi.',
        type: AppPopupType.success,
      );
    } catch (error) {
      if (!mounted) return;

      showAppPopup(
        context,
        message: 'QR kod indirilemedi: $error',
        type: AppPopupType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          indirmeYapiliyor = false;
        });
      }
    }
  }

  void qrKoduYenile() {
    setState(() {
      qrYenilemeAnahtari++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final olusturulanLink = qrMenuLinkiOlustur();
    final linkGecerli = olusturulanLink.isNotEmpty;
    final ekranGenisligi = MediaQuery.of(context).size.width;
    final darEkran = ekranGenisligi < 520;

    return themedRoot(
      Scaffold(
      backgroundColor: AppThemeHelper.sayfaZemin,
      body: SafeArea(
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Sayfa başlığı/header bölümü.
                PanelBaslikAlani(
                  baslik: 'QR Menü Yönetimi',
                  altBaslik:
                      'Müşterilerin telefonla okutarak menüyü görüntüleyebileceği QR kodları buradan oluşturun.',
                  tema: theme,
                  logoUrl: cafeLogoUrl,
                  aksiyonlar: [
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Yenile',
                      onPressed: qrKoduYenile,
                    ),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Geri Dön'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const AppInfoCard(
                  mesaj:
                      'Telefonla test etmek için bilgisayar ve telefon aynı '
                      'Wi-Fi ağına bağlı olmalıdır. Telefonda localhost yerine '
                      'bilgisayarın IP adresi kullanılmalıdır.',
                ),
                const SizedBox(height: 24),
                StitchKart(
                  kenarlikRengi: theme.primary,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      StitchBolumBasligi(
                        baslik: 'QR Menü Bağlantısı',
                        ikon: Icons.link,
                        temaRengi: theme.primary,
                        altBaslik:
                            'IP, port ve menü yolunu girerek paylaşılacak linki oluşturun.',
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: ipController,
                        decoration: stitchInputDekorasyonu(
                          labelText: 'Bilgisayar IP Adresi',
                          hintText: '192.168.1.50',
                          temaRengi: theme.primary,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                        TextField(
                          controller: portController,
                          keyboardType: TextInputType.number,
                          decoration: stitchInputDekorasyonu(
                            labelText: 'Port',
                            hintText: '8080',
                            temaRengi: theme.primary,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: menuYoluController,
                          decoration: stitchInputDekorasyonu(
                            labelText: 'Menü Yolu',
                            hintText: '/#/menu',
                            temaRengi: theme.primary,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 20),
                        StitchBolumBasligi(
                          baslik: 'Masa Bazlı QR Kod',
                          ikon: Icons.table_restaurant,
                          temaRengi: theme.primary,
                        ),
                        const SizedBox(height: 10),
                        SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment<bool>(
                              value: true,
                              label: Text('Genel Menü QR'),
                              icon: Icon(Icons.menu_book),
                            ),
                            ButtonSegment<bool>(
                              value: false,
                              label: Text('Masa Bazlı QR'),
                              icon: Icon(Icons.table_restaurant),
                            ),
                          ],
                          selected: {genelMenuQr},
                          onSelectionChanged: (secim) {
                            setState(() {
                              genelMenuQr = secim.first;
                            });
                          },
                        ),
                        if (!genelMenuQr) ...[
                          const SizedBox(height: 16),
                          FutureBuilder<List<MasaModel>>(
                            future: masalarFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(12),
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }

                              if (snapshot.hasError) {
                                return Text(
                                  'Masalar yüklenemedi: ${snapshot.error}',
                                  style: const TextStyle(color: Colors.red),
                                );
                              }

                              final masalar = snapshot.data ?? [];

                              if (masalar.isEmpty) {
                                return const Text(
                                  'Masa bulunamadı. Önce masa ekleyiniz.',
                                );
                              }

                              final siraliMasalar = [...masalar]
                                ..sort(
                                  (a, b) => a.tableNo.compareTo(b.tableNo),
                                );

                              final gecerliMasaNo =
                                  seciliMasaNo ?? siraliMasalar.first.tableNo;

                              return DropdownButtonFormField<int>(
                                value: gecerliMasaNo,
                                decoration: stitchInputDekorasyonu(
                                  labelText: 'Masa Seçimi',
                                  temaRengi: theme.primary,
                                ),
                                items: siraliMasalar.map((masa) {
                                  return DropdownMenuItem<int>(
                                    value: masa.tableNo,
                                    child: Text(
                                      'Masa ${masa.tableNo} (${masa.section})',
                                    ),
                                  );
                                }).toList(),
                                onChanged: (yeniMasaNo) {
                                  setState(() {
                                    seciliMasaNo = yeniMasaNo;
                                  });
                                },
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
                StitchKart(
                  kenarlikRengi: theme.primary,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      StitchBolumBasligi(
                        baslik: 'Oluşturulan Link',
                        ikon: Icons.content_copy,
                        temaRengi: theme.primary,
                      ),
                        const SizedBox(height: 10),
                        SelectableText(
                          linkGecerli
                              ? olusturulanLink
                              : 'Geçerli IP, port ve menü yolu giriniz.',
                          style: TextStyle(
                            fontSize: 15,
                            color: linkGecerli
                                ? Colors.black87
                                : Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (darEkran) ...[
                          AppTooltip(
                            message: 'QR menü linkini kopyala',
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.copy),
                              label: const Text('Linki Kopyala'),
                              onPressed: linkGecerli && !indirmeYapiliyor
                                  ? () => linkiKopyala(olusturulanLink)
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 10),
                          AppTooltip(
                            message: 'QR kodu PNG olarak indir',
                            child: ElevatedButton.icon(
                            icon: indirmeYapiliyor
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.download),
                            label: Text(
                              indirmeYapiliyor
                                  ? 'İndiriliyor...'
                                  : 'QR Kodu İndir',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.primary,
                              foregroundColor: theme.onPrimary,
                            ),
                            onPressed: linkGecerli && !indirmeYapiliyor
                                ? qrKoduIndir
                                : null,
                          ),
                          ),
                          const SizedBox(height: 10),
                          AppTooltip(
                            message: 'QR kod önizlemesini yenile',
                            child: ElevatedButton.icon(
                            icon: const Icon(Icons.refresh),
                            label: const Text('QR Kodu Yenile'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.lightBackground,
                              foregroundColor: theme.primary,
                            ),
                            onPressed:
                                linkGecerli && !indirmeYapiliyor
                                    ? qrKoduYenile
                                    : null,
                          ),
                          ),
                        ] else
                          Row(
                            children: [
                              Expanded(
                                child: AppTooltip(
                                  message: 'QR menü linkini kopyala',
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.copy),
                                    label: const Text('Linki Kopyala'),
                                    onPressed: linkGecerli && !indirmeYapiliyor
                                        ? () => linkiKopyala(olusturulanLink)
                                        : null,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: AppTooltip(
                                  message: 'QR kodu PNG olarak indir',
                                  child: ElevatedButton.icon(
                                  icon: indirmeYapiliyor
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.download),
                                  label: Text(
                                    indirmeYapiliyor
                                        ? 'İndiriliyor...'
                                        : 'QR Kodu İndir',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.primary,
                                    foregroundColor: theme.onPrimary,
                                  ),
                                  onPressed: linkGecerli && !indirmeYapiliyor
                                      ? qrKoduIndir
                                      : null,
                                ),
                                ),
                              ),
                            ],
                          ),
                        if (!darEkran) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: AppTooltip(
                              message: 'QR kod önizlemesini yenile',
                              child: ElevatedButton.icon(
                              icon: const Icon(Icons.refresh),
                              label: const Text('QR Kodu Yenile'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.lightBackground,
                                foregroundColor: theme.primary,
                              ),
                              onPressed:
                                  linkGecerli && !indirmeYapiliyor
                                      ? qrKoduYenile
                                      : null,
                            ),
                            ),
                          ),
                        ],
                      ],
                    ),
                ),
                const SizedBox(height: 20),
                StitchKart(
                  kenarlikRengi: theme.primary,
                  child: Column(
                    children: [
                      StitchBolumBasligi(
                        baslik: 'QR Kod Önizleme',
                        ikon: Icons.qr_code,
                        temaRengi: theme.primary,
                      ),
                        const SizedBox(height: 20),
                        if (!linkGecerli)
                          const Text(
                            'QR kod için önce geçerli bir link oluşturunuz.',
                            textAlign: TextAlign.center,
                          )
                        else
                          RepaintBoundary(
                            key: qrKey,
                            child: Container(
                              key: ValueKey(qrYenilemeAnahtari),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: theme.primary.withValues(alpha: 0.15),
                                ),
                              ),
                              child: QrImageView(
                                data: olusturulanLink,
                                version: QrVersions.auto,
                                size: 220,
                                backgroundColor: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                ),
                const SizedBox(height: 20),
                StitchKart(
                  kenarlikRengi: theme.primary,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StitchBolumBasligi(
                        baslik: 'Kullanım Bilgilendirmesi',
                        ikon: Icons.info_outline,
                        temaRengi: theme.primary,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        '• QR kodu yazdırıp masalara veya girişe yerleştirebilirsiniz.\n'
                        '• Masa bazlı QR ile müşteri masa numarası otomatik iletilir.\n'
                        '• Linki Kopyala ile bağlantıyı paylaşabilirsiniz.\n'
                        '• QR Kodu İndir ile PNG dosyası alabilirsiniz.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
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
