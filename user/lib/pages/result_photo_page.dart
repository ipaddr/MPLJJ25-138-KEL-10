import 'package:flutter/material.dart';

class ResultPhotoPage extends StatelessWidget {
  const ResultPhotoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: BackButton()),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/selfie_preview.png', height: 250),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/waiting-result');
            },
            child: const Text('Gunakan'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Ulangi'),
          ),
        ],
      ),
    );
  }
}
