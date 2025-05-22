import 'package:flutter/material.dart';

class VerificationWarningPage extends StatelessWidget {
  const VerificationWarningPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: BackButton()),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Image.asset('assets/selfie_warning.png', height: 200),
            const SizedBox(height: 20),
            const Text('Perhatikan sebelum melakukan selfie!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('✓ Tekan tombol mulai untuk proses verifikasi wajah.\n'
                '✓ Pastikan wajah terlihat jelas dan berada di dalam frame.\n'
                '✓ Hindari cahaya berlebih atau terlalu gelap.\n'
                '✓ Jangan memakai masker atau aksesoris.\n'
                '✓ Proses hanya memakan waktu singkat.'),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/take-photo');
              },
              child: const Text('Mulai'),
            ),
          ],
        ),
      ),
    );
  }
}
