// Garson ve kurye panellerinde tekrar kullanılan işlem kartı.
import 'package:flutter/material.dart';

import 'app_themed_widgets.dart';

class GarsonIslemKarti extends StatelessWidget {
  final IconData icon;
  final String baslik;
  final String aciklama;
  final VoidCallback onTap;
  final String? aksiyonMetni;

  const GarsonIslemKarti({
    super.key,
    required this.icon,
    required this.baslik,
    required this.aciklama,
    required this.onTap,
    this.aksiyonMetni,
  });

  @override
  Widget build(BuildContext context) {
    return ModernIslemKarti(
      ikon: icon,
      baslik: baslik,
      aciklama: aciklama,
      onTap: onTap,
      aksiyonMetni: aksiyonMetni,
    );
  }
}
