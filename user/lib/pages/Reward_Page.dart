import 'package:flutter/material.dart';
import 'reward_code_page.dart'; // Import halaman kode kupon

class RewardPage extends StatefulWidget {
  const RewardPage({super.key});

  @override
  State<RewardPage> createState() => _RewardPageState();
}

class _RewardPageState extends State<RewardPage> {
  bool claimed = false;

  Future<void> _goToRewardCodePage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RewardCodePage()),
    );

    if (result == true) {
      setState(() {
        claimed = true;
      });
    }
  }

  Widget _buildTask(String title, bool completed, {bool isFirst = false}) {
    return GestureDetector(
      onTap: completed && isFirst && !claimed ? _goToRewardCodePage : null,
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
                if (claimed && isFirst)
                  const Icon(Icons.check_circle, color: Colors.green)
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Hadiah Apresiasi")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "Kupon apresiasi setara dengan nilai uang dan dapat ditukarkan dengan uang",
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            _buildTask("Minum obat 2x dalam 2 hari", true, isFirst: true),
            _buildTask("Minum obat seminggu penuh", false),
            _buildTask("Minum obat tanpa putus", false),
            _buildTask("Minum obat sampai habis", false),
          ],
        ),
      ),
    );
  }
}
