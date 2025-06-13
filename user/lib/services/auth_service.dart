// Path: user/services/auth_service.dart
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============================================================
  // 🔐 LOGIN
  // ============================================================
  static Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user?.uid;
      if (uid == null) {
        print('[AuthService] Gagal mendapatkan UID user.');
        return null;
      }

      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (!userDoc.exists) {
        print('[AuthService] Dokumen user tidak ditemukan di Firestore.');
        return null;
      }

      final isVerified = userDoc.data()?['isVerified'] == true;
      if (!isVerified) {
        print('[AuthService] Akun belum diverifikasi oleh admin.');
        return null;
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      print('Login error [${e.code}]: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unexpected login error: $e');
      rethrow;
    }
  }

  static Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Sign out error: $e');
      rethrow;
    }
  }

  // ============================================================
  // 📝 REGISTER
  // ============================================================
  static Future<UserCredential?> registerWithEmail(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user?.uid;
      if (uid != null) {
        await _firestore.collection('users').doc(uid).set({
          'email': email,
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
      print('Register error [${e.code}]: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unexpected register error: $e');
      rethrow;
    }
  }

  static User? getCurrentUser() => _auth.currentUser;

  static bool isEmailVerified() {
    final user = _auth.currentUser;
    return user?.emailVerified ?? false;
  }

  // ============================================================
  // 🔍 CHECK ADMIN VERIFICATION
  // ============================================================
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
      final code = (Random().nextInt(9000) + 1000).toString(); // kode 4 digit
      final expiresAt = DateTime.now().add(const Duration(minutes: 10));

      await _firestore.collection('reset_codes').doc(email).set({
        'code': code,
        'email': email,
        'expiresAt': DateTime.now().add(const Duration(minutes: 10)),
      });

      // Untuk dev: tampilkan di console
      print('✅ Kode verifikasi untuk $email adalah: $code');

      // Kirim email melalui Firebase Functions atau backend kamu di sini

      return true;
    } catch (e) {
      print('Gagal mengirim kode reset: $e');
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
      print('Verifikasi kode gagal: $e');
      return false;
    }
  }

  static Future<bool> resetPassword(String email, String newPassword) async {
    try {
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      if (!methods.contains('password')) {
        print('[AuthService] Email tidak ditemukan atau tidak valid.');
        return false;
      }

      // Firebase tidak izinkan langsung reset password user lain
      // Solusi workaround: Kirim link reset ke email user
      await _auth.sendPasswordResetEmail(email: email);
      print('[AuthService] Link reset password dikirim ke $email.');

      return true;
    } on FirebaseAuthException catch (e) {
      print('Reset password error [${e.code}]: ${e.message}');
      return false;
    } catch (e) {
      print('Unexpected reset password error: $e');
      return false;
    }
  }

  static Future<bool> isUserVerifiedInFirestore(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc['isVerified'] ?? false;
      }
      return false;
    } catch (e) {
      print("Error checking user verification status in Firestore: $e");
      return false;
    }
  }
}