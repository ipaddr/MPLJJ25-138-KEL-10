// Path: user/services/auth_service.dart
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  // Ini adalah AuthService untuk USER
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Login dengan email dan password
  static Future<UserCredential?> signInWithEmail(
    String email,
    String password,
  ) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      print('Login error [${e.code}]: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unexpected login error: $e');
      rethrow;
    }
  }

  // Logout
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Sign out error: $e');
      rethrow;
    }
  }

  // Registrasi akun baru (dimodifikasi untuk menyimpan ke Firestore)
  static Future<UserCredential?> registerWithEmail(
    String email,
    String password,
    String username,
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Simpan data user ke Firestore setelah berhasil daftar di Firebase Auth
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'email': email,
        'username': username,
        'gender': 'unknown', // Default, bisa disesuaikan di UI register user
        'birthDate':
            DateTime(2000, 1, 1).toIso8601String(), // Default, bisa disesuaikan
        'isVerified': false, // Status awal: belum diverifikasi
        'profilePictureUrl': '', // Kosong dulu, atau default avatar
        'role': 'user', // Role untuk user/pasien
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(), // Initial update timestamp
      });

      return credential;
    } on FirebaseAuthException catch (e) {
      print('Register error [${e.code}]: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unexpected register error: $e');
      rethrow;
    }
  }

  // Mendapatkan user saat ini
  static User? getCurrentUser() => _auth.currentUser;

  // Cek verifikasi email
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

  static Future<bool> sendResetCode(String email) async {
    try {
      final code = (Random().nextInt(9000) + 1000).toString(); // 4-digit

      await _firestore.collection('reset_codes').doc(email).set({
        'code': code,
        'email': email,
        'expiresAt': DateTime.now().add(
          const Duration(minutes: 10),
        ), // kadaluarsa 10 menit
      });

      print('Kode verifikasi untuk $email adalah: $code');
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
      await _auth.sendPasswordResetEmail(email: email);
      print('Email reset password telah dikirim ke $email');
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
