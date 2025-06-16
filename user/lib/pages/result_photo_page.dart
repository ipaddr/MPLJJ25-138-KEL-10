import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:user/services/auth_service.dart';

class ResultPhotoPage extends StatefulWidget {
  final String scheduleId;
  final String doseTime;
  final bool isPhotoVerified;
  final String imagePath;

  const ResultPhotoPage({
    super.key,
    required this.scheduleId,
    required this.doseTime,
    required this.isPhotoVerified,
    required this.imagePath,
  });

  @override
  State<ResultPhotoPage> createState() => _ResultPhotoPageState();
}

class _ResultPhotoPageState extends State<ResultPhotoPage> {
  final User? _currentUser = AuthService.getCurrentUser();
  bool _isSending = false;

  void _cancelVerification() {
    // Navigasi kembali ke halaman sebelumnya (kemungkinan TakePhotoPage)
    // dan berikan indikasi bahwa verifikasi dibatalkan/gagal.
    Navigator.pop(context, false);
  }

  Future<void> _sendVerificationResult() async {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User tidak login. Gagal mengirim verifikasi.'),
          backgroundColor: Colors.red,
        ),
      );
      _cancelVerification(); // Kembali jika user tidak login
      return;
    }

    setState(() => _isSending = true);

    try {
      // Perbarui status dosis di Firebase
      await AuthService.updateDoseTakenStatus(
        userId: _currentUser!.uid,
        scheduleId: widget.scheduleId,
        doseTime: widget.doseTime,
        date: DateTime.now(),
        isTaken: true,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Verifikasi obat berhasil dikirim!',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green,
        ),
      );

      // --- START NAVIGATION UPDATE ---
      // Setelah berhasil update status di Firebase, navigasi ke WaitingPhotoPage.
      // Gunakan pushReplacementNamed untuk membersihkan stack navigasi dari ResultPhotoPage.
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/waiting-photo', // Route ke halaman menunggu verifikasi
          arguments: {
            'scheduleId': widget.scheduleId,
            'doseTime': widget.doseTime,
            'imagePath': widget.imagePath,
            // isPhotoVerified tidak perlu diteruskan lagi karena di WaitingPhotoPage
            // kita akan menentukan hasil verifikasi final (misalnya dari AI atau simulasi)
            // dan langsung mengarahkan ke VerificationDonePage atau kembali ke ResultPhotoPage
            // jika ada kegagalan verifikasi setelah WaitingPhotoPage.
          },
        );
      }
      // --- END NAVIGATION UPDATE ---

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Terjadi kesalahan saat mengirim verifikasi: $e',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
      _cancelVerification(); // Kembali jika ada error saat mengirim ke Firebase
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool success = widget.isPhotoVerified;
    final Color primaryColor = success ? const Color(0xFF0072CE) : Colors.red;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          // Ketika tombol kembali di AppBar ditekan, kembali ke halaman sebelumnya (TakePhotoPage)
          onPressed: () => Navigator.pop(context, success),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                success ? Icons.check_circle_outline : Icons.cancel_outlined,
                size: 100,
                color: success ? Colors.green : Colors.red,
              ),
              const SizedBox(height: 24),
              Text(
                success ? "Foto berhasil diverifikasi!" : "Foto gagal diverifikasi!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                success
                    ? "Wajah Anda terdeteksi dengan jelas. Silakan kirim verifikasi."
                    : "Wajah tidak terdeteksi atau foto tidak jelas. Silakan ulangi.",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              if (widget.imagePath.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(widget.imagePath),
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 100),
                  ),
                ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSending
                      ? null
                      : () {
                          if (success) {
                            // Jika foto berhasil diverifikasi, kirim hasilnya (yang akan navigasi)
                            _sendVerificationResult();
                          } else {
                            // Jika foto gagal diverifikasi, ulangi proses selfie
                            _cancelVerification();
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          success ? "Kirim Verifikasi" : "Ulangi Selfie",
                          style: const TextStyle(fontSize: 16, color: Colors.white),
                        ),
                ),
              ),
              // Tombol "Ulangi" hanya muncul jika verifikasi berhasil.
              // Jika gagal, tombol utama sudah menjadi "Ulangi Selfie".
              if (success) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _isSending ? null : _cancelVerification, // Navigasi kembali untuk ambil foto baru
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Ulangi Foto', // Teks yang lebih spesifik
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}