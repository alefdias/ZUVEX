import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import '../../app/theme.dart';
import '../../data/models/category_model.dart';
import '../../widgets/ad_card.dart';
import '../../widgets/zuvex_logo.dart';
import '../bottom_nav/app_bottom_nav_bar.dart';
import '../bottom_nav/bottom_nav_controller.dart';
import '../favorites/favorites_view.dart';
import '../profile/profile_view.dart';
import '../search/search_view.dart';
import '../create_ad/create_ad_view.dart';
import '../profile/my_ads_view.dart';
import '../../data/models/ad_model.dart';
import '../../data/services/ad_service.dart';
import '../../data/services/firebase_service.dart';
import 'home_controller.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final navCtrl = BottomNavController.to;

    // As 5 telas da navegação inferior
    final pages = [
      const _HomeContent(),
      const SearchView(),
      const CreateAdView(),
      const FavoritesView(),
      const ProfileView(),
    ];

    return Obx(() {
      return Scaffold(
        body: IndexedStack(
          index: navCtrl.currentIndex.value,
          children: pages,
        ),
        bottomNavigationBar: const AppBottomNavBar(),
      );
    });
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent();

  void _showCitySelector(BuildContext context, HomeController ctrl) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Selecione sua Cidade',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Começando por Promissão e expandindo para toda a região.',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: Obx(() {
                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: ctrl.availableCities.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final city = ctrl.availableCities[index];
                      final isSelected = ctrl.selectedCity.value.id == city.id;

                      return ListTile(
                        leading: Icon(
                          Iconsax.location5,
                          color: isSelected ? AppColors.primary : AppColors.textLight,
                        ),
                        title: Text(
                          city.displayName,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? AppColors.primary : null,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                            : null,
                        onTap: () {
                          ctrl.selectCity(city);
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFilterModal(BuildContext context, HomeController ctrl) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final minCtrl = TextEditingController(
      text: ctrl.minPrice.value != null ? ctrl.minPrice.value!.toInt().toString() : '',
    );
    final maxCtrl = TextEditingController(
      text: ctrl.maxPrice.value != null ? ctrl.maxPrice.value!.toInt().toString() : '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filtros de Busca',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  TextButton(
                    onPressed: () {
                      ctrl.clearFilters();
                      Navigator.pop(ctx);
                    },
                    child: const Text('Limpar'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Faixa de Preço (R\$)', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: minCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: 'Mínimo'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: maxCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: 'Máximo'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Ordenar por', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Obx(() {
                return Wrap(
                  spacing: 8,
                  children: SortOption.values.map((sort) {
                    final selected = ctrl.selectedSort.value == sort;
                    return ChoiceChip(
                      label: Text(sort.label),
                      selected: selected,
                      selectedColor: AppColors.primaryLight,
                      labelStyle: TextStyle(
                        color: selected ? AppColors.primary : null,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                      onSelected: (_) => ctrl.setSortOption(sort),
                    );
                  }).toList(),
                );
              }),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final min = double.tryParse(minCtrl.text.trim());
                    final max = double.tryParse(maxCtrl.text.trim());
                    ctrl.setPriceFilter(min, max);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Aplicar Filtros'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = HomeController.to;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Topo: Logotipo ZUVEX + Slogan + Seletor de Cidade
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const ZuvexLogo(
                          fontSize: 24,
                          showSlogan: true,
                        ),
                        // Seletor de Cidade
                        Obx(() {
                          final city = ctrl.selectedCity.value;
                          return InkWell(
                            onTap: () => _showCitySelector(context, ctrl),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.surfaceDark : AppColors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Iconsax.location5,
                                    size: 15,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    city.name,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.arrow_drop_down_rounded, size: 18),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Barra de Busca com Botão de Filtro
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => BottomNavController.to.changePage(1), // Aba Buscar
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.surfaceDark : AppColors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Iconsax.search_normal_1,
                                    size: 18,
                                    color: isDark ? AppColors.textLight : AppColors.textSecondaryLight,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Buscar carros, motos, imóveis...',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark ? AppColors.textLight : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        InkWell(
                          onTap: () => _showFilterModal(context, ctrl),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Iconsax.filter_edit,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Banner de Rascunhos Pendentes (se o usuário tiver algum rascunho salvo)
            SliverToBoxAdapter(
              child: StreamBuilder<List<AdModel>>(
                stream: AdService.streamUserAds(FirebaseService.currentUid ?? ''),
                builder: (context, snapshot) {
                  final drafts = (snapshot.data ?? [])
                      .where((a) => a.status == AdStatus.draft || a.status == AdStatus.pendingPayment)
                      .toList();
                  if (drafts.isEmpty) return const SizedBox.shrink();

                  return Container(
                    margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.amber.withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.edit_note_rounded, color: Colors.amber, size: 24),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            drafts.length == 1
                                ? 'Você tem 1 anúncio em rascunho.'
                                : 'Você tem ${drafts.length} anúncios em rascunho.',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () => Get.to(() => const MyAdsView(initialIndex: 2)),
                          child: const Text('Pagar e Ativar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Carrossel de Categorias
            SliverToBoxAdapter(
              child: SizedBox(
                height: 98,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: ctrl.categories.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      // Categoria "Todas"
                      return Obx(() {
                        final isSelected = ctrl.selectedCategoryId.value == 'todas';
                        return _CategoryChip(
                          title: 'Todas',
                          icon: Iconsax.grid_5,
                          isSelected: isSelected,
                          onTap: () => ctrl.selectCategory('todas'),
                        );
                      });
                    }

                    final cat = ctrl.categories[index - 1];
                    return Obx(() {
                      final isSelected = ctrl.selectedCategoryId.value == cat.id;
                      return _CategoryChip(
                        title: cat.title,
                        icon: cat.icon,
                        isSelected: isSelected,
                        onTap: () => ctrl.selectCategory(cat.id),
                      );
                    });
                  },
                ),
              ),
            ),

            // Anúncios em Destaque
            Obx(() {
              final featured = ctrl.featuredAds;
              if (featured.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

              return SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: AppColors.featured.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.star_rounded, color: AppColors.featured, size: 16),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Anúncios em Destaque',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 250,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        scrollDirection: Axis.horizontal,
                        itemCount: featured.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 14),
                        itemBuilder: (context, index) {
                          return SizedBox(
                            width: 180,
                            child: AdCard(ad: featured[index]),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            }),

            // Cabeçalho: Anúncios Recentes
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Obx(() {
                      final catName = ctrl.selectedCategoryId.value == 'todas'
                          ? 'Recentes'
                          : CategoryModel.findById(ctrl.selectedCategoryId.value).title;

                      return Text(
                        'Anúncios $catName em ${ctrl.selectedCity.value.name}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      );
                    }),
                    Obx(() {
                      return Text(
                        '${ctrl.filteredAds.length} anúncios',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // Grid de Anúncios Recentes
            Obx(() {
              if (ctrl.isLoading.value) {
                return const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                );
              }

              final ads = ctrl.recentAds;

              if (ads.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Iconsax.box_remove,
                          size: 54,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textLight,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Nenhum anúncio encontrado.',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tente mudar a categoria ou os filtros.',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => ctrl.clearFilters(),
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Limpar Filtros'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.65,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => AdCard(ad: ads[index]),
                    childCount: ads.length,
                  ),
                ),
              );
            }),

            const SliverToBoxAdapter(
              child: SizedBox(height: 32),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary
                  : (isDark ? AppColors.surfaceDark : AppColors.white),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.3)
                      : Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 26,
              color: isSelected
                  ? Colors.white
                  : (isDark ? AppColors.textPrimaryDark : AppColors.graphite),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 66,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? AppColors.textPrimaryDark : AppColors.graphite),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
