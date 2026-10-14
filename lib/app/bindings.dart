import 'package:get/get.dart';
import '../modules/auth/auth_controller.dart';
import '../modules/bottom_nav/bottom_nav_controller.dart';
import '../modules/favorites/favorites_controller.dart';
import '../modules/home/home_controller.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    Get.put(AuthController(), permanent: true);
    Get.put(FavoritesController(), permanent: true);
    Get.put(HomeController(), permanent: true);
    Get.put(BottomNavController(), permanent: true);
  }
}
