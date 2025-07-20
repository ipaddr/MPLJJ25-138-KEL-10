import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:user/services/auth_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:user/services/gemini_service.dart'; // Import GeminiService
import '../../main.dart'; // Supaya bisa akses flutterLocalNotificationsPlugin
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:permission_handler/permission_handler.dart'; // <-- TAMBAHKAN INI

// Import Awesome Notifications
import 'package:awesome_notifications/awesome_notifications.dart';

// Other imported pages
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
  final AuthService _authService = AuthService(); // Instance needed for non-static methods
  DateTime _selectedDate = DateTime.now();
  Map<String, dynamic>? _userProfile;

  bool _notificationsPermissionsRequested = false;
  bool _exactAlarmPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    _checkCurrentUserAndLoadData();
    // Mengatur locale default untuk format tanggal dan waktu menjadi Bahasa Indonesia
    Intl.defaultLocale = 'id_ID';
    // Meminta izin notifikasi saat aplikasi dimulai
    _requestNotificationPermissions();
  }

  // Meminta izin notifikasi untuk Android 13+ DAN izin SCHEDULE_EXACT_ALARM
  void _requestNotificationPermissions() async {
    // Permintaan izin notifikasi umum untuk Android 13 (API 33) ke atas
    if (Theme.of(context).platform == TargetPlatform.android) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        // Request POST_NOTIFICATIONS permission for Android 13+
        final bool? granted = await androidImplementation.requestNotificationsPermission();
        if (granted != null && granted) {
          print("DEBUG: Izin notifikasi umum Android diberikan.");
        } else {
          print("WARN: Izin notifikasi umum Android ditolak.");
        }
      }
    }

    // Permintaan izin SCHEDULE_EXACT_ALARM (untuk Android 12+)
    // Ini adalah izin runtime, jadi harus diminta dari pengguna
    final status = await Permission.scheduleExactAlarm.status;
    if (status.isDenied || status.isRestricted || status.isLimited) {
      print("DEBUG: Meminta izin SCHEDULE_EXACT_ALARM...");
      final result = await Permission.scheduleExactAlarm.request();
      if (result.isGranted) {
        print("DEBUG: Izin SCHEDULE_EXACT_ALARM diberikan.");
      } else {
        print("WARN: Izin SCHEDULE_EXACT_ALARM ditolak. Fitur pengingat tepat mungkin tidak berfungsi.");
        // Anda bisa menampilkan dialog atau snackbar untuk memberitahu pengguna
        // bahwa mereka harus mengaktifkannya secara manual dari pengaturan aplikasi.
        // openAppSettings(); // Membuka pengaturan aplikasi
      }
    } else if (status.isGranted) {
      print("DEBUG: Izin SCHEDULE_EXACT_ALARM sudah diberikan.");
    }
  }

  void _checkCurrentUserAndLoadData() async {
    print("DEBUG: _checkCurrentUserAndLoadData called.");
    if (_currentUser == null) {
      print("DEBUG: Current user is null. Navigating to /login.");
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      });
    } else {
      _loadUserProfile(); // Muat profil pengguna jika sudah masuk
    }
  }

  Future<void> _loadUserProfile() async {
    final profile = await _authService.getUserProfile(_currentUser!.uid);
    if (mounted) {
      setState(() {
        _userProfile = profile; // Perbarui state dengan data profil
      });
    }
  }

  /// Menjadwalkan notifikasi pengingat minum obat.
  /// Notifikasi akan dijadwalkan 5 menit sebelum waktu dosis yang sebenarnya.
  /// Jika waktu pengingat sudah lewat, akan dijadwalkan untuk hari berikutnya.
   // ... (kode di atas) ...

Future<void> scheduleReminderNotification({
  required String medicineName,
  required String doseTime,
  required DateTime scheduledDateTime, // Ini adalah waktu dosis yang sebenarnya
}) async {
  // Hitung waktu notifikasi = 5 menit sebelum waktu minum obat yang dijadwalkan
  final reminderTime = scheduledDateTime.subtract(const Duration(minutes: 5));

  // Dapatkan waktu sekarang di zona waktu lokal
  final now = tz.TZDateTime.now(tz.local);

  // Variabel untuk waktu notifikasi yang akan digunakan
  tz.TZDateTime finalScheduledNotificationTime;

  // Logika untuk menjadwalkan notifikasi jika waktu pengingat sudah lewat
  if (reminderTime.isBefore(now)) {
    // Jika waktu pengingat sudah lewat hari ini, jadwalkan untuk hari berikutnya pada waktu yang sama
    finalScheduledNotificationTime = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      reminderTime.hour,
      reminderTime.minute,
      reminderTime.second,
    ).add(const Duration(days: 1)); // Tambah 1 hari
    print('DEBUG: Waktu pengingat untuk $medicineName pada $doseTime sudah lewat. Dijadwalkan untuk besok pada ${DateFormat.Hm().format(finalScheduledNotificationTime)}.');
  } else {
    // Jika waktu pengingat masih di masa depan hari ini, gunakan waktu tersebut
    finalScheduledNotificationTime = tz.TZDateTime.from(reminderTime, tz.local);
    print('DEBUG: Menjadwalkan notifikasi untuk $medicineName pada ${DateFormat.Hm().format(finalScheduledNotificationTime)}.');
  }

  // Ambil pesan notifikasi dari GeminiService
  final message = await GeminiService.getReminderMessage(medicineName, doseTime);

  // Jadwalkan notifikasi lokal
  await flutterLocalNotificationsPlugin.zonedSchedule(
    // ID unik untuk notifikasi ini
    '${scheduledDateTime.toIso8601String()}_${medicineName}_$doseTime'.hashCode,
    'Pengingat Minum Obat', // Judul notifikasi
    message, // Pesan notifikasi dari Gemini
    finalScheduledNotificationTime, // Waktu notifikasi yang telah disesuaikan
    const NotificationDetails( // <-- Argumen ke-5: NotificationDetails
      android: AndroidNotificationDetails(
        'reminder_channel',
        'Pengingat Obat',
        channelDescription: 'Channel untuk notifikasi pengingat minum obat',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
      ),
      // Untuk iOS, jika Anda perlu pengaturan serupa, gunakan:
      // iOS: DarwinNotificationDetails(
      //   presentAlert: true,
      //   presentBadge: true,
      //   presentSound: true,
      //   interruptionLevel: InterruptionLevel.active,
      // ),
    ), // <-- PENUTUP NotificationDetails
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, // <-- INI ADALAH NAMED ARGUMENT SETELAH NOTIFICATIONDETAILS
    // matchDateTimeComponents: DateTimeComponents.time, // Jika ingin notifikasi berulang harian
  ); // <-- PENUTUP zonedSchedule. Pastikan ini ada dan koma di atasnya benar.

  print('SUCCESS: Notifikasi dijadwalkan untuk $medicineName pada ${DateFormat.Hm().format(finalScheduledNotificationTime)} (Aktual: ${DateFormat.Hm().format(scheduledDateTime)})');
}

  @override
  Widget build(BuildContext context) {
    // This initial check for _currentUser and _userProfile ensures
    // the app displays a loading indicator until basic user data is available.
    if (_currentUser == null || _userProfile == null) {
      print("DEBUG: Building initial loading screen (currentUser: ${_currentUser != null}, userProfile: ${_userProfile != null})");
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    print("DEBUG: Building HomePage content. User: ${_userProfile!['username']}");

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: AuthService.getMedicationSchedules(_currentUser!.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            print("DEBUG: StreamBuilder ConnectionState: waiting. Displaying CircularProgressIndicator.");
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print("ERROR: StreamBuilder snapshot error: ${snapshot.error}");
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            print("DEBUG: StreamBuilder has no data or empty. Displaying empty state.");
            return _buildEmptyState();
          }

          // Filter jadwal untuk hari yang dipilih
          final allSchedules = snapshot.data!;
          final activeSchedulesToday = allSchedules.where((schedule) {
            final startDate = schedule['startDate'] as String?;
            final endDate = schedule['endDate'] as String?;
            if (startDate == null || endDate == null) return false;
            final todayStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
            return todayStr.compareTo(startDate) >= 0 &&
                todayStr.compareTo(endDate) <= 0;
          }).toList();

          // --- Penjadwalan Notifikasi ---
          // Penting: Batalkan semua notifikasi yang telah dijadwalkan sebelumnya untuk menghindari duplikasi.
          // Ini sangat krusial karena StreamBuilder bisa rebuild beberapa kali.
          // Namun, berhati-hatilah dengan `cancelAll()`. Jika Anda memiliki notifikasi lain
          // yang tidak terkait dengan jadwal obat, mereka juga akan dibatalkan.
          // Pertimbangkan untuk membatalkan notifikasi hanya dengan ID tertentu jika memungkinkan.
          flutterLocalNotificationsPlugin.cancelAll(); 
          
          for (final schedule in activeSchedulesToday) {
            final medicineName = schedule['medicineName'];
            // Pastikan scheduledTimes adalah List<String>
            final doseTimes = List<String>.from(schedule['scheduledTimes'] ?? []);

            for (final doseTime in doseTimes) {
              // Pisahkan string waktu (misal "08:30" menjadi "08" dan "30")
              final parts = doseTime.split(':');
              final int hour = int.parse(parts[0]);
              final int minute = int.parse(parts[1]);
              
              // Buat objek TZDateTime lengkap untuk dosis berdasarkan tanggal yang dipilih dan waktu dosis
              // Ini penting agar notifikasi dijadwalkan di zona waktu yang benar
              final scheduledDateTime = tz.TZDateTime(
                tz.local,
                _selectedDate.year,
                _selectedDate.month,
                _selectedDate.day,
                hour,
                minute,
              );

              // Langsung panggil scheduleReminderNotification.
              // Logika pengecekan apakah waktu sudah lewat ada di dalam fungsi tersebut.
              scheduleReminderNotification(
                medicineName: medicineName,
                doseTime: doseTime,
                scheduledDateTime: scheduledDateTime,
              );
            }
          }
          // --- Akhir Penjadwalan Notifikasi ---

          return _buildMainContent(allSchedules);
        },
      ),
    );
  }

  AppBar _buildAppBar() {
    String username = _userProfile?['username'] ?? 'Pengguna';
    String profilePictureBase64 = _userProfile?['profilePictureBase64'] ?? '';
    ImageProvider profileImage = const AssetImage("assets/images/avatar.png");

    if (profilePictureBase64.isNotEmpty) {
      try {
        profileImage = MemoryImage(base64Decode(profilePictureBase64));
      } catch (e) {
        print("Error decoding base64 image in AppBar: $e");
      }
    }

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      toolbarHeight: 80,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          CircleAvatar(radius: 24, backgroundImage: profileImage),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Selamat Datang,',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              Text(
                username,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        _buildAppBarAction(
          Icons.card_giftcard_rounded,
          const Color(0xFF0072CE),
          () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RewardPage()),
            );
          },
        ),
        _buildAppBarAction(Icons.person_outline_rounded, Colors.black, () async {
          // When navigating to ProfileUserPage, after returning, call function to update notifications
          // as ProfileUserPage might trigger user data changes relevant to schedules
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfileUserPage()),
          );
          // After returning from ProfileUserPage, call function to reschedule notifications
          _updateAndRescheduleAllNotifications();
          // Call setState to ensure UI in HomePage is updated after returning
          setState(() {
            _loadUserProfile(); // Reload profile if there were changes (e.g., username, profile pic)
          });
        }),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildAppBarAction(
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
      child: SizedBox(
        width: 48,
        height: 48,
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            padding: EdgeInsets.zero,
          ),
          child: Icon(icon, color: color),
        ),
      ),
    );
  }

  Widget _buildMainContent(List<Map<String, dynamic>> schedules) {
    // Filter jadwal yang aktif untuk tanggal yang dipilih
    final activeSchedulesToday =
        schedules.where((schedule) {
          final startDate = schedule['startDate'] as String?;
          final endDate = schedule['endDate'] as String?;
          if (startDate == null || endDate == null) return false;
          final todayStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
          return todayStr.compareTo(startDate) >= 0 &&
              todayStr.compareTo(endDate) <= 0;
        }).toList();

    // Buat daftar dosis yang akan ditampilkan untuk hari ini
    List<Map<String, dynamic>> scheduledDosesToday = [];
    for (var schedule in activeSchedulesToday) {
      List<String> times = List<String>.from(schedule['scheduledTimes'] ?? []);
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
    // Urutkan dosis berdasarkan waktu agar tampilannya rapi
    scheduledDosesToday.sort(
      (a, b) => a['displayTime'].compareTo(b['displayTime']),
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          _buildDateSelector(),
          const SizedBox(height: 24),
          _buildProgressAndScheduleList(scheduledDosesToday),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 7, // Menampilkan 7 hari dari hari ini
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final date = DateTime.now().add(Duration(days: index));
          final bool isSelected = DateUtils.isSameDay(date, _selectedDate);
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = date;
              });
              // No need to trigger notification rescheduling here as notifications are global (for all relevant days)
            },
            child: Container(
              width: 60,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? const Color(0xFF0072CE)
                        : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('EEE').format(date), // Nama hari (misal: "Sen")
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    date.day.toString(), // Tanggal (misal: "15")
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressAndScheduleList(
    List<Map<String, dynamic>> scheduledDosesToday,
  ) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getMedicationProgress(scheduledDosesToday),
      builder: (context, progressSnapshot) {
        if (progressSnapshot.connectionState == ConnectionState.waiting) {
          print("DEBUG: Progress FutureBuilder ConnectionState: waiting. Displaying CircularProgressIndicator.");
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (progressSnapshot.hasError) {
          print("ERROR: Progress FutureBuilder snapshot error: ${progressSnapshot.error}");
          return Center(
            child: Text("Error loading progress: ${progressSnapshot.error}"),
          );
        }

        final progressData = progressSnapshot.data ?? {'taken': 0, 'total': 0, 'statuses': {}};
        final takenCount = progressData['taken']!;
        final totalCount = progressData['total']!;
        final statuses =
            progressData['statuses'] as Map<String, Map<String, bool>>;

        print("DEBUG: Progress loaded: Taken $takenCount of Total $totalCount. Building progress and schedule list.");
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProgressCircle(takenCount, totalCount),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                "Jadwal Hari Ini (${DateFormat('d MMMM y').format(_selectedDate)})",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (scheduledDosesToday.isEmpty)
              _buildEmptyScheduleForDay()
            else
              _buildDoseList(scheduledDosesToday, statuses),
          ],
        );
      },
    );
  }

  Widget _buildProgressCircle(int takenMedsCount, int totalMedsCount) {
    final progressValue =
        totalMedsCount > 0 ? takenMedsCount / totalMedsCount : 0.0;
    return Center(
      child: SizedBox(
        width: 160,
        height: 160,
        child: Stack(
          alignment: Alignment.center,
          fit: StackFit.expand,
          children: [
            CircularProgressIndicator(
              value: progressValue,
              strokeWidth: 12,
              backgroundColor: Colors.grey.shade200,
              color: const Color(0xFF0072CE),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "$takenMedsCount dari $totalMedsCount",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    "Obat diminum",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoseList(
    List<Map<String, dynamic>> doses,
    Map<String, Map<String, bool>> allStatuses,
  ) {
    return ListView.builder(
      itemCount: doses.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemBuilder: (context, index) {
        final doseItem = doses[index];
        final scheduleId = doseItem['scheduleId'];
        final doseTime = doseItem['displayTime'];
        // Cek apakah dosis sudah diminum berdasarkan status yang diambil dari Firebase
        final bool isTaken = allStatuses[scheduleId]?[doseTime] ?? false;
        return _buildDoseCard(doseItem, isTaken);
      },
    );
  }

  Widget _buildDoseCard(Map<String, dynamic> doseItem, bool isTaken) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isTaken ? const Color(0xFFE8F5E9) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isTaken ? Colors.green.shade100 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          // Jika sudah diminum, onTap dinonaktifkan
          onTap:
              isTaken
                  ? null
                  : () async {
                      // Navigasi ke halaman detail obat
                      final result = await Navigator.pushNamed(
                        context,
                        '/med-info',
                        arguments: {
                          'scheduleId': doseItem['scheduleId'],
                          'name': doseItem['medicineName'],
                          'dose': doseItem['dose'],
                          'medicineType': doseItem['medicineType'],
                          'doseTime': doseItem['displayTime'],
                        },
                      );
                      // Jika ada perubahan (misal, obat ditandai sudah diminum), perbarui UI
                      if (result == true && mounted) {
                        setState(() {});
                      }
                    },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(
                  isTaken ? Icons.check_circle : Icons.alarm,
                  color: isTaken ? Colors.green : const Color(0xFF0072CE),
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      doseItem['displayTime'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isTaken ? "Selesai" : "Menunggu",
                      style: TextStyle(
                        fontSize: 12,
                        color: isTaken ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 20),
            const Text(
              "Jadwal Anda Kosong",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Belum ada jadwal obat yang diberikan oleh admin untuk saat ini.",
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyScheduleForDay() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48.0, horizontal: 24.0),
        child: Column(
          children: [
            Icon(
              Icons.event_busy_outlined,
              size: 60,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            const Text(
              "Tidak Ada Jadwal",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Anda tidak memiliki jadwal minum obat pada tanggal ini.",
              style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Mengambil progres minum obat untuk dosis yang dijadwalkan pada tanggal tertentu.
  Future<Map<String, dynamic>> _getMedicationProgress(
    List<Map<String, dynamic>> scheduledDoses,
  ) async {
    print("DEBUG: _getMedicationProgress called for ${scheduledDoses.length} doses.");
    int takenCount = 0;
    final Map<String, Map<String, bool>> statusesBySchedule = {};
    if (_currentUser == null) {
      print("DEBUG: _currentUser is null in _getMedicationProgress.");
      return {
        'taken': 0,
        'total': scheduledDoses.length,
        'statuses': statusesBySchedule,
      };
    }

    // Kumpulkan ID jadwal unik
    final scheduleIds =
        scheduledDoses.map((d) => d['scheduleId'] as String).toSet();
    // Untuk setiap ID jadwal, ambil status minum obatnya
    for (String id in scheduleIds) {
      try {
        final status = await AuthService.getDoseTakenStatus(
          userId: _currentUser!.uid,
          scheduleId: id,
          date: _selectedDate,
        );
        statusesBySchedule[id] = status;
        print("DEBUG: Status for schedule $id on ${_selectedDate.toIso8601String()}: $status");
      } catch (e) {
        print("ERROR: Failed to get dose taken status for schedule $id: $e");
        // Continue even if one schedule fails, to try and load others
      }
    }

    // Hitung jumlah dosis yang sudah diminum
    for (var dose in scheduledDoses) {
      if (statusesBySchedule[dose['scheduleId']]?[dose['displayTime']] ==
          true) {
        takenCount++;
      }
    }

    return {
      'taken': takenCount,
      'total': scheduledDoses.length,
      'statuses': statusesBySchedule,
    };
  }
}
