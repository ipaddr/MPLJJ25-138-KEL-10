import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:user/services/auth_service.dart';
import 'package:user/services/gemini_service.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart'; // For PlatformException

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
    Intl.defaultLocale = 'id_ID'; // Ensure locale is set for date formatting
    _checkCurrentUserAndLoadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_notificationsPermissionsRequested) {
      _requestNotificationPermissions();
      _notificationsPermissionsRequested = true;
    }
  }

  void _requestNotificationPermissions() async {
    print("DEBUG: _requestNotificationPermissions called.");
    // Request general notification permission (Android 13+)
    final AwesomeNotifications awesomeNotifications = AwesomeNotifications();
    bool isAllowed = await awesomeNotifications.isNotificationAllowed();
    if (!isAllowed) {
      print("DEBUG: General notification permission not granted. Requesting...");
      isAllowed = await awesomeNotifications.requestPermissionToSendNotifications();
      if (isAllowed) {
        print("DEBUG: General notification permission granted.");
      } else {
        print("WARN: General notification permission denied.");
      }
    } else {
      print("DEBUG: General notification permission already granted.");
    }

    // Request SCHEDULE_EXACT_ALARM permission
    final status = await Permission.scheduleExactAlarm.status;
    if (status.isDenied || status.isRestricted || status.isLimited) {
      print("DEBUG: Requesting SCHEDULE_EXACT_ALARM permission...");
      final result = await Permission.scheduleExactAlarm.request();
      if (result.isGranted) {
        print("DEBUG: SCHEDULE_EXACT_ALARM permission granted.");
        setState(() { _exactAlarmPermissionGranted = true; });
      } else {
        print("WARN: SCHEDULE_EXACT_ALARM permission denied. Exact reminders may not work.");
        setState(() { _exactAlarmPermissionGranted = false; });
        if (result.isDenied || result.isPermanentlyDenied) {
          _showExactAlarmPermissionDeniedDialog();
        }
      }
    } else if (status.isGranted) {
      print("DEBUG: SCHEDULE_EXACT_ALARM permission already granted.");
      setState(() { _exactAlarmPermissionGranted = true; });
    }
  }

  void _showExactAlarmPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Izin Diperlukan"),
          content: const Text(
            "Untuk menjadwalkan pengingat obat yang akurat, aplikasi memerlukan izin 'Alarm & Pengingat'. Mohon aktifkan izin ini di pengaturan aplikasi Anda.",
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("Nanti"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text("Buka Pengaturan"),
              onPressed: () {
                openAppSettings();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _checkCurrentUserAndLoadData() async {
    print("DEBUG: _checkCurrentUserAndLoadData called.");
    if (_currentUser == null) {
      print("DEBUG: Current user is null. Navigating to /login.");
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      });
    } else {
      print("DEBUG: Current user exists. Loading user profile and rescheduling notifications.");
      await _loadUserProfile(); // Load profile first
      // Schedule notifications after profile is loaded and user is confirmed
      if (_currentUser != null) {
        _updateAndRescheduleAllNotifications();
      }
    }
  }

  Future<void> _loadUserProfile() async {
    print("DEBUG: _loadUserProfile called for user ${_currentUser?.uid}");
    try {
      final profile = await _authService.getUserProfile(_currentUser!.uid);
      if (mounted) {
        setState(() {
          _userProfile = profile;
        });
        print("DEBUG: User profile loaded: $_userProfile");
      }
    } catch (e) {
      print("ERROR: Failed to load user profile: $e");
      // Optionally, show an error dialog or sign out the user
    }
  }

  /// Schedules medication reminder notifications using Awesome Notifications.
  /// NOTE: This function should be called when medication schedules are created/updated, NOT inside StreamBuilder.
  Future<void> scheduleReminderNotification({
    required String medicineName,
    required String doseTime,
    required DateTime scheduledDateTime,
    required String scheduleId, // Add scheduleId for more unique notification IDs
  }) async {
    // Check if permission is still granted just before scheduling
    if (!_exactAlarmPermissionGranted) {
      print("WARN: 'Alarm & Reminder' permission NOT granted. Notification not scheduled for $medicineName.");
      return;
    }

    // Calculate reminder time: 5 minutes before the actual dose time
    final reminderTime = scheduledDateTime.subtract(const Duration(minutes: 5));
    final now = DateTime.now();

    // Only schedule if the reminder time is in the future
    if (reminderTime.isBefore(now)) {
      print('DEBUG: Reminder time for $medicineName at $doseTime has passed. Not scheduled.');
      return; // Do not schedule if time has already passed
    }

    final message = await GeminiService.getReminderMessage(medicineName, doseTime);
    
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          // Use combination of scheduleId and timestamp for unique ID per dose
          id: '${scheduleId}_${scheduledDateTime.millisecondsSinceEpoch}'.hashCode,
          channelKey: 'reminder_channel', // Must match channel defined in main.dart
          title: 'Pengingat Minum Obat',
          body: message,
          notificationLayout: NotificationLayout.Default,
          payload: {'medicineName': medicineName, 'doseTime': doseTime, 'scheduleId': scheduleId}, // payload must be Map<String, String>
          category: NotificationCategory.Reminder,
          wakeUpScreen: true, // To wake up the screen
          fullScreenIntent: true, // For fullscreen pop-up (requires special permission on Android 10+)
          autoDismissible: false,
          icon: 'resource://mipmap/ic_launcher', // Ensures notification icon is set
          // customSound: 'resource://raw/res_custom_sound', // If you have a custom sound
        ),
        schedule: NotificationCalendar.fromDate(
          date: reminderTime, // Schedule the notification for the reminder time
          allowWhileIdle: true, // Allow when device is idle
          repeats: false, // Set false for individual notifications
          preciseAlarm: true, // Requires SCHEDULE_EXACT_ALARM permission
        ),
      );
      print('SUCCESS: Awesome notification scheduled for $medicineName at ${DateFormat.Hm().format(reminderTime)} (Actual Dose: ${DateFormat.Hm().format(scheduledDateTime)})');
    } on PlatformException catch (e) {
      print('ERROR: Failed to schedule Awesome notification due to PlatformException: ${e.code} - ${e.message}');
    } catch (e) {
      print('ERROR: Failed to schedule Awesome notification due to unexpected error: $e');
    }
  }

  /// Updates and reschedules all active medication notifications.
  /// This should be called once on app startup (after user login/data load)
  /// and whenever medication schedules are added, updated, or deleted.
  Future<void> _updateAndRescheduleAllNotifications() async {
    if (_currentUser == null) {
      print("DEBUG: User is null, skipping notification rescheduling.");
      return;
    }
    print("DEBUG: _updateAndRescheduleAllNotifications called.");

    // 1. Cancel all existing notifications for this channel
    await AwesomeNotifications().cancelNotificationsByChannelKey('reminder_channel');
    print("DEBUG: All existing notifications in 'reminder_channel' have been cancelled.");

    // 2. Fetch all active medication schedules from Firestore (once)
    // Using .first to get the initial snapshot from the stream
    try {
      final schedulesSnapshot = await AuthService.getMedicationSchedules(_currentUser!.uid).first;
      print("DEBUG: Fetched ${schedulesSnapshot.length} medication schedules.");

      // 3. Reschedule notifications only for active and future schedules
      final today = DateTime.now();
      final todayAtMidnight = DateTime(today.year, today.month, today.day);

      for (final schedule in schedulesSnapshot) {
        final String medicineName = schedule['medicineName'] ?? 'Obat';
        final String scheduleId = schedule['id'];
        final List<String> doseTimes = List<String>.from(schedule['scheduledTimes'] ?? []);
        final String startDateStr = schedule['startDate'] as String? ?? '1970-01-01';
        final String endDateStr = schedule['endDate'] as String? ?? '2999-12-31';

        final DateTime scheduleStartDate = DateTime.parse(startDateStr);
        final DateTime scheduleEndDate = DateTime.parse(endDateStr);
        final bool isActive = schedule['isActive'] ?? false;

        // Skip schedules that are not active or have already ended
        if (!isActive || scheduleEndDate.isBefore(todayAtMidnight)) {
          print("DEBUG: Skipping inactive or past schedule: $medicineName (ID: $scheduleId)");
          continue;
        }

        // Loop through each day from today up to the schedule end date (max 1 year)
        for (int day = 0; day <= 365; day++) { // Limit to 365 days to prevent excessive scheduling
          final currentProcessingDate = todayAtMidnight.add(Duration(days: day));

          // Stop if we pass the schedule end date
          if (currentProcessingDate.isAfter(scheduleEndDate)) {
            break;
          }

          // Only process dates that are >= scheduleStartDate
          if (currentProcessingDate.isBefore(scheduleStartDate)) {
            continue;
          }

          for (final doseTime in doseTimes) {
            final parts = doseTime.split(':');
            final int hour = int.parse(parts[0]);
            final int minute = int.parse(parts[1]);

            final scheduledDateTime = DateTime(
              currentProcessingDate.year,
              currentProcessingDate.month,
              currentProcessingDate.day,
              hour,
              minute,
            );

            // Call the local scheduling function
            await scheduleReminderNotification(
              medicineName: medicineName,
              doseTime: doseTime,
              scheduledDateTime: scheduledDateTime,
              scheduleId: scheduleId,
            );
          }
        }
      }
      print("DEBUG: All active notifications have been re-scheduled.");
    } catch (e) {
      print("ERROR: Failed to fetch/reschedule notifications: $e");
    }
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

          print("DEBUG: StreamBuilder has data. Processing schedules.");
          final allSchedules = snapshot.data!;
          final activeSchedulesToday = allSchedules.where((schedule) {
            final startDate = schedule['startDate'] as String?;
            final endDate = schedule['endDate'] as String?;
            if (startDate == null || endDate == null) return false;
            final todayStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
            return todayStr.compareTo(startDate) >= 0 &&
                todayStr.compareTo(endDate) <= 0;
          }).toList();

          List<Map<String, dynamic>> scheduledDosesToday = [];
          for (final schedule in activeSchedulesToday) {
            final doseTimes = List<String>.from(schedule['scheduledTimes'] ?? []);
            for (final time in doseTimes) {
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

          print("DEBUG: Processed ${scheduledDosesToday.length} doses for selected date.");

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

  Widget _buildDateSelector() {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 7, // Display 7 days from today
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
                    DateFormat('EEE').format(date), // Day name (e.g., "Jum")
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    date.day.toString(), // Date (e.g., "20")
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
                "Jadwal Hari Ini (${DateFormat('d MMMM').format(_selectedDate)})",
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
      physics: const NeverScrollableScrollPhysics(), // Non-scrollable list
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemBuilder: (context, index) {
        final doseItem = doses[index];
        final scheduleId = doseItem['scheduleId'];
        final doseTime = doseItem['displayTime'];
        // Check if dose has been taken based on status retrieved from Firebase
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
          // If already taken, onTap is disabled
          onTap:
              isTaken
                  ? null
                  : () async {
                      // Navigate to medication detail page
                      final result = await Navigator.pushNamed(
                        context,
                        '/med-info',
                        arguments: {
                          'scheduleId': doseItem['scheduleId'],
                          'name': doseItem['medicineName'],
                          'dose': doseItem['dose'],
                          'medicineType': doseItem['medicineType'],
                          'doseTime': doseItem['displayTime'],
                          'selectedDate': _selectedDate.toIso8601String(), // Pass selected date
                        },
                      );
                      // If there's a change (e.g., medication marked as taken), update UI
                      if (result == true && mounted) {
                        setState(() {
                          // This setState will trigger a rebuild, and StreamBuilder will refetch the latest data.
                        });
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

  /// Retrieves medication progress for scheduled doses on a specific date.
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

    // Collect unique schedule IDs
    final scheduleIds =
        scheduledDoses.map((d) => d['scheduleId'] as String).toSet();
    print("DEBUG: Fetching dose statuses for schedule IDs: $scheduleIds");

    // For each unique schedule ID, fetch its dose taken status
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

    // Count taken doses
    for (var dose in scheduledDoses) {
      if (statusesBySchedule[dose['scheduleId']]?[dose['displayTime']] ==
          true) {
        takenCount++;
      }
    }
    print("DEBUG: Calculated taken doses: $takenCount of ${scheduledDoses.length}");

    return {
      'taken': takenCount,
      'total': scheduledDoses.length,
      'statuses': statusesBySchedule,
    };
  }
}