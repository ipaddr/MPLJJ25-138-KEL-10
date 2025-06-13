import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:user/services/auth_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // Import this
import '../main.dart'; // Import main.dart to access flutterLocalNotificationsPlugin

import 'profile_user.dart';
import 'reward_page.dart';
import 'med_info_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final User? _currentUser = AuthService.getCurrentUser();
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (_currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      });
    }
    Intl.defaultLocale = 'id_ID'; // Set locale once
  }

  // Fungsi untuk menandai obat sudah diminum (tetap sama)
  void _markDoseTaken({
    required String scheduleId,
    required String doseTime,
    required bool isTaken,
  }) async {
    if (_currentUser == null) return;
    try {
      await AuthService.updateDoseTakenStatus(
        userId: _currentUser!.uid,
        scheduleId: scheduleId,
        doseTime: doseTime,
        date: _selectedDate,
        isTaken: isTaken,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isTaken
                ? 'Obat berhasil ditandai diminum!'
                : 'Status obat dibatalkan.',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: isTaken ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal memperbarui status obat: $e',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Fungsi untuk menjadwalkan ulang semua notifikasi
  void _rescheduleAllNotifications(List<Map<String, dynamic>> schedules) async {
    if (_currentUser == null) return;

    // Batalkan semua notifikasi yang mungkin sudah ada untuk user ini
    await flutterLocalNotificationsPlugin
        .cancelAll(); // Assuming access to global instance

    for (var schedule in schedules) {
      final String scheduleId = schedule['id'];
      final String medicineName = schedule['medicineName'];
      final String dose = schedule['dose']; // Dosis penuh
      final String medicineType = schedule['medicineType'];
      final String firstDoseTime = schedule['firstDoseTime'];
      final int timesPerDay = schedule['timesPerDay'];
      final int intervalHours = schedule['intervalHours'];
      final int daysDuration = schedule['daysDuration'];
      final bool alarmEnabled = schedule['alarmEnabled'];
      final DateTime startDate = DateTime.parse(
        schedule['startDate'],
      ); // Pastikan ini DateTime

      await AuthService.scheduleMedicationNotification(
        localNotificationsPlugin:
            flutterLocalNotificationsPlugin, // Pass the plugin instance
        id: scheduleId,
        medicineName: medicineName,
        doseTime: firstDoseTime, // Waktu dosis pertama (HH:MM)
        timesPerDay: timesPerDay,
        intervalHours: intervalHours,
        daysDuration: daysDuration,
        startDate: startDate,
        alarmEnabled: alarmEnabled,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            const Text(
              'Hari ini',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.emoji_emotions, color: Colors.amber),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RewardPage()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.person_outline, color: Colors.black),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileUserPage()),
                );
              },
            ),
          ],
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: AuthService.getMedicationSchedules(_currentUser!.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                "Belum ada jadwal obat yang diberikan oleh admin.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final List<Map<String, dynamic>> schedules = snapshot.data!;

          // Panggil penjadwalan notifikasi setiap kali stream diperbarui
          // Ini mungkin dipicu terlalu sering, pertimbangkan debounce atau panggil hanya saat initState
          // Untuk demo, ini cukup. Untuk production, pikirkan trigger yang lebih cerdas.
          _rescheduleAllNotifications(schedules);

          final today = DateFormat('yyyy-MM-dd').format(_selectedDate);
          final activeSchedulesToday =
              schedules.where((schedule) {
                final startDate = schedule['startDate'] as String?;
                final endDate = schedule['endDate'] as String?;

                if (startDate == null || endDate == null) return false;

                return today.compareTo(startDate) >= 0 &&
                    today.compareTo(endDate) <= 0;
              }).toList();

          List<Map<String, dynamic>> scheduledDosesToday = [];
          for (var schedule in activeSchedulesToday) {
            List<String> times = List<String>.from(
              schedule['scheduledTimes'] ?? [],
            );
            for (var time in times) {
              scheduledDosesToday.add({
                'scheduleId': schedule['id'],
                'medicineName': schedule['medicineName'],
                'dose': schedule['dose'],
                'medicineType': schedule['medicineType'],
                'displayTime': time,
              });
            }
          }

          scheduledDosesToday.sort((a, b) {
            final timeA = DateFormat('HH:mm').parse(a['displayTime']);
            final timeB = DateFormat('HH:mm').parse(b['displayTime']);
            return timeA.compareTo(timeB);
          });

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 70,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 7,
                    itemBuilder: (context, index) {
                      final currentDay = DateTime.now().add(
                        Duration(days: index),
                      ); // Menampilkan hari ini dan 6 hari ke depan
                      final isSelected = DateUtils.isSameDay(
                        currentDay,
                        _selectedDate,
                      );

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedDate = currentDay;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Column(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color:
                                      isSelected
                                          ? const Color(0xFF0072CE)
                                          : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color:
                                        isSelected
                                            ? const Color(0xFF0072CE)
                                            : Colors.grey.shade300,
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      currentDay.day.toString(),
                                      style: TextStyle(
                                        color:
                                            isSelected
                                                ? Colors.white
                                                : Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      DateFormat(
                                        'EEE',
                                        'id_ID',
                                      ).format(currentDay),
                                      style: TextStyle(
                                        color:
                                            isSelected
                                                ? Colors.white
                                                : Colors.black,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                const Center(
                  child: Text(
                    'Diminum',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
                FutureBuilder<Map<String, int>>(
                  future: _getMedicationProgress(schedules, _selectedDate),
                  builder: (context, progressSnapshot) {
                    if (progressSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (progressSnapshot.hasError) {
                      return Center(
                        child: Text(
                          "Error progress: ${progressSnapshot.error}",
                        ),
                      );
                    }

                    final progressData =
                        progressSnapshot.data ?? {'taken': 0, 'total': 1};
                    final takenMedsCount = progressData['taken']!;
                    final totalMedsCount = progressData['total']!;
                    final progressValue =
                        totalMedsCount > 0
                            ? takenMedsCount / totalMedsCount
                            : 0.0;

                    return Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 150,
                            height: 150,
                            child: CircularProgressIndicator(
                              value: progressValue,
                              strokeWidth: 10,
                              backgroundColor: Colors.blue.shade100,
                              color: Colors.blue,
                            ),
                          ),
                          Column(
                            children: [
                              const Icon(
                                Icons.medication,
                                size: 32,
                                color: Colors.orange,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "$takenMedsCount/$totalMedsCount",
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat(
                                  'EEE',
                                  'id_ID',
                                ).format(_selectedDate),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),
                if (scheduledDosesToday.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text(
                        "Tidak ada jadwal obat untuk tanggal ini.",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  ...scheduledDosesToday.asMap().entries.map((entry) {
                    final doseItem = entry.value;

                    return FutureBuilder<Map<String, bool>>(
                      future: AuthService.getDoseTakenStatus(
                        userId: _currentUser!.uid,
                        scheduleId: doseItem['scheduleId'],
                        date: _selectedDate,
                      ),
                      builder: (context, takenStatusSnapshot) {
                        bool isTakenForThisTime = false;
                        if (takenStatusSnapshot.hasData) {
                          isTakenForThisTime =
                              takenStatusSnapshot
                                  .data![doseItem['displayTime']] ??
                              false;
                        }

                        return GestureDetector(
                          onTap:
                              isTakenForThisTime
                                  ? null
                                  : () async {
                                    final result = await Navigator.pushNamed(
                                      context,
                                      '/med-info',
                                      arguments: {
                                        'scheduleId': doseItem['scheduleId'],
                                        'name': doseItem['medicineName'],
                                        'dose': doseItem['dose'],
                                        'medicineType':
                                            doseItem['medicineType'],
                                        'doseTime': doseItem['displayTime'],
                                      },
                                    );
                                    // Jika kembali dengan true, berarti verifikasi berhasil
                                    if (result == true) {
                                      setState(() {
                                        // Memicu rebuild untuk refresh status progress bar
                                      });
                                    }
                                  },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color:
                                  isTakenForThisTime
                                      ? Colors.green.shade50
                                      : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isTakenForThisTime
                                      ? Icons.check_circle
                                      : Icons.info,
                                  color:
                                      isTakenForThisTime
                                          ? Colors.green
                                          : Colors.orange,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        doseItem['medicineName'],
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "${doseItem['dose']} (${doseItem['medicineType']})",
                                      ),
                                    ],
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed:
                                      isTakenForThisTime
                                          ? () => _markDoseTaken(
                                            scheduleId: doseItem['scheduleId'],
                                            doseTime: doseItem['displayTime'],
                                            isTaken: !isTakenForThisTime,
                                          )
                                          : null, // Hanya bisa ditekan jika sudah diminum untuk toggle
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black,
                                    side: BorderSide(
                                      color:
                                          isTakenForThisTime
                                              ? Colors.green
                                              : Colors.blue,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(doseItem['displayTime']),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<Map<String, int>> _getMedicationProgress(
    List<Map<String, dynamic>> allSchedules,
    DateTime date,
  ) async {
    int totalDosesToday = 0;
    int takenDosesToday = 0;
    final userId = _currentUser!.uid;

    final todayStr = DateFormat('yyyy-MM-dd').format(date);

    for (var schedule in allSchedules) {
      final startDate = schedule['startDate'] as String?;
      final endDate = schedule['endDate'] as String?;

      if (startDate != null &&
          endDate != null &&
          todayStr.compareTo(startDate) >= 0 &&
          todayStr.compareTo(endDate) <= 0) {
        List<String> scheduledTimes = List<String>.from(
          schedule['scheduledTimes'] ?? [],
        );
        totalDosesToday += scheduledTimes.length;

        final takenStatus = await AuthService.getDoseTakenStatus(
          userId: userId,
          scheduleId: schedule['id'],
          date: date,
        );

        for (var time in scheduledTimes) {
          if (takenStatus[time] == true) {
            takenDosesToday++;
          }
        }
      }
    }
    return {'taken': takenDosesToday, 'total': totalDosesToday};
  }
}
