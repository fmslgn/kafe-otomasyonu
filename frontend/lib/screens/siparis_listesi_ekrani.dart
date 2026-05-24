// Flutter arayüz bileşenlerini kullanmak için import ediyoruz.
import 'package:flutter/material.dart';

// Aktif siparişlerin listeleneceği ekrandır.
class SiparisListesiEkrani extends StatelessWidget {
  // Constructor yapısıdır.
  const SiparisListesiEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    // Sayfanın ana iskeletidir.
    return Scaffold(
      // Üst başlık alanıdır.
      appBar: AppBar(
        // Sayfa başlığıdır.
        title: const Text('Sipariş Listesi'),

        // AppBar arka plan rengidir.
        backgroundColor: Colors.brown.shade100,

        // Başlığı ortalar.
        centerTitle: true,
      ),

      // Sayfa arka plan rengidir.
      backgroundColor: const Color(0xFFF8F1E7),

      // Şimdilik geçici içerik alanıdır.
      body: const Center(
        child: Text(
          'Sipariş listesi burada olacak',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}