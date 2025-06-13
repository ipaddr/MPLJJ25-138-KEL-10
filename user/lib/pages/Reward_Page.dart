import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Untuk mendapatkan user ID
import 'package:user/services/auth_service.dart'; // Import AuthService user
import 'reward_code_page.dart'; // Import halaman kode kupon

class RewardPage extends StatefulWidget {
  const RewardPage({super.key});

  @override
  State<RewardPage> createState() => _RewardPageState();
}

class _RewardPageState extends State<RewardPage> {
  final User? _currentUser = AuthService.getCurrentUser();

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(
        body: Center(child: Text("Anda harus login untuk melihat hadiah.")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Hadiah Apresiasi")),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: AuthService.getUserRewards(_currentUser!.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final Map<String, dynamic> userRewards = snapshot.data ?? {};
          final bool reward1Claimed =
              userRewards['minumObat2Hari2KaliClaimed'] ?? false;
          final bool reward2Claimed =
              userRewards['minumObatSemingguPenuhClaimed'] ?? false;
          // Tambahkan deklarasi untuk reward lain jika ada di Firestore
          final bool rewardTanpaPutusClaimed =
              userRewards['minumObatTanpaPutusClaimed'] ?? false;
          final bool rewardSampaiHabisClaimed =
              userRewards['minumObatSampaiHabisClaimed'] ?? false;

          return FutureBuilder<Map<String, int>>(
            // Memeriksa progress untuk reward "2x dalam 2 hari"
            future: AuthService.getDosesTakenStats(
              userId: _currentUser!.uid,
              daysAgo: 2,
            ),
            builder: (context, dosesStatsSnapshot) {
              bool reward1Completed = false;
              if (dosesStatsSnapshot.connectionState == ConnectionState.done &&
                  dosesStatsSnapshot.hasData) {
                final stats = dosesStatsSnapshot.data!;
                // Kriteria: min 2 dosis diminum dalam 2 hari terakhir.
                reward1Completed = stats['taken']! >= 2;
              }

              // Menghitung status reward "Minum obat seminggu penuh"
              return FutureBuilder<int>(
                future: AuthService.getConsecutiveDaysCompleted(
                  _currentUser!.uid,
                ),
                builder: (context, consecutiveDaysSnapshot) {
                  bool reward2Completed = false;
                  if (consecutiveDaysSnapshot.connectionState ==
                          ConnectionState.done &&
                      consecutiveDaysSnapshot.hasData) {
                    reward2Completed =
                        consecutiveDaysSnapshot.data! >=
                        7; // Kriteria: 7 hari berturut-turut
                  }

                  // TODO: Tambahkan FutureBuilder/logika untuk reward "tanpa putus" dan "sampai habis"
                  bool reward3Completed = false; // Placeholder
                  bool reward4Completed = false; // Placeholder

                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text(
                          "Kupon apresiasi setara dengan nilai uang dan dapat ditukarkan dengan uang",
                          style: TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        // Reward 1: Minum obat 2x dalam 2 hari
                        _buildTask(
                          "Minum obat 2x dalam 2 hari",
                          reward1Completed,
                          isClaimed: reward1Claimed, // Teruskan status klaim
                          rewardKey:
                              'minumObat2Hari2KaliClaimed', // Kunci untuk reward ini
                        ),
                        // Reward 2: Minum obat seminggu penuh
                        _buildTask(
                          "Minum obat seminggu penuh",
                          reward2Completed,
                          isClaimed:
                              reward2Claimed, // Status klaim untuk reward ini
                          rewardKey: 'minumObatSemingguPenuhClaimed',
                        ),
                        // Reward 3: Minum obat tanpa putus (ganti false dengan logika sebenarnya)
                        _buildTask(
                          "Minum obat tanpa putus (30 hari)", // Contoh kriteria
                          reward3Completed, // Ganti dengan logika deteksi completed
                          isClaimed: rewardTanpaPutusClaimed,
                          rewardKey: 'minumObatTanpaPutusClaimed',
                        ),
                        // Reward 4: Minum obat sampai habis (ganti false dengan logika sebenarnya)
                        _buildTask(
                          "Minum obat sampai habis",
                          reward4Completed, // Ganti dengan logika deteksi completed
                          isClaimed: rewardSampaiHabisClaimed,
                          rewardKey: 'minumObatSampaiHabisClaimed',
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTask(
    String title,
    bool completed, {
    // isFirst tidak lagi diperlukan untuk logika onTap
    required bool isClaimed, // Menerima status klaim
    String? rewardKey, // Kunci reward untuk update Firestore
  }) {
    return GestureDetector(
      // Hanya bisa ditekan jika completed, belum diklaim, dan rewardKey tidak null
      onTap:
          completed && !isClaimed && rewardKey != null
              ? () => _goToRewardCodePage(rewardKey!)
              : null,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: Text(title)),
            Row(
              children: [
                if (isClaimed) // Jika sudah diklaim, tampilkan centang hijau
                  const Icon(Icons.check_circle, color: Colors.green)
                else // Jika belum diklaim
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: completed ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      completed ? 'Selesai' : 'Belum',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _goToRewardCodePage(String rewardKey) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RewardCodePage(rewardKey: rewardKey),
      ), // Teruskan rewardKey
    );

    if (result == true) {
      // Reward telah diklaim dari RewardCodePage, update di Firestore
      await AuthService.updateRewardClaimStatus(
        _currentUser!.uid,
        rewardKey,
        true,
      );
      if (mounted) {
        // Pastikan widget masih mounted sebelum menampilkan SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Kupon berhasil diklaim!',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}
