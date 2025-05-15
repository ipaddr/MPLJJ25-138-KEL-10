import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top icons (notification and settings)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 12.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_none,
                      color: Colors.amber,
                    ),
                    onPressed: () {
                      // Tambahkan logika notifikasi di sini
                    },
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.settings_outlined,
                      color: Colors.black54,
                    ),
                    onPressed: () {
                      // Tambahkan logika pengaturan di sini
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Ilustrasi (harus tersedia di folder assets/images)
            SizedBox(
              height: 200,
              child: Image.asset(
                'assets/images/calendar_medicine.png', // Ganti dengan path sesuai asset kamu
                fit: BoxFit.contain,
              ),
            ),

            const SizedBox(height: 30),

            // Judul
            const Text(
              'Kelola obat\npasien Anda',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),

            const SizedBox(height: 16),

            // Subjudul
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 30.0),
              child: Text(
                'Input jadwal obat pasien agar sistem dapat mengingatkan sesuai waktu yang ditentukan',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),

            const Spacer(),

            // Tombol Tambahkan Obat
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    // Tambahkan aksi navigasi ke halaman input obat
                  },
                  child: const Text(
                    'Tambahkan Obat',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Tombol Logout
            TextButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
