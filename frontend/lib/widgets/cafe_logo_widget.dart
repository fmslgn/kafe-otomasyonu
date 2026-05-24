// Kafe logosu veya varsayılan ikon gösterimi.
import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../utils/app_theme_helper.dart';

/// [logoUrl] doluysa ağ üzerinden logo; değilse kahve ikonu gösterilir.
class CafeLogoWidget extends StatelessWidget {
  const CafeLogoWidget({
    super.key,
    this.logoUrl,
    this.size = 72,
    this.iconColor,
    this.backgroundColor,
    this.yuvarlak = true,
  });

  final String? logoUrl;
  final double size;
  final Color? iconColor;
  final Color? backgroundColor;
  final bool yuvarlak;

  @override
  Widget build(BuildContext context) {
    final renk = iconColor ?? const Color(0xFF795548);
    final arkaPlan = backgroundColor ?? AppThemeHelper.getSoftCardColor(renk);
    final tamUrl = ApiService.getCafeLogoUrl(logoUrl);
    final kenar = yuvarlak
        ? BorderRadius.circular(size / 2)
        : BorderRadius.circular(14);

    Widget icerik;
    if (tamUrl.isNotEmpty) {
      icerik = ClipRRect(
        borderRadius: kenar,
        child: Image.network(
          tamUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _varsayilanIkon(renk, size * 0.55),
        ),
      );
    } else {
      icerik = _varsayilanIkon(renk, size * 0.55);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: arkaPlan,
        borderRadius: kenar,
      ),
      alignment: Alignment.center,
      child: icerik,
    );
  }

  Widget _varsayilanIkon(Color renk, double ikonBoyut) {
    return Icon(
      Icons.local_cafe,
      size: ikonBoyut,
      color: renk,
    );
  }
}
