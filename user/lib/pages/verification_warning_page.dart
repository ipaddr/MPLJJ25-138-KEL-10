import 'package:flutter/material.dart';
import 'take_photo_page.dart'; // Pastikan file ini tersedia

class VerificationWarningPage extends StatelessWidget {
  final String scheduleId;
  final String doseTime;

  const VerificationWarningPage({
    super.key,
    required this.scheduleId,
    required this.doseTime,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Image.asset(
                      'assets/images/selfie_frame.png', // Pastikan gambar ini ada
                      height: 150,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Perhatikan Sebelum Verifikasi',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0072CE),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Pastikan Anda mengikuti panduan berikut untuk hasil verifikasi yang akurat.',
                      style: TextStyle(
                        fontFamily: 'Urbanist',
                        fontSize: 15,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    _buildChecklistCard(),
                  ],
                ),
              ),
            ),
            _buildStartButton(context),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      title: const Text(
        "Panduan Verifikasi",
        style: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0072CE),
        ),
      ),
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: 48,
            height: 48,
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Icon(
                Icons.arrow_back,
                size: 24,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChecklistCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _buildChecklistItem(
            "Arahkan kamera ke wajah dan sesuaikan dengan bingkai.",
          ),
          const Divider(height: 24),
          _buildChecklistItem(
            "Pastikan tidak memakai masker, kacamata hitam, atau topi.",
          ),
          const Divider(height: 24),
          _buildChecklistItem(
            "Pastikan wajah berada di tempat dengan cahaya yang cukup.",
          ),
          const Divider(height: 24),
          _buildChecklistItem(
            "Pastikan hanya satu wajah yang terdeteksi oleh kamera.",
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle, color: Colors.green, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 15, fontFamily: 'Urbanist'),
          ),
        ),
      ],
    );
  }

  Widget _buildStartButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          // FUNGSI TOMBOL TIDAK DIUBAH
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) =>
                      TakePhotoPage(scheduleId: scheduleId, doseTime: doseTime),
            ),
          );
          if (result == true && context.mounted) {
            Navigator.pop(context, true);
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0072CE),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Mulai Verifikasi',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Urbanist',
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
