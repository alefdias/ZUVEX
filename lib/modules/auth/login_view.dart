import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../data/services/auth_service.dart';
import '../../widgets/zuvex_logo.dart';

/// Tela de login do ZUVEX.
///
/// Fluxo:
///   - Se biometria está ativa → mostra botão de impressão digital
///   - 1ª vez ou biometria desativada → botão "Entrar com Google"
///   - Opção de e-mail/senha sempre disponível
class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  bool _isLoading = false;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _checkBiometric();
    // Se já logado, vai direto para home
    if (AuthService.currentUser != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offAllNamed(AppRoutes.home);
      });
    }
  }

  Future<void> _checkBiometric() async {
    final available = await AuthService.isBiometricAvailable;
    final enabled = await AuthService.isBiometricEnabled;
    if (mounted) {
      setState(() {
        _biometricAvailable = available;
        _biometricEnabled = enabled;
      });
      // Se biometria está ativa, dispara automaticamente ao abrir
      if (available && enabled) {
        _loginWithBiometrics();
      }
    }
  }

  // ── Login com impressão digital ───────────────────────────────────────────
  Future<void> _loginWithBiometrics() async {
    setState(() { _isLoading = true; _error = ''; });

    final ok = await AuthService.authenticateWithBiometrics();
    if (!ok) {
      if (mounted) setState(() { _isLoading = false; _error = 'Biometria não confirmada.'; });
      return;
    }

    // Tenta reconectar silenciosamente ao Google (token ainda válido)
    final silentOk = await AuthService.silentGoogleSignIn();
    if (!mounted) return;

    if (silentOk) {
      Get.offAllNamed(AppRoutes.home);
    } else {
      // Token expirou — pede login Google normal
      setState(() { _isLoading = false; _error = 'Sessão expirada. Faça login com Google novamente.'; });
      await _loginWithGoogle();
    }
  }

  // ── Login com Google (fluxo completo) ────────────────────────────────────
  Future<void> _loginWithGoogle() async {
    setState(() { _isLoading = true; _error = ''; });

    try {
      final cred = await AuthService.signInWithGoogle();
      if (cred == null) {
        if (mounted) setState(() { _isLoading = false; });
        return;
      }

      // Primeira vez: pergunta se quer ativar biometria
      if (mounted && _biometricAvailable && !_biometricEnabled) {
        _promptEnableBiometric();
      } else {
        if (mounted) Get.offAllNamed(AppRoutes.home);
      }
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _error = e.toString(); });
    }
  }

  // ── Pergunta se quer ativar biometria (só na 1ª vez) ─────────────────────
  void _promptEnableBiometric() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.fingerprint, color: AppColors.primary, size: 28),
            SizedBox(width: 10),
            Text('Ativar Biometria?', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: const Text(
          'Nas próximas vezes, você poderá entrar no ZUVEX usando apenas sua impressão digital — sem precisar fazer login novamente.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Get.offAllNamed(AppRoutes.home);
            },
            child: const Text('Agora não'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.fingerprint),
            label: const Text('Ativar'),
            onPressed: () async {
              await AuthService.setBiometricEnabled(true);
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              Get.offAllNamed(AppRoutes.home);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.graphite : AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo ZUVEX
                const ZuvexLogo(fontSize: 64),
                const SizedBox(height: 12),
                Text(
                  'ZUVEX',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Compre e venda perto de você.',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white60 : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 48),

                // ── Botão de Biometria (se ativa) ──────────────────────────
                if (_biometricAvailable && _biometricEnabled) ...[
                  _BiometricButton(
                    onTap: _isLoading ? null : _loginWithBiometrics,
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: _isLoading ? null : _loginWithGoogle,
                    child: Text(
                      'Usar outra conta',
                      style: TextStyle(color: AppColors.primary, fontSize: 13),
                    ),
                  ),
                ] else ...[
                  // ── Botão Google ──────────────────────────────────────────
                  _GoogleSignInButton(
                    onTap: _isLoading ? null : _loginWithGoogle,
                    isLoading: _isLoading,
                  ),
                ],

                const SizedBox(height: 16),

                // Erro
                if (_error.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: AppColors.error, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error,
                            style: TextStyle(color: AppColors.error, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 32),
                const _DividerOr(),
                const SizedBox(height: 24),

                // ── Acesso rápido como visitante ──────────────────────────
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Get.offAllNamed(AppRoutes.home),
                  child: const Text('Navegar como visitante'),
                ),

                const SizedBox(height: 32),
                Text(
                  'Ao entrar, você concorda com nossos\nTermos de Uso e Política de Privacidade.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white38 : AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Botão de Impressão Digital ─────────────────────────────────────────────
class _BiometricButton extends StatelessWidget {
  final VoidCallback? onTap;
  const _BiometricButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.75)],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            const Icon(Icons.fingerprint, color: Colors.white, size: 52),
            const SizedBox(height: 10),
            const Text(
              'Toque para entrar',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Use sua impressão digital',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Botão Google Sign In ───────────────────────────────────────────────────
class _GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onTap;
  final bool isLoading;
  const _GoogleSignInButton({this.onTap, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2B35) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: isLoading
            ? const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.primary,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Ícone G do Google (SVG-like com Text)
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                    ),
                    child: const Text(
                      'G',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF4285F4),
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Continuar com Google',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.graphite,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ── Divisor "ou" ───────────────────────────────────────────────────────────
class _DividerOr extends StatelessWidget {
  const _DividerOr();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Expanded(child: Divider(color: isDark ? Colors.white12 : Colors.black12)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'ou',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white38 : AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(child: Divider(color: isDark ? Colors.white12 : Colors.black12)),
      ],
    );
  }
}
