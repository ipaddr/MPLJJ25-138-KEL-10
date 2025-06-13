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
                  .map(
                    (doc) => {
                      // Pastikan data dikonversi ke Map<String, dynamic> dengan aman
                      ...doc.data() as Map<String, dynamic>,
                      'id': doc.id,
                    },
                  )
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
        // Pastikan docData adalah Map<String, dynamic>
        final Map<String, dynamic> docData = doc.data() as Map<String, dynamic>;
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
      // PERBAIKAN: Cast scheduleData ke Map<String, dynamic>
      final Map<String, dynamic> scheduleData =
          scheduleDoc.data() as Map<String, dynamic>;
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

        // Only consider this schedule if it was active on currentCheckDate
        if (currentCheckDate.isAfter(scheduleEndDate) ||
            currentCheckDate.isBefore(scheduleStartDate)) {
          continue; // Schedule not active on this day
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

    // Track if there's any active schedule for the given date that *requires* doses
    bool hasAnyDosesScheduledForDate = false;

    for (var scheduleDoc in schedulesSnapshot.docs) {
      // PERBAIKAN: Cast scheduleData ke Map<String, dynamic>
      final Map<String, dynamic> scheduleData =
          scheduleDoc.data() as Map<String, dynamic>;
      final String scheduleStartDateStr =
          scheduleData['startDate'] as String? ?? '1970-01-01';
      final String scheduleEndDateStr =
          scheduleData['endDate'] as String? ?? '2999-12-31';

      final DateTime scheduleStartDate = DateTime.parse(scheduleStartDateStr);
      final DateTime scheduleEndDate = DateTime.parse(scheduleEndDateStr);

      // Check if this schedule is active on the given date
      final DateTime dateAtMidnight = DateTime(date.year, date.month, date.day);
      if (dateAtMidnight.isBefore(scheduleStartDate) ||
          dateAtMidnight.isAfter(scheduleEndDate)) {
        continue; // Schedule not active on this specific date
      }

      final List<String> scheduledTimes = List<String>.from(
        scheduleData['scheduledTimes'] ?? [],
      );

      if (scheduledTimes.isEmpty) {
        continue; // No doses scheduled for this specific schedule, so it doesn't prevent completion
      }

      hasAnyDosesScheduledForDate =
          true; // Yes, there are doses scheduled for today

      final takenDosesDoc =
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('medication_schedules')
              .doc(scheduleDoc.id)
              .collection('taken_doses')
              .doc(dateKey)
              .get();

      // PERBAIKAN: Cast dosesStatus ke Map<String, bool>
      final Map<String, bool> dosesStatus =
          (takenDosesDoc.exists && takenDosesDoc.data() != null)
              ? Map<String, bool>.from(takenDosesDoc.data()!['doses'] ?? {})
              : {};

      for (String time in scheduledTimes) {
        if (dosesStatus[time] != true) {
          return false; // Found an untaken dose for an active schedule on this date
        }
      }
    }
    // If we reached here:
    // 1. Either there were NO active schedules for the `date` (hasAnyDosesScheduledForDate is false) -> return true (day is "completed" because no doses were required)
    // 2. Or there were active schedules for the `date` AND all of them were taken -> return true.
    return true; // If no un-taken doses found, return true.
  }

  static Future<int> getConsecutiveDaysCompleted(String userId) async {
    int consecutiveDays = 0;
    DateTime currentDate = DateTime.now();

    currentDate = DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day,
    );

    // Check from today backwards
    // For "consecutive days completed", typically we check for *fully completed days*.
    // If today is not fully completed yet, it breaks the streak starting from today.
    // If the streak is calculated for the most recent completed period,
    // we should iterate backward.

    // Iterasi mundur dari HARI INI
    for (int i = 0; i < 365; i++) {
      // Max 365 days streak check
      final dateToCheck = currentDate.subtract(Duration(days: i));
      final bool allTakenOnThisDay = await areAllDosesTakenForDay(
        userId,
        dateToCheck,
      );

      if (allTakenOnThisDay) {
        consecutiveDays++;
      } else {
        // If today is NOT fully completed, the streak from today breaks.
        // If it's a previous day that is NOT fully completed, the streak also breaks.
        return consecutiveDays; // Return the streak found so far.
      }
    }
    return consecutiveDays; // Return streak if it goes back 365 days
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
      return false; // No schedules, so cannot be completed
    }

    final DateTime now = DateTime.now();
    final DateTime todayAtMidnight = DateTime(now.year, now.month, now.day);

    for (var scheduleDoc in schedulesSnapshot.docs) {
      // PERBAIKAN: Cast scheduleData ke Map<String, dynamic>
      final Map<String, dynamic> scheduleData =
          scheduleDoc.data() as Map<String, dynamic>;
      final String startDateStr =
          scheduleData['startDate'] as String? ?? '1970-01-01';
      final String endDateStr =
          scheduleData['endDate'] as String? ?? '2999-12-31';
      final int timesPerDay = scheduleData['timesPerDay'] as int? ?? 1;

      final DateTime scheduleStartDate = DateTime.parse(startDateStr);
      final DateTime scheduleEndDate = DateTime.parse(endDateStr);

      // Condition for "all medication" - the schedule must have already ended.
      if (scheduleEndDate.isAfter(todayAtMidnight)) {
        // Use todayAtMidnight for comparison
        // If the schedule is still ongoing or ends today, it's not "completed all medication" yet.
        return false;
      }

      int actualTakenDosesForThisSchedule = 0;
      int totalExpectedDosesForThisSchedule = 0;

      // Iterate from schedule start date to schedule end date to count expected and taken doses
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
          // PERBAIKAN: Cast dosesStatus ke Map<String, bool>
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

      // If for this specific *ended* schedule, taken doses don't match expected total, return false.
      if (actualTakenDosesForThisSchedule < totalExpectedDosesForThisSchedule) {
        return false;
      }
    }
    // If all schedules have either not yet started or have ended AND all doses were taken, then true.
    // Also, if there are no schedules, it should return false based on initial check.
    return true;
  }
}
