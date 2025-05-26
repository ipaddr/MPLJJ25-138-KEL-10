import 'package:flutter/material.dart';
import 'dart:async';
import 'result_photo_page.dart';

class WaitingPhotoPage extends StatefulWidget {
  const WaitingPhotoPage({super.key});

  @override
  State<WaitingPhotoPage> createState() => _WaitingPhotoPageState();
}

class _WaitingPhotoPageState extends State<WaitingPhotoPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Timer _timer;

  @override
  void initState() {
    super.initState();

    // Navigasi otomatis ke ResultPhotoPage
    _timer = Timer(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ResultPhotoPage()),
      );
    });

    // Untuk animasi titik-titik (opsional jika ingin bergerak)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Opacity(
                    opacity: 0.4,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset(
                        'assets/images/selfie_blur.png',
                        height: 320,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const FaceDots(), // Titik-titik di wajah
                ],
              ),
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(
                  'Pegang smartphone\n'
                  'dan sesuaikan posisi\n'
                  'kamera dengan wajah Anda',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black45,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FaceDots extends StatelessWidget {
  const FaceDots({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      width: 200,
      child: Stack(
        children: [
          _buildDot(90, 80),
          _buildDot(120, 80),
          _buildDot(105, 110),
          _buildDot(85, 140),
          _buildDot(125, 140),
          _buildDot(105, 160),
        ],
      ),
    );
  }

  Widget _buildDot(double top, double left) {
    return Positioned(
      top: top,
      left: left,
      child: Container(
        width: 12,
        height: 12,
        decoration: const BoxDecoration(
          color: Colors.black,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
