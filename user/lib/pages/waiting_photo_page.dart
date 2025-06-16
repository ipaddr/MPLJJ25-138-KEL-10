import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'result_photo_page.dart';

class WaitingPhotoPage extends StatefulWidget {
  final String scheduleId;
  final String doseTime;
  final String imagePath;

  const WaitingPhotoPage({
    super.key,
    required this.scheduleId,
    required this.doseTime,
    required this.imagePath,
  });

  @override
  State<WaitingPhotoPage> createState() => _WaitingPhotoPageState();
}

class _WaitingPhotoPageState extends State<WaitingPhotoPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isVerificationSuccessful = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(_controller);

    _performFaceVerification();
  }

  Future<void> _performFaceVerification() async {
    // Simulasi proses verifikasi wajah
    await Future.delayed(const Duration(seconds: 3));

    final bool simulatedResult = Random().nextInt(10) < 8;

    if (!mounted) return;

    setState(() {
      _isVerificationSuccessful = simulatedResult;
    });

    // Navigasi ke halaman hasil verifikasi
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultPhotoPage(
          scheduleId: widget.scheduleId,
          doseTime: widget.doseTime,
          isPhotoVerified: _isVerificationSuccessful,
          imagePath: widget.imagePath,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final File imageFile = File(widget.imagePath);
    final bool imageExists = imageFile.existsSync();

    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Opacity(
                      opacity: 0.3,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: imageExists
                            ? Image.file(
                                imageFile,
                                height: screenHeight * 0.45,
                                width: screenWidth * 0.6,
                                fit: BoxFit.cover,
                              )
                            : const Icon(Icons.broken_image, size: 120),
                      ),
                    ),
                    FadeTransition(
                      opacity: _animation,
                      child: const FaceDots(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Memverifikasi foto Anda...\nMohon tunggu sebentar',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0072CE)),
                  strokeWidth: 3,
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Batalkan',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
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
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
