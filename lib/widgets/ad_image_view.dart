import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../app/theme.dart';

/// Widget unificado para exibição segura de fotos de anúncios no ZUVEX.
/// Suporta URLs públicas da Web/Firebase Storage, caminhos de arquivos locais capturados
/// pela câmera ou galeria, assets locais e exibe placeholders elegantes com fallback.
class AdImageView extends StatelessWidget {
  final String imageSource;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;

  const AdImageView({
    super.key,
    required this.imageSource,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    final trimmed = imageSource.trim();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget child;

    if (trimmed.isEmpty) {
      child = _buildDefaultFallback(isDark);
    } else if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      child = CachedNetworkImage(
        imageUrl: trimmed,
        fit: fit,
        width: width,
        height: height,
        placeholder: (context, url) =>
            placeholder ??
            Container(
              width: width,
              height: height,
              color: isDark ? const Color(0xFF2D2F3E) : const Color(0xFFE5E7EB),
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
            ),
        errorWidget: (context, url, error) =>
            errorWidget ?? _buildDefaultFallback(isDark),
      );
    } else if (trimmed.startsWith('assets/')) {
      child = Image.asset(
        trimmed,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, __, ___) =>
            errorWidget ?? _buildDefaultFallback(isDark),
      );
    } else {
      // Arquivo local (capturado por Câmera ou Galeria)
      final cleanPath = trimmed.replaceFirst('file://', '');
      final file = File(cleanPath);

      if (file.existsSync()) {
        child = Image.file(
          file,
          fit: fit,
          width: width,
          height: height,
          errorBuilder: (_, __, ___) =>
              errorWidget ?? _buildDefaultFallback(isDark),
        );
      } else {
        child = errorWidget ?? _buildDefaultFallback(isDark);
      }
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: child,
      );
    }

    return child;
  }

  Widget _buildDefaultFallback(bool isDark) {
    return Container(
      width: width,
      height: height,
      color: isDark ? const Color(0xFF2D2F3E) : const Color(0xFFF3F4F6),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_outlined,
              size: (width != null && width! < 60) ? 22 : 36,
              color: isDark ? Colors.white38 : Colors.grey.shade400,
            ),
            if (height == null || height! >= 90) ...[
              const SizedBox(height: 4),
              Text(
                'ZUVEX',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: isDark ? Colors.white24 : Colors.grey.shade400,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
