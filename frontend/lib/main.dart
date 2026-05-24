// Flutter'ın Material Design bileşenlerini kullanmamızı sağlar.
import 'package:flutter/material.dart';

// Giriş ekranını ana dosyaya dahil ediyoruz.
import 'screens/giris_ekrani.dart';

// Müşteri QR menü ekranını dahil ediyoruz.
import 'screens/qr_menu_ekrani.dart';

// Flutter uygulamasının başlangıç noktasıdır.
void main() {
  runApp(KafeOtomasyonuApp(baslangicRotasi: baslangicRotasiniBelirle()));
}

// Route adından yalnızca path kısmını alır (?table=4 gibi sorguları ayırır).
String _rotaYolunuTemizle(String? rotaAdi) {
  if (rotaAdi == null || rotaAdi.trim().isEmpty) {
    return '/';
  }

  final ham = rotaAdi.trim();
  final path = Uri.parse(ham.startsWith('/') ? ham : '/$ham').path;

  if (path.isEmpty) {
    return '/';
  }

  return path;
}

// Verilen path QR menü rotası mı kontrol eder.
bool _menuRotasiMi(String path) {
  return path == '/menu' || path == '/qr-menu';
}

// Web ve mobilde URL'den başlangıç rotasını belirler.
// Örnek: http://127.0.0.1:8080/#/menu?table=4
String baslangicRotasiniBelirle() {
  final uri = Uri.base;

  // Path tabanlı: /menu veya .../menu
  if (uri.path.endsWith('/menu') || uri.path == '/menu') {
    return '/menu';
  }

  if (uri.path.endsWith('/qr-menu') || uri.path == '/qr-menu') {
    return '/menu';
  }

  final fragment = uri.fragment;
  if (fragment.isNotEmpty) {
    // Fragment: /menu?table=4 veya menu?table=4
    final fragmentPath = _rotaYolunuTemizle(fragment);
    if (_menuRotasiMi(fragmentPath)) {
      return '/menu';
    }
  }

  return '/';
}

// Uygulamanın ana sınıfıdır.
class KafeOtomasyonuApp extends StatelessWidget {
  const KafeOtomasyonuApp({
    super.key,
    required this.baslangicRotasi,
  });

  // Uygulama açılışında hangi ekranın gösterileceğini belirler.
  final String baslangicRotasi;

  // Tanımlı olmayan rotalar için yönlendirme (ör. /menu?table=4).
  Route<dynamic> _rotaOlustur(RouteSettings settings) {
    final path = _rotaYolunuTemizle(settings.name);

    if (_menuRotasiMi(path)) {
      return MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/menu'),
        builder: (context) => const QrMenuEkrani(),
      );
    }

    return MaterialPageRoute<void>(
      settings: const RouteSettings(name: '/'),
      builder: (context) => const GirisEkrani(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kafe Otomasyonu',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.brown,
        tooltipTheme: const TooltipThemeData(
          waitDuration: Duration(milliseconds: 350),
          showDuration: Duration(seconds: 3),
          decoration: BoxDecoration(
            color: Color(0xFF4E342E),
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          textStyle: TextStyle(
            color: Colors.white,
            fontSize: 13,
            height: 1.3,
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF5D4037),
          contentTextStyle: const TextStyle(color: Colors.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      initialRoute: baslangicRotasi,
      routes: {
        '/': (context) => const GirisEkrani(),
        '/menu': (context) => const QrMenuEkrani(),
        // Eski/alternatif QR menü linkleri de aynı ekrana gider.
        '/qr-menu': (context) => const QrMenuEkrani(),
      },
      // Hash route'ta /menu?table=4 gibi sorgulu path'ler routes tablosuna düşmez.
      onGenerateRoute: _rotaOlustur,
    );
  }
}
