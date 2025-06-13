import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Untuk mendapatkan nama hari
import 'verification_warning_page.dart';

class MedInfoPage extends StatelessWidget {
  final String scheduleId; // ID Dokumen jadwal obat di Firestore
  final String name;
  final String dose;
  final String medicineType; // Tambahkan medicineType dari home_page
  final String doseTime; // Waktu dosis spesifik yang perlu diverifikasi

  const MedInfoPage({
    super.key,
    required this.scheduleId, // Pastikan ini diterima
    required this.name,
    required this.dose,
    required this.medicineType, // Pastikan ini diterima
    required this.doseTime, // Pastikan ini diterima
  });

  @override
  Widget build(BuildContext context) {
    // Dapatkan nama hari ini
    String dayName = DateFormat(
      'EEEE',
      'id_ID',
    ).format(DateTime.now()); // Contoh: "Rabu"

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFEAF6FF),
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.info,
                      color: Colors.amber,
                      size: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Sudah minum obat Anda?",
                  style: TextStyle(
                    fontSize: 18,
                    color: Color(0xFF0072CE), // Warna yang konsisten
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Image.asset(
                  'assets/images/pill.png', // Pastikan gambar ini ada
                  height: 60,
                ),
                const SizedBox(height: 16),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0072CE), // Warna yang konsisten
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Jadwal
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: Color(0xFF0072CE),
                    ), // Warna konsisten
                    const SizedBox(width: 8),
                    Text(
                      "Jadwal $doseTime, $dayName", // Menggunakan doseTime dan dayName
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF0072CE), // Warna konsisten
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Dosis
                Row(
                  children: [
                    const Icon(
                      Icons.description_outlined,
                      size: 18,
                      color: Color(0xFF0072CE),
                    ), // Warna konsisten
                    const SizedBox(width: 8),
                    Text(
                      "$dose ($medicineType)", // Menampilkan dosis dan tipe obat
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF0072CE), // Warna konsisten
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Tombol Verifikasi
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      // Meneruskan scheduleId dan doseTime ke VerificationWarningPage
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => VerificationWarningPage(
                                scheduleId: scheduleId,
                                doseTime: doseTime,
                              ),
                        ),
                      );
                      // Jika kembali dengan true, berarti verifikasi berhasil
                      if (result == true) {
                        Navigator.pop(
                          context,
                          true,
                        ); // Kembali ke HomePage dengan true
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(
                        0xFF0072CE,
                      ), // Warna konsisten
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Verifikasi",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
