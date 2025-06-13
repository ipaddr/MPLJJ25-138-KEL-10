import 'package:flutter/material.dart';
import 'dart:async';
import 'verification_success_page.dart'; // pastikan import halaman tujuan

class WaitingVerificationPage extends StatefulWidget {
  const WaitingVerificationPage({super.key});

  @override
  State<WaitingVerificationPage> createState() =>
      _WaitingVerificationPageState();
}

class _WaitingVerificationPageState extends State<WaitingVerificationPage> {
  @override
  void initState() {
    super.initState();
    // Navigasi otomatis setelah 2 detik
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const VerificationSuccessPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<bool?>(
        stream: _verificationStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Menampilkan indikator loading saat menunggu data pertama kali
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    strokeWidth: 6,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    "Menunggu konfirmasi admin...",
                    style: TextStyle(
                      fontFamily: 'Roboto', // Menggunakan font Roboto
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0072CE), // Warna yang konsisten
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      "Proses ini mungkin akan sedikit memakan waktu, mohon bersabar.",
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            // Handle error, mungkin ada masalah koneksi atau Firestore rules
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => const VerificationSuccessPage(
                        isSuccess: false,
                        message:
                            "Terjadi kesalahan saat memeriksa status verifikasi. Silakan coba lagi.",
                      ),
                ),
              );
            });
            return const SizedBox.shrink(); // Widget kosong sementara navigasi
          }

          final isVerified = snapshot.data;

          if (isVerified == true) {
            // Jika isVerified adalah true, navigasi ke halaman sukses
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => const VerificationSuccessPage(isSuccess: true),
                ),
              );
            });
            return const SizedBox.shrink(); // Widget kosong sementara navigasi
          } else if (isVerified == false) {
            // Jika isVerified adalah false (secara eksplisit, user ditolak atau belum), tetap di halaman ini.
            // Atau, jika ada logic lain untuk penolakan eksplisit (misal field 'isRejected: true')
            // untuk saat ini, kita tetap di halaman menunggu jika false.
            // Jika dokumen dihapus, snapshot.data akan null.
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    strokeWidth: 6,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    "Menunggu konfirmasi admin...",
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0072CE),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      "Proses ini mungkin akan sedikit memakan waktu, mohon bersabar.",
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            );
          } else {
            // snapshot.data adalah null, artinya dokumen user mungkin dihapus atau tidak ditemukan
            // Ini bisa jadi indikasi bahwa admin menolak user dengan menghapus dokumennya.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => const VerificationSuccessPage(
                        isSuccess: false,
                        message:
                            "Verifikasi akun ditolak atau akun tidak ditemukan. Silakan hubungi admin.",
                      ),
                ),
              );
            });
            return const SizedBox.shrink(); // Widget kosong sementara navigasi
          }
        },
      ),
    );
  }
}
