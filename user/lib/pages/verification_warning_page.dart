import 'package:flutter/material.dart';
import 'take_photo_page.dart'; // Pastikan file ini tersedia

class VerificationWarningPage extends StatelessWidget {
  const VerificationWarningPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton()),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Image.asset('assets/selfie_warning.png', height: 200),
            const SizedBox(height: 20),
            const Text(
              'Perhatikan sebelum melakukan selfie!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              '✓ Tekan tombol mulai untuk proses verifikasi wajah.\n'
              '✓ Pastikan wajah terlihat jelas dan berada di dalam frame.\n'
              '✓ Hindari cahaya berlebih atau terlalu gelap.\n'
              '✓ Jangan memakai masker atau aksesoris.\n'
              '✓ Proses hanya memakan waktu singkat.',
              textAlign: TextAlign.left,
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TakePhotoPage()),
                );
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text('Mulai'),
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
