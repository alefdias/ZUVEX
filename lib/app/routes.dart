import 'package:get/get.dart';
import '../modules/admin/admin_panel_view.dart';
import '../modules/auth/login_view.dart';
import '../modules/auth/signup_view.dart';
import '../modules/auth/setup_profile_view.dart';
import '../modules/create_ad/create_ad_view.dart';
import '../modules/favorites/favorites_view.dart';
import '../modules/home/home_view.dart';
import '../modules/profile/my_ads_view.dart';
import '../modules/profile/profile_view.dart';
import '../modules/product/product_detail_view.dart';
import '../modules/search/search_view.dart';
import '../modules/splash/splash_view.dart';

class AppRoutes {
  static const splash = '/splash';
  static const home = '/';
  static const login = '/login';
  static const signup = '/signup';
  static const setupProfile = '/setup-profile';
  static const productDetail = '/product';
  static const createAd = '/create-ad';
  static const myAds = '/my-ads';
  static const admin = '/admin';
  static const favorites = '/favorites';
  static const search = '/search';
  static const profile = '/profile';

  static final pages = [
    GetPage(name: splash, page: () => const SplashView()),
    GetPage(name: home, page: () => const HomeView()),
    GetPage(name: login, page: () => const LoginView()),
    GetPage(name: signup, page: () => const SignupView()),
    GetPage(
      name: setupProfile,
      page: () => const SetupProfileView(isEdit: false),
    ),
    GetPage(name: productDetail, page: () => const ProductDetailView()),
    GetPage(name: createAd, page: () => const CreateAdView()),
    GetPage(name: myAds, page: () => const MyAdsView()),
    GetPage(name: admin, page: () => const AdminPanelView()),
    GetPage(name: favorites, page: () => const FavoritesView()),
    GetPage(name: search, page: () => const SearchView()),
    GetPage(name: profile, page: () => const ProfileView()),
  ];
}
