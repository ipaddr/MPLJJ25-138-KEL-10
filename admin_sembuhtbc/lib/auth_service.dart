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

  Stream<List<Map<String, dynamic>>> getPendingUsers() {
    return _firestore
        .collection('users')
        .where('isVerified', isEqualTo: false)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => {...doc.data(), 'uid': doc.id})
                  .toList(),
        );
  }

  Future<void> verifyUser(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'isVerified': true,
        'verifiedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error verifying user: $e");
      rethrow;
    }
  }

  Future<void> deleteUser(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).delete();
    } catch (e) {
      print("Error deleting user: $e");
      rethrow;
    }
  }

  // ============== FUNGSI BARU UNTUK MANAJEMEN OBAT OLEH ADMIN ==============

  // Mendapatkan daftar user yang sudah diverifikasi (untuk dipilih admin)
  Stream<List<Map<String, dynamic>>> getVerifiedUsers() {
    return _firestore
        .collection('users')
        .where('isVerified', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) => {
                      'uid': doc.id,
                      'username': doc['username'],
                      'email': doc['email'],
                    },
                  )
                  .toList(),
        );
  }

  // Menyimpan jadwal obat ke sub-koleksi 'medication_schedules' user
  Future<void> addMedicationSchedule({
    required String pasienUid,
    required String medicineName,
    required String medicineType,
    required String dose,
    required int amount,
    required String firstDoseTime, // format "HH:MM AM/PM" atau "HH:MM" (24h)
    required int timesPerDay,
    required int intervalHours,
    required int daysDuration,
    required bool alarmEnabled,
    required String assignedByAdminId,
  }) async {
    try {
      // Menghasilkan daftar waktu minum berdasarkan firstDoseTime, timesPerDay, dan intervalHours
      List<String> scheduledTimes = _calculateDoseTimes(
        firstDoseTime,
        timesPerDay,
        intervalHours,
      );

      await _firestore
          .collection('users')
          .doc(pasienUid)
          .collection('medication_schedules')
          .add({
            'medicineName': medicineName,
            'medicineType': medicineType,
            'dose': dose,
            'amount': amount,
            'firstDoseTime': firstDoseTime,
            'timesPerDay': timesPerDay,
            'intervalHours': intervalHours,
            'daysDuration': daysDuration,
            'alarmEnabled': alarmEnabled,
            'assignedByAdminId': assignedByAdminId,
            'assignedAt': FieldValue.serverTimestamp(),
            'scheduledTimes': scheduledTimes, // Simpan daftar waktu terjadwal
            'isActive': true, // menandakan jadwal aktif
            'startDate': DateTime.now().toIso8601String().substring(
              0,
              10,
            ), // Tanggal mulai hari ini
            'endDate': DateTime.now()
                .add(Duration(days: daysDuration - 1))
                .toIso8601String()
                .substring(0, 10), // Tanggal berakhir
          });
    } catch (e) {
      print("Error adding medication schedule: $e"); // Menggunakan print
      rethrow;
    }
  }

  // Helper untuk menghitung waktu dosis (dipindahkan dari manage_med.dart agar bisa diakses di sini)
  List<String> _calculateDoseTimes(
    String firstDose,
    int timesPerDay,
    int intervalHours,
  ) {
    List<String> doseTimes = [];
    if (firstDose.isEmpty) return doseTimes;

    try {
      int hour;
      int minute;

      // Coba parse 12-hour format "HH:MM AM/PM"
      if (firstDose.contains("AM") || firstDose.contains("PM")) {
        final timeParts = firstDose.split(RegExp(r'[: ]'));
        hour = int.parse(timeParts[0]);
        minute = int.parse(timeParts[1]);
        final period = timeParts[2].toLowerCase();

        if (period == 'pm' && hour != 12) {
          hour += 12;
        } else if (period == 'am' && hour == 12) {
          hour = 0;
        }
      } else {
        // Asumsi format 24-hour "HH:MM"
        final timeParts = firstDose.split(':');
        hour = int.parse(timeParts[0]);
        minute = int.parse(timeParts[1]);
      }

      for (int i = 0; i < timesPerDay; i++) {
        // Handle minute overflow when calculating next hour, then adjust hour
        int currentHour = hour + (minute + i * intervalHours * 60) ~/ 60;
        int currentMinute = (minute + i * intervalHours * 60) % 60;

        currentHour = currentHour % 24; // Ensure hour stays within 0-23

        doseTimes.add(
          "${currentHour.toString().padLeft(2, '0')}:${currentMinute.toString().padLeft(2, '0')}",
        );
      }
    } catch (e) {
      print(
        "Error calculating dose times in AuthService: $e",
      ); // Menggunakan print
    }
    return doseTimes.toSet().toList()
      ..sort(); // Urutkan dan hapus duplikat jika ada
  }
}
