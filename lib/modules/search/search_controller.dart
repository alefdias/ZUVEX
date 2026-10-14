import 'package:get/get.dart';
import '../../data/models/ad_model.dart';
import '../home/home_controller.dart';

class ProductSearchController extends GetxController {
  final query = ''.obs;

  // Filtros
  final selectedCategories = <String>{}.obs;
  final priceMin = 0.0.obs;
  final priceMax = 1000000.0.obs;

  bool get hasActiveFilters =>
      selectedCategories.isNotEmpty ||
      priceMin.value > 0 ||
      priceMax.value < 1000000;

  // Resultados
  List<AdModel> get results {
    final all = Get.find<HomeController>().ads;
    return all.where((ad) {
      // Busca de texto (Título, Descrição ou Bairro)
      if (query.isNotEmpty) {
        final q = query.value.toLowerCase().trim();
        final matches = ad.title.toLowerCase().contains(q) ||
            ad.description.toLowerCase().contains(q) ||
            ad.district.toLowerCase().contains(q) ||
            ad.cityName.toLowerCase().contains(q);
        if (!matches) return false;
      }

      // Filtro de Categoria
      if (selectedCategories.isNotEmpty && !selectedCategories.contains(ad.categoryId.toLowerCase())) {
        return false;
      }

      // Filtro de Preço
      if (ad.price < priceMin.value || ad.price > priceMax.value) {
        return false;
      }

      return true;
    }).toList();
  }

  void resetFilters() {
    selectedCategories.clear();
    priceMin(0.0);
    priceMax(1000000.0);
  }

  void toggleCategory(String catId) {
    if (selectedCategories.contains(catId.toLowerCase())) {
      selectedCategories.remove(catId.toLowerCase());
    } else {
      selectedCategories.add(catId.toLowerCase());
    }
  }
}
