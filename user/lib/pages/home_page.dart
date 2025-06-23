import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:user/services/auth_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:typed_data';

// Halaman lain yang diimpor
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
  final AuthService _authService = AuthService();
  DateTime _selectedDate = DateTime.now();
  Map<String, dynamic>? _userProfile;

  @override
  void initState() {
    super.initState();
    Intl.defaultLocale = 'id_ID';
    _checkCurrentUserAndLoadData();
    _setupNotifications();
  }

  // --- LOGIKA NOTIFIKASI BARU ---
  void _setupNotifications() async {
    // 1. Minta semua izin yang diperlukan
    bool permissionsGranted = await _requestAllPermissions();

    // 2. Jika izin diberikan DAN pengguna sudah login, jadwalkan semua notifikasi
    if (permissionsGranted && _currentUser != null) {
      await AuthService.scheduleAllNotificationsForUser(_currentUser!.uid);
    } else {
      print("WARN: Izin tidak lengkap, penjadwalan notifikasi dibatalkan.");
    }
  }

  Future<bool> _requestAllPermissions() async {
    PermissionStatus notificationStatus =
        await Permission.notification.request();
    if (notificationStatus.isDenied) {
      print("WARN: Izin notifikasi umum DITOLAK.");
      return false;
    }
    print("DEBUG: Izin notifikasi umum DIBERIKAN.");

    PermissionStatus alarmStatus =
        await Permission.scheduleExactAlarm.request();
    if (alarmStatus.isDenied) {
      print("WARN: Izin alarm presisi DITOLAK.");
      return false;
    }
    print("DEBUG: Izin alarm presisi DIBERIKAN.");

    return true;
  }
  // --- AKHIR LOGIKA NOTIFIKASI BARU ---

  void _checkCurrentUserAndLoadData() {
    if (_currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      });
    } else {
      _loadUserProfile();
    }
  }

  Future<void> _loadUserProfile() async {
    final profile = await _authService.getUserProfile(_currentUser!.uid);
    if (mounted) {
      setState(() {
        _userProfile = profile;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null || _userProfile == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
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
            return _buildEmptyState();
          }

          // UI dibangun di sini, logika notifikasi sudah pindah
          return _buildMainContent(snapshot.data!);
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
        _buildAppBarAction(Icons.person_outline_rounded, Colors.black, () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfileUserPage()),
          );
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
    final activeSchedulesToday =
        schedules.where((schedule) {
          final startDate = schedule['startDate'] as String?;
          final endDate = schedule['endDate'] as String?;
          if (startDate == null || endDate == null) return false;
          final todayStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
          return todayStr.compareTo(startDate) >= 0 &&
              todayStr.compareTo(endDate) <= 0;
        }).toList();

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
        itemCount: 7,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final date = DateTime.now().add(Duration(days: index));
          final bool isSelected = DateUtils.isSameDay(date, _selectedDate);
          return GestureDetector(
            onTap: () => setState(() => _selectedDate = date),
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
                    DateFormat('EEE').format(date),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    date.day.toString(),
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
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (progressSnapshot.hasError) {
          return Center(
            child: Text("Error memuat progres: ${progressSnapshot.error}"),
          );
        }

        final progressData = progressSnapshot.data ?? {'taken': 0, 'total': 0};
        final takenCount = progressData['taken']!;
        final totalCount = progressData['total']!;
        final statuses =
            progressData['statuses'] as Map<String, Map<String, bool>>;

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
          onTap:
              isTaken
                  ? null
                  : () async {
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

  Future<Map<String, dynamic>> _getMedicationProgress(
    List<Map<String, dynamic>> scheduledDoses,
  ) async {
    int takenCount = 0;
    final Map<String, Map<String, bool>> statusesBySchedule = {};
    if (_currentUser == null) {
      return {
        'taken': 0,
        'total': scheduledDoses.length,
        'statuses': statusesBySchedule,
      };
    }
    final scheduleIds =
        scheduledDoses.map((d) => d['scheduleId'] as String).toSet();
    for (String id in scheduleIds) {
      final status = await AuthService.getDoseTakenStatus(
        userId: _currentUser!.uid,
        scheduleId: id,
        date: _selectedDate,
      );
      statusesBySchedule[id] = status;
    }
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
