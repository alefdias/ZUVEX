import 'dart:async';
import 'package:get/get.dart';
import '../../data/models/ad_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/city_model.dart';
import '../../data/services/ad_service.dart';

enum SortOption {
  recent('Mais recentes'),
  lowestPrice('Menor preço'),
  highestPrice('Maior preço');

  final String label;
  const SortOption(this.label);
}

class HomeController extends GetxController {
  static HomeController get to => Get.find();

  final ads = <AdModel>[].obs;
  final availableCities = <CityModel>[].obs;
  final selectedCity = CityModel.promissao.obs;

  final categories = CategoryModel.allCategories;
  final selectedCategoryId = 'todas'.obs;

  final searchQuery = ''.obs;
  final selectedSort = SortOption.recent.obs;
  final minPrice = Rxn<double>();
  final maxPrice = Rxn<double>();

  final isLoading = true.obs;
  final error = ''.obs;

  StreamSubscription? _adsSubscription;

  @override
  void onInit() {
    super.onInit();
    loadCities();
    listenAds();
  }

  @override
  void onClose() {
    _adsSubscription?.cancel();
    super.onClose();
  }

  Future<void> loadCities() async {
    try {
      final cities = await AdService.fetchCities();
      availableCities.assignAll(cities);
    } catch (_) {
      availableCities.assignAll(CityModel.defaultCities);
    }
  }

  void selectCity(CityModel city) {
    selectedCity.value = city;
    listenAds();
  }

  void selectCategory(String catId) {
    selectedCategoryId.value = catId;
  }

  void setSortOption(SortOption sort) {
    selectedSort.value = sort;
  }

  void setPriceFilter(double? min, double? max) {
    minPrice.value = min;
    maxPrice.value = max;
  }

  void clearFilters() {
    selectedCategoryId.value = 'todas';
    minPrice.value = null;
    maxPrice.value = null;
    selectedSort.value = SortOption.recent;
  }

  void listenAds() {
    isLoading(true);
    error('');
    _adsSubscription?.cancel();

    try {
      _adsSubscription = AdService.streamActiveAds(
        cityId: selectedCity.value.id,
      ).listen(
        (list) {
          if (list.isEmpty) {
            // Em caso de banco inicial vazio, fornece os dados realistas de Promissão
            ads.assignAll(AdService.getInitialMockAds());
          } else {
            ads.assignAll(list);
          }
          isLoading(false);
        },
        onError: (err) {
          // Fallback para os anúncios de demonstração de Promissão
          ads.assignAll(AdService.getInitialMockAds());
          isLoading(false);
        },
      );
    } catch (_) {
      ads.assignAll(AdService.getInitialMockAds());
      isLoading(false);
    }
  }

  // Anúncios Filtrados
  List<AdModel> get filteredAds {
    List<AdModel> list = List.from(ads);

    // Filtro por Categoria
    if (selectedCategoryId.value != 'todas') {
      list = list.where((a) => a.categoryId.toLowerCase() == selectedCategoryId.value.toLowerCase()).toList();
    }

    // Filtro por Busca de Texto
    if (searchQuery.value.trim().isNotEmpty) {
      final query = searchQuery.value.toLowerCase().trim();
      list = list.where((a) {
        return a.title.toLowerCase().contains(query) ||
            a.description.toLowerCase().contains(query) ||
            a.district.toLowerCase().contains(query);
      }).toList();
    }

    // Filtro por Faixa de Preço
    if (minPrice.value != null) {
      list = list.where((a) => a.price >= minPrice.value!).toList();
    }
    if (maxPrice.value != null) {
      list = list.where((a) => a.price <= maxPrice.value!).toList();
    }

    // Ordenação
    switch (selectedSort.value) {
      case SortOption.lowestPrice:
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case SortOption.highestPrice:
        list.sort((a, b) => b.price.compareTo(a.price));
        break;
      case SortOption.recent:
        // Mantém destacados primeiro, depois mais recentes
        list.sort((a, b) {
          if (a.isFeatured && !b.isFeatured) return -1;
          if (!a.isFeatured && b.isFeatured) return 1;
          return b.createdAt.compareTo(a.createdAt);
        });
        break;
    }

    return list;
  }

  // Apenas Destaques para o Carrossel Superior
  List<AdModel> get featuredAds {
    return ads.where((a) => a.isFeatured).toList();
  }

  // Anúncios Recentes
  List<AdModel> get recentAds {
    return filteredAds;
  }
}
