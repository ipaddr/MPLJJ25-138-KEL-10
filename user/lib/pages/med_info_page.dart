import 'package:flutter/material.dart';
import 'verification_warning_page.dart'; 

class MedInfoPage extends StatelessWidget {
  final String name;
  final String time;

  const MedInfoPage({super.key, required this.name, required this.time});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.medication_liquid, size: 80, color: Colors.orange),
            const SizedBox(height: 24),
            const Text(
              "Sudah minum obat Anda?",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
                    const SizedBox(height: 12),
                    Text("Jadwal: $time, Rabu"),
                    const Text("Dosis: 4 Tablet (40mg)"),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // Navigasi ke halaman verifikasi warning
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const VerificationWarningPage(),
                  ),
                );
              },
              icon: const Icon(Icons.check_circle),
              label: const Text("Verifikasi"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
