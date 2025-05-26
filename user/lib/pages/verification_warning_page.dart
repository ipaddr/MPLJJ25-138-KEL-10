import 'package:flutter/material.dart';
import 'take_photo_page.dart'; // Pastikan file ini tersedia

class VerificationWarningPage extends StatelessWidget {
  const VerificationWarningPage({super.key});

  Widget _buildChecklistItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle, color: Colors.green),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Center(
              child: Image.asset(
                'assets/images/selfie_frame.png',
                height: 180,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Perhatikan sebelum\nmelakukan selfie!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            _buildChecklistItem("Tekan tombol mulai untuk memulai proses"),
            const SizedBox(height: 12),
            _buildChecklistItem("Arahkan kamera ke wajah Anda dan sesuaikan dengan bingkai pada layar"),
            const SizedBox(height: 12),
            _buildChecklistItem("Pastikan tidak memakai aksesoris yang menghalangi wajah seperti masker, kacamata hitam dan topi"),
            const SizedBox(height: 12),
            _buildChecklistItem("Pastikan berada di tempat dengan cahaya terang"),
            const SizedBox(height: 12),
            _buildChecklistItem("Pastikan foto memiliki gambar yang jelas"),
            const SizedBox(height: 12),
            _buildChecklistItem("Pastikan hanya satu wajah yang terdeteksi"),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TakePhotoPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF1E70BF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Mulai',
                 style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
