import 'dart:typed_data';
import 'package:flutter/material.dart';

class ImageViewPage extends StatelessWidget {
  final Uint8List imageBytes;
  final String text;
  final String text2;

  const ImageViewPage(this.imageBytes, this.text, this.text2, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rotated Image')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.memory(imageBytes),
            const SizedBox(
                height: 10), // Adds some space between the image and the text
            Text(
              text,
              style:
              TextStyle(color: Colors.blue), // Sets the text color to blue
            ),
            Text(
              text2,
              style:
              TextStyle(color: Colors.red), // Sets the text color to blue
            ),
          ],
        ),
      ),
    );
  }
}
