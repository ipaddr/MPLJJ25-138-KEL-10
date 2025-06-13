import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============================================================
  // 🔐 LOGIN
  // ============================================================
  static Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
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
      print('[AuthService] FirebaseAuthException [${e.code}]: ${e.message}');
      return null;
    } catch (e) {
      print('[AuthService] Unexpected error during login: $e');
      return null;
    }
  }

  // ============================================================
  // 🚪 LOGOUT
  // ============================================================
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
      print('[AuthService] Sign out berhasil.');
    } catch (e) {
      print('[AuthService] Sign out error: $e');
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
      print('[AuthService] FirebaseAuthException [${e.code}]: ${e.message}');
      return null;
    } catch (e) {
      print('[AuthService] Unexpected error during registration: $e');
      return null;
    }
  }

  // ============================================================
  // 👤 GET CURRENT USER
  // ============================================================
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

  // ============================================================
  // 🔑 RESET PASSWORD - SEND 4 DIGIT CODE
  // ============================================================
  static Future<bool> sendResetCode(String email) async {
    try {
      final code = (Random().nextInt(9000) + 1000).toString(); // kode 4 digit
      final expiresAt = DateTime.now().add(const Duration(minutes: 10));

      await _firestore.collection('reset_codes').doc(email).set({
        'email': email,
        'code': code,
        'expiresAt': expiresAt,
      });

      // Untuk dev: tampilkan di console
      print('✅ Kode verifikasi untuk $email adalah: $code');

      // Kirim email melalui Firebase Functions atau backend kamu di sini

      return true;
    } catch (e) {
      print('[AuthService] Gagal mengirim kode verifikasi: $e');
      return false;
    }
  }

  // ============================================================
  // 🔍 VERIFY 4 DIGIT RESET CODE
  // ============================================================
  static Future<bool> verifyResetCode(String email, String inputCode) async {
    try {
      final doc = await _firestore.collection('reset_codes').doc(email).get();
      if (!doc.exists) return false;

      final data = doc.data()!;
      final savedCode = data['code'];
      final expiresAt = (data['expiresAt'] as Timestamp).toDate();

      if (DateTime.now().isAfter(expiresAt)) {
        print('[AuthService] Kode sudah kedaluwarsa.');
        return false;
      }

      return savedCode == inputCode;
    } catch (e) {
      print('[AuthService] Gagal memverifikasi kode: $e');
      return false;
    }
  }

  // ============================================================
  // 🔁 RESET PASSWORD SETELAH KODE TERVERIFIKASI
  // ============================================================
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
    } catch (e) {
      print('[AuthService] Gagal reset password: $e');
      return false;
    }
  }
}
