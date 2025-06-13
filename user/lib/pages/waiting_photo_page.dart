import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'result_photo_page.dart';

class WaitingPhotoPage extends StatefulWidget {
  final String scheduleId;
  final String doseTime;
  final String imagePath; // Tambahkan imagePath agar preview bisa ditampilkan

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
  bool _isVerificationSuccessful = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _performFaceVerification();
  }

  Future<void> _performFaceVerification() async {
    await Future.delayed(const Duration(seconds: 3));

    final bool simulatedResult =
        DateTime.now().millisecond % 10 < 8; // 80% berhasil

    if (mounted) {
      setState(() {
        _isVerificationSuccessful = simulatedResult;
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultPhotoPage(
            scheduleId: widget.scheduleId,
            doseTime: widget.doseTime,
            isPhotoVerified: _isVerificationSuccessful,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
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
                      child: Image.file(
                        File(widget.imagePath),
                        height: 320,
                        width: 240,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const FaceDots(),
                ],
              ),
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(
                  'Memverifikasi foto Anda...\nMohon tunggu sebentar',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 16,
                    color: Colors.black45,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Color(0xFF0072CE),
                ),
                strokeWidth: 3,
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
