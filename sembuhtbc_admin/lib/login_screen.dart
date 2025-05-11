import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: ListView(
            children: [
              const SizedBox(height: 20),
              IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_back),
              ),
              const SizedBox(height: 20),
              const Text(
                'Selamat datang kembali!',
                style: TextStyle(
                  fontFamily: 'Urbanist',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0072CE),
                ),
              ),
              const Text(
                'Senang melihat Anda lagi!',
                style: TextStyle(
                  fontFamily: 'Urbanist',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0072CE),
                ),
              ),
              const SizedBox(height: 30),
              TextField(
                style: TextStyle(fontFamily: 'Urbanist', fontSize: 16),
                decoration: InputDecoration(
                  labelText: 'Masukkan email Anda',
                  labelStyle: TextStyle(
                    fontFamily: 'Urbanist',
                    color: const Color.fromARGB(255, 128, 128, 128),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                obscureText: true,
                style: TextStyle(fontFamily: 'Urbanist', fontSize: 16),
                decoration: InputDecoration(
                  labelText: 'Masukkan sandi Anda',
                  labelStyle: TextStyle(
                    fontFamily: 'Urbanist',
                    color: const Color.fromARGB(255, 128, 128, 128),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  suffixIcon: Icon(Icons.visibility_off),
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  // Aksi login di sini
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF0072CE),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 106,
                    vertical: 19,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Login',
                  style: TextStyle(fontFamily: 'Urbanist', color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
