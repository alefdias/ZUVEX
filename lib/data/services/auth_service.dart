import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart' show firebaseReady;

/// Serviço central de autenticação do ZUVEX.
/// Fluxo:
///   1ª vez → Login com Google (OAuth completo)
///   Próximas vezes → Impressão digital (biometria) → reentra sem nova tela Google
class AuthService {
  static FirebaseAuth? get _auth => firebaseReady ? FirebaseAuth.instance : null;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();
  static final LocalAuthentication _localAuth = LocalAuthentication();

  static const _keyBiometricEnabled = 'zuvex_biometric_enabled';
  static const _keyUserEmail = 'zuvex_user_email';

  // ── Super Administrador Master ZUVEX ─────────────────────────────────────
  /// E-mail exclusivo do Administrador Geral que controla tudo: usuários, pagamentos e moderação
  static const String masterAdminEmail = 'devalefdias44@gmail.com';

  /// Verifica se o e-mail informado (ou atual) é o Administrador Master
  static bool isMasterAdmin([String? email]) {
    final target = (email ?? currentEmail)?.trim().toLowerCase();
    return target == masterAdminEmail.toLowerCase();
  }

  /// Retorna true se o usuário logado atualmente é o Administrador Master
  static bool get isCurrentMasterAdmin => isMasterAdmin(currentEmail);

  // ── Usuário atual ──────────────────────────────────────────────────────────
  static User? get currentUser => _auth?.currentUser;
  static String? get currentUid => _auth?.currentUser?.uid;
  static String? get currentEmail => _auth?.currentUser?.email;
  static String? get displayName => _auth?.currentUser?.displayName;
  static String? get photoUrl => _auth?.currentUser?.photoURL;
  static Stream<User?> get authStateChanges =>
      _auth != null ? _auth!.authStateChanges() : const Stream.empty();

  // ── Verifica se biometria está disponível no dispositivo ───────────────────
  static Future<bool> get isBiometricAvailable async {
    try {
      final isAvailable = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;
      return isAvailable && canCheck;
    } catch (_) {
      return false;
    }
  }

  // ── Verifica se o usuário já ativou biometria ──────────────────────────────
  static Future<bool> get isBiometricEnabled async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyBiometricEnabled) ?? false;
  }

  // ── Salva preferência de biometria ────────────────────────────────────────
  static Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBiometricEnabled, enabled);
  }

  // ── Salva e-mail do último usuário logado (para biometria) ─────────────────
  static Future<void> _saveLastEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserEmail, email);
  }

  static Future<String?> get lastSavedEmail async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserEmail);
  }

  // ── LOGIN COM GOOGLE (fluxo completo OAuth) ────────────────────────────────
  static Future<UserCredential?> signInWithGoogle() async {
    if (_auth == null) {
      throw 'Firebase não está disponível nesta plataforma (Linux desktop). Teste no Android ou ative Firebase Web.';
    }
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // usuário cancelou

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth!.signInWithCredential(credential);

      // Salva e-mail para uso futuro na biometria
      if (userCredential.user?.email != null) {
        await _saveLastEmail(userCredential.user!.email!);
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseError(e);
    } catch (e) {
      throw 'Erro ao fazer login com Google. Tente novamente.';
    }
  }

  // ── AUTENTICAÇÃO BIOMÉTRICA ────────────────────────────────────────────────
  /// Autentica o usuário com impressão digital.
  /// Retorna `true` se autenticado com sucesso.
  static Future<bool> authenticateWithBiometrics({
    String reason = 'Use sua impressão digital para entrar no ZUVEX',
  }) async {
    try {
      final bool authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false, // permite PIN como fallback
          stickyAuth: true,     // mantém diálogo se app vai para background
          useErrorDialogs: true,
        ),
      );
      return authenticated;
    } on PlatformException {
      return false;
    }
  }

  // ── REAUTENTICAR SILENCIOSAMENTE (Google silent sign-in) ──────────────────
  /// Tenta reconectar o token Google sem mostrar tela de seleção de conta.
  static Future<bool> silentGoogleSignIn() async {
    if (_auth == null) return false;
    try {
      final GoogleSignInAccount? googleUser =
          await _googleSignIn.signInSilently();
      if (googleUser == null) return false;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await _auth!.signInWithCredential(credential);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── LOGIN COM E-MAIL/SENHA ─────────────────────────────────────────────────
  static Future<UserCredential> signInWithEmail(
      String email, String password) async {
    if (_auth == null) {
      throw 'Firebase não está disponível nesta plataforma (Linux desktop).';
    }
    try {
      return await _auth!.signInWithEmailAndPassword(
          email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseError(e);
    }
  }

  // ── CADASTRO COM E-MAIL/SENHA ──────────────────────────────────────────────
  static Future<UserCredential> createAccount(
      String email, String password) async {
    if (_auth == null) {
      throw 'Firebase não está disponível nesta plataforma (Linux desktop).';
    }
    try {
      return await _auth!.createUserWithEmailAndPassword(
          email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseError(e);
    }
  }

  // ── LOGOUT ─────────────────────────────────────────────────────────────────
  static Future<void> signOut() async {
    final futures = <Future>[];
    if (_auth != null) futures.add(_auth!.signOut());
    futures.add(_googleSignIn.signOut());
    await Future.wait(futures);
    // NÃO apaga a preferência de biometria — o usuário já configurou
  }

  // ── Mapeamento de erros Firebase ──────────────────────────────────────────
  static String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Nenhuma conta encontrada com este e-mail.';
      case 'wrong-password':
        return 'Senha incorreta.';
      case 'email-already-in-use':
        return 'Este e-mail já está cadastrado.';
      case 'invalid-email':
        return 'E-mail inválido.';
      case 'weak-password':
        return 'Senha muito fraca. Use ao menos 6 caracteres.';
      case 'network-request-failed':
        return 'Sem conexão com a internet.';
      case 'too-many-requests':
        return 'Muitas tentativas. Aguarde e tente novamente.';
      default:
        return e.message ?? 'Erro de autenticação.';
    }
  }

  // ── Sincroniza e-mail no Firestore ────────────────────────────────────────
  static Future<void> syncEmail(String uid, String email) async {
    // delegado ao firebase_service.dart existente
  }
}
