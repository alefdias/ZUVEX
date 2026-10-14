import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../main.dart' show firebaseReady;
import '../../widgets/zuvex_logo.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    await Future.delayed(const Duration(milliseconds: 1200));

    // Se Firebase não estiver pronto (modo demo desktop), abre tela de login
    if (!firebaseReady) {
      if (mounted) Get.offAllNamed(AppRoutes.login);
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (mounted) {
        if (user != null) {
          // Usuário já conectado → abre Home
          Get.offAllNamed(AppRoutes.home);
        } else {
          // Usuário NÃO conectado → pede login obrigatoriamente
          Get.offAllNamed(AppRoutes.login);
        }
      }
    } catch (_) {
      if (mounted) Get.offAllNamed(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const ZuvexLogo(
              fontSize: 36,
              showSlogan: true,
            ),
            const SizedBox(height: 48),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Promissão – SP e Região',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
