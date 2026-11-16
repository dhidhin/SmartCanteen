import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserModel?> getUserModel(String uid) async {
    try {
      final doc =
          await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
    } catch (e) {
      debugPrint('Error getting user model: $e');
    }
    return null;
  }

  Future<UserModel?> register({
    required String email,
    required String password,
    required String nama,
    required String role,
    String kelas = '',
    String namaStand = '',
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user!.uid;
    final fcmToken = await _getFcmToken();

    final user = UserModel(
      uid: uid,
      nama: nama,
      email: email,
      role: role,
      kelas: kelas,
      namaStand: namaStand,
      fcmToken: fcmToken,
    );

    await _firestore.collection('users').doc(uid).set(user.toMap());
    return user;
  }

  Future<UserModel?> login({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user!.uid;

    // Update FCM token setiap login
    final fcmToken = await _getFcmToken();
    if (fcmToken.isNotEmpty) {
      await _firestore.collection('users').doc(uid).update({
        'fcmToken': fcmToken,
      });
    }

    return getUserModel(uid);
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<void> updateNamaStand(String uid, String namaStand) async {
    await _firestore.collection('users').doc(uid).update({
      'namaStand': namaStand,
    });

    // Sinkronkan nama stand ke semua menu milik penjual ini
    try {
      final snap = await _firestore
          .collection('menus')
          .where('penjualId', isEqualTo: uid)
          .get();
      final batch = _firestore.batch();
      for (final doc in snap.docs) {
        batch.update(doc.reference, {'namaStand': namaStand});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Warning syncing stand name to menus: $e');
    }
  }

  Future<String> _getFcmToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      return token ?? '';
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return '';
    }
  }
}
