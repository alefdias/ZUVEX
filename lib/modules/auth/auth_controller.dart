import 'package:get/get.dart';
import '../../data/services/firebase_service.dart';
import '../../data/services/hive_service.dart';
import '../../app/routes.dart';
import '../../modules/favorites/favorites_controller.dart';
import '../../modules/bottom_nav/bottom_nav_controller.dart';

class AuthController extends GetxController {
  static AuthController get to => Get.find();

  Future<void> signOut() async {
    await FirebaseService.signOut();

    // Limpar cache local do perfil
    await HiveService.clearProfile();

    // Limpar observables em memória
    try {
      Get.find<FavoritesController>().favorites.clear();
    } catch (_) {}

    try {
      Get.find<BottomNavController>().currentIndex.value = 0;
    } catch (_) {}

    Get.offAllNamed(AppRoutes.login);
  }
}
