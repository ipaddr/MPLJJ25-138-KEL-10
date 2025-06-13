<<<<<<< HEAD
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

  static Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Sign out error: $e');
      rethrow;
    }
  }

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

      await _firestore.collection('users').doc(credential.user!.uid).set({
        'email': email,
        'username': username,
        'gender': 'unknown',
        'birthDate': DateTime(2000, 1, 1).toIso8601String(),
        'isVerified': false,
        'profilePictureUrl': '',
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'rewards': {
          // Inisialisasi field rewards
          'minumObat2Hari2KaliClaimed': false,
          'minumObatSemingguPenuhClaimed': false,
          // Tambahkan reward lainnya di sini
        },
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

  static User? getCurrentUser() => _auth.currentUser;

  static bool isEmailVerified() {
    final user = _auth.currentUser;
    return user?.emailVerified ?? false;
  }

  static Stream<bool?> isUserVerifiedStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return snapshot.data()?['isVerified'] as bool?;
      }
      return null;
    });
  }

  static Future<bool> sendResetCode(String email) async {
    try {
      final code = (Random().nextInt(9000) + 1000).toString();

      await _firestore.collection('reset_codes').doc(email).set({
        'code': code,
        'email': email,
        'expiresAt': DateTime.now().add(const Duration(minutes: 10)),
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

  static Stream<List<Map<String, dynamic>>> getMedicationSchedules(
    String userId,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('medication_schedules')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => {...doc.data(), 'id': doc.id})
                  .toList(),
        );
  }

  static Future<void> updateDoseTakenStatus({
    required String userId,
    required String scheduleId,
    required String doseTime,
    required DateTime date,
    required bool isTaken,
  }) async {
    try {
      String dateKey = DateFormat('yyyy-MM-dd').format(date);

      final takenDoseRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('medication_schedules')
          .doc(scheduleId)
          .collection('taken_doses')
          .doc(dateKey);

      await takenDoseRef.set({
        'doses': {doseTime: isTaken},
        'takenAt': {doseTime: FieldValue.serverTimestamp()},
      }, SetOptions(merge: true));
    } catch (e) {
      print("Error updating dose taken status: $e");
      rethrow;
    }
  }

  static Future<Map<String, bool>> getDoseTakenStatus({
    required String userId,
    required String scheduleId,
    required DateTime date,
  }) async {
    try {
      String dateKey = DateFormat('yyyy-MM-dd').format(date);
      final doc =
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('medication_schedules')
              .doc(scheduleId)
              .collection('taken_doses')
              .doc(dateKey)
              .get();

      if (doc.exists && doc.data() != null && doc.data()!['doses'] is Map) {
        return Map<String, bool>.from(doc.data()!['doses']);
      }
      return {};
    } catch (e) {
      print("Error getting dose taken status: $e");
      return {};
    }
  }

  static Future<void> scheduleMedicationNotification({
    required FlutterLocalNotificationsPlugin localNotificationsPlugin,
    required String id,
    required String medicineName,
    required String doseTime,
    required int timesPerDay,
    required int intervalHours,
    required int daysDuration,
    required DateTime startDate,
    required bool alarmEnabled,
  }) async {
    if (!alarmEnabled) return;

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'medication_channel',
          'Pengingat Obat SembuhTBC',
          channelDescription: 'Pengingat untuk minum obat TB sesuai jadwal',
          importance: Importance.max,
          priority: Priority.high,
          sound: const RawResourceAndroidNotificationSound('res_custom_sound'),
        );
    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(sound: 'custom_sound.aiff');

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    List<DateTime> scheduledTimes = [];
    try {
      final timeParts = doseTime.split(':');
      final int hour = int.parse(timeParts[0]);
      final int minute = int.parse(timeParts[1]);

      for (int i = 0; i < timesPerDay; i++) {
        DateTime time = DateTime(
          startDate.year,
          startDate.month,
          startDate.day,
          hour,
          minute,
        );

        time = time.add(Duration(hours: i * intervalHours));

        if (time.isBefore(DateTime.now())) {
          time = time.add(const Duration(days: 1));
        }
        scheduledTimes.add(time);
      }
    } catch (e) {
      print("Error calculating notification times: $e");
      return;
    }

    for (int day = 0; day < daysDuration; day++) {
      final currentDay = startDate.add(Duration(days: day));
      for (int i = 0; i < scheduledTimes.length; i++) {
        final scheduledTime = scheduledTimes[i];

        final notificationDateTime = tz.TZDateTime(
          tz.local,
          currentDay.year,
          currentDay.month,
          currentDay.day,
          scheduledTime.hour,
          scheduledTime.minute,
          scheduledTime.second,
        );

        if (notificationDateTime.isAfter(tz.TZDateTime.now(tz.local))) {
          await localNotificationsPlugin.zonedSchedule(
            '$id-$day-$i'.hashCode,
            'Waktunya minum obat!',
            'Anda punya jadwal minum $medicineName ($doseTime) sekarang.',
            notificationDateTime,
            platformChannelSpecifics,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            payload: '$id|${doseTime}|$medicineName',
          );
          print(
            "Scheduled: $medicineName at $notificationDateTime (ID: ${'$id-$day-$i'.hashCode})",
          );
        }
      }
    }
    print("Jadwal notifikasi untuk $medicineName telah dibuat.");
  }

  static Future<void> cancelMedicationNotifications({
    required FlutterLocalNotificationsPlugin localNotificationsPlugin,
    required String scheduleId,
  }) async {
    print(
      "Placeholder for canceling notifications for scheduleId: $scheduleId",
    );
  }

  // ============== FUNGSI BARU UNTUK REWARD ==============

  // Mendapatkan status reward user
  static Stream<Map<String, dynamic>> getUserRewards(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((
      snapshot,
    ) {
      if (snapshot.exists && snapshot.data() != null) {
        return (snapshot.data()!['rewards'] ?? {}) as Map<String, dynamic>;
      }
      return {};
    });
  }

  // Mengupdate status klaim reward
  static Future<void> updateRewardClaimStatus(
    String userId,
    String rewardKey,
    bool claimedStatus,
  ) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'rewards.$rewardKey': claimedStatus,
      });
    } catch (e) {
      print("Error updating reward claim status: $e");
      rethrow;
    }
  }

  // Mendapatkan jumlah dosis diminum dalam X hari terakhir
  static Future<Map<String, int>> getDosesTakenStats({
    required String userId,
    required int daysAgo, // Misal 2 untuk "2 hari terakhir"
  }) async {
    final DateTime now = DateTime.now();
    final DateTime startDate = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: daysAgo - 1)); // Hitung dari X hari yang lalu

    int totalDosesInPeriod = 0;
    int takenDosesInPeriod = 0;

    final schedulesSnapshot =
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('medication_schedules')
            .where('isActive', isEqualTo: true)
            .get();

    for (var scheduleDoc in schedulesSnapshot.docs) {
      final scheduleId = scheduleDoc.id;
      final scheduleData = scheduleDoc.data();
      final List<String> scheduledTimes = List<String>.from(
        scheduleData['scheduledTimes'] ?? [],
      );

      for (int i = 0; i < daysAgo; i++) {
        // Iterasi untuk setiap hari dalam periode
        final currentCheckDate = startDate.add(Duration(days: i));
        final dateKey = DateFormat('yyyy-MM-dd').format(currentCheckDate);

        final takenDosesDoc =
            await _firestore
                .collection('users')
                .doc(userId)
                .collection('medication_schedules')
                .doc(scheduleId)
                .collection('taken_doses')
                .doc(dateKey)
                .get();

        if (takenDosesDoc.exists && takenDosesDoc.data() != null) {
          final Map<String, bool> dosesStatus = Map<String, bool>.from(
            takenDosesDoc.data()!['doses'] ?? {},
          );

          totalDosesInPeriod +=
              scheduledTimes
                  .length; // Setiap jadwal memiliki sejumlah dosis per hari
          dosesStatus.forEach((time, isTaken) {
            if (isTaken) {
              takenDosesInPeriod++;
            }
          });
        } else {
          // Jika dokumen taken_doses tidak ada, berarti tidak ada obat yang diminum untuk jadwal ini di tanggal tersebut.
          totalDosesInPeriod += scheduledTimes.length;
        }
      }
    }
    return {'taken': takenDosesInPeriod, 'total': totalDosesInPeriod};
  }

  // Metode untuk memeriksa apakah semua dosis pada hari tertentu telah diminum
  static Future<bool> areAllDosesTakenForDay(
    String userId,
    DateTime date,
  ) async {
    final String dateKey = DateFormat('yyyy-MM-dd').format(date);

    final schedulesSnapshot =
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('medication_schedules')
            .where('isActive', isEqualTo: true)
            .get();

    if (schedulesSnapshot.docs.isEmpty) {
      return false; // Tidak ada jadwal obat, jadi tidak ada yang bisa diselesaikan
    }

    for (var scheduleDoc in schedulesSnapshot.docs) {
      final scheduleId = scheduleDoc.id;
      final List<String> scheduledTimes = List<String>.from(
        scheduleDoc.data()['scheduledTimes'] ?? [],
      );

      if (scheduledTimes.isEmpty)
        continue; // Lewati jika tidak ada waktu terjadwal

      final takenDosesDoc =
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('medication_schedules')
              .doc(scheduleId)
              .collection('taken_doses')
              .doc(dateKey)
              .get();

      final Map<String, bool> dosesStatus =
          (takenDosesDoc.exists && takenDosesDoc.data() != null)
              ? Map<String, bool>.from(takenDosesDoc.data()!['doses'] ?? {})
              : {};

      for (String time in scheduledTimes) {
        if (dosesStatus[time] != true) {
          return false; // Ada dosis yang belum diminum
        }
      }
    }
    return true; // Semua dosis telah diminum untuk hari itu
  }

  // Mendapatkan jumlah hari berturut-turut di mana semua dosis diminum
  static Future<int> getConsecutiveDaysCompleted(String userId) async {
    int consecutiveDays = 0;
    DateTime currentDate = DateTime.now();
    // Start from yesterday to check if 'today' is complete.
    // If 'today' needs to be complete, then loop from current date backward.
    // For "minum obat seminggu penuh", it needs to check last 7 days.
    // Let's assume "consecutive" means starting from the most recent full day.

    // Adjust current date to midnight for consistent comparison
    currentDate = DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day,
    );

    // Check from today backwards
    for (int i = 0; i < 365; i++) {
      // Check up to a year back, adjust as needed
      final dateToCheck = currentDate.subtract(Duration(days: i));
      final bool allTaken = await areAllDosesTakenForDay(userId, dateToCheck);

      if (allTaken) {
        consecutiveDays++;
      } else {
        // If current day is not complete AND it's not the very first day being checked,
        // it means the streak is broken.
        if (i > 0) {
          // Only break if it's not today and today isn't finished
          break;
        } else {
          // If today is not complete, the streak is 0 if no prior days completed
          if (!allTaken && consecutiveDays == 0)
            return 0; // If today is not complete, streak starts from 0 for today.
        }
      }
    }
    return consecutiveDays;
  }
}
=======
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
>>>>>>> 218be8392ac25805bbed300cbbb884f7cf3eedad
