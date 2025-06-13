// Path: verification_done_page.dart
import 'package:flutter/material.dart';

class VerificationDonePage extends StatelessWidget {
  // Anda bisa meneruskan data jadwal jika perlu ditampilkan di sini
  // final String medicineName;
  // final String doseTime;

  const VerificationDonePage({
    super.key,
    // this.medicineName,
    // this.doseTime,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, size: 100, color: Colors.green),
              const SizedBox(height: 32),
              const Text(
                "Obat berhasil diverifikasi!",
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                "Terima kasih telah melakukan verifikasi. Obat Anda telah ditandai diminum.",
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    // Kembali ke home_page dan hapus semua rute di atasnya
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/home', // Kembali ke home_page
                      (route) => false,
                    );
                  },
                  child: const Text(
                    "Kembali ke Beranda",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
