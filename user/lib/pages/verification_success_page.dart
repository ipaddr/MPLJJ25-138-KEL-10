import 'package:flutter/material.dart';
import 'dart:async';

class VerificationSuccessPage extends StatefulWidget {
  // Tambahkan parameter untuk status sukses dan pesan
  final bool isSuccess;
  final String message;

  const VerificationSuccessPage({
    super.key,
    this.isSuccess = true, // Default: sukses
    this.message =
        "Akun Anda telah berhasil diverifikasi oleh admin.", // Default pesan sukses
  });

  @override
  State<VerificationSuccessPage> createState() =>
      _VerificationSuccessPageState();
}

class _VerificationSuccessPageState extends State<VerificationSuccessPage> {
  @override
  void initState() {
    super.initState();

    // Navigasi otomatis ke halaman login setelah 3 detik
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login', // Kembali ke halaman login
          (route) => false,
        );
      }
    });
  }

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
              Icon(
                widget.isSuccess
                    ? Icons.verified
                    : Icons.cancel, // Icon berdasarkan status
                size: 100,
                color:
                    widget.isSuccess
                        ? Colors.green
                        : Colors.red, // Warna berdasarkan status
              ),
              const SizedBox(height: 32),
              Text(
                widget.isSuccess
                    ? "Akun berhasil diverifikasi!"
                    : "Verifikasi akun gagal!", // Judul berdasarkan status
                style: TextStyle(
                  fontFamily: 'Roboto', // Menggunakan font Roboto
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color:
                      widget.isSuccess
                          ? Colors.blue
                          : Colors.red, // Warna berdasarkan status
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                widget.message, // Pesan dinamis
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 14,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        widget.isSuccess
                            ? Colors.blue
                            : Colors.red, // Warna tombol berdasarkan status
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/login',
                      (route) => false,
                    );
                  },
                  child: Text(
                    widget.isSuccess
                        ? "Lanjutkan ke Login"
                        : "Kembali ke Login", // Teks tombol dinamis
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontFamily: 'Roboto',
                    ), // Menggunakan font Roboto
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
