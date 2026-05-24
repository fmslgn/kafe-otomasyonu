// Kullanıcının kendi şifresini değiştirmesi için ortak dialog.
import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/cafe_theme_controller.dart';
import 'app_feedback_widgets.dart';
import 'app_themed_widgets.dart';

/// Garson, yönetici ve kurye panellerinden çağrılır.
Future<void> sifremiDegistirDialogGoster(
  BuildContext context, {
  required int userId,
}) async {
  final mevcutController = TextEditingController();
  final yeniController = TextEditingController();
  final tekrarController = TextEditingController();
  final ekranBaglami = context;
  final tema = CafeThemeController.instance.palette;

  bool mevcutGizli = true;
  bool yeniGizli = true;
  bool tekrarGizli = true;
  bool kaydediliyor = false;

  try {
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Container(
                  decoration: stitchKartDekorasyonu(),
                  padding: const EdgeInsets.all(24),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: tema.softCard,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.lock_reset,
                                color: tema.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Şifremi Değiştir',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: tema.primary,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: kaydediliyor
                                  ? null
                                  : () => Navigator.pop(dialogContext),
                              icon: const Icon(Icons.close),
                              tooltip: 'Kapat',
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Hesabınızın güvenliği için mevcut şifrenizi doğrulayarak yeni şifrenizi belirleyin.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: mevcutController,
                          obscureText: mevcutGizli,
                          decoration: InputDecoration(
                            labelText: 'Mevcut Şifre',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                mevcutGizli
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              tooltip: mevcutGizli
                                  ? 'Şifreyi göster'
                                  : 'Şifreyi gizle',
                              onPressed: () {
                                setDialogState(
                                  () => mevcutGizli = !mevcutGizli,
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: yeniController,
                          obscureText: yeniGizli,
                          decoration: InputDecoration(
                            labelText: 'Yeni Şifre',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.lock_reset),
                            suffixIcon: IconButton(
                              icon: Icon(
                                yeniGizli
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              tooltip:
                                  yeniGizli ? 'Şifreyi göster' : 'Şifreyi gizle',
                              onPressed: () {
                                setDialogState(() => yeniGizli = !yeniGizli);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: tekrarController,
                          obscureText: tekrarGizli,
                          decoration: InputDecoration(
                            labelText: 'Yeni Şifre Tekrar',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.lock_reset),
                            suffixIcon: IconButton(
                              icon: Icon(
                                tekrarGizli
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              tooltip: tekrarGizli
                                  ? 'Şifreyi göster'
                                  : 'Şifreyi gizle',
                              onPressed: () {
                                setDialogState(
                                  () => tekrarGizli = !tekrarGizli,
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Güvenlik bilgi kartı.
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: tema.softCard,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.security,
                                color: tema.primary,
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'Şifrenizi kimseyle paylaşmayın ve kolay tahmin edilebilecek şifreler kullanmayın.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.black87,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final darEkran = constraints.maxWidth < 340;
                            final vazgecBtn = OutlinedButton(
                              onPressed: kaydediliyor
                                  ? null
                                  : () => Navigator.pop(dialogContext),
                              child: const Text('Vazgeç'),
                            );
                            final guncelleBtn = FilledButton.icon(
                              style: themedElevatedButtonStyle(tema),
                              icon: kaydediliyor
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.check),
                              label: Text(
                                kaydediliyor
                                    ? 'Güncelleniyor...'
                                    : 'Şifreyi Güncelle',
                              ),
                              onPressed: kaydediliyor
                                  ? null
                                  : () async {
                                        final mevcut =
                                            mevcutController.text.trim();
                                        final yeni =
                                            yeniController.text.trim();
                                        final tekrar =
                                            tekrarController.text.trim();

                                        // Validasyon bölümü — Türkçe mesajlar korunur.
                                        if (mevcut.isEmpty) {
                                          showAppPopup(
                                            ekranBaglami,
                                            message:
                                                'Mevcut şifre boş bırakılamaz.',
                                            type: AppPopupType.warning,
                                          );
                                          return;
                                        }
                                        if (yeni.isEmpty) {
                                          showAppPopup(
                                            ekranBaglami,
                                            message:
                                                'Yeni şifre boş bırakılamaz.',
                                            type: AppPopupType.warning,
                                          );
                                          return;
                                        }
                                        if (yeni.length < 3) {
                                          showAppPopup(
                                            ekranBaglami,
                                            message:
                                                'Şifre en az 3 karakter olmalıdır.',
                                            type: AppPopupType.warning,
                                          );
                                          return;
                                        }
                                        if (yeni != tekrar) {
                                          showAppPopup(
                                            ekranBaglami,
                                            message:
                                                'Yeni şifre tekrar alanı eşleşmiyor.',
                                            type: AppPopupType.warning,
                                          );
                                          return;
                                        }

                                        setDialogState(
                                          () => kaydediliyor = true,
                                        );

                                        try {
                                          final response =
                                              await ApiService
                                                  .changeOwnPassword(
                                            userId: userId,
                                            currentPassword: mevcut,
                                            newPassword: yeni,
                                          );

                                          if (!ekranBaglami.mounted) return;

                                          showAppPopup(
                                            ekranBaglami,
                                            message: response['message']
                                                    ?.toString() ??
                                                'Şifreniz başarıyla güncellendi.',
                                            type: AppPopupType.success,
                                          );
                                          Navigator.pop(dialogContext);
                                        } catch (error) {
                                          if (!ekranBaglami.mounted) return;

                                          showAppPopup(
                                            ekranBaglami,
                                            message:
                                                ApiService.kullaniciHataMesaji(
                                              error,
                                            ),
                                            type: AppPopupType.error,
                                          );
                                          setDialogState(
                                            () => kaydediliyor = false,
                                          );
                                        }
                                      },
                            );

                            if (darEkran) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  vazgecBtn,
                                  const SizedBox(height: 10),
                                  guncelleBtn,
                                ],
                              );
                            }

                            return Row(
                              children: [
                                Expanded(child: vazgecBtn),
                                const SizedBox(width: 12),
                                Expanded(child: guncelleBtn),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  } finally {
    mevcutController.dispose();
    yeniController.dispose();
    tekrarController.dispose();
  }
}
