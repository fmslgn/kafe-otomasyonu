// Flutter arayüz bileşenlerini kullanmak için import ediyoruz.
import 'package:flutter/material.dart';

// Masa modelini kullanıyoruz.
// Backend'den gelen masa numarası, durum ve bölüm bilgilerini tutar.
import '../models/masa_model.dart';

// Backend API servis dosyasını kullanıyoruz.
// Masa listeleme, ekleme, silme ve bölüm güncelleme işlemleri buradan yapılır.
import '../services/api_service.dart';

import '../widgets/app_feedback_widgets.dart';

// Masa Yönetimi ekranıdır.
// Yönetici bu ekranda masa ekler, siler, bölüm değiştirir ve masaları filtreler.
class MasaYonetimiEkrani extends StatefulWidget {
  // Constructor yapısıdır.
  const MasaYonetimiEkrani({super.key});

  @override
  State<MasaYonetimiEkrani> createState() => _MasaYonetimiEkraniState();
}

// Masa yönetimi ekranındaki değişen verileri yöneten State sınıfıdır.
class _MasaYonetimiEkraniState extends State<MasaYonetimiEkrani> {
  // Backend'den gelecek masa listesini tutar.
  late Future<List<MasaModel>> masalarFuture;

  // Seçili bölüm filtresidir.
  String seciliBolum = 'Tümü';

  @override
  void initState() {
    super.initState();

    // Sayfa açıldığında masalar backend API'den çekilir.
    masalarFuture = ApiService.getTables();
  }

  // Masa listesini yenileyen fonksiyondur.
  void masalariYenile() {
    setState(() {
      masalarFuture = ApiService.getTables();
    });
  }

  // Yeni masa ekleme penceresini açar.
  Future<void> masaEklePenceresiAc() async {
    // Masa numarası input alanını kontrol etmek için controller kullanılır.
    final TextEditingController masaNoController = TextEditingController();

    // Bölüm input alanını kontrol etmek için controller kullanılır.
    final TextEditingController bolumController =
        TextEditingController(text: 'Genel');

    try {
      final sonuc = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            // Dialog başlığıdır.
            title: const Text('Yeni Masa Ekle'),

            // Dialog içeriğidir.
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Masa numarası alanı.
                  TextField(
                    controller: masaNoController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Masa Numarası',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Masa bölümü alanı.
                  TextField(
                    controller: bolumController,
                    decoration: const InputDecoration(
                      labelText: 'Bölüm / Kategori',
                      hintText: 'Genel, Salon, Bahçe, Teras',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),

            // Dialog butonlarıdır.
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
                message: 'Masayı kaydet',
                child: ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Kaydet'),
                onPressed: () async {
                  // Masa numarası alınır.
                  final masaNoText = masaNoController.text.trim();

                  // Bölüm adı alınır.
                  final bolum = bolumController.text.trim();

                  // Masa numarası integer değere çevrilir.
                  final masaNo = int.tryParse(masaNoText);

                  // Masa numarası geçersizse uyarı verilir.
                  if (masaNo == null || masaNo <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Geçerli bir masa numarası giriniz.'),
                      ),
                    );
                    return;
                  }

                  // Bölüm boşsa uyarı verilir.
                  if (bolum.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Bölüm adı boş bırakılamaz.'),
                      ),
                    );
                    return;
                  }

                  try {
                    // Masa backend API'ye gönderilir.
                    final response = await ApiService.addTable(
                      tableNo: masaNo,
                      section: bolum,
                    );

                    // Başarı mesajı gösterilir.
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(response['message']),
                      ),
                    );

                    // Dialog kapatılır.
                    Navigator.pop(context, true);
                  } catch (error) {
                    // Hata mesajı gösterilir.
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(ApiService.kullaniciHataMesaji(error)),
                      ),
                    );
                  }
                },
              ),
              ),
            ],
          );
        },
      );

      // Masa eklendiyse liste yenilenir.
      if (sonuc == true) {
        masalariYenile();
      }
    } finally {
      // Controller nesneleri temizlenir.
      masaNoController.dispose();
      bolumController.dispose();
    }
  }

  // Masa bölümünü değiştiren pencereyi açar.
  Future<void> masaBolumuDegistirPenceresiAc(MasaModel masa) async {
    // Mevcut bölüm varsayılan olarak gelir.
    final TextEditingController bolumController =
        TextEditingController(text: masa.section);

    try {
      final sonuc = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            // Dialog başlığıdır.
            title: Text('Masa ${masa.tableNo} Bölümünü Değiştir'),

            // Dialog içeriğidir.
            content: SizedBox(
              width: 400,
              child: TextField(
                controller: bolumController,
                decoration: const InputDecoration(
                  labelText: 'Yeni Bölüm / Kategori',
                  hintText: 'Genel, Salon, Bahçe, Teras',
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
                  Navigator.pop(context, false);
                },
                child: const Text('Vazgeç'),
              ),
              ),

              AppTooltip(
                message: 'Masa bölümünü kaydet',
                child: ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Kaydet'),
                onPressed: () async {
                  // Yeni bölüm adı alınır.
                  final yeniBolum = bolumController.text.trim();

                  // Bölüm boşsa uyarı verilir.
                  if (yeniBolum.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Bölüm adı boş bırakılamaz.'),
                      ),
                    );
                    return;
                  }

                  try {
                    // Masa bölümü backend API üzerinden güncellenir.
                    final response = await ApiService.updateTableSection(
                      tableId: masa.id,
                      section: yeniBolum,
                    );

                    // Başarı mesajı gösterilir.
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(response['message']),
                      ),
                    );

                    // Dialog kapatılır.
                    Navigator.pop(context, true);
                  } catch (error) {
                    // Hata mesajı gösterilir.
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(ApiService.kullaniciHataMesaji(error)),
                      ),
                    );
                  }
                },
              ),
              ),
            ],
          );
        },
      );

      // Bölüm değiştiyse liste yenilenir.
      if (sonuc == true) {
        masalariYenile();
      }
    } finally {
      // Controller temizlenir.
      bolumController.dispose();
    }
  }

  // Masa silme onay penceresini açar.
  Future<void> masaSilmeOnayiAc(MasaModel masa) async {
    // Dolu masa silinmesin diye kullanıcıya uyarı verilir.
    if (masa.status == 'dolu') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dolu masa silinemez. Önce hesabı kapatmalısınız.'),
        ),
      );
      return;
    }

    final sonuc = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          // Dialog başlığıdır.
          title: const Text('Masa Sil'),

          // Dialog açıklamasıdır.
          content: Text(
            'Masa ${masa.tableNo} silinsin mi?\n'
            'Bu işlem geri alınamaz.',
          ),

          // Dialog butonlarıdır.
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
              message: 'Masayı sil',
              child: ElevatedButton.icon(
              icon: const Icon(Icons.delete),
              label: const Text('Sil'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade100,
                foregroundColor: Colors.red,
              ),
              onPressed: () {
                Navigator.pop(context, true);
              },
            ),
            ),
          ],
        );
      },
    );

    // Kullanıcı silmeyi onaylamadıysa işlem yapılmaz.
    if (sonuc != true) return;

    try {
      // Masa backend API üzerinden silinir.
      final response = await ApiService.deleteTable(
        tableId: masa.id,
      );

      // Başarı mesajı gösterilir.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message']),
        ),
      );

      // Liste yenilenir.
      masalariYenile();
    } catch (error) {
      // Hata mesajı gösterilir.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ApiService.kullaniciHataMesaji(error)),
        ),
      );
    }
  }

  // Masa durumunu ekranda düzgün göstermek için kullanılır.
  String durumYazisi(String status) {
    if (status == 'dolu') {
      return 'Dolu';
    }

    return 'Boş';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Üst başlık alanıdır.
      appBar: AppBar(
        title: const Text('Masa Yönetimi'),
        backgroundColor: Colors.brown.shade100,
        centerTitle: true,

        // Sağ üstte yenileme butonu bulunur.
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Masaları Yenile',
            onPressed: masalariYenile,
          ),
        ],
      ),

      // Sayfa arka plan rengidir.
      backgroundColor: const Color(0xFFF8F1E7),

      // Sağ alttaki masa ekleme butonudur.
      floatingActionButton: FloatingActionButton.extended(
        tooltip: 'Yeni masa ekle',
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Masa Ekle'),
        onPressed: masaEklePenceresiAc,
      ),

      // Masa listesini backend'den bekleyen yapı.
      body: FutureBuilder<List<MasaModel>>(
        future: masalarFuture,
        builder: (context, snapshot) {
          // Veri yüklenirken loading gösterilir.
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingView(mesaj: 'Masalar yükleniyor...');
          }

          if (snapshot.hasError) {
            return AppErrorView(
              hataDetayi: snapshot.error.toString(),
              tekrarDene: masalariYenile,
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return AppEmptyView(
              ikon: Icons.table_restaurant_outlined,
              baslik: 'Masa kaydı bulunmuyor.',
              aciklama: 'Yeni masa eklemek için sağ alttaki butonu kullanın.',
              aksiyonMetni: 'Masa Ekle',
              aksiyon: masaEklePenceresiAc,
            );
          }

          // Backend'den gelen masa listesi alınır.
          final masalar = snapshot.data!;

          // Bölüm adları çıkarılır.
          final bolumler = <String>{
            'Tümü',
            ...masalar.map((masa) => masa.section),
          }.toList();

          // Seçili bölüm artık yoksa tekrar tümü yapılır.
          if (!bolumler.contains(seciliBolum)) {
            seciliBolum = 'Tümü';
          }

          // Filtrelenmiş masa listesi hazırlanır.
          final filtrelenmisMasalar = seciliBolum == 'Tümü'
              ? masalar
              : masalar
                  .where((masa) => masa.section == seciliBolum)
                  .toList();

          // Masalar bölümlere göre gruplanır.
          final Map<String, List<MasaModel>> bolumlereGoreMasalar = {};

          for (final masa in filtrelenmisMasalar) {
            bolumlereGoreMasalar.putIfAbsent(masa.section, () => []);
            bolumlereGoreMasalar[masa.section]!.add(masa);
          }

          final bolumAdlari = bolumlereGoreMasalar.keys.toList();

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Bölüm filtreleri.
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: bolumler.map((bolum) {
                      final seciliMi = seciliBolum == bolum;

                      final tooltipMesaj = bolum == 'Tümü'
                          ? 'Tüm bölümlerdeki masaları göster'
                          : '$bolum bölümündeki masaları göster';

                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: AppTooltip(
                          message: tooltipMesaj,
                          child: ChoiceChip(
                            label: Text(bolum),
                            selected: seciliMi,
                            selectedColor: Colors.brown.shade200,
                            labelStyle: TextStyle(
                              color: seciliMi ? Colors.white : Colors.brown,
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (_) {
                              setState(() {
                                seciliBolum = bolum;
                              });
                            },
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 20),

                // Masa liste alanı.
                Expanded(
                  child: ListView.builder(
                    itemCount: bolumAdlari.length,
                    itemBuilder: (context, bolumIndex) {
                      // Mevcut bölüm adı alınır.
                      final bolumAdi = bolumAdlari[bolumIndex];

                      // Bölüme ait masalar alınır.
                      final bolumMasalari = bolumlereGoreMasalar[bolumAdi]!;

                      // Masa numarasına göre sıralama yapılır.
                      bolumMasalari.sort(
                        (a, b) => a.tableNo.compareTo(b.tableNo),
                      );

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Bölüm başlığı.
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 10,
                              bottom: 12,
                            ),
                            child: Text(
                              bolumAdi,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.brown,
                              ),
                            ),
                          ),

                          // Masalar grid şeklinde gösterilir.
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: bolumMasalari.length,
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 320,
                              mainAxisExtent: 190,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemBuilder: (context, index) {
                              final masa = bolumMasalari[index];
                              final doluMu = masa.status == 'dolu';

                              return Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: doluMu
                                      ? Colors.red.shade50
                                      : Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: doluMu ? Colors.red : Colors.green,
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.06),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Masa ikon ve başlık alanı.
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.table_restaurant,
                                          color: doluMu
                                              ? Colors.red
                                              : Colors.green,
                                          size: 36,
                                        ),

                                        const SizedBox(width: 10),

                                        Expanded(
                                          child: Text(
                                            'Masa ${masa.tableNo}',
                                            style: const TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 10),

                                    // Masa durum bilgileri.
                                    Text(
                                      'Durum: ${durumYazisi(masa.status)}\n'
                                      'Bölüm: ${masa.section}',
                                      style: const TextStyle(
                                        fontSize: 15,
                                      ),
                                    ),

                                    const Spacer(),

                                    // İşlem butonları.
                                    Row(
                                      children: [
                                        // Bölüm değiştir butonu.
                                        Expanded(
                                          child: AppTooltip(
                                            message: 'Masa bölümünü düzenle',
                                            child: OutlinedButton.icon(
                                              icon: const Icon(Icons.edit),
                                              label: const Text('Bölüm'),
                                              onPressed: () {
                                                masaBolumuDegistirPenceresiAc(
                                                  masa,
                                                );
                                              },
                                            ),
                                          ),
                                        ),

                                        const SizedBox(width: 8),

                                        // Sil butonu.
                                        Expanded(
                                          child: AppTooltip(
                                            message: 'Masayı sil',
                                            child: ElevatedButton.icon(
                                            icon: const Icon(Icons.delete),
                                            label: const Text('Sil'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.red.shade100,
                                              foregroundColor: Colors.red,
                                            ),
                                            onPressed: doluMu
                                                ? null
                                                : () {
                                                    masaSilmeOnayiAc(masa);
                                                  },
                                          ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 24),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}