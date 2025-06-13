// Path: admin_sembuhtbc/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  // Ini adalah AuthService untuk ADMIN
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get userStream => _auth.authStateChanges();

  Future<User?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      rethrow;
    } catch (e) {
      print("Error in signInWithEmailAndPassword (Admin): $e");
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print("Error in signOut (Admin): $e");
      rethrow;
    }
  }

  Future<void> updateAdminProfile({
    required String uid,
    required String username,
    required String gender,
    required DateTime birthDate,
    String? profilePictureBase64,
  }) async {
    try {
      final adminRef = _firestore.collection('admins').doc(uid);
      final doc = await adminRef.get();

      if (!doc.exists) {
        await adminRef.set({
          'username': username,
          'gender': gender,
          'birthDate': birthDate.toIso8601String(),
          'profilePictureBase64': profilePictureBase64,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await adminRef.update({
          'username': username,
          'gender': gender,
          'birthDate': birthDate.toIso8601String(),
          'profilePictureBase64': profilePictureBase64,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print("Error in updateAdminProfile: $e");
      rethrow;
    }
  }

  Future<void> createAdminProfileIfNotExists(String uid, String email) async {
    try {
      final doc = await _firestore.collection('admins').doc(uid).get();
      if (!doc.exists) {
        await _firestore.collection('admins').doc(uid).set({
          'email': email,
          'username': email.split('@').first,
          'gender': 'Perempuan',
          'birthDate': DateTime(2000, 1, 1).toIso8601String(),
          'profilePictureBase64': '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print("Error in createAdminProfileIfNotExists: $e");
      rethrow;
    }
  }

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  Future<Map<String, dynamic>?> getAdminProfile(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('admins').doc(uid).get();
      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      print("Error in getAdminProfile: $e");
      rethrow;
    }
  }

  // ============== FUNGSI UNTUK VERIFIKASI AKUN PASIEN (DIJALANKAN OLEH ADMIN) ==============

  // Mendapatkan daftar user dengan 'isVerified: false'
  Stream<List<Map<String, dynamic>>> getPendingUsers() {
    return _firestore
        .collection('users')
        .where('isVerified', isEqualTo: false) // Menggunakan 'isVerified'
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) => {
                      ...doc.data(),
                      'uid': doc.id, // Menambahkan UID dari document ID
                    },
                  )
                  .toList(),
        );
  }

  // Mengubah status user menjadi 'isVerified: true'
  Future<void> verifyUser(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'isVerified': true, // Mengubah 'isVerified' menjadi true
        'verifiedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error verifying user: $e");
      rethrow;
    }
  }

  // Menghapus user dari Firestore (untuk penolakan)
  Future<void> deleteUser(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).delete();
      // Perhatikan: Menghapus akun Firebase Auth dari sisi client untuk user lain sangat tidak disarankan
      // dan hampir tidak mungkin tanpa Admin SDK atau otentikasi ulang yang rumit.
      // Cukup hapus data di Firestore saja jika memang ingin user tersebut tidak terdaftar di aplikasi.
    } catch (e) {
      print("Error deleting user: $e");
      rethrow;
    }
  }
}
