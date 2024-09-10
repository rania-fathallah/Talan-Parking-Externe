import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:tflite_v2/tflite_v2.dart';
//import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class PlateDetector {
  PlateDetector() {
    loadModel();
  }

  Future<void> loadModel() async {
    dispose();
    //final interpreter = await Interpreter.fromAsset('assets/detect_plate.tflite');
    await Tflite.loadModel(
        model: "assets/detect_plate.tflite",
        labels: "assets/detect_plate.txt",
        numThreads: 1,
        isAsset: true,
        useGpuDelegate: false);
  }

  void dispose() {
    Tflite.close();
    //interpreter?.close();
  }

  Future<Uint8List?> detectAndCropPlate(
      BuildContext context, Uint8List inputImage) async {
    await loadModel();
    final rotatedImagePath = await saveImageToTempFile(inputImage);
    var results = await _runModelOnImage(rotatedImagePath);

    if (results!.isNotEmpty) {
      var firstResult = results[0];
      var croppedImage = await _cropImageToBoundingBox(inputImage, firstResult);
      return croppedImage;
    } else {
      _showAlert(context);
      return null;
    }
  }

  Future<List<dynamic>?> _runModelOnImage(String input) async {
    var recognitions = await Tflite.detectObjectOnImage(
      path: input,
      model: "YOLO",
      threshold: 0.4,
      numResultsPerClass: 5,
      blockSize: 32,
      numBoxesPerBlock: 5,
      asynch: true,
    );
    return recognitions;
  }

  Future<Uint8List?> _cropImageToBoundingBox(
      Uint8List image, dynamic result) async {
    final originalImage = img.decodeImage(image);
    if (originalImage == null) {
      throw Exception('Could not decode image');
    }
    double x = result['rect']['x'];
    double y = result['rect']['y'];
    double width = result['rect']['w'];
    double height = result['rect']['h'];
    // Convert to pixel coordinates
    int cropWidth = (width * originalImage.width).toInt() - 5;
    int cropHeight = ((height * originalImage.height)).toInt();
    int cropX = ((x * originalImage.width) - (cropWidth / 2)).toInt() + 10;
    int cropY = ((y * originalImage.height) - (cropHeight / 2)).toInt();
    img.Image croppedImage = img.copyCrop(originalImage,
        x: cropX, y: cropY, width: cropWidth, height: cropHeight);
    return Uint8List.fromList(img.encodeJpg(croppedImage));
  }

  void _showAlert(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Alert"),
          content: Text("No plate detected"),
          actions: <Widget>[
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop(); // Close the alert dialog
              },
            ),
          ],
        );
      },
    );
  }

  Future<String> saveImageToTempFile(Uint8List imageBytes) async {
    final tempDir = Directory.systemTemp;
    final tempFile = await File('${tempDir.path}/image.jpg').create();
    await tempFile.writeAsBytes(imageBytes as List<int>);
    return tempFile.path;
  }
}
