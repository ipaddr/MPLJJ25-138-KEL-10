// Path: user/services/auth_service.dart
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  // Ini adalah AuthService untuk USER
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Login dengan email dan password
  static Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      print('Login error [${e.code}]: ${e.message}');
      return null;
    } catch (e) {
      print('Unexpected login error: $e');
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
      print('Sign out error: $e');
    }
  }

  // Registrasi akun baru
  static Future<UserCredential?> registerWithEmail(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      await credential.user?.sendEmailVerification();
      return credential;
    } on FirebaseAuthException catch (e) {
      print('Register error [${e.code}]: ${e.message}');
      return null;
    } catch (e) {
      print('Unexpected register error: $e');
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

  // ============== FUNGSI BARU UNTUK MEMANTAU STATUS VERIFIKASI DARI FIRESTORE ==============
  static Stream<bool?> isUserVerifiedStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return snapshot.data()?['isVerified'] as bool?;
      }
      return null; // Mengembalikan null jika dokumen tidak ada (mungkin dihapus oleh admin)
    });
  }

  // ====================
  // 🔐 RESET PASSWORD
  // ====================

  // 1. Generate and send 4-digit code to email (using Firestore)
  static Future<bool> sendResetCode(String email) async {
    try {
      final code = (Random().nextInt(9000) + 1000).toString(); // kode 4 digit
      final expiresAt = DateTime.now().add(const Duration(minutes: 10));

      await _firestore.collection('reset_codes').doc(email).set({
        'email': email,
        'expiresAt': DateTime.now().add(const Duration(minutes: 10)), // kadaluarsa 10 menit
      });

      // Kirim kode via email (gunakan extension / backend / SendGrid)
      // → Untuk sekarang hanya cetak ke konsol
      print('Kode verifikasi untuk $email adalah: $code');

      return true;
    } catch (e) {
      print('[AuthService] Gagal mengirim kode verifikasi: $e');
      return false;
    }
  }

  // 2. Verifikasi kode yang dimasukkan user
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

  // 3. Reset password
  static Future<bool> resetPassword(String email, String newPassword) async {
    try {
      // Langkah: login sementara lalu update password (karena Firebase tidak izinkan reset langsung via client)
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      if (methods.contains('password')) {
        // Buat login sementara
        final tempUser = await _auth.signInWithEmailAndPassword(email: email, password: '12345678');
        await tempUser.user?.updatePassword(newPassword);
        return true;
      } else {
        print("Email tidak ditemukan atau tidak valid.");
        return false;
      }
    } catch (e) {
      print('Reset password error: $e');
      return false;
    }
  }
}
