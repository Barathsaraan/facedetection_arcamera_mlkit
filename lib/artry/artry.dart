import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:facedetection_ar_app/arcamera/arcamerapage.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

class Artry extends StatefulWidget {
  const Artry({super.key});

  @override
  State<Artry> createState() => _ArtryState();
}

class _ArtryState extends State<Artry> {
  File? _capturedImage;
  Uint8List? _croppedFaceBytes;

  // Function to detect face and crop it
  Future<void> _detectAndCropFace(File imageFile) async {
    final InputImage inputImage = InputImage.fromFile(imageFile);
    final faceDetector = GoogleMlKit.vision.faceDetector();
    final faces = await faceDetector.processImage(inputImage);

    if (faces.isNotEmpty) {
      final face = faces.first;
      final boundingBox = face.boundingBox;

      // Decode the image and crop the face
      final decodedImage =
          await decodeImageFromList(imageFile.readAsBytesSync());
      final croppedBytes = await _cropImage(decodedImage, boundingBox);

      setState(() {
        _croppedFaceBytes = croppedBytes;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No face detected!")),
      );
    }

    faceDetector.close();
  }

  // Function to crop the face from the decoded image
  Future<Uint8List> _cropImage(ui.Image decodedImage, Rect cropRect) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Draw the cropped part of the image
    final paint = Paint();
    canvas.drawImageRect(
      decodedImage,
      cropRect,
      Rect.fromLTWH(0, 0, cropRect.width, cropRect.height),
      paint,
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(
      cropRect.width.toInt(),
      cropRect.height.toInt(),
    );

    // Convert cropped dart:ui.Image to Uint8List
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Try On Dress')),
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.asset('assets/dress.jpg',
                width: 300, height: 500), // Base dress image
            if (_croppedFaceBytes != null)
              Positioned(
                top: 100, // Adjust face position dynamically
                child: Image.memory(
                  _croppedFaceBytes!,
                  width: 100, // Match head size
                  height: 100,
                  fit: BoxFit.cover,
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final capturedImage = await Navigator.push<File?>(
            context,
            MaterialPageRoute(builder: (context) => const ArtryCamera()),
          );

          if (capturedImage != null) {
            await _detectAndCropFace(capturedImage);
          }
        },
        child: const Icon(Icons.camera),
      ),
    );
  }
}
