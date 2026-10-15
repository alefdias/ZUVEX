import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../main.dart' show firebaseReady;

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
    await Future.delayed(const Duration(milliseconds: 1400));

    // Se Firebase não estiver pronto (modo demo desktop), abre tela de login
    if (!firebaseReady) {
      if (mounted) Get.offAllNamed(AppRoutes.login);
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (mounted) {
        if (user != null) {
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
            // Novo Ícone Oficial do App ZUVEX
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/images/app_icon.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.primary,
                  child: const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 52),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Zuvex',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Compre e venda perto de você.',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 44),
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
