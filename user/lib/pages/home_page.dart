import 'package:flutter/material.dart';
import 'med_info_page.dart';
import 'profile_user.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Medication> medications = [
      Medication(name: "Isoniazid", time: "09:41"),
      Medication(name: "Rifampicin", time: "09:44"),
    ];

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
            icon: const Icon(Icons.settings),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const DaySelector(),
            const SizedBox(height: 16),
            const Text("Diminum", style: TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            CircularProgressIndicatorWidget(progress: medications.length),
            const SizedBox(height: 20),
            if (medications.isEmpty)
              const Text("Belum ada obat untuk hari ini.")
            else
              ...medications.map(
                (med) => MedicationItem(name: med.name, time: med.time),
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
          final day = index + 1;
          final selected = day == selectedDay;
          return GestureDetector(
            onTap: () => setState(() => selectedDay = day),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: CircleAvatar(
                backgroundColor: selected ? Colors.blue : Colors.grey[300],
                child: Text(
                  '$day',
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class CircularProgressIndicatorWidget extends StatelessWidget {
  final int progress; // jumlah obat yang diminum dari total 2
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
            strokeWidth: 8,
            backgroundColor: Colors.grey[300],
            color: progress == 2 ? Colors.green : Colors.blue,
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.medication, size: 32, color: Colors.orange),
              const SizedBox(height: 8),
              Text(
                "$progress/2",
                style: const TextStyle(fontSize: 20),
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
  const MedicationItem({super.key, required this.name, required this.time});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const CircleAvatar(backgroundColor: Colors.yellow),
      title: Text(name),
      trailing: Text(time),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MedInfoPage(name: name, time: time)),
        );
      },
    );
  }
}

// =======================
// Dummy SettingsPage
// =======================

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pengaturan")),
      body: const Center(child: Text("Halaman Pengaturan")),
    );
  }
}
