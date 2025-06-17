import 'dart:io'; // Perlu diimpor untuk File
import 'package:flutter/material.dart';
import 'package:user/pages/verification_done_page.dart'; // Import VerificationDonePage
import 'package:user/pages/result_photo_page.dart'; // Import ResultPhotoPage jika diperlukan

class WaitingResultPage extends StatefulWidget {
  // Nama kelas tetap WaitingResultPage
  final String scheduleId; // <<-- DITAMBAHKAN
  final String doseTime; // <<-- DITAMBAHKAN
  final String imagePath;

  const WaitingResultPage({
    super.key,
    required this.scheduleId, // <<-- DITAMBAHKAN
    required this.doseTime, // <<-- DITAMBAHKAN
    required this.imagePath,
  });

  @override
  State<WaitingResultPage> createState() => _WaitingResultPageState();
}

class _WaitingResultPageState extends State<WaitingResultPage> {
  @override
  void initState() {
    super.initState();
    // Simulasi proses verifikasi AI atau backend
    // Setelah delay, kita akan navigasi ke halaman berikutnya
    Future.delayed(const Duration(seconds: 3), () {
      // Durasi simulasi bisa disesuaikan
      if (mounted) {
        // --- LOGIKA SIMULASI HASIL VERIFIKASI ---
        // Di aplikasi nyata, di sini Anda akan memanggil layanan backend/AI
        // untuk benar-benar memverifikasi foto dan mendapatkan hasilnya.
        // Untuk tujuan demo/pengembangan, kita asumsikan selalu sukses.
        bool isAIVerified =
            true; // Ganti ini dengan hasil sebenarnya dari API verifikasi AI Anda

        if (isAIVerified) {
          // Jika verifikasi AI berhasil, navigasi ke VerificationDonePage
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (_) => VerificationDonePage(
                    scheduleId: widget.scheduleId, // Teruskan scheduleId
                    doseTime: widget.doseTime, // Teruskan doseTime
                  ),
            ),
          );
        } else {
          // Jika verifikasi AI gagal, navigasi kembali ke ResultPhotoPage
          // dengan status gagal untuk memungkinkan pengguna mencoba lagi.
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (_) => ResultPhotoPage(
                    scheduleId: widget.scheduleId,
                    doseTime: widget.doseTime,
                    isPhotoVerified:
                        false, // Beri tahu ResultPhotoPage bahwa ini gagal
                    imagePath: widget.imagePath,
                  ),
            ),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Tampilkan preview foto yang diambil dengan sedikit transparansi
              Stack(
                alignment: Alignment.center,
                children: [
                  Opacity(
                    opacity: 0.4,
                    child: Image.file(
                      File(widget.imagePath),
                      height: 300,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const FaceDots(), // Pastikan FaceDots class tersedia atau diimpor
                ],
              ),
              const SizedBox(height: 40),
              const Text(
                'Memverifikasi foto...',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              const CircularProgressIndicator(color: Color(0xFF0072CE)),
            ],
          ),
        ),
      ),
    );
  }
}

// Pastikan FaceDots class juga ada di file waiting_result_page.dart jika tidak diimpor dari tempat lain.
// Jika sudah ada di file terpisah dan diimpor, Anda bisa menghapus bagian ini.
class FaceDots extends StatelessWidget {
  const FaceDots({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      width: 200,
      child: Stack(
        children: [
          _buildDot(90, 80),
          _buildDot(120, 80),
          _buildDot(105, 110),
          _buildDot(85, 140),
          _buildDot(125, 140),
          _buildDot(105, 160),
        ],
      ),
    );
  }

  Widget _buildDot(double top, double left) {
    return Positioned(
      top: top,
      left: left,
      child: Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          color: Colors.black,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
