import 'package:flutter/material.dart';
import 'verification_warning_page.dart';

class MedInfoPage extends StatelessWidget {
  final String name;
  final String time;
  final String dose; // ✅ Tambah parameter dosis

  const MedInfoPage({
    super.key,
    required this.name,
    required this.time,
    required this.dose,
  });

  @override
  Widget build(BuildContext context) {
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
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        )
                      ],
                    ),
                    child: const Icon(Icons.info, color: Colors.amber, size: 16),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Sudah minum obat Anda?",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Image.asset(
                  'assets/images/pill.png',
                  height: 60,
                ),
                const SizedBox(height: 16),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF007BCE),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Jadwal
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 18, color: Color(0xFF007BCE)),
                    const SizedBox(width: 8),
                    Text(
                      "Jadwal $time, Rabu",
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF007BCE),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Dosis
                Row(
                  children: [
                    const Icon(Icons.description_outlined,
                        size: 18, color: Color(0xFF007BCE)),
                    const SizedBox(width: 8),
                    Text(
                      dose,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF007BCE),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Tombol Verifikasi
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const VerificationWarningPage(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007BCE),
                      foregroundColor: Colors.white, // ✅ teks tombol putih
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
                        color: Colors.white, // ✅ pastikan ini juga putih
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
