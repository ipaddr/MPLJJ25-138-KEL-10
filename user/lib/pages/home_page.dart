import 'package:flutter/material.dart';
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
  final List<Medication> medications = [
    Medication(name: "Isoniazid", dose: "4 Tablet, 400mg", time: "09:41"),
    Medication(name: "Rifampicin", dose: "4 Tablet, 180mg", time: "09:42"),
  ];

  int selectedDayIndex = 5;

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
      setState(() {
        med.isTaken = true;
      });
    }
  }

  int get takenMeds => medications.where((m) => m.isTaken).length;

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
            const Text('Hari ini', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.emoji_emotions, color: Colors.amber),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const RewardPage()));
              },
            ),
            IconButton(
              icon: const Icon(Icons.person_outline, color: Colors.black),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileUserPage()));
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
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
                  final days = ['JM', 'SB', 'MG', 'SN', 'SL', 'RB', 'KM'];
                  final day = 2 + index;
                  final isSelected = index == selectedDayIndex;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedDayIndex = index;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.blue : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? Colors.blue : Colors.grey.shade300,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Column(
                              children: [
                                Text("$day",
                                    style: TextStyle(
                                        color: isSelected ? Colors.white : Colors.black,
                                        fontWeight: FontWeight.bold)),
                                Text(days[index],
                                    style: TextStyle(
                                        color: isSelected ? Colors.white : Colors.black,
                                        fontSize: 12)),
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
              child: Text('Diminum', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                      const Icon(Icons.medication, size: 32, color: Colors.orange),
                      const SizedBox(height: 8),
                      Text(
                        "$takenMeds/${medications.length}",
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const Text("Rabu"),
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
                      color: med.isTaken ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(med.name,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
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
  final String name;
  final String dose;
  final String time;
  bool isTaken;

  Medication({
    required this.name,
    required this.dose,
    required this.time,
    this.isTaken = false,
  });
}
