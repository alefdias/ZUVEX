import 'dart:convert';
import 'package:flutter/material.dart';
import '../app/theme.dart';

/// Widget especializado para exibição segura e legível do QR Code Pix.
/// Suporta tanto imagens Base64 (data:image/png;base64) enviadas diretamente
/// pelo gateway (BotaPix/Efí Bank) quanto URLs públicas e fallbacks oficiais.
class PixQrView extends StatelessWidget {
  final String qrCodeSource;
  final String pixCopiaECola;
  final double size;

  const PixQrView({
    super.key,
    required this.qrCodeSource,
    required this.pixCopiaECola,
    this.size = 200,
  });

  @override
  Widget build(BuildContext context) {
    final trimmedQr = qrCodeSource.trim();

    // 1. Imagem Base64 gerada diretamente pelo BotaPix / Efí Bank
    if (trimmedQr.startsWith('data:image')) {
      try {
        final commaIndex = trimmedQr.indexOf(',');
        final base64Data = commaIndex != -1 ? trimmedQr.substring(commaIndex + 1) : trimmedQr;
        final cleanBase64 = base64Data.replaceAll(RegExp(r'\s+'), '');
        final bytes = base64Decode(cleanBase64);

        return Image.memory(
          bytes,
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _buildOnlineQr(context),
        );
      } catch (_) {
        return _buildOnlineQr(context);
      }
    }

    // 2. Se for uma URL web pública
    if (trimmedQr.startsWith('http://') || trimmedQr.startsWith('https://')) {
      return Image.network(
        trimmedQr,
        width: size,
        height: size,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return SizedBox(
            width: size,
            height: size,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            ),
          );
        },
        errorBuilder: (_, __, ___) => _buildOnlineQr(context),
      );
    }

    return _buildOnlineQr(context);
  }

  Widget _buildOnlineQr(BuildContext context) {
    if (pixCopiaECola.isEmpty) {
      return SizedBox(
        width: size,
        height: size,
        child: const Center(
          child: Icon(Icons.qr_code_2_rounded, size: 100, color: Colors.grey),
        ),
      );
    }

    final encoded = Uri.encodeComponent(pixCopiaECola);
    final url = 'https://api.qrserver.com/v1/create-qr-code/?size=${size.toInt()}x${size.toInt()}&margin=10&data=$encoded';

    return Image.network(
      url,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) {
        // Fallback secundário de servidor de QR Code
        final quickChartUrl = 'https://quickchart.io/qr?size=${size.toInt()}&text=$encoded';
        return Image.network(
          quickChartUrl,
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Center(
            child: Icon(Icons.qr_code_2_rounded, size: 100, color: Colors.grey),
          ),
        );
      },
    );
  }
}
