import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/hive_service.dart';

/// Tela de Login e Cadastro do ZUVEX.
/// Suporta:
///   - E-mail e Senha (Entrar e Criar Conta)
///   - Google Sign-In
///   - Recuperação de senha
///   - Biometria (se configurada)
///   - Modo visitante
class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isSignUp = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _initAuthSession();
  }

  Future<void> _initAuthSession() async {
    final available = await AuthService.isBiometricAvailable;
    final enabled = await AuthService.isBiometricEnabled;
    if (!mounted) return;

    setState(() {
      _biometricAvailable = available;
      _biometricEnabled = enabled;
    });

    if (AuthService.currentUser != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Get.offAllNamed(AppRoutes.home);
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  // ── Login / Cadastro com E-mail e Senha ────────────────────────────────────
  Future<void> _submitEmailAuth() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (_isSignUp && password != _confirmPasswordController.text) {
      setState(() {
        _error = 'As senhas não coincidem.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      if (_isSignUp) {
        final cred = await AuthService.createAccount(email, password);
        if (_nameController.text.trim().isNotEmpty) {
          await cred.user?.updateDisplayName(_nameController.text.trim());
        }
        Get.snackbar(
          'Conta criada!',
          'Bem-vindo ao ZUVEX!',
          backgroundColor: AppColors.success.withValues(alpha: 0.9),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
        );
      } else {
        await AuthService.signInWithEmail(email, password);
      }

      if (mounted) {
        Get.offAllNamed(AppRoutes.home);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ── Login com Google ──────────────────────────────────────────────────────
  Future<void> _loginWithGoogle() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final cred = await AuthService.signInWithGoogle();
      if (cred == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      if (mounted) {
        Get.offAllNamed(AppRoutes.home);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ── Login Biometria ───────────────────────────────────────────────────────
  Future<void> _loginWithBiometrics() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _error = '';
    });

    final ok = await AuthService.authenticateWithBiometrics(
      reason: 'Confirme sua biometria para acessar sua conta ZUVEX',
    );

    if (!mounted) return;

    if (!ok) {
      setState(() {
        _isLoading = false;
        _error = 'Biometria não confirmada. Toque no leitor ou entre com sua senha.';
      });
      return;
    }

    // Se confirmou a biometria com sucesso:
    if (AuthService.currentUser != null) {
      Get.offAllNamed(AppRoutes.home);
      return;
    }

    // Tenta reconexão silenciosa com Google caso a conta use Google
    final silentOk = await AuthService.silentGoogleSignIn();
    if (!mounted) return;

    if (silentOk || AuthService.currentUser != null || HiveService.isProfileSetup) {
      Get.offAllNamed(AppRoutes.home);
    } else {
      setState(() {
        _isLoading = false;
        _error = 'Informe seu e-mail e senha para validar sua conta.';
      });
    }
  }

  // ── Modal de Esqueci Minha Senha ──────────────────────────────────────────
  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController(text: _emailController.text);
    bool isSending = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.lock_reset, color: AppColors.primary, size: 28),
                SizedBox(width: 10),
                Text('Recuperar Senha', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Informe seu e-mail para receber as instruções de redefinição de senha:',
                  style: TextStyle(fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: resetEmailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'E-mail',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSending ? null : () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: isSending
                    ? null
                    : () async {
                        final email = resetEmailController.text.trim();
                        if (email.isEmpty || !email.contains('@')) {
                          Get.snackbar(
                            'Atenção',
                            'Digite um e-mail válido.',
                            backgroundColor: AppColors.error,
                            colorText: Colors.white,
                          );
                          return;
                        }

                        setDialogState(() => isSending = true);
                        try {
                          await AuthService.sendPasswordReset(email);
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          Get.snackbar(
                            'E-mail Enviado!',
                            'Verifique sua caixa de entrada para redefinir a senha.',
                            backgroundColor: AppColors.success,
                            colorText: Colors.white,
                            duration: const Duration(seconds: 4),
                          );
                        } catch (err) {
                          setDialogState(() => isSending = false);
                          Get.snackbar(
                            'Erro',
                            err.toString(),
                            backgroundColor: AppColors.error,
                            colorText: Colors.white,
                          );
                        }
                      },
                child: isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Enviar Link'),
              ),
            ],
          );
        },
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
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo e Ícone ZUVEX
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.28),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      'assets/images/app_icon.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.primary,
                        child: const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 48),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Zuvex',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Compre e venda perto de você.',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white60 : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Seletor Entrar / Criar Conta ──────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2B2D3A) : const Color(0xFFEAEBFA),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              if (_isSignUp) {
                                setState(() {
                                  _isSignUp = false;
                                  _error = '';
                                });
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: !_isSignUp
                                    ? AppColors.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: !_isSignUp
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primary.withValues(alpha: 0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        )
                                      ]
                                    : [],
                              ),
                              child: Text(
                                'Entrar',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: !_isSignUp
                                      ? Colors.white
                                      : (isDark ? Colors.white70 : AppColors.textSecondary),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              if (!_isSignUp) {
                                setState(() {
                                  _isSignUp = true;
                                  _error = '';
                                });
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _isSignUp
                                    ? AppColors.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: _isSignUp
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primary.withValues(alpha: 0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        )
                                      ]
                                    : [],
                              ),
                              child: Text(
                                'Criar Conta',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: _isSignUp
                                      ? Colors.white
                                      : (isDark ? Colors.white70 : AppColors.textSecondary),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Campo Nome (apenas Cadastro) ──────────────────────────
                  if (_isSignUp) ...[
                    TextFormField(
                      controller: _nameController,
                      keyboardType: TextInputType.name,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: 'Nome completo',
                        hintText: 'Como quer ser chamado',
                        prefixIcon: const Icon(Icons.person_outline),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF262733) : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white12 : Colors.black12,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white12 : Colors.black12,
                          ),
                        ),
                      ),
                      validator: (val) {
                        if (_isSignUp && (val == null || val.trim().isEmpty)) {
                          return 'Informe seu nome.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                  ],

                  // ── Campo E-mail ──────────────────────────────────────────
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    decoration: InputDecoration(
                      labelText: 'E-mail',
                      hintText: 'seuemail@exemplo.com',
                      prefixIcon: const Icon(Icons.email_outlined),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF262733) : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: isDark ? Colors.white12 : Colors.black12,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: isDark ? Colors.white12 : Colors.black12,
                        ),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Informe seu e-mail.';
                      }
                      if (!val.contains('@') || !val.contains('.')) {
                        return 'E-mail inválido.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // ── Campo Senha ───────────────────────────────────────────
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      hintText: _isSignUp ? 'Mínimo 6 caracteres' : 'Sua senha',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF262733) : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: isDark ? Colors.white12 : Colors.black12,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: isDark ? Colors.white12 : Colors.black12,
                        ),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Informe sua senha.';
                      }
                      if (_isSignUp && val.length < 6) {
                        return 'A senha deve ter no mínimo 6 caracteres.';
                      }
                      return null;
                    },
                  ),

                  // ── Confirmar Senha (apenas Cadastro) ─────────────────────
                  if (_isSignUp) ...[
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: 'Confirmar Senha',
                        hintText: 'Repita sua senha',
                        prefixIcon: const Icon(Icons.lock_reset),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                          },
                        ),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF262733) : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white12 : Colors.black12,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white12 : Colors.black12,
                          ),
                        ),
                      ),
                      validator: (val) {
                        if (_isSignUp && (val == null || val.isEmpty)) {
                          return 'Confirme sua senha.';
                        }
                        return null;
                      },
                    ),
                  ],

                  // ── Esqueci minha senha (apenas Login) ────────────────────
                  if (!_isSignUp) ...[
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _isLoading ? null : _showForgotPasswordDialog,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                        ),
                        child: Text(
                          'Esqueceu a senha?',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 16),
                  ],

                  // ── Mensagem de Erro ──────────────────────────────────────
                  if (_error.isNotEmpty) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error,
                              style: const TextStyle(color: AppColors.error, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // ── Botão Principal (Entrar / Criar Conta) ─────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _isLoading ? null : _submitEmailAuth,
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _isSignUp ? 'Criar Conta Grátis' : 'Entrar na Conta',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 22),
                  const _DividerOr(),
                  const SizedBox(height: 20),

                  // ── Botão Google ──────────────────────────────────────────
                  _GoogleSignInButton(
                    onTap: _isLoading ? null : _loginWithGoogle,
                    isLoading: _isLoading,
                  ),

                  // ── Atalho Biometria (se ativa no aparelho) ───────────────
                  if (_biometricAvailable && _biometricEnabled && !_isSignUp) ...[
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.fingerprint, color: AppColors.primary, size: 24),
                      label: const Text(
                        'Entrar com Impressão Digital',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: _isLoading ? null : _loginWithBiometrics,
                    ),
                  ],

                  const SizedBox(height: 24),

                  // ── Navegar como Visitante ────────────────────────────────
                  TextButton.icon(
                    onPressed: () => Get.offAllNamed(AppRoutes.home),
                    icon: const Icon(Icons.arrow_forward, size: 16),
                    label: const Text(
                      'Continuar como visitante',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  Text(
                    'Ao continuar, você concorda com nossos\nTermos de Uso e Política de Privacidade.',
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
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF262733) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? Colors.white12 : const Color(0xFFDADCE0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: const Text(
                'G',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF4285F4),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Continuar com Google',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF3C4043),
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
            'ou continue com',
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
