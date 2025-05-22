import 'package:flutter/material.dart';

class CheckMedPage extends StatefulWidget {
  final int medsTaken; // Tambahkan parameter ini

  const CheckMedPage({super.key, required this.medsTaken});

  @override
  State<CheckMedPage> createState() => _CheckMedPageState();
}

class _CheckMedPageState extends State<CheckMedPage> {
  int totalDosis = 2;
  late int dosisDiminum;

  @override
  void initState() {
    super.initState();
    dosisDiminum = widget.medsTaken; // Gunakan nilai dari parameter
  }

  void verifikasiMinumObat() {
    setState(() {
      if (dosisDiminum < totalDosis) {
        dosisDiminum++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    double progress = dosisDiminum / totalDosis;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hari ini'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Diminum',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 140,
              width: 140,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress == 1 ? Colors.green : Colors.blue,
                    ),
                    strokeWidth: 12,
                  ),
                  Center(
                    child: Text(
                      '$dosisDiminum/$totalDosis',
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  _buildObatTile('Isoniazid', '06:41', 0),
                  const SizedBox(height: 10),
                  _buildObatTile('Rifampicin', '06:42', 1),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildObatTile(String namaObat, String jam, int index) {
    bool diminum = index < dosisDiminum;
    return Card(
      child: ListTile(
        leading: Icon(
          diminum ? Icons.check_circle : Icons.radio_button_unchecked,
          color: diminum ? Colors.green : Colors.grey,
        ),
        title: Text(namaObat),
        subtitle: Text(jam),
        trailing: diminum
            ? const Text("Diminum", style: TextStyle(color: Colors.green))
            : ElevatedButton(
                onPressed: verifikasiMinumObat,
                child: const Text('Verifikasi'),
              ),
      ),
    );
  }
}
