import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user?.uid;
      if (uid == null) return null;

      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (!userDoc.exists || userDoc.data()?['isVerified'] != true) {
        return null;
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      print('[AuthService] FirebaseAuthException [${e.code}]: ${e.message}');
      return null;
    } catch (e) {
      print('[AuthService] Unexpected error during login: $e');
      return null;
    }
  }

  static Future<void> signOut() async {
    try {
      await _auth.signOut();
      print('[AuthService] Sign out berhasil.');
    } catch (e) {
      print('[AuthService] Sign out error: $e');
    }
  }

  // ✅ Fungsi ini sudah diperbaiki untuk menerima parameter `name`
  static Future<UserCredential?> registerWithEmail(String email, String password, String name) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user?.uid;
      if (uid != null) {
        await _firestore.collection('users').doc(uid).set({
          'email': email,
          'name': name, // ✅ Simpan nama ke Firestore
          'username': '',
          'birthdate': null,
          'gender': '',
          'profilePictureUrl': '',
          'role': 'user',
          'isVerified': false,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print('[AuthService] User registered dan disimpan ke Firestore.');
      }

      await credential.user?.sendEmailVerification();
      return credential;
    } on FirebaseAuthException catch (e) {
      print('[AuthService] FirebaseAuthException [${e.code}]: ${e.message}');
      return null;
    } catch (e) {
      print('[AuthService] Unexpected error during registration: $e');
      return null;
    }
  }

  static User? getCurrentUser() => _auth.currentUser;

  static bool isEmailVerified() {
    final user = _auth.currentUser;
    return user?.emailVerified ?? false;
  }

  static Future<bool> isUserVerifiedByAdmin(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.exists && doc.data()?['isVerified'] == true;
    } catch (e) {
      print('[AuthService] Error checking admin verification: $e');
      return false;
    }
  }

  static Future<bool> sendResetCode(String email) async {
    try {
      final code = (Random().nextInt(9000) + 1000).toString();
      final expiresAt = DateTime.now().add(const Duration(minutes: 10));

      await _firestore.collection('reset_codes').doc(email).set({
        'email': email,
        'code': code,
        'expiresAt': expiresAt,
      });

      print('✅ Kode verifikasi untuk $email adalah: $code');
      return true;
    } catch (e) {
      print('[AuthService] Gagal mengirim kode verifikasi: $e');
      return false;
    }
  }

  static Future<bool> verifyResetCode(String email, String inputCode) async {
    try {
      final doc = await _firestore.collection('reset_codes').doc(email).get();
      if (!doc.exists) return false;

      final data = doc.data()!;
      final savedCode = data['code'];
      final expiresAt = (data['expiresAt'] as Timestamp).toDate();

      if (DateTime.now().isAfter(expiresAt)) return false;

      return savedCode == inputCode;
    } catch (e) {
      print('[AuthService] Gagal memverifikasi kode: $e');
      return false;
    }
  }

  static Future<bool> resetPassword(String email, String newPassword) async {
    try {
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      if (!methods.contains('password')) return false;

      await _auth.sendPasswordResetEmail(email: email);
      print('[AuthService] Link reset password dikirim ke $email.');
      return true;
    } catch (e) {
      print('[AuthService] Gagal reset password: $e');
      return false;
    }
  }
}
