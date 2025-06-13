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
  late Future<void> _initializeControllerFuture;

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

      _controller = CameraController(frontCamera, ResolutionPreset.medium);
      _initializeControllerFuture = _controller!.initialize();
      setState(() {});
    } catch (e) {
      print('Error initializing camera: $e');
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
      await _initializeControllerFuture;

      final XFile file = await _controller!.takePicture();

      final directory = await getTemporaryDirectory();
      final imagePath = join(directory.path, '${DateTime.now().millisecondsSinceEpoch}.png');

      // Salin ke path baru (opsional, bisa langsung pakai file.path)
      await file.saveTo(imagePath);

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WaitingPhotoPage(
            scheduleId: widget.scheduleId,
            doseTime: widget.doseTime,
            imagePath: imagePath,
          ),
        ),
      );

      if (mounted) {
        Navigator.pop(context, result);
      }
    } catch (e) {
      print("Error taking picture: $e");
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
          : FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return Stack(
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
                  );
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),
    );
  }
}
