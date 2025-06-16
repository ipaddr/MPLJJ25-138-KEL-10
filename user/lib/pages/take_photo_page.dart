import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'waiting_photo_page.dart';

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
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
      );

      _controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      _initializeControllerFuture = _controller!.initialize();
      await _initializeControllerFuture;

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kamera tidak tersedia: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

 Future<void> _takePicture(BuildContext context) async {
  try {
    if (_controller == null || !_controller!.value.isInitialized) {
      throw Exception('Kamera belum siap');
    }

    await _controller!.takePicture().then((file) async {
      final imagePath = file.path;
      final exists = await File(imagePath).exists();
      final size = await File(imagePath).length();
      print('✅ Foto disimpan: $imagePath | exists: $exists | size: $size bytes');

await Navigator.pushReplacement(
  context,
  MaterialPageRoute(
    builder: (_) => WaitingPhotoPage(
      scheduleId: widget.scheduleId,
      doseTime: widget.doseTime,
      imagePath: imagePath,
    ),
  ),
);
    });
  } catch (e) {
    debugPrint("❌ Error taking picture: $e");
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil foto: $e')),
      );
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context, false),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _controller == null
          ? const Center(child: CircularProgressIndicator())
          : (_controller!.value.isInitialized
              ? Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    CameraPreview(_controller!),
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: FloatingActionButton(
                        backgroundColor: Colors.white,
                        onPressed: () => _takePicture(context),
                        child: const Icon(Icons.camera_alt, color: Colors.black),
                      ),
                    ),
                  ],
                )
              : const Center(child: CircularProgressIndicator())),
    );
  }
}
