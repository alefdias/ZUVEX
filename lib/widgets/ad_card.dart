import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../app/routes.dart';
import '../app/theme.dart';
import '../data/models/ad_model.dart';
import '../modules/favorites/favorites_controller.dart';

class AdCard extends StatelessWidget {
  final AdModel ad;

  const AdCard({super.key, required this.ad});

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inHours < 1) {
      return 'Agora há pouco';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h atrás';
    } else if (diff.inDays == 1) {
      return 'Ontem';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} dias atrás';
    } else {
      return DateFormat('dd/MM', 'pt_BR').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.productDetail, arguments: ad),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: ad.isFeatured
                ? AppColors.featured.withValues(alpha: 0.6)
                : (isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
            width: ad.isFeatured ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagem do Anúncio com Badges e Botão Favoritar
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1.28,
                  child: Hero(
                    tag: 'ad_${ad.id}_${key.hashCode}',
                    child: CachedNetworkImage(
                      imageUrl: ad.primaryImage,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: isDark ? const Color(0xFF2D2F3E) : const Color(0xFFE5E7EB),
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: isDark ? const Color(0xFF2D2F3E) : const Color(0xFFE5E7EB),
                        child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
                      ),
                    ),
                  ),
                ),

                // Selo de Destaque
                if (ad.isFeatured)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star_rounded, color: Colors.white, size: 13),
                          SizedBox(width: 3),
                          Text(
                            'DESTAQUE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Botão de Favoritar
                Positioned(
                  top: 6,
                  right: 6,
                  child: Obx(() {
                    bool isFav = false;
                    try {
                      isFav = FavoritesController.to.isAdFavorite(ad.id);
                    } catch (_) {}

                    return GestureDetector(
                      onTap: () {
                        try {
                          FavoritesController.to.toggleAdFavorite(ad);
                        } catch (_) {}
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.85),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Icon(
                          isFav ? Iconsax.heart5 : Iconsax.heart,
                          size: 18,
                          color: isFav ? AppColors.error : AppColors.graphite,
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),

            // Informações do Anúncio
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Preço
                  Text(
                    ad.formattedPrice,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.white : AppColors.primary,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Título
                  Text(
                    ad.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (ad.isPixVerified) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_rounded, size: 11, color: Color(0xFF10B981)),
                          SizedBox(width: 3),
                          Text(
                            'Pix Verificado',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),

                  // Localização (Bairro / Cidade)
                  Row(
                    children: [
                      Icon(
                        Iconsax.location,
                        size: 12,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          '${ad.district}, ${ad.cityName.split(' - ')[0]}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),

                  // Data
                  Text(
                    _formatDate(ad.createdAt),
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? AppColors.textLight.withValues(alpha: 0.7) : AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
