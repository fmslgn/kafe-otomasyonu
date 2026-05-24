import 'package:flutter_test/flutter_test.dart';
import 'package:kafe_otomasyonu/main.dart';

void main() {
  testWidgets('Uygulama giriş ekranı ile açılır', (WidgetTester tester) async {
    await tester.pumpWidget(
      const KafeOtomasyonuApp(baslangicRotasi: '/'),
    );

    expect(find.text('Kafe Otomasyonu'), findsOneWidget);
    expect(find.text('Giriş türünüzü seçerek devam edin.'), findsOneWidget);
  });
}
