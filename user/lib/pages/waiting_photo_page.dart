// Path: waiting_photo_page.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'result_photo_page.dart'; // Halaman hasil foto

class WaitingPhotoPage extends StatefulWidget {
  final String scheduleId;
  final String doseTime;
  // final String? imagePath; // Jika foto dari kamera perlu diproses di sini

  const WaitingPhotoPage({
    super.key,
    required this.scheduleId,
    required this.doseTime,
    // this.imagePath,
  });

  @override
  State<WaitingPhotoPage> createState() => _WaitingPhotoPageState();
}

class _WaitingPhotoPageState extends State<WaitingPhotoPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  // Timer tidak lagi digunakan untuk navigasi, StreamBuilder di TakePhotoPage yang handle
  bool _isVerificationSuccessful = false; // Hasil dari simulasi verifikasi

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2), // Durasi animasi dots
    )..repeat();

    _performFaceVerification(); // Memulai proses verifikasi wajah
  }

  Future<void> _performFaceVerification() async {
    // Simulasi proses deteksi wajah (misal, ML Kit)
    await Future.delayed(const Duration(seconds: 3)); // Simulasi waktu proses

    // Logika simulasi hasil verifikasi:
    // Contoh: 80% kemungkinan berhasil, 20% kemungkinan gagal
    final bool simulatedResult =
        DateTime.now().millisecond % 10 < 8; // Random success/fail

    if (mounted) {
      setState(() {
        _isVerificationSuccessful = simulatedResult;
      });
      // Navigasi ke ResultPhotoPage dengan hasil verifikasi
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (_) => ResultPhotoPage(
                scheduleId: widget.scheduleId,
                doseTime: widget.doseTime,
                isPhotoVerified: _isVerificationSuccessful,
              ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    // _timer.cancel(); // Timer sudah dihapus
    super.dispose();
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
              Stack(
                alignment: Alignment.center,
                children: [
                  Opacity(
                    opacity: 0.4,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset(
                        'assets/images/selfie_blur.png', // Gambar blur selfie
                        height: 320,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const FaceDots(), // Titik-titik di wajah
                ],
              ),
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(
                  'Memverifikasi foto Anda...\n'
                  'Mohon tunggu sebentar', // Pesan disesuaikan
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Roboto', // Font konsisten
                    fontSize: 16,
                    color: Colors.black45,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Tambahkan indikator loading jika perlu
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Color(0xFF0072CE),
                ), // Warna konsisten
                strokeWidth: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// FaceDots tetap sama
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
        width: 12,
        height: 12,
        decoration: const BoxDecoration(
          color: Colors.black,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
