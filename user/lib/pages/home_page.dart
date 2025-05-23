import 'package:flutter/material.dart';
import 'profile_user.dart';
import 'reward_page.dart';
import 'verification_warning_page.dart'; // halaman verifikasi

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int takenMeds = 0; // jumlah obat yang sudah diminum

  final List<Medication> medications = [
    Medication(name: "Isoniazid", time: "09:41"),
    Medication(name: "Rifampicin", time: "09:44"),
  ];

  void handleVerification() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const VerificationWarningPage()),
    );

    if (result == true && takenMeds < medications.length) {
      setState(() {
        takenMeds++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hari Ini"),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileUserPage()),
              );
            },
            icon: const Icon(Icons.settings, color: Colors.black),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RewardPage()),
              );
            },
            icon: const Icon(Icons.emoji_emotions, color: Colors.amber),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const DaySelector(),
            const SizedBox(height: 16),
            const Text("Diminum", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            CircularProgressIndicatorWidget(progress: takenMeds),
            const SizedBox(height: 20),
            ...medications.map(
              (med) => MedicationItem(
                name: med.name,
                time: med.time,
                onPressed: handleVerification,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Medication {
  final String name;
  final String time;

  Medication({required this.name, required this.time});
}

class DaySelector extends StatefulWidget {
  const DaySelector({super.key});

  @override
  State<DaySelector> createState() => _DaySelectorState();
}

class _DaySelectorState extends State<DaySelector> {
  int selectedDay = DateTime.now().day;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        itemBuilder: (context, index) {
          final day = index + 2;
          final selected = day == selectedDay;
          return GestureDetector(
            onTap: () => setState(() => selectedDay = day),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                children: [
                  Text("$day", style: const TextStyle(fontWeight: FontWeight.bold)),
                  CircleAvatar(
                    backgroundColor: selected ? Colors.blue : Colors.grey[300],
                    child: Text(
                      '$day',
                      style: TextStyle(
                        color: selected ? Colors.white : Colors.black,
                      ),
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
}

class CircularProgressIndicatorWidget extends StatelessWidget {
  final int progress;
  const CircularProgressIndicatorWidget({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    final percent = progress / 2.0;
    return SizedBox(
      width: 150,
      height: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: percent,
            strokeWidth: 10,
            backgroundColor: Colors.grey[300],
            color: progress == 2 ? Colors.green : Colors.blue,
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.local_pharmacy, size: 30, color: Colors.orange),
              const SizedBox(height: 8),
              Text(
                "$progress/2",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MedicationItem extends StatelessWidget {
  final String name;
  final String time;
  final VoidCallback onPressed;

  const MedicationItem({
    super.key,
    required this.name,
    required this.time,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.yellow,
          child: Icon(Icons.medication, color: Colors.white),
        ),
        title: Text(name),
        subtitle: Text("4 Tablet, 500mg"),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(time, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            ElevatedButton(
              onPressed: onPressed,
              child: const Text("Minum"),
            ),
          ],
        ),
      ),
    );
  }
}
