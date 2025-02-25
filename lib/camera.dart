import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

class TyreOCRApp extends StatefulWidget {
  const TyreOCRApp({super.key});

  @override
  State<TyreOCRApp> createState() => _TyreOCRAppState();
}

class _TyreOCRAppState extends State<TyreOCRApp> {
  final Dio _dio = Dio();
  File? _selectedImage;
  String? _tireSize;
  String? _width;
  String? _profile;
  String? _diameter;
  bool _loading = false;
  String? _error;

  Future<void> pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(
      source: source,
      imageQuality: 30,
      maxWidth: 800,
      maxHeight: 600,
    );
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _tireSize = null;
        _width = null;
        _profile = null;
        _diameter = null;
        _error = null;
      });
      await processImage();
    }
  }

  Future<void> processImage() async {
    if (_selectedImage == null) return;
    setState(() => _loading = true);

    try {
      img.Image? image = img.decodeImage(await _selectedImage!.readAsBytes());
      if (image != null) {
        img.Image resizedImage = img.copyResize(image, width: 600);
        List<int> compressedBytes = img.encodeJpg(resizedImage, quality: 40);
        String base64Image = base64Encode(compressedBytes);

        Response response = await _dio.post(
          'http://13.212.78.136:5001/api/tyre-info/process-tire-image',
          data: jsonEncode({
            'image': base64Image, // Ensure correct key as expected by backend
          }),
          options: Options(headers: {
            'Content-Type': 'application/json',
          }),
        );

        if (response.statusCode == 200 && response.data['ocrResult'] != null) {
          var data = response.data['ocrResult'];
          setState(() {
            _tireSize = data['tyreSize'] ?? 'No tire size detected';
            _width = data['width']?.toString();
            _profile = data['profile']?.toString();
            _diameter = data['diameter']?.toString();
          });
        } else {
          setState(() => _error = "Failed to process image");
        }
      }
    } catch (e) {
      setState(() => _error = "Error processing image: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tyre OCR App')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_selectedImage != null)
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Image.file(_selectedImage!, height: 200),
              ),
            if (_loading) const CircularProgressIndicator(),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            if (_tireSize != null)
              Column(
                children: [
                  Text("Extracted Tire Size: $_tireSize",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  if (_width != null) Text("Width: $_width"),
                  if (_profile != null) Text("Profile: $_profile"),
                  if (_diameter != null) Text("Diameter: $_diameter"),
                ],
              ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => pickImage(ImageSource.camera),
                  child: const Text('Open Camera'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => pickImage(ImageSource.gallery),
                  child: const Text('Open Gallery'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
