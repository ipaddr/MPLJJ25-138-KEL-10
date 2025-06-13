import 'package:flutter/material.dart';
import 'verification_done_page.dart';

class WaitingResultPage extends StatefulWidget {
  final String imagePath;

  const WaitingResultPage({super.key, required this.imagePath});

  @override
  State<WaitingResultPage> createState() => _WaitingResultPageState();
}

class _WaitingResultPageState extends State<WaitingResultPage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const VerificationDonePage()),
        );
      }
    });
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
              // Ganti background dengan preview foto yang diambil
              Stack(
                alignment: Alignment.center,
                children: [
                  Opacity(
                    opacity: 0.4,
                    child: Image.file(
                      File(widget.imagePath),
                      height: 300,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const FaceDots(),
                ],
              ),
              const SizedBox(height: 40),
              const Text(
                'Memverifikasi foto...',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              const CircularProgressIndicator(color: Color(0xFF0072CE)),
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
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          color: Colors.black,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
