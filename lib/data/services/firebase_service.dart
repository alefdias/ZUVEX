import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/order_model.dart';
import '../../main.dart' show firebaseReady;

class FirebaseService {
  static const String masterAdminEmail = 'devalefdias44@gmail.com';

  static FirebaseAuth? get _auth => firebaseReady ? FirebaseAuth.instance : null;
  static FirebaseFirestore? get _db => firebaseReady ? FirebaseFirestore.instance : null;

  static String? get currentUid => _auth?.currentUser?.uid;
  static String? get currentEmail => _auth?.currentUser?.email;

  static bool get isMasterAdmin =>
      (currentEmail ?? '').trim().toLowerCase() == masterAdminEmail.toLowerCase();

  // Auth
  static Future<String?> signUp(String email, String password) async {
    if (_auth == null) return 'Firebase não disponível.';
    try {
      await _auth!.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return _authError(e);
    }
  }

  static Future<String?> signIn(String email, String password) async {
    if (_auth == null) return 'Firebase não disponível.';
    try {
      await _auth!.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return _authError(e);
    }
  }

  static Future<void> signOut() async {
    if (_auth != null) await _auth!.signOut();
  }

  static String _authError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Nenhuma conta encontrada com este e-mail.';
      case 'wrong-password':
        return 'Senha incorreta.';
      case 'email-already-in-use':
        return 'Já existe uma conta com este e-mail.';
      case 'weak-password':
        return 'A senha é muito fraca.';
      case 'invalid-email':
        return 'E-mail inválido.';
      case 'too-many-requests':
        return 'Muitas tentativas. Tente novamente mais tarde.';
      case 'invalid-credential':
        return 'Credenciais inválidas.';
      default:
        return e.message ?? 'Ocorreu um erro. Tente novamente.';
    }
  }

  // Profile
  static Future<void> saveUserProfile({
    required String uid,
    required String name,
    required String avatarPath,
  }) async {
    if (_db == null) return;
    final email = currentEmail ?? '';
    final isMaster = email.trim().toLowerCase() == masterAdminEmail.toLowerCase();
    await _db!.collection('users').doc(uid).set({
      'name': name,
      'avatarPath': avatarPath,
      'email': email,
      'role': isMaster ? 'master_admin' : 'user',
      'isBlocked': false,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<Map<String, dynamic>?> fetchUserProfile(String uid) async {
    if (_db == null) return null;
    final doc = await _db!.collection('users').doc(uid).get();
    return doc.exists ? doc.data() : null;
  }

  static Future<void> syncEmail(String uid, String email) async {
    if (_db == null) return;
    final isMaster = email.trim().toLowerCase() == masterAdminEmail.toLowerCase();
    await _db!.collection('users').doc(uid).set({
      'email': email,
      if (isMaster) 'role': 'master_admin',
    }, SetOptions(merge: true));
  }

  // Orders
  static Future<void> saveOrder(String uid, OrderModel order) async {
    if (_db == null) return;
    await _db!
        .collection('users')
        .doc(uid)
        .collection('orders')
        .doc(order.orderId)
        .set(order.toMap());
  }

  static Future<List<OrderModel>> fetchOrders(String uid) async {
    if (_db == null) return [];
    final snap = await _db!
        .collection('users')
        .doc(uid)
        .collection('orders')
        .orderBy('placedAt', descending: true)
        .get();
    return snap.docs.map((d) => OrderModel.fromMap(d.data())).toList();
  }

  // Master Admin Controls: Usuários & Pagamentos
  static Future<List<Map<String, dynamic>>> fetchAllUsers() async {
    if (_db == null) return [];
    try {
      final snap = await _db!.collection('users').get();
      return snap.docs.map((d) => {'uid': d.id, ...d.data()}).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> setUserBlocked(String uid, bool blocked) async {
    if (_db == null) return;
    await _db!.collection('users').doc(uid).set({
      'isBlocked': blocked,
      'blockedAt': blocked ? FieldValue.serverTimestamp() : null,
    }, SetOptions(merge: true));
  }
}
