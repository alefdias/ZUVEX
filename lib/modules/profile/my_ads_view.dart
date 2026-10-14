import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import '../../app/theme.dart';
import '../../data/models/ad_model.dart';
import '../../data/services/ad_service.dart';
import '../../data/services/firebase_service.dart';

class MyAdsView extends StatefulWidget {
  const MyAdsView({super.key});

  @override
  State<MyAdsView> createState() => _MyAdsViewState();
}

class _MyAdsViewState extends State<MyAdsView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseService.currentUid ?? 'user_guest';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Meus Anúncios'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Todos'),
            Tab(text: 'Ativos'),
            Tab(text: 'Vendidos'),
            Tab(text: 'Expirados'),
          ],
        ),
      ),
      body: StreamBuilder<List<AdModel>>(
        stream: AdService.streamUserAds(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final allAds = snapshot.data ?? [];

          // Se não houver anúncios no stream (ex: usuário novo ou offline), exibe lista de demonstração
          final ads = allAds.isNotEmpty ? allAds : AdService.getInitialMockAds().take(2).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildAdsList(ads, 'Nenhum anúncio criado ainda.'),
              _buildAdsList(ads.where((a) => a.status == AdStatus.active).toList(), 'Nenhum anúncio ativo.'),
              _buildAdsList(ads.where((a) => a.status == AdStatus.sold).toList(), 'Nenhum anúncio marcado como vendido.'),
              _buildAdsList(ads.where((a) => a.status == AdStatus.expired).toList(), 'Nenhum anúncio expirado.'),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAdsList(List<AdModel> list, String emptyMessage) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.box, size: 48, color: isDark ? AppColors.textSecondaryDark : AppColors.textLight),
            const SizedBox(height: 12),
            Text(emptyMessage, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final ad = list[index];
        return _MyAdItemCard(ad: ad);
      },
    );
  }
}

class _MyAdItemCard extends StatelessWidget {
  final AdModel ad;
  const _MyAdItemCard({required this.ad});

  void _showAdActions(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.check_circle_outline, color: AppColors.success),
                title: const Text('Marcar como Vendido'),
                onTap: () async {
                  await AdService.updateAdStatus(ad.id, AdStatus.sold);
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  Get.snackbar('Sucesso', 'Anúncio marcado como vendido!', backgroundColor: AppColors.success, colorText: Colors.white);
                },
              ),
              if (ad.status == AdStatus.expired)
                ListTile(
                  leading: const Icon(Icons.autorenew_rounded, color: AppColors.primary),
                  title: const Text('Renovar Anúncio (30 dias)'),
                  onTap: () async {
                    await AdService.renewAd(ad.id, 30);
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    Get.snackbar('Sucesso', 'Anúncio renovado!', backgroundColor: AppColors.primary, colorText: Colors.white);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.error),
                title: const Text('Excluir Anúncio', style: TextStyle(color: AppColors.error)),
                onTap: () async {
                  await AdService.deleteAd(ad.id);
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  Get.snackbar('Excluído', 'O anúncio foi removido permanentemente.');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 80,
              height: 80,
              child: Image.network(
                ad.primaryImage,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade300),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _getStatusColor(ad.status).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    ad.status.label,
                    style: TextStyle(
                      color: _getStatusColor(ad.status),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ad.title,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  ad.formattedPrice,
                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary, fontSize: 14),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showAdActions(context),
            icon: const Icon(Icons.more_vert_rounded),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(AdStatus status) {
    switch (status) {
      case AdStatus.active:
        return AppColors.success;
      case AdStatus.pendingPayment:
      case AdStatus.inReview:
        return AppColors.warning;
      case AdStatus.sold:
        return AppColors.sold;
      case AdStatus.expired:
      case AdStatus.rejected:
      case AdStatus.removed:
        return AppColors.error;
      case AdStatus.draft:
        return Colors.grey;
    }
  }
}
