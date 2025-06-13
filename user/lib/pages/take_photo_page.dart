// Path: take_photo_page.dart
import 'package:flutter/material.dart';
import 'waiting_photo_page.dart'; // Import halaman selanjutnya

class TakePhotoPage extends StatefulWidget {
  final String scheduleId;
  final String doseTime;

  const TakePhotoPage({
    super.key,
    required this.scheduleId,
    required this.doseTime,
  });

  @override
  State<TakePhotoPage> createState() => _TakePhotoPageState();
}

class _TakePhotoPageState extends State<TakePhotoPage> {
  // Anda akan mengintegrasikan plugin kamera di sini, misal:
  // late CameraController _cameraController;
  // Future<void>? _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    // Di sini Anda akan menginisialisasi kamera
    // _initializeCamera();
  }

  // Future<void> _initializeCamera() async {
  //   final cameras = await availableCameras();
  //   final firstCamera = cameras.firstWhere((camera) => camera.lensDirection == CameraLensDirection.front);
  //   _cameraController = CameraController(firstCamera, ResolutionPreset.medium);
  //   _initializeControllerFuture = _cameraController.initialize();
  //   if (mounted) setState(() {});
  // }

  @override
  void dispose() {
    // _cameraController.dispose(); // Jangan lupa dispose controller kamera
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed:
              () =>
                  Navigator.pop(context, false), // Kembali dan batalkan proses
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Area Tampilan Kamera (saat ini simulasi dengan gambar)
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  'assets/images/selfie_issue.png', // Ganti dengan CameraPreview()
                  height: 350,
                  fit: BoxFit.cover,
                ),
              ),
              // Contoh penggunaan CameraPreview jika sudah ada plugin kamera:
              // FutureBuilder<void>(
              //   future: _initializeControllerFuture,
              //   builder: (context, snapshot) {
              //     if (snapshot.connectionState == ConnectionState.done) {
              //       return CameraPreview(_cameraController);
              //     } else {
              //       return const Center(child: CircularProgressIndicator());
              //     }
              //   },
              // ),
              const SizedBox(height: 24),
              const Text(
                "Pegang smartphone\ndan sesuaikan posisi\nkamera dengan wajah Anda",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Color(0xFF0072CE), // Warna konsisten
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    // Di sini Anda akan mengambil foto
                    // try {
                    //   await _initializeControllerFuture;
                    //   final image = await _cameraController.takePicture();
                    //   // Proses foto: kirim ke ML model, dll.
                    //   // Untuk demo, langsung ke WaitingPhotoPage
                    //   final bool? result = await Navigator.push(
                    //     context,
                    //     MaterialPageRoute(
                    //       builder: (_) => WaitingPhotoPage(
                    //         scheduleId: widget.scheduleId,
                    //         doseTime: widget.doseTime,
                    //         // imagePath: image.path, // Teruskan path gambar jika perlu diproses di WaitingPhotoPage
                    //       ),
                    //     ),
                    //   );
                    //   Navigator.pop(context, result); // Kembali ke halaman sebelumnya dengan hasil
                    // } catch (e) {
                    //   print("Error taking photo: $e");
                    //   ScaffoldMessenger.of(context).showSnackBar(
                    //     SnackBar(content: Text('Gagal mengambil foto: $e')),
                    //   );
                    // }

                    // Simulasi: Langsung navigasi ke WaitingPhotoPage
                    final bool? result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => WaitingPhotoPage(
                              scheduleId: widget.scheduleId,
                              doseTime: widget.doseTime,
                            ),
                      ),
                    );
                    if (mounted) {
                      Navigator.pop(
                        context,
                        result,
                      ); // Kembali ke VerificationWarningPage dengan hasil
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFF0072CE), // Warna konsisten
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Ambil Foto',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
