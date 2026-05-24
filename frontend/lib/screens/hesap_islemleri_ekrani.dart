// Flutter arayüz bileşenlerini kullanmak için import ediyoruz.
import 'package:flutter/material.dart';

// Aktif sipariş modelini kullanıyoruz.
import '../models/aktif_siparis_model.dart';

// Backend API servis dosyasını kullanıyoruz.
import '../services/api_service.dart';

import '../widgets/app_feedback_widgets.dart';

// Hesap işlemleri ekranıdır.
// Açık hesapları listeler ve hesabı kapatma işlemini yapar.
class HesapIslemleriEkrani extends StatefulWidget {
  // Constructor yapısıdır.
  const HesapIslemleriEkrani({super.key});

  @override
  State<HesapIslemleriEkrani> createState() =>
      _HesapIslemleriEkraniState();
}

// Hesap işlemleri ekranındaki değişen verileri yöneten State sınıfıdır.
class _HesapIslemleriEkraniState extends State<HesapIslemleriEkrani> {
  // Backend'den gelecek aktif sipariş listesini tutar.
  late Future<List<AktifSiparisModel>> aktifSiparislerFuture;

  @override
  void initState() {
    super.initState();

    // Sayfa açıldığında aktif siparişler backend API'den çekilir.
    aktifSiparislerFuture = ApiService.getActiveOrders();
  }

  // Aktif siparişleri yeniden yükleyen fonksiyondur.
  void siparisleriYenile() {
    setState(() {
      aktifSiparislerFuture = ApiService.getActiveOrders();
    });
  }

  // Hesabı kapatma işlemini yapan fonksiyondur.
  Future<void> hesabiKapat(AktifSiparisModel siparis) async {
    // Kullanıcıdan onay almak için dialog açılır.
    final onay = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          // Dialog başlığıdır.
          title: const Text('Hesabı Kapat'),

          // Dialog açıklama metnidir.
          content: Text(
            'Masa ${siparis.tableNo} hesabı kapatılsın mı?\n'
            'Toplam: ${siparis.totalPrice.toStringAsFixed(2)} TL',
          ),

          // Dialog altındaki butonlardır.
          actions: [
            // Vazgeç butonu.
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Vazgeç'),
            ),

            // Hesabı kapatma onay butonu.
            ElevatedButton.icon(
              icon: const Icon(Icons.check),
              label: const Text('Hesabı Kapat'),
              onPressed: () {
                Navigator.pop(context, true);
              },
            ),
          ],
        );
      },
    );

    // Kullanıcı onay vermediyse işlem yapılmaz.
    if (onay != true) return;

    try {
      // Backend API üzerinden hesap kapatılır.
      final response = await ApiService.closeOrder(siparis.id);

      // İşlem başarılıysa kullanıcıya mesaj gösterilir.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message']),
        ),
      );

      // Hesap kapandıktan sonra aktif sipariş listesi yenilenir.
      siparisleriYenile();
    } catch (error) {
      // Hata olursa kullanıcıya hata mesajı gösterilir.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ApiService.kullaniciHataMesaji(error)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Üst başlık alanıdır.
      appBar: AppBar(
        title: const Text('Hesap İşlemleri'),
        backgroundColor: Colors.brown.shade100,
        centerTitle: true,

        // Sağ üstte yenileme butonu bulunur.
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Yenile',
            onPressed: siparisleriYenile,
          ),
        ],
      ),

      // Sayfanın arka plan rengidir.
      backgroundColor: const Color(0xFFF8F1E7),

      // FutureBuilder, backend'den gelen aktif siparişleri bekler.
      body: FutureBuilder<List<AktifSiparisModel>>(
        future: aktifSiparislerFuture,
        builder: (context, snapshot) {
          // Veri yüklenirken loading gösterilir.
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingView(
              mesaj: 'Açık hesaplar yükleniyor...',
            );
          }

          if (snapshot.hasError) {
            return AppErrorView(
              hataDetayi: snapshot.error.toString(),
              tekrarDene: siparisleriYenile,
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const AppEmptyView(
              ikon: Icons.receipt_long_outlined,
              baslik: 'Açık hesap bulunmuyor.',
              aciklama:
                  'Tüm masaların hesabı kapalıdır veya aktif sipariş yoktur.',
            );
          }

          // Backend'den gelen aktif sipariş listesi alınır.
          final aktifSiparisler = snapshot.data!;

          // Aktif hesaplar liste halinde gösterilir.
          return Padding(
            padding: const EdgeInsets.all(24),
            child: ListView.builder(
              itemCount: aktifSiparisler.length,
              itemBuilder: (context, index) {
                // Mevcut aktif sipariş alınır.
                final siparis = aktifSiparisler[index];

                // Her aktif sipariş için kart oluşturulur.
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),

                  // Kart içeriğidir.
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: ListTile(
                      // Sol taraftaki ikon.
                      leading: const Icon(
                        Icons.receipt_long,
                        color: Colors.brown,
                        size: 42,
                      ),

                      // Kart başlığıdır.
                      title: Text(
                        'Masa ${siparis.tableNo}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      // Kart alt bilgileri.
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Ürün adeti: ${siparis.itemCount}\n'
                          'Durum: ${siparis.status}\n'
                          'Toplam: ${siparis.totalPrice.toStringAsFixed(2)} TL',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),

                      // Sağ taraftaki hesabı kapat butonu.
                      trailing: AppTooltip(
                        message: 'Masa hesabını kapat',
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.payments),
                          label: const Text('Hesabı Kapat'),
                          onPressed: () {
                            hesabiKapat(siparis);
                          },
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}