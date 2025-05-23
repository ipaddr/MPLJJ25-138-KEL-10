import 'package:flutter/material.dart';

class RewardClaimedPage extends StatelessWidget {
  const RewardClaimedPage({super.key});

  Widget _buildTask(String title, bool completed) {
    return ListTile(
      title: Text(title),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: completed ? Colors.green : Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          completed ? 'Selesai' : 'Belum',
          style: const TextStyle(color: Colors.white),
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
            _buildTask("Minum obat 2 dalam 2 hari", true),
            _buildTask("Minum obat seminggu penuh", false),
            _buildTask("Minum obat tanpa putus", false),
            _buildTask("Minum obat sampai habis", false),
          ],
        ),
      ),
    );
  }
}
