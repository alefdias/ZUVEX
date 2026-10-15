import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app/bindings.dart';
import 'app/routes.dart';
import 'app/theme.dart';
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

class ZuvexApp extends StatelessWidget {
  const ZuvexApp({super.key});

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
