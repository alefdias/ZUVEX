import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../app/theme.dart';
import '../../data/models/ad_model.dart';
import '../../main.dart' show firebaseReady;

class FavoritesController extends GetxController {
  static FavoritesController get to => Get.find();

  final favoriteAds = <AdModel>[].obs;
  Box? _favBox;

  List<AdModel> get favorites => favoriteAds;

  @override
  void onInit() {
    super.onInit();
    final uid = firebaseReady
        ? (FirebaseAuth.instance.currentUser?.uid ?? 'guest')
        : 'guest';
    _initBox(uid);
  }

  Future<void> _initBox(String uid) async {
    final boxName = 'zuvex_favs_$uid';
    if (!Hive.isBoxOpen(boxName)) {
      _favBox = await Hive.openBox(boxName);
    } else {
      _favBox = Hive.box(boxName);
    }
    _loadFromBox();
  }

  void reloadForUser(String uid) {
    _initBox(uid);
  }

  void _loadFromBox() {
    if (_favBox == null) return;
    final List<AdModel> loaded = [];
    for (final key in _favBox!.keys) {
      final map = _favBox!.get(key);
      if (map is Map) {
        try {
          loaded.add(AdModel.fromMap(Map<String, dynamic>.from(map)));
        } catch (_) {}
      }
    }
    favoriteAds.assignAll(loaded);
  }

  bool isAdFavorite(String adId) => favoriteAds.any((a) => a.id == adId);

  void toggleAdFavorite(AdModel ad) {
    if (isAdFavorite(ad.id)) {
      _favBox?.delete(ad.id);
      favoriteAds.removeWhere((a) => a.id == ad.id);
      Get.snackbar(
        'Removido dos Favoritos',
        ad.title,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.graphite,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    } else {
      _favBox?.put(ad.id, ad.toMap());
      favoriteAds.add(ad);
      Get.snackbar(
        'Salvo nos Favoritos',
        ad.title,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.primary,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    }
    favoriteAds.refresh();
  }
}
