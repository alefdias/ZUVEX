import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import '../../app/theme.dart';
import '../../data/models/category_model.dart';
import '../../widgets/ad_card.dart';
import 'search_controller.dart';

class SearchView extends StatelessWidget {
  const SearchView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(ProductSearchController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: _SearchField(ctrl: ctrl),
        titleSpacing: 16,
        actions: [
          Obx(
            () => IconButton(
              onPressed: () => _showFilterDialog(context, ctrl),
              icon: Icon(
                ctrl.hasActiveFilters ? Iconsax.filter_edit5 : Iconsax.filter_edit,
                color: ctrl.hasActiveFilters ? AppColors.primary : null,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Obx(() {
        final results = ctrl.results;

        if (ctrl.query.isEmpty && !ctrl.hasActiveFilters) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Iconsax.search_normal_1, size: 40, color: AppColors.primary),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Buscar nos classificados ZUVEX',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  'Encontre carros, motos, casas e produtos perto de você.',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          );
        }

        if (results.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Iconsax.search_status,
                  size: 48,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textLight,
                ),
                const SizedBox(height: 14),
                Text(
                  'Nenhum anúncio encontrado para "${ctrl.query.value}"',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  'Tente buscar por termos mais genéricos ou mudar os filtros.',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Row(
                children: [
                  Text(
                    '${results.length} anúncio${results.length == 1 ? '' : 's'} encontrado${results.length == 1 ? '' : 's'}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                  const Spacer(),
                  if (ctrl.hasActiveFilters)
                    TextButton(
                      onPressed: ctrl.resetFilters,
                      child: const Text('Limpar filtros', style: TextStyle(fontSize: 12)),
                    ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.65,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: results.length,
                itemBuilder: (_, i) => AdCard(ad: results[i]),
              ),
            ),
          ],
        );
      }),
    );
  }

  void _showFilterDialog(BuildContext context, ProductSearchController ctrl) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Filtrar Anúncios', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  TextButton(
                    onPressed: () {
                      ctrl.resetFilters();
                      Navigator.pop(ctx);
                    },
                    child: const Text('Limpar'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Categorias', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: CategoryModel.allCategories.map((cat) {
                  return Obx(() {
                    final selected = ctrl.selectedCategories.contains(cat.id.toLowerCase());
                    return FilterChip(
                      label: Text(cat.title),
                      selected: selected,
                      selectedColor: AppColors.primaryLight,
                      onSelected: (_) => ctrl.toggleCategory(cat.id),
                    );
                  });
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Ver Resultados'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SearchField extends StatelessWidget {
  final ProductSearchController ctrl;
  const _SearchField({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return TextField(
      autofocus: false,
      onChanged: ctrl.query.call,
      decoration: const InputDecoration(
        hintText: 'Buscar por nome, marca, bairro...',
        prefixIcon: Icon(Iconsax.search_normal_1, size: 20),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
