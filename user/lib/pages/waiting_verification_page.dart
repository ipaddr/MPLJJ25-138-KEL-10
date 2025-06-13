import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'verification_success_page.dart'; // pastikan file ini ada

class WaitingVerificationPage extends StatefulWidget {
  const WaitingVerificationPage({super.key});

  @override
  State<WaitingVerificationPage> createState() => _WaitingVerificationPageState();
}

class _WaitingVerificationPageState extends State<WaitingVerificationPage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid != null) {
      _timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
        try {
          final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
          final isVerified = doc.data()?['isVerified'] ?? false;

          if (isVerified) {
            timer.cancel();
            if (!mounted) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const VerificationSuccessPage()),
            );
          }
        } catch (e) {
          debugPrint('Error checking verification status: $e');
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              strokeWidth: 6,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
            ),
            const SizedBox(height: 32),
            const Text(
              "Menunggu konfirmasi admin...",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                "Proses ini mungkin akan sedikit memakan waktu, mohon bersabar.",
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
