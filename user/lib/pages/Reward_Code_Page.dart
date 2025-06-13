import 'package:flutter/material.dart';

class RewardCodePage extends StatelessWidget {
  final String rewardKey; // Menerima kunci reward

  const RewardCodePage({
    super.key,
    required this.rewardKey, // Tandai sebagai required
  });

  @override
  Widget build(BuildContext context) {
    // Pastikan rewardKey cukup panjang sebelum menggunakan substring
    final String displayRewardKey =
        rewardKey.length >= 5
            ? rewardKey.substring(0, 5).toUpperCase()
            : rewardKey.toUpperCase(); // Fallback jika terlalu pendek

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.3),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Kupon hadiah Anda!",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Image.asset(
                'assets/images/voucher.png',
                height: 80,
              ), // Pastikan gambar ini ada
              const SizedBox(height: 12),
              // Tampilkan ID kupon dinamis atau placeholder
              Text(
                "ID Kupon: QW847STY-$displayRewardKey", // Menggunakan displayRewardKey
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Implementasi simpan ke galeri (gunakan package like `image_gallery_saver` or `path_provider` + `image` + `gallery_saver`)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Fitur simpan ke Gallery akan segera hadir!",
                      ),
                      backgroundColor: Colors.blue,
                    ),
                  );
                },
                icon: const Icon(Icons.download),
                label: const Text("Simpan di Gallery"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size(double.infinity, 44),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                    true,
                  ); // Kembali ke RewardPage dan tandai sudah klaim
                },
                child: const Text("Kembali"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
