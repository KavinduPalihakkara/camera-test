import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img; // Image processing package

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
          _imageFile = XFile(processedImage.path);
        });

        _recognizeText(processedImage.path);
      }
    } else {
      print('Camera permission denied');
    }
  }

  Future<File> _preprocessImage(File imageFile) async {
    // Read image file as bytes
    img.Image? image = img.decodeImage(await imageFile.readAsBytes());

    if (image == null) return imageFile;

    // Convert to grayscale
    image = img.grayscale(image);

    // Increase contrast
    image = img.adjustColor(image, contrast: 150);

    // Save the processed image
    File processedFile = File('${imageFile.path}_processed.jpg')
      ..writeAsBytesSync(img.encodeJpg(image));

    return processedFile;
  }

  Future<void> _recognizeText(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final textRecognizer = TextRecognizer();
    final RecognizedText recognizedText =
        await textRecognizer.processImage(inputImage);

    setState(() {
      _recognizedText = recognizedText.text; // Store recognized text
    });

    textRecognizer.close();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tyre Scan'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_imageFile != null)
              Column(
                children: [
                  Image.file(
                    File(_imageFile!.path),
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
                backgroundColor: const Color.fromARGB(
                    255, 77, 175, 255), // Set the button color to blue
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
