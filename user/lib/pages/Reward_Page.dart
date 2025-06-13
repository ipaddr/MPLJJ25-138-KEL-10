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
            // Tangani error dengan lebih baik, misal jika field 'rewards' tidak ada atau formatnya salah
            // print("Error fetching user rewards: ${snapshot.error}"); // Debugging
            return Center(
              child: Text("Error memuat hadiah: ${snapshot.error}"),
            );
          }

          // PERBAIKAN UTAMA: Konversi data secara aman
          final Map<String, dynamic> userRewards = Map<String, dynamic>.from(
            snapshot.data ?? {},
          );

          final bool reward1Claimed =
              userRewards['minumObat2Hari2KaliClaimed'] ?? false;
          final bool reward2Claimed =
              userRewards['minumObatSemingguPenuhClaimed'] ?? false;
          final bool rewardTanpaPutusClaimed =
              userRewards['minumObatTanpaPutusClaimed'] ?? false;
          final bool rewardSampaiHabisClaimed =
              userRewards['minumObatSampaiHabisClaimed'] ?? false;

          return FutureBuilder<Map<String, int>>(
            future: AuthService.getDosesTakenStats(
              userId: _currentUser!.uid,
              daysAgo: 2,
            ),
            builder: (context, dosesStatsSnapshot) {
              bool reward1Completed = false;
              if (dosesStatsSnapshot.connectionState == ConnectionState.done &&
                  dosesStatsSnapshot.hasData) {
                final stats = dosesStatsSnapshot.data!;
                reward1Completed = stats['taken']! >= 2;
              }

              return FutureBuilder<int>(
                future: AuthService.getConsecutiveDaysCompleted(
                  _currentUser!.uid,
                ),
                builder: (context, consecutiveDaysSnapshot) {
                  bool reward2Completed = false;
                  if (consecutiveDaysSnapshot.connectionState ==
                          ConnectionState.done &&
                      consecutiveDaysSnapshot.hasData) {
                    reward2Completed = consecutiveDaysSnapshot.data! >= 7;
                  }

                  // === Logika untuk reward "Minum obat tanpa putus" ===
                  return FutureBuilder<bool>(
                    future: AuthService.hasCompletedConsecutiveDays(
                      _currentUser!.uid,
                      30,
                    ), // Kriteria 30 hari tanpa putus
                    builder: (context, reward3CompletedSnapshot) {
                      bool reward3Completed = false;
                      if (reward3CompletedSnapshot.connectionState ==
                              ConnectionState.done &&
                          reward3CompletedSnapshot.hasData) {
                        reward3Completed = reward3CompletedSnapshot.data!;
                      }

                      // === Logika untuk reward "Minum obat sampai habis" ===
                      return FutureBuilder<bool>(
                        future: AuthService.hasCompletedAllMedication(
                          _currentUser!.uid,
                        ),
                        builder: (context, reward4CompletedSnapshot) {
                          bool reward4Completed = false;
                          if (reward4CompletedSnapshot.connectionState ==
                                  ConnectionState.done &&
                              reward4CompletedSnapshot.hasData) {
                            reward4Completed = reward4CompletedSnapshot.data!;
                          }

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
                                _buildTask(
                                  "Minum obat 2x dalam 2 hari",
                                  reward1Completed,
                                  isClaimed: reward1Claimed,
                                  rewardKey: 'minumObat2Hari2KaliClaimed',
                                ),
                                _buildTask(
                                  "Minum obat seminggu penuh",
                                  reward2Completed,
                                  isClaimed: reward2Claimed,
                                  rewardKey: 'minumObatSemingguPenuhClaimed',
                                ),
                                _buildTask(
                                  "Minum obat tanpa putus (30 hari)",
                                  reward3Completed,
                                  isClaimed: rewardTanpaPutusClaimed,
                                  rewardKey: 'minumObatTanpaPutusClaimed',
                                ),
                                _buildTask(
                                  "Minum obat sampai habis",
                                  reward4Completed,
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
    required bool isClaimed,
    String? rewardKey,
  }) {
    return GestureDetector(
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
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: Text(title)),
            Row(
              children: [
                if (isClaimed)
                  const Icon(Icons.check_circle, color: Colors.green)
                else
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
      MaterialPageRoute(builder: (_) => RewardCodePage(rewardKey: rewardKey)),
    );

    if (result == true) {
      await AuthService.updateRewardClaimStatus(
        _currentUser!.uid,
        rewardKey,
        true,
      );
      if (mounted) {
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
