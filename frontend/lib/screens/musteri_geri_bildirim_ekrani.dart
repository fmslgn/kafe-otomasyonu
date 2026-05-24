// Yönetici müşteri geri bildirimleri ekranıdır (QR menü mesajları).
import 'package:flutter/material.dart';

import '../models/customer_feedback_model.dart';
import '../services/api_service.dart';
import '../utils/app_theme_helper.dart';
import '../widgets/app_feedback_widgets.dart';
import '../widgets/app_themed_widgets.dart';

class MusteriGeriBildirimEkrani extends StatefulWidget {
  const MusteriGeriBildirimEkrani({super.key});

  @override
  State<MusteriGeriBildirimEkrani> createState() =>
      _MusteriGeriBildirimEkraniState();
}

class _MusteriGeriBildirimEkraniState extends State<MusteriGeriBildirimEkrani>
    with CafeThemeScreenMixin {
  late Future<List<CustomerFeedbackModel>> geriBildirimFuture;
  String seciliDurum = 'all';
  String seciliTur = 'all';
  final TextEditingController aramaController = TextEditingController();
  String aramaMetni = '';

  @override
  void initState() {
    super.initState();
    initCafeThemeListener();
    verileriYukle();
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

  void verileriYukle() {
    geriBildirimFuture = ApiService.getCustomerFeedback(
      status: seciliDurum,
      type: seciliTur,
    );
  }

  void ekraniYenile() => setState(verileriYukle);

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

  List<CustomerFeedbackModel> _aramaIleFiltrele(
    List<CustomerFeedbackModel> liste,
  ) {
    if (aramaMetni.isEmpty) return liste;
    final q = aramaMetni.toLowerCase();
    return liste.where((k) {
      return (k.customerName ?? '').toLowerCase().contains(q) ||
          (k.customerPhone ?? '').toLowerCase().contains(q) ||
          k.message.toLowerCase().contains(q) ||
          (k.tableNumber?.toString() ?? '').contains(q);
    }).toList();
  }

  String turYazisi(String tur) {
    switch (tur) {
      case 'sikayet':
        return 'Şikayet';
      case 'oneri':
        return 'Öneri';
      default:
        return 'İstek';
    }
  }

  String durumYazisi(String durum) {
    switch (durum) {
      case 'incelendi':
        return 'İncelendi';
      case 'tamamlandi':
        return 'Tamamlandı';
      case 'reddedildi':
        return 'Reddedildi';
      default:
        return 'Bekliyor';
    }
  }

  Color turRengi(String tur) {
    switch (tur) {
      case 'sikayet':
        return Colors.red.shade700;
      case 'oneri':
        return Colors.green.shade700;
      default:
        return Colors.brown;
    }
  }

  Color durumRengi(String durum) {
    switch (durum) {
      case 'incelendi':
        return Colors.orange.shade800;
      case 'tamamlandi':
        return Colors.green.shade700;
      case 'reddedildi':
        return Colors.red.shade800;
      default:
        return Colors.blue.shade700;
    }
  }

  String tarihFormatla(String tarih) {
    try {
      final dt = DateTime.parse(tarih).toLocal();
      final gun = dt.day.toString().padLeft(2, '0');
      final ay = dt.month.toString().padLeft(2, '0');
      final yil = dt.year;
      final saat = dt.hour.toString().padLeft(2, '0');
      final dakika = dt.minute.toString().padLeft(2, '0');
      return '$gun.$ay.$yil $saat:$dakika';
    } catch (_) {
      return tarih;
    }
  }

  Widget _durumFiltreChip(String baslik, String deger) {
    final secili = seciliDurum == deger;
    return StitchFiltreChip(
      etiket: baslik,
      secili: secili,
      temaRengi: theme.primary,
      onTap: () {
        setState(() {
          seciliDurum = deger;
          verileriYukle();
        });
      },
    );
  }

  Widget _turFiltreChip(String baslik, String deger) {
    final secili = seciliTur == deger;
    return StitchFiltreChip(
      etiket: baslik,
      secili: secili,
      temaRengi: theme.primary,
      onTap: () {
        setState(() {
          seciliTur = deger;
          verileriYukle();
        });
      },
    );
  }

  Future<void> durumGuncellePenceresiAc(CustomerFeedbackModel kayit) async {
    String seciliStatus = kayit.status;
    final notController = TextEditingController(text: kayit.managerNote ?? '');
    final ekranBaglami = context;
    bool kaydediliyor = false;

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return Dialog(
                backgroundColor: Colors.transparent,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: StitchKart(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Durum güncelleme dialog bölümü.
                        StitchBolumBasligi(
                          baslik: 'Durum Güncelle',
                          ikon: Icons.edit_note,
                          temaRengi: theme.primary,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: seciliStatus,
                          decoration: stitchInputDekorasyonu(
                            labelText: 'Durum',
                            temaRengi: theme.primary,
                          ),
                        items: const [
                          DropdownMenuItem(
                            value: 'bekliyor',
                            child: Text('Bekliyor'),
                          ),
                          DropdownMenuItem(
                            value: 'incelendi',
                            child: Text('İncelendi'),
                          ),
                          DropdownMenuItem(
                            value: 'tamamlandi',
                            child: Text('Tamamlandı'),
                          ),
                          DropdownMenuItem(
                            value: 'reddedildi',
                            child: Text('Reddedildi'),
                          ),
                        ],
                        onChanged: (v) {
                          if (v != null) {
                            setDialogState(() => seciliStatus = v);
                          }
                        },
                      ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: notController,
                          maxLines: 3,
                          decoration: stitchInputDekorasyonu(
                            labelText: 'Yönetici Notu (opsiyonel)',
                            temaRengi: theme.primary,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: kaydediliyor
                                    ? null
                                    : () => Navigator.pop(dialogContext),
                                child: const Text('Vazgeç'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton.icon(
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
                                    : const Icon(Icons.save),
                                label: Text(
                                  kaydediliyor ? 'Kaydediliyor...' : 'Kaydet',
                                ),
                                onPressed: kaydediliyor
                                    ? null
                                    : () async {
                            setDialogState(() => kaydediliyor = true);
                            try {
                              final response =
                                  await ApiService.updateCustomerFeedback(
                                id: kayit.id,
                                status: seciliStatus,
                                managerNote: notController.text.trim(),
                              );

                              if (!ekranBaglami.mounted) return;

                              showAppPopup(
                                ekranBaglami,
                                message: response['message']?.toString() ??
                                    'Geri bildirim güncellendi.',
                                type: AppPopupType.success,
                              );
                              Navigator.pop(dialogContext);
                              ekraniYenile();
                            } catch (error) {
                              if (!ekranBaglami.mounted) return;

                              showAppPopup(
                                ekranBaglami,
                                message: ApiService.kullaniciHataMesaji(error),
                                type: AppPopupType.error,
                              );
                              setDialogState(() => kaydediliyor = false);
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
              );
            },
          );
        },
      );
    } finally {
      notController.dispose();
    }
  }

  Future<void> mesajSilOnayi(CustomerFeedbackModel kayit) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mesajı Sil'),
        content: const Text(
          'Bu geri bildirimi silmek istediğinize emin misiniz?',
        ),
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
      final response = await ApiService.deleteCustomerFeedback(id: kayit.id);
      if (!mounted) return;

      showAppPopup(
        context,
        message: response['message']?.toString() ?? 'Geri bildirim silindi.',
        type: AppPopupType.success,
      );
      ekraniYenile();
    } catch (error) {
      if (!mounted) return;

      showAppPopup(
        context,
        message: ApiService.kullaniciHataMesaji(error),
        type: AppPopupType.error,
      );
    }
  }

  // Geri bildirim kartları bölümü.
  Widget _geriBildirimKarti(CustomerFeedbackModel kayit) {
    return StitchKart(
      margin: const EdgeInsets.only(bottom: 12),
      kenarlikRengi: theme.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StitchEtiket(
                metin: turYazisi(kayit.feedbackType),
                renk: turRengi(kayit.feedbackType),
              ),
              StitchEtiket(
                metin: durumYazisi(kayit.status),
                renk: durumRengi(kayit.status),
              ),
            ],
          ),
            const SizedBox(height: 10),
            if (kayit.customerName != null && kayit.customerName!.isNotEmpty)
              Text('Müşteri: ${kayit.customerName}'),
            if (kayit.customerPhone != null && kayit.customerPhone!.isNotEmpty)
              Text('Telefon: ${kayit.customerPhone}'),
            if (kayit.tableNumber != null)
              Text('Masa: ${kayit.tableNumber}'),
            const SizedBox(height: 8),
            Text(
              kayit.message,
              style: const TextStyle(fontSize: 15, height: 1.4),
            ),
            if (kayit.managerNote != null && kayit.managerNote!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Yönetici notu: ${kayit.managerNote}',
                style: TextStyle(
                  fontSize: 14,
                  color: theme.primary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              'Tarih: ${tarihFormatla(kayit.createdAt)}',
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                AppTooltip(
                  message: 'Durum güncelle',
                  child: FilledButton.icon(
                    style: themedElevatedButtonStyle(theme),
                    icon: const Icon(Icons.edit_note),
                    label: const Text('Durum Değiştir'),
                    onPressed: () => durumGuncellePenceresiAc(kayit),
                  ),
                ),
                const SizedBox(width: 8),
                AppTooltip(
                  message: 'Yönetici notu ekle veya güncelle',
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.note_add_outlined),
                    label: const Text('Not Ekle'),
                    onPressed: () => durumGuncellePenceresiAc(kayit),
                  ),
                ),
                const SizedBox(width: 8),
                AppTooltip(
                  message: 'Mesaj sil',
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Sil'),
                    onPressed: () => mesajSilOnayi(kayit),
                  ),
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
          child: FutureBuilder<List<CustomerFeedbackModel>>(
            future: geriBildirimFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const AppLoadingView(
                  mesaj: 'Geri bildirimler yükleniyor...',
                );
              }

              if (snapshot.hasError) {
                return AppErrorView(
                  hataDetayi: snapshot.error.toString(),
                  tekrarDene: ekraniYenile,
                );
              }

              final liste = snapshot.data ?? [];
              final gorunenListe = _aramaIleFiltrele(liste);
              final bekleyen =
                  liste.where((k) => k.status == 'bekliyor').length;
              final sikayet =
                  liste.where((k) => k.feedbackType == 'sikayet').length;
              final tamamlanan =
                  liste.where((k) => k.status == 'tamamlandi').length;

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
                          baslik: 'Müşteri Geri Bildirimleri',
                          altBaslik:
                              'QR menüden gelen istek, şikayet ve önerileri buradan görüntüleyin ve yönetin.',
                          tema: theme,
                          logoUrl: cafeLogoUrl,
                          aksiyonlar: _ustAksiyonlar(context),
                        ),
                        const SizedBox(height: 20),
                        OzetKartSatiri(
                          kartlar: [
                            OzetKart(
                              baslik: 'Toplam Mesaj',
                              deger: '${liste.length}',
                              ikon: Icons.mail_outline,
                              tema: theme,
                            ),
                            OzetKart(
                              baslik: 'Bekleyen Mesaj',
                              deger: '$bekleyen',
                              ikon: Icons.hourglass_empty,
                              tema: theme,
                            ),
                            OzetKart(
                              baslik: 'Şikayetler',
                              deger: '$sikayet',
                              ikon: Icons.report_outlined,
                              tema: theme,
                            ),
                            OzetKart(
                              baslik: 'Tamamlananlar',
                              deger: '$tamamlanan',
                              ikon: Icons.task_alt,
                              tema: theme,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        StitchKart(
                          kenarlikRengi: theme.primary,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextField(
                                controller: aramaController,
                                decoration: stitchInputDekorasyonu(
                                  hintText:
                                      'Müşteri adı, telefon, masa veya mesaj ara...',
                                  prefixIcon: Icons.search,
                                  temaRengi: theme.primary,
                                  suffixIcon: aramaMetni.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear),
                                          onPressed: () =>
                                              aramaController.clear(),
                                        )
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 14),
                              // Filtre chipleri bölümü.
                              const Text(
                                'Durum',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _durumFiltreChip('Tümü', 'all'),
                                    const SizedBox(width: 8),
                                    _durumFiltreChip('Bekleyen', 'bekliyor'),
                                    const SizedBox(width: 8),
                                    _durumFiltreChip('İncelenen', 'incelendi'),
                                    const SizedBox(width: 8),
                                    _durumFiltreChip(
                                      'Tamamlanan',
                                      'tamamlandi',
                                    ),
                                    const SizedBox(width: 8),
                                    _durumFiltreChip(
                                      'Reddedilen',
                                      'reddedildi',
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                'Tür',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _turFiltreChip('Tümü', 'all'),
                                    const SizedBox(width: 8),
                                    _turFiltreChip('İstek', 'istek'),
                                    const SizedBox(width: 8),
                                    _turFiltreChip('Şikayet', 'sikayet'),
                                    const SizedBox(width: 8),
                                    _turFiltreChip('Öneri', 'oneri'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (liste.isEmpty)
                          AppEmptyView(
                            ikon: Icons.feedback_outlined,
                            baslik: seciliDurum != 'all' || seciliTur != 'all'
                                ? 'Bu filtreye uygun mesaj bulunmuyor.'
                                : 'Geri bildirim bulunmuyor.',
                            aciklama: 'QR menüden gelen mesajlar burada listelenir.',
                          )
                        else if (gorunenListe.isEmpty)
                          const AppEmptyView(
                            baslik: 'Arama sonucu bulunamadı.',
                            aciklama:
                                'Farklı bir arama terimi veya filtre deneyin.',
                          )
                        else
                          ...gorunenListe.map(_geriBildirimKarti),
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
