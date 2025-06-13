import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'verification_warning_page.dart';

class MedInfoPage extends StatelessWidget {
  final String scheduleId;
  final String name;
  final String dose;
  final String medicineType;
  final String doseTime;

  const MedInfoPage({
    super.key,
    required this.scheduleId,
    required this.name,
    required this.dose,
    required this.medicineType,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            // Header
            const Text(
              "Konfirmasi Dosis Obat",
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 20,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Pastikan Anda akan meminum obat sesuai dengan detail jadwal di bawah ini.",
              style: TextStyle(
                fontFamily: 'Urbanist',
                fontSize: 15,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),

            // Kartu Detail Obat
            _buildInfoCard(),

            const Spacer(),

            // Tombol Verifikasi
            _buildVerificationButton(context),
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
        "Detail Obat",
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

  Widget _buildInfoCard() {
    String dayName = DateFormat('EEEE', 'id_ID').format(DateTime.now());

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Image.asset('assets/images/pill.png', height: 60)),
          const SizedBox(height: 16),
          Center(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                fontFamily: 'Montserrat',
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              "$dose ($medicineType)",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontFamily: 'Urbanist',
              ),
            ),
          ),
          const Divider(height: 40, thickness: 1),
          _buildInfoRow(
            icon: Icons.access_time_filled_rounded,
            title: "Waktu Minum",
            value: doseTime,
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            icon: Icons.calendar_today_rounded,
            title: "Hari Ini",
            value: dayName,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF0072CE), size: 20),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey.shade700,
            fontFamily: 'Urbanist',
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            fontFamily: 'Urbanist',
          ),
        ),
      ],
    );
  }

  Widget _buildVerificationButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          // FUNGSI TOMBOL TIDAK DIUBAH
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
          "Lanjut Verifikasi",
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
