import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:talan_parking_externe/ConfirmTextPage.dart';
import 'package:talan_parking_externe/plateDetector.dart';
import 'package:talan_parking_externe/textRecognizer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image/image.dart' as img;
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:typed_data';

class CameraApp extends StatefulWidget {
  final List<CameraDescription> cameras;
  const CameraApp(this.cameras, {super.key});
  @override
  State<CameraApp> createState() => _CameraAppState();
}

class _CameraAppState extends State<CameraApp> {
  late CameraController controller;
  late PlateDetector plateDetector;
  late TextRecognizer textRecognizer;
  double? _currentOrientation;
  bool _isFlashOn = false;

  @override
  void initState() {
    super.initState();
    initializeCamera();
    plateDetector = PlateDetector();
    textRecognizer = TextRecognizer();
    listenToOrientationChanges();
  }

  void initializeCamera() {
    controller = CameraController(
      widget.cameras[0],
      ResolutionPreset.max,
      enableAudio: false,
    );
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    }).catchError((Object e) {
      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
            showPermissionDeniedDialog();
            break;
          default:
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Error'),
                  content:
                  const Text('An Error occured while accessing camera.'),
                  actions: <Widget>[
                    TextButton(
                      child: const Text('Cancel'),
                      onPressed: () {
                        Navigator.of(context).pop();
                        dispose();
                        exit(0);
                      },
                    ),
                  ],
                );
              },
            );
            break;
        }
      }
    });
  }

  void showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permission Denied'),
          content: const Text(
              'Camera access is denied. Please grant permission to use the camera.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
                dispose();
                exit(0);
              },
            ),
            TextButton(
              child: const Text('OK'),
              onPressed: () async {
                Navigator.of(context).pop();
                await Permission.camera.request();
                initializeCamera();
              },
            ),
          ],
        );
      },
    );
  }

  void toggleFlash() async {
    setState(() {
      _isFlashOn = !_isFlashOn;
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    } else {
      return Scaffold(
        appBar: AppBar(title: const Text('Take a picture')),
        body: Stack(
          children: [
            Positioned.fill(
              child: CameraPreview(controller),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    FloatingActionButton(
                      onPressed: toggleFlash,
                      child: Icon(
                        _isFlashOn ? Icons.flash_on : Icons.flash_off,
                      ),
                    ),
                    FloatingActionButton(
                      onPressed: () async {
                        try {
                          await controller.setFlashMode(
                            _isFlashOn ? FlashMode.torch : FlashMode.off,
                          );
                          final orientation = _currentOrientation;
                          final image = await controller.takePicture();
                          await controller.setFlashMode(FlashMode.off);
                          if (!context.mounted) return;
                          final imageBytes = await image.readAsBytes();
                          final rotatedImage = await _rotateImageIfNeeded(
                              imageBytes, orientation!);
                          final rur = work(context, rotatedImage);

                          // Navigate to ImageViewPage when treatedImageFuture completes
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  FutureBuilder<Map<String, dynamic>>(
                                    future: rur,
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const Center(
                                            child: CircularProgressIndicator());
                                      } else if (snapshot.hasError) {
                                        return Center(
                                            child:
                                            Text('Error: ${snapshot.error}'));
                                      } else if (!snapshot.hasData ||
                                          snapshot.data == null) {
                                        return const Center(
                                            child: Text('No data available'));
                                      } else {
                                        //return ImageViewPage(
                                        //  snapshot.data!['image']!,
                                        //snapshot.data!['text'],
                                        //snapshot.data!['text2']);
                                        return ConfirmTextPage(result: snapshot.data!);
                                      }
                                    },
                                  ),
                            ),
                          );
                        } catch (e) {
                          print(e);
                        }
                      },
                      child: const Icon(Icons.camera_alt),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Future<Map<String, dynamic>> work(
      BuildContext context, Uint8List imageBytes) async {
    // Recognize objects in the image
    final licensePlate =
    await plateDetector.detectAndCropPlate(context, imageBytes);
    if (licensePlate != null) {
      final treatedImageFuture =
      await textRecognizer.recognizeTextFromPlate(context, licensePlate);
      return treatedImageFuture;
    } else {
      Map<String, dynamic> results = {
        'type': "other",
        'image': imageBytes,
        'num': "",
      };
      return results;
    }
  }

  // The state that is listening to phone orientation
  void listenToOrientationChanges() {
    accelerometerEventStream(AccelerometerEvent event){
      setState(() {
        _currentOrientation = _getOrientation(event);
      });
    }
  }

  // Get orientation from accelerometer data
  double _getOrientation(AccelerometerEvent event) {
    if (event.y.abs() > event.x.abs()) {
      return event.y > 0 ? 0 : 180;
    } else {
      return event.x > 0 ? -90 : 90;
    }
  }

  Future<Uint8List> _rotateImageIfNeeded(
      Uint8List image, double orientation) async {
    final originalImage = img.decodeImage(image);
    if (originalImage == null) {
      throw Exception('Could not decode image');
    }
    final rotatedImage = img.copyRotate(originalImage, angle: orientation);
    return Uint8List.fromList(img.encodeJpg(rotatedImage));
  }
}
