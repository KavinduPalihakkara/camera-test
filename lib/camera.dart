import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:image/image.dart' as img;

class MyWidget extends StatefulWidget {
  const MyWidget({super.key});

  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;
  String _recognizedText = '';

  Future<void> _openCamera() async {
    var status = await Permission.camera.request();
    if (status.isGranted) {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        File processedImage = await _preprocessImage(File(photo.path));

        setState(() {
          _imageFile = XFile(processedImage.path); // Fixing image display issue
        });

        _recognizeText(processedImage.path);
      }
    } else {
      print('Camera permission denied');
    }
  }

  Future<File> _preprocessImage(File imageFile) async {
    try {
      img.Image? image = img.decodeImage(await imageFile.readAsBytes());

      if (image == null) return imageFile;

      // Convert to grayscale
      image = img.grayscale(image);

      // Increase contrast
      image = img.contrast(image, contrast: 150);

      // Adjust color to enhance image
      image = img.adjustColor(image, contrast: 1.5, saturation: 1.2);

      // Save the processed image
      final directory = await path_provider.getTemporaryDirectory();
      final processedFilePath = '${directory.path}/processed_image.jpg';
      File processedFile = File(processedFilePath)
        ..writeAsBytesSync(img.encodeJpg(image));

      return processedFile;
    } catch (e) {
      print('Error processing image: $e');
      return imageFile; // Return original if processing fails
    }
  }

  Future<void> _recognizeText(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final textRecognizer = TextRecognizer();
    final RecognizedText recognizedText =
        await textRecognizer.processImage(inputImage);

    setState(() {
      _recognizedText = recognizedText.text;
    });

    textRecognizer.close();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tyre OCR App'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_imageFile != null)
              Column(
                children: [
                  Image.file(
                    File(_imageFile!.path), // ✅ Fixed Image Not Showing Issue
                    width: 400,
                    height: 500,
                    fit: BoxFit.cover,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _recognizedText.isNotEmpty
                        ? _recognizedText
                        : 'No text recognized.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 77, 175, 255),
              ),
              onPressed: _openCamera,
              child: const Text('Open Camera'),
            ),
          ],
        ),
      ),
    );
  }
}
