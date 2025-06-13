import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:user/services/auth_service.dart';
import 'reward_code_page.dart';

// Model untuk menampung semua status reward agar lebih rapi
class RewardStatus {
  final bool minumObat2Hari2KaliCompleted;
  final bool minumObatSemingguPenuhCompleted;
  final bool minumObatTanpaPutusCompleted;
  final bool minumObatSampaiHabisCompleted;

  RewardStatus({
    required this.minumObat2Hari2KaliCompleted,
    required this.minumObatSemingguPenuhCompleted,
    required this.minumObatTanpaPutusCompleted,
    required this.minumObatSampaiHabisCompleted,
  });
}

class RewardPage extends StatefulWidget {
  const RewardPage({super.key});

  @override
  State<RewardPage> createState() => _RewardPageState();
}

class _RewardPageState extends State<RewardPage> {
  final User? _currentUser = AuthService.getCurrentUser();
  Future<RewardStatus>? _rewardStatusFuture;

  @override
  void initState() {
    super.initState();
    if (_currentUser != null) {
      _rewardStatusFuture = _loadAllRewardStatus();
    }
  }

  // Fungsi untuk memuat semua data secara paralel dengan Future.wait
  Future<RewardStatus> _loadAllRewardStatus() async {
    final results = await Future.wait([
      AuthService.getDosesTakenStats(userId: _currentUser!.uid, daysAgo: 2),
      AuthService.hasCompletedConsecutiveDays(_currentUser!.uid, 7),
      AuthService.hasCompletedConsecutiveDays(_currentUser!.uid, 30),
      AuthService.hasCompletedAllMedication(_currentUser!.uid),
    ]);

    return RewardStatus(
      minumObat2Hari2KaliCompleted:
          (results[0] as Map<String, int>)['taken']! >= 2,
      minumObatSemingguPenuhCompleted: results[1] as bool,
      minumObatTanpaPutusCompleted: results[2] as bool,
      minumObatSampaiHabisCompleted: results[3] as bool,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return Scaffold(
        appBar: _buildAppBar(),
        body: const Center(
          child: Text("Anda harus login untuk melihat hadiah."),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: AuthService.getUserRewards(_currentUser!.uid),
        builder: (context, claimedStatusSnapshot) {
          if (claimedStatusSnapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (claimedStatusSnapshot.hasError) {
            return Center(child: Text("Error: ${claimedStatusSnapshot.error}"));
          }

          final userRewards = Map<String, dynamic>.from(
            claimedStatusSnapshot.data ?? {},
          );
          final reward1Claimed =
              userRewards['minumObat2Hari2KaliClaimed'] ?? false;
          final reward2Claimed =
              userRewards['minumObatSemingguPenuhClaimed'] ?? false;
          final reward3Claimed =
              userRewards['minumObatTanpaPutusClaimed'] ?? false;
          final reward4Claimed =
              userRewards['minumObatSampaiHabisClaimed'] ?? false;

          return FutureBuilder<RewardStatus>(
            future: _rewardStatusFuture,
            builder: (context, completionStatusSnapshot) {
              if (completionStatusSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (completionStatusSnapshot.hasError) {
                return Center(
                  child: Text("Error: ${completionStatusSnapshot.error}"),
                );
              }
              if (!completionStatusSnapshot.hasData) {
                return const Center(
                  child: Text("Tidak dapat memuat status misi."),
                );
              }

              final statuses = completionStatusSnapshot.data!;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0072CE).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        "Selesaikan misi kepatuhan minum obat untuk mendapatkan kupon apresiasi yang dapat ditukarkan.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Urbanist',
                          fontSize: 15,
                          color: Color(0xFF005A9E),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildRewardCard(
                      title: "Pemanasan",
                      subtitle:
                          "Minum obat minimal 2 kali dalam 2 hari terakhir.",
                      isCompleted: statuses.minumObat2Hari2KaliCompleted,
                      isClaimed: reward1Claimed,
                      rewardKey: 'minumObat2Hari2KaliClaimed',
                    ),
                    _buildRewardCard(
                      title: "Konsisten Seminggu",
                      subtitle:
                          "Minum obat setiap hari selama 7 hari berturut-turut.",
                      isCompleted: statuses.minumObatSemingguPenuhCompleted,
                      isClaimed: reward2Claimed,
                      rewardKey: 'minumObatSemingguPenuhClaimed',
                    ),
                    _buildRewardCard(
                      title: "Disiplin Sebulan",
                      subtitle:
                          "Minum obat setiap hari selama 30 hari tanpa putus.",
                      isCompleted: statuses.minumObatTanpaPutusCompleted,
                      isClaimed: reward3Claimed,
                      rewardKey: 'minumObatTanpaPutusClaimed',
                    ),
                    _buildRewardCard(
                      title: "Tuntas!",
                      subtitle: "Selesaikan seluruh jadwal pengobatan Anda.",
                      isCompleted: statuses.minumObatSampaiHabisCompleted,
                      isClaimed: reward4Claimed,
                      rewardKey: 'minumObatSampaiHabisClaimed',
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text(
        'Hadiah & Misi',
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
                  side: BorderSide(color: Colors.grey[300]!, width: 1),
                ),
              ),
              onPressed:
                  () =>
                      Navigator.canPop(context) ? Navigator.pop(context) : null,
              child: const Icon(
                Icons.arrow_back,
                size: 24,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    );
  }

  Widget _buildRewardCard({
    required String title,
    required String subtitle,
    required bool isCompleted,
    required bool isClaimed,
    required String rewardKey,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Urbanist',
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _buildStatusButton(
            isCompleted: isCompleted,
            isClaimed: isClaimed,
            rewardKey: rewardKey,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusButton({
    required bool isCompleted,
    required bool isClaimed,
    required String rewardKey,
  }) {
    if (isClaimed) {
      return const Column(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 28),
          SizedBox(height: 4),
          Text(
            "Diklaim",
            style: TextStyle(
              fontFamily: 'Urbanist',
              fontSize: 12,
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    }

    if (isCompleted) {
      return ElevatedButton(
        onPressed: () => _goToRewardCodePage(rewardKey),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0072CE),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
        child: const Text(
          "Klaim",
          style: TextStyle(
            fontFamily: 'Urbanist',
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    // Belum Selesai
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Belum Selesai',
        style: TextStyle(
          fontFamily: 'Urbanist',
          color: Colors.grey.shade700,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Future<void> _goToRewardCodePage(String rewardKey) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RewardCodePage(rewardKey: rewardKey)),
    );

    if (result == true && mounted) {
      await AuthService.updateRewardClaimStatus(
        _currentUser!.uid,
        rewardKey,
        true,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Kupon berhasil diklaim!',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green,
        ),
      );
      // Refresh status
      setState(() {
        _rewardStatusFuture = _loadAllRewardStatus();
      });
    }
  }
}
