// Path: result_photo_page.dart
import 'package:flutter/material.dart';
import 'package:user/services/auth_service.dart'; // Import AuthService User
import 'package:firebase_auth/firebase_auth.dart'; // Untuk mendapatkan UID user

class ResultPhotoPage extends StatefulWidget {
  final String scheduleId;
  final String doseTime;
  final bool isPhotoVerified; // Hasil dari deteksi wajah

  const ResultPhotoPage({
    super.key,
    required this.scheduleId,
    required this.doseTime,
    required this.isPhotoVerified,
  });

  @override
  State<ResultPhotoPage> createState() => _ResultPhotoPageState();
}

class _ResultPhotoPageState extends State<ResultPhotoPage> {
  final User? _currentUser = AuthService.getCurrentUser();
  bool _isSending = false;

  Future<void> _sendVerificationResult() async {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User tidak login. Gagal mengirim verifikasi.'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.pop(context, false); // Kembali ke Home/login
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      if (widget.isPhotoVerified) {
        // Panggil fungsi untuk menandai obat sudah diminum di Firestore
        await AuthService.updateDoseTakenStatus(
          userId: _currentUser!.uid,
          scheduleId: widget.scheduleId,
          doseTime: widget.doseTime,
          date: DateTime.now(), // Tanggal saat ini
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
        Navigator.pop(
          context,
          true,
        ); // Kembali ke home_page dengan status sukses (refresh)
      } else {
        // Jika foto tidak terverifikasi, kembali ke halaman sebelumnya dengan pesan gagal
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verifikasi foto gagal. Silakan coba lagi.'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context, false); // Kembali ke TakePhotoPage untuk ulangi
      }
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
      Navigator.pop(context, false); // Kembali dengan status gagal
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            // Jika foto gagal diverifikasi, tombol kembali akan mengulang proses
            // Jika sukses, tombol ini seharusnya tidak terlalu relevan setelah pengiriman
            if (!widget.isPhotoVerified) {
              Navigator.pop(
                context,
                false,
              ); // Kembali ke take_photo_page untuk ulangi
            } else {
              // Jika sudah sukses tapi belum dikirim, atau sudah dikirim, kembali ke home
              Navigator.pop(context, true); // Kembali ke home_page
            }
          },
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.isPhotoVerified
                    ? Icons.check_circle_outline
                    : Icons.cancel_outlined,
                size: 100,
                color: widget.isPhotoVerified ? Colors.green : Colors.red,
              ),
              const SizedBox(height: 32),
              Text(
                widget.isPhotoVerified
                    ? "Foto berhasil diverifikasi!"
                    : "Foto gagal diverifikasi!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color:
                      widget.isPhotoVerified
                          ? const Color(0xFF0072CE)
                          : Colors.red,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.isPhotoVerified
                    ? "Wajah Anda terdeteksi dengan jelas. Silakan kirim verifikasi."
                    : "Wajah tidak terdeteksi atau foto tidak jelas. Silakan ulangi.",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      _isSending
                          ? null
                          : () {
                            if (widget.isPhotoVerified) {
                              _sendVerificationResult(); // Jika berhasil, kirim
                            } else {
                              Navigator.pop(
                                context,
                                false,
                              ); // Jika gagal, kembali untuk ulangi
                            }
                          },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor:
                        widget.isPhotoVerified
                            ? const Color(0xFF0072CE)
                            : Colors.red, // Warna tombol dinamis
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child:
                      _isSending
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : Text(
                            widget.isPhotoVerified
                                ? "Kirim Verifikasi"
                                : "Ulangi Selfie", // Teks tombol dinamis
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                ),
              ),
              if (widget.isPhotoVerified) ...[
                // Hanya tampilkan tombol "Ulangi" jika foto sudah terverifikasi (opsi lain)
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(
                        context,
                        false,
                      ); // Kembali ke TakePhotoPage untuk ulangi
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Ulangi',
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
