import 'package:flutter/material.dart';
import 'waiting_photo_page.dart'; 

class TakePhotoPage extends StatelessWidget {
  const TakePhotoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton()),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/selfie_frame.png', height: 250),
            const SizedBox(height: 20),
            const Text(
              "Pegang smartphone dan sesuaikan posisi kamera dengan wajah Anda",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WaitingPhotoPage()),
                );
              },
              child: const Text('Ambil Foto'),
            ),
          ],
        ),
      ),
    );
  }
}
