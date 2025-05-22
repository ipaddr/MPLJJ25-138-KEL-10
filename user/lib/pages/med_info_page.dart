// med_info_page.dart
import 'package:flutter/material.dart';

class MedInfoPage extends StatelessWidget {
  final String name;
  final String time;
  const MedInfoPage({super.key, required this.name, required this.time});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text("Sudah minum obat Anda?", style: TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            Text(name, style: const TextStyle(fontSize: 24, color: Colors.blue, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text("Jadwal $time, Rabu\n4 Tablet, 40mg"),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Verifikasi"),
            )
          ],
        ),
      ),
    );
  }
}
