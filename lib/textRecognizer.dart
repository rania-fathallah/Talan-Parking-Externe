import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tesseract_ocr/android_ios.dart';
import 'package:image/image.dart';

class TextRecognizer {
  TextRecognizer();

  Future<Map<String, dynamic>> recognizeTextFromPlate(
      BuildContext context, Uint8List croppedPlateImage) async {
    Uint8List blackAndWhiteImage = convertToBlackAndWhite(croppedPlateImage);
    final croppedPlateImagePath = await saveImageToTempFile(blackAndWhiteImage);
    String text = await FlutterTesseractOcr.extractText(croppedPlateImagePath,
        language: 'eng',
        args: {
          "psm": "7",
          "oem": "1",
          "tessedit_char_whitelist": "|0123 456789RS",
        });
    print(text);
    var result = postTreatment(text);
    //Map<String, dynamic> myDict = {
    //'image': blackAndWhiteImage,
    //'text': text,
    //'result': result
    //};
    return result;
  }

  Map<String, String> postTreatment(String inputText) {
    var outputText = '';
    var count = 0;
    Map<String, String> result;

    for (int i = 0; i < inputText.length; i++) {
      if (!_isNumeric(inputText[i])) {
        if (inputText[i] == 'R') {
          result = treatRS(inputText, i);
          return result;
        } else if (inputText[i] == '|') {
        } else if (inputText[i] == ' ') {
          if (count == 0) {
          } else if (count <= 3) {
            result = treatTun(inputText, i, outputText);
            return result;
          }
        }
      } else {
        if (count < 3) {
          outputText = outputText + inputText[i];
          count++;
        }
        if (count == 3) {
          if (!checkNT(inputText, i)) {
            result = treatTun(inputText, i, outputText);
            return result;
          } else {
            result = treatNT(inputText, i, count, outputText);
            return result;
          }
        }
      }
    }
    result = {
      "type" : "other",
      "num" : outputText,
    };
    return result;
  }

  bool checkNT(String inputText, int index) {
    var i = inputText.length - 1;
    var count = 0;
    while (true) {
      if (_isNumeric(inputText[i])) {
        count++;
        i--;
        if (i == index) {
          if (count <= 3) {
            return true;
          } else {
            return false;
          }
        }
      } else if (inputText[i] == " " || inputText[i] == "|") {
        if (count == 0) {
          i--;
        } else {
          return false;
        }
      }
    }
  }

  Map<String, String> treatNT(String inputText, int index, int count, String concatText) {
    var outputString = concatText;
    var c = count;
    for (int i = index + 1; i < inputText.length; i++) {
      if (_isNumeric(inputText[i])) {
        outputString = outputString + inputText[i];
        c++;
      } else {
        break;
      }
      if (c == 6) {
        break;
      }
    }
    //outputString = outputString + "ن ت ";
    final output = {
      "type" : "TN",
      "num" : outputString,
    };
    return output;
  }

  Map<String, String> treatTun(String inputText, int index, String concatText) {
    var way = '';
    var c = 0;
    for (int i = inputText.length - 1; i >= 0; i--) {
      if (_isNumeric(inputText[i])) {
        way = inputText[i] + way;
        c++;
      } else if ((c >= 1)) {
        break;
      }
      if ((c == 4)) {
        break;
      }
    }
    //final outputString = concatText + ' تونس ' + way;
    final output = {
      "type" : "tunis",
      "num1" : concatText,
      "num2" : way
    };
    return output;
  }

  Map<String, String> treatRS(String inputText, int count) {
    var outputString = 'R';
    if (inputText[count + 1] == "S") {
      outputString = "${outputString}S ";
    }
    var c = 0;
    for (int i = count + 2; i < inputText.length; i++) {
      if (_isNumeric(inputText[i])) {
        outputString = outputString + inputText[i];
        c++;
      }
      if (c == 6) {
        break;
      }
    }
    final output = {
      "type" : "other",
      "num" : outputString,
    };
    return output;
  }

  bool _isNumeric(String str) {
    return double.tryParse(str) != null;
  }

  Future<String> saveImageToTempFile(Uint8List imageBytes) async {
    final tempDir = Directory.systemTemp;
    final tempFile = await File('${tempDir.path}/image.jpg').create();
    await tempFile.writeAsBytes(imageBytes as List<int>);
    return tempFile.path;
  }

  void _showAlert(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Alert"),
          content: Text("Plate Number wasn't read !"),
          actions: <Widget>[
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop(); // Close the alert dialog
                Navigator.of(context).pop(); // Go back to the previous page
              },
            ),
          ],
        );
      },
    );
  }

  Uint8List convertToBlackAndWhite(Uint8List input) {
    // Decode the image from the Uint8List
    img.Image originalImage = img.decodeImage(input)!;
    int threshold = 128;
    for (var y = 0; y < originalImage.height; y++) {
      for (var x = 0; x < originalImage.width; x++) {
        final pixel = originalImage.getPixel(x, y);
        final r = pixel.r;
        final g = pixel.g;
        final b = pixel.b;
        final gray = (r * 0.299 + g * 0.587 + b * 0.114).toInt();
        if (gray > threshold) {
          originalImage.setPixel(
              x, y, ColorFloat32.rgb(255.0, 255.0, 255.0)); // White
        } else {
          originalImage.setPixel(
              x, y, ColorFloat32.rgb(0.0, 0.0, 0.0)); // Black
        }
      }
    }
    // Smooth the image with a weight of 0.5
    final smoothedImage = img.smooth(originalImage, weight: 0.5);
    // Encode the image back to Uint8List
    return Uint8List.fromList(img.encodePng(smoothedImage));
  }
}
