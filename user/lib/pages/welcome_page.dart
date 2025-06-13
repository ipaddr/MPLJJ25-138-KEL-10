import 'package:flutter/material.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Sesuaikan warna latar belakang
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Gambar ikon jam + obat (sesuai welcome_admin_screen)
                SizedBox(
                  height: 180, // Tinggi gambar disesuaikan
                  child: Image.asset(
                    'assets/images/clock_pill.png', // Ganti dengan path gambar yang ada di assets Anda
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 30), // Spasi disesuaikan
                const Text(
                  'Selamat Datang di',
                  style: TextStyle(
                    fontFamily: 'Roboto', // Font Family disesuaikan
                    fontSize: 25, // Ukuran font disesuaikan
                    color: Color.fromARGB(
                      255,
                      252,
                      134,
                      0,
                    ), // Warna disesuaikan
                    fontWeight: FontWeight.w600, // Ketebalan font disesuaikan
                  ),
                ),
                const Text(
                  'SembuhTBC',
                  style: TextStyle(
                    fontFamily: 'Roboto', // Font Family disesuaikan
                    fontSize: 44, // Ukuran font disesuaikan
                    color: Color(0xFF0072CE), // Warna disesuaikan
                    fontWeight: FontWeight.bold, // Ketebalan font disesuaikan
                  ),
                ),
                const Text(
                  'versi Pasien', // Tambahan teks "versi Pasien"
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 25,
                    color: Colors.red, // Warna disesuaikan
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16), // Spasi disesuaikan
                const Text(
                  'Asisten digital Anda untuk mengelola\njadwal pengobatan Anda dengan\nmudah dan akurat', // Teks deskripsi disesuaikan
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Roboto', // Font Family disesuaikan
                    fontSize: 14, // Ukuran font disesuaikan
                    color: Color(0xFF0072CE), // Warna disesuaikan
                  ),
                ),
                const SizedBox(height: 40), // Spasi disesuaikan
                // Tombol Login (sesuai welcome_admin_screen)
                SizedBox(
                  width: 327, // Lebar disesuaikan
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(
                        0xFF0072CE,
                      ), // Warna disesuaikan
                      padding: const EdgeInsets.symmetric(
                        horizontal: 105.5, // Padding disesuaikan
                        vertical: 19, // Padding disesuaikan
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          10,
                        ), // Radius disesuaikan
                      ),
                    ),
                    child: const Text(
                      'Login',
                      style: TextStyle(
                        fontFamily: 'Urbanist', // Font Family disesuaikan
                        color: Colors.white,
                        fontSize: 16, // Ukuran font disesuaikan
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12), // Spasi disesuaikan
                // Tombol Daftar (sesuai welcome_admin_screen)
                SizedBox(
                  width: 327, // Lebar disesuaikan
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/register');
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 19,
                      ), // Padding disesuaikan
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          10,
                        ), // Radius disesuaikan
                      ),
                      side: const BorderSide(
                        color: Color(0xFF0072CE),
                      ), // Warna border disesuaikan
                    ),
                    child: const Text(
                      'Daftar',
                      style: TextStyle(
                        fontFamily: 'Urbanist', // Font Family disesuaikan
                        fontSize: 16, // Ukuran font disesuaikan
                        color: Color(0xFF0072CE), // Warna teks disesuaikan
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
