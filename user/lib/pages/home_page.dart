import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

import 'profile_user.dart';
import 'reward_page.dart';
import 'med_info_page.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Medication> medications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    initializeNotifications();
    fetchMedications();
  }

  Future<void> initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> scheduleMedicationReminder(String name, String time, int id) async {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    final now = DateTime.now();
    final scheduledTime = DateTime(now.year, now.month, now.day, hour, minute);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      'Waktunya minum obat',
      'Minum obat $name sekarang.',
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails('channel_id', 'Reminder Obat',
            importance: Importance.max, priority: Priority.high),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> fetchMedications() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('medication_schedules')
        .get();

    final meds = <Medication>[];

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final startDate = data['assignedAt'].toDate();
      final endDate = DateTime.parse(data['endDate']);
      final isActiveToday = data['isActive'] == true &&
          !today.isBefore(startDate) &&
          !today.isAfter(endDate);

      if (isActiveToday) {
        final takenDose = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('medication_schedules')
            .doc(doc.id)
            .collection('taken_doses')
            .doc("${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}")
            .get();

        final isTaken = takenDose.exists && takenDose.data()?['isTaken'] == true;

        meds.add(Medication(
          id: doc.id,
          name: data['medicineName'] ?? '',
          dose: data['dose'] ?? '',
          time: data['firstDoseTime'] ?? '',
          isTaken: isTaken,
        ));

        await scheduleMedicationReminder(data['medicineName'], data['firstDoseTime'], meds.length);
      }
    }

    setState(() {
      medications = meds;
      isLoading = false;
    });
  }

  void handleVerification(int index) async {
    final med = medications[index];
    if (med.isTaken) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MedInfoPage(
          name: med.name,
          time: med.time,
          dose: med.dose,
        ),
      ),
    );

    if (result == true) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final now = DateTime.now();
      final formattedDate = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('medication_schedules')
          .doc(med.id)
          .collection('taken_doses')
          .doc(formattedDate)
          .set({
        'isTaken': true,
        'takenAt': now,
      });

      setState(() {
        medications[index].isTaken = true;
      });
    }
  }

  int get takenMeds => medications.where((m) => m.isTaken).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            const Text('Hari ini',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.emoji_emotions, color: Colors.amber),
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const RewardPage()));
              },
            ),
            IconButton(
              icon: const Icon(Icons.person_outline, color: Colors.black),
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ProfileUserPage()));
              },
            )
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : medications.isEmpty
              ? const Center(child: Text('Belum ada data obat dari admin'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      const Center(
                        child: Text('Diminum',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 150,
                              height: 150,
                              child: CircularProgressIndicator(
                                value: takenMeds / medications.length,
                                strokeWidth: 10,
                                backgroundColor: Colors.blue.shade100,
                                color: Colors.blue,
                              ),
                            ),
                            Column(
                              children: [
                                const Icon(Icons.medication,
                                    size: 32, color: Colors.orange),
                                const SizedBox(height: 8),
                                Text(
                                  "$takenMeds/${medications.length}",
                                  style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                const Text("Hari Ini"),
                              ],
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      ...medications.asMap().entries.map((entry) {
                        final index = entry.key;
                        final med = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                med.isTaken ? Icons.check_circle : Icons.info,
                                color:
                                    med.isTaken ? Colors.green : Colors.orange,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(med.name,
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text(med.dose),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () => handleVerification(index),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black,
                                  side: const BorderSide(color: Colors.blue),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(med.time),
                              ),
                            ],
                          ),
                        );
                      })
                    ],
                  ),
                ),
    );
  }
}

class Medication {
  final String id;
  final String name;
  final String dose;
  final String time;
  bool isTaken;

  Medication({
    required this.id,
    required this.name,
    required this.dose,
    required this.time,
    this.isTaken = false,
  });
}