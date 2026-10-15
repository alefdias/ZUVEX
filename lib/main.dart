import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app/bindings.dart';
import 'app/routes.dart';
import 'app/theme.dart';
import 'data/services/auth_service.dart';
import 'firebase_options.dart';

/// Flag global: Firebase inicializou com sucesso?
bool firebaseReady = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Firebase NÃO suporta Linux/Windows nativamente.
  // Só inicializa em plataformas suportadas (Android, iOS, Web, macOS).
  final isFirebaseSupported = !kIsWeb
      ? defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS
      : true;

  if (isFirebaseSupported) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      firebaseReady = true;
      debugPrint('✅ Firebase inicializado com sucesso.');
    } catch (e) {
      firebaseReady = false;
      debugPrint('⚠️ Firebase falhou, modo offline ativo: $e');
    }
  } else {
    firebaseReady = false;
    debugPrint('ℹ️ Plataforma Linux/Windows: Firebase desabilitado, modo demo ativo.');
  }

  // Hive para armazenamento offline
  await Hive.initFlutter();
  await Hive.openBox('profile');

  runApp(const ZuvexApp());
}

class ZuvexApp extends StatefulWidget {
  const ZuvexApp({super.key});

  @override
  State<ZuvexApp> createState() => _ZuvexAppState();
}

class _ZuvexAppState extends State<ZuvexApp> with WidgetsBindingObserver {
  bool _isAuthenticating = false;
  DateTime? _lastPaused;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _lastPaused = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      _handleAppResume();
    }
  }

  Future<void> _handleAppResume() async {
    // Se ficou em segundo plano por menos de 2s (ex: troca de tela, permissão ou teclado), não bloqueia
    if (_lastPaused != null && DateTime.now().difference(_lastPaused!).inSeconds < 2) {
      return;
    }
    _lastPaused = null;

    if (_isAuthenticating) return;

    // Se o usuário já estiver na tela de Splash ou Login, deixa o fluxo dessas telas agir
    final currentRoute = Get.currentRoute;
    if (currentRoute == AppRoutes.splash || currentRoute == AppRoutes.login) {
      return;
    }

    final user = AuthService.currentUser;
    if (user == null) return;

    final isBioEnabled = await AuthService.isBiometricEnabled;
    final isBioAvailable = await AuthService.isBiometricAvailable;

    if (isBioEnabled && isBioAvailable) {
      _isAuthenticating = true;
      try {
        final ok = await AuthService.authenticateWithBiometrics(
          reason: 'Confirme sua biometria para continuar no ZUVEX',
        );
        if (!ok) {
          // Se cancelar a biometria ao voltar ao app, bloqueia e vai para a tela de login
          Get.offAllNamed(AppRoutes.login);
        }
      } finally {
        _isAuthenticating = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'ZUVEX — Compre e venda perto de você',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: AppRoutes.splash,
      getPages: AppRoutes.pages,
      initialBinding: AppBindings(),
      defaultTransition: Transition.cupertino,
    );
  }
}
