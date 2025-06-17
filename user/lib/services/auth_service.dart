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
        'gender': 'Perempuan', // <-- PERUBAHAN UTAMA: Nilai default yang valid
        'birthDate': DateTime(2000, 1, 1).toIso8601String(),
        'isVerified': false,
        'profilePictureUrl': '',
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'rewards': {
          'minumObat2Hari2KaliClaimed': false,
          'minumObatSemingguPenuhClaimed': false,
          'minumObatTanpaPutusClaimed': false,
          'minumObatSampaiHabisClaimed': false,
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

  static Future<void> sendPasswordResetEmail(String email) async {
    try {
      // Firebase akan secara internal memeriksa apakah email ada
      // dan mengirimkan link reset jika ada. Ini lebih aman.
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      // Lempar kembali exception dari Firebase agar bisa ditangani di UI
      // dengan pesan yang lebih spesifik.
      throw e;
    } catch (e) {
      // Menangani error tak terduga lainnya.
      throw Exception('Terjadi kesalahan tidak terduga: ${e.toString()}');
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

      if (doc.exists && doc.data() != null) {
        final Map<String, dynamic> docData = doc.data()!;
        if (docData['doses'] is Map) {
          return Map<String, bool>.from(docData['doses']!);
        }
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

        // Menggunakan tz.TZDateTime.now(tz.local) untuk perbandingan zona waktu yang benar
        if (time.isBefore(tz.TZDateTime.now(tz.local))) {
          time = time.add(const Duration(days: 1)); // Jadwalkan untuk hari berikutnya jika sudah lewat
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

        // Perbandingan juga menggunakan tz.TZDateTime.now(tz.local)
        if (notificationDateTime.isAfter(tz.TZDateTime.now(tz.local))) {
          await localNotificationsPlugin.zonedSchedule(
            '$id-$day-$i'.hashCode,
            'Waktunya minum obat!',
            'Anda punya jadwal minum $medicineName ($doseTime) sekarang.',
            notificationDateTime,
            platformChannelSpecifics,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            // >>>>>>>>> BARIS INI DIHAPUS <<<<<<<<<
            // uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
            // >>>>>>>>> BARIS INI DIHAPUS <<<<<<<<<
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

  static Stream<Map<String, dynamic>> getUserRewards(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((
      snapshot,
    ) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data();
        return Map<String, dynamic>.from(data?['rewards'] ?? {});
      }
      return {};
    });
  }

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();
      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      print("Error getting user profile: $e");
      rethrow;
    }
  }

  Future<void> updateUserProfile({
    required String uid,
    required String username,
    required String gender,
    required DateTime birthDate,
    required String profilePictureBase64,
  }) async {
    try {
      final userRef = _firestore.collection('users').doc(uid);
      final doc = await userRef.get();

      if (!doc.exists) {
        await userRef.set({
          'username': username,
          'gender': gender,
          'birthDate': birthDate.toIso8601String(),
          'profilePictureBase64': profilePictureBase64,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await userRef.update({
          'username': username,
          'gender': gender,
          'birthDate': birthDate.toIso8601String(),
          'profilePictureBase64': profilePictureBase64,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print("Error updating user profile: $e");
      rethrow;
    }
  }

  Future<void> createUserProfileIfNotExists(String uid, String email) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) {
        await _firestore.collection('users').doc(uid).set({
          'email': email,
          'username': email.split('@').first,
          'gender': 'Perempuan',
          'birthDate': DateTime(2000, 1, 1).toIso8601String(),
          'profilePictureBase64': '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print("Error creating user profile: $e");
      rethrow;
    }
  }

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

  static Future<Map<String, int>> getDosesTakenStats({
    required String userId,
    required int daysAgo,
  }) async {
    final DateTime now = DateTime.now();
    final DateTime startOfDay = DateTime(now.year, now.month, now.day);
    final DateTime checkStartDate = startOfDay.subtract(
      Duration(days: daysAgo - 1),
    );

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
      final Map<String, dynamic> scheduleData = scheduleDoc.data();
      final List<String> scheduledTimes = List<String>.from(
        scheduleData['scheduledTimes'] ?? [],
      );

      final String scheduleStartDateStr =
          scheduleData['startDate'] as String? ?? '1970-01-01';
      final String scheduleEndDateStr =
          scheduleData['endDate'] as String? ?? '2999-12-31';

      final DateTime scheduleStartDate = DateTime.parse(scheduleStartDateStr);
      final DateTime scheduleEndDate = DateTime.parse(scheduleEndDateStr);

      for (int i = 0; i < daysAgo; i++) {
        final currentCheckDate = checkStartDate.add(Duration(days: i));
        final String dateKey = DateFormat(
          'yyyy-MM-dd',
        ).format(currentCheckDate);

        if (currentCheckDate.isAfter(scheduleEndDate) ||
            currentCheckDate.isBefore(scheduleStartDate)) {
          continue;
        }

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

        totalDosesInPeriod += scheduledTimes.length;
        dosesStatus.forEach((time, isTaken) {
          if (isTaken) {
            takenDosesInPeriod++;
          }
        });
      }
    }

    return {'taken': takenDosesInPeriod, 'total': totalDosesInPeriod};
  }

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

    // ignore: unused_local_variable
    bool hasAnyDosesScheduledForDate = false;

    for (var scheduleDoc in schedulesSnapshot.docs) {
      final Map<String, dynamic> scheduleData = scheduleDoc.data();
      final String scheduleStartDateStr =
          scheduleData['startDate'] as String? ?? '1970-01-01';
      final String scheduleEndDateStr =
          scheduleData['endDate'] as String? ?? '2999-12-31';

      final DateTime scheduleStartDate = DateTime.parse(scheduleStartDateStr);
      final DateTime scheduleEndDate = DateTime.parse(scheduleEndDateStr);

      final DateTime dateAtMidnight = DateTime(date.year, date.month, date.day);
      if (dateAtMidnight.isBefore(scheduleStartDate) ||
          dateAtMidnight.isAfter(scheduleEndDate)) {
        continue;
      }

      final List<String> scheduledTimes = List<String>.from(
        scheduleData['scheduledTimes'] ?? [],
      );

      if (scheduledTimes.isEmpty) continue;

      hasAnyDosesScheduledForDate = true;

      final takenDosesDoc =
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('medication_schedules')
              .doc(scheduleDoc.id)
              .collection('taken_doses')
              .doc(dateKey)
              .get();

      final Map<String, bool> dosesStatus =
          (takenDosesDoc.exists && takenDosesDoc.data() != null)
              ? Map<String, bool>.from(takenDosesDoc.data()!['doses'] ?? {})
              : {};

      for (String time in scheduledTimes) {
        if (dosesStatus[time] != true) {
          return false;
        }
      }
    }
    return true;
  }

  static Future<int> getConsecutiveDaysCompleted(String userId) async {
    int consecutiveDays = 0;
    DateTime currentDate = DateTime.now();

    currentDate = DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day,
    );

    for (int i = 0; i < 365; i++) {
      final dateToCheck = currentDate.subtract(Duration(days: i));
      final bool allTakenOnThisDay = await areAllDosesTakenForDay(
        userId,
        dateToCheck,
      );

      if (allTakenOnThisDay) {
        consecutiveDays++;
      } else {
        return consecutiveDays;
      }
    }
    return consecutiveDays;
  }

  static Future<bool> hasCompletedConsecutiveDays(
    String userId,
    int requiredDays,
  ) async {
    final int consecutive = await getConsecutiveDaysCompleted(userId);
    return consecutive >= requiredDays;
  }

  static Future<bool> hasCompletedAllMedication(String userId) async {
    final schedulesSnapshot =
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('medication_schedules')
            .where('isActive', isEqualTo: true)
            .get();

    if (schedulesSnapshot.docs.isEmpty) {
      return false;
    }

    final DateTime now = DateTime.now();
    final DateTime todayAtMidnight = DateTime(now.year, now.month, now.day);

    for (var scheduleDoc in schedulesSnapshot.docs) {
      final Map<String, dynamic> scheduleData = scheduleDoc.data();
      final String startDateStr =
          scheduleData['startDate'] as String? ?? '1970-01-01';
      final String endDateStr =
          scheduleData['endDate'] as String? ?? '2999-12-31';

      final DateTime scheduleStartDate = DateTime.parse(startDateStr);
      final DateTime scheduleEndDate = DateTime.parse(endDateStr);

      if (scheduleEndDate.isAfter(todayAtMidnight)) {
        return false;
      }

      int actualTakenDosesForThisSchedule = 0;
      int totalExpectedDosesForThisSchedule = 0;

      for (
        DateTime d = scheduleStartDate;
        d.isBefore(scheduleEndDate.add(const Duration(days: 1)));
        d = d.add(const Duration(days: 1))
      ) {
        final String dateKey = DateFormat('yyyy-MM-dd').format(d);
        final List<String> scheduledTimes = List<String>.from(
          scheduleData['scheduledTimes'] ?? [],
        );
        totalExpectedDosesForThisSchedule += scheduledTimes.length;

        final takenDosesDoc =
            await _firestore
                .collection('users')
                .doc(userId)
                .collection('medication_schedules')
                .doc(scheduleDoc.id)
                .collection('taken_doses')
                .doc(dateKey)
                .get();

        if (takenDosesDoc.exists && takenDosesDoc.data() != null) {
          final Map<String, bool> dosesStatus = Map<String, bool>.from(
            takenDosesDoc.data()!['doses'] ?? {},
          );
          dosesStatus.forEach((time, isTaken) {
            if (isTaken) {
              actualTakenDosesForThisSchedule++;
            }
          });
        }
      }

      if (actualTakenDosesForThisSchedule < totalExpectedDosesForThisSchedule) {
        return false;
      }
    }

    return true;
  }
}
