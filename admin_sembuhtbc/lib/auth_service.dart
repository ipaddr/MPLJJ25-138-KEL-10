import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream untuk memantau perubahan status autentikasi
  Stream<User?> get userStream => _auth.authStateChanges();

  // Sign in with email and password
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
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // Update admin profile
  Future<void> updateAdminProfile({
    required String uid,
    required String username,
    required String gender,
    required DateTime birthDate,
    String? profilePictureBase64, // Ganti dari profilePictureUrl
  }) async {
    try {
      final adminRef = _firestore.collection('admins').doc(uid);
      final doc = await adminRef.get();

      if (!doc.exists) {
        // Jika dokumen tidak ada, buat baru
        await adminRef.set({
          'username': username,
          'gender': gender,
          'birthDate': birthDate.toIso8601String(),
          'profilePictureBase64': profilePictureBase64, // Simpan sebagai base64
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Jika dokumen ada, lakukan update
        await adminRef.update({
          'username': username,
          'gender': gender,
          'birthDate': birthDate.toIso8601String(),
          'profilePictureBase64': profilePictureBase64, // Update field base64
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
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
          'profilePictureBase64': '', // Defaultkan sebagai string kosong
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Fetch admin profile data
  Future<Map<String, dynamic>?> getAdminProfile(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('admins').doc(uid).get();
      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      rethrow;
    }
  }
}
