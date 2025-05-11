import 'package:flutter/material.dart';

class WelcomeAdminScreen extends StatelessWidget {
  const WelcomeAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Gambar ikon jam + obat
                SizedBox(
                  height: 180,
                  child: Image.asset(
                    'assets/images/welcome_scr.png', // <--- Ganti dengan path gambar Anda
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'Selamat Datang di',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 25,
                    color: Color.fromARGB(255, 252, 134, 0),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Text(
                  'SembuhTBC',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 44,
                    color: Color(0xFF0072CE),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'versi Admin',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 25,
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Asisten digital Anda untuk mengelola\njadwal dan jenis obat pasien dengan\nmudah dan akurat',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 14,
                    color: Color(0xFF0072CE),
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF0072CE),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 105.5,
                      vertical: 19,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Login',
                    style: TextStyle(
                      fontFamily: 'Urbanist',
                      color: Colors.white,
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
