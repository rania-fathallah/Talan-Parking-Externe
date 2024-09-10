import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:csv/csv.dart';
import 'package:talan_parking_externe/Contact.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum MyFileType {
  json,
  csv,
}

class UpdateDb extends StatelessWidget {
  const UpdateDb({super.key});

  Future<void> pickAndUpdateDb(BuildContext context, MyFileType fileType) async {
    try {
      // Pick a file based on the fileType (json or csv)
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: fileType == MyFileType.json ? ['json'] : ['csv'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);

        // Read and decode file content
        String content = await file.readAsString();

        List<Contact> contacts;
        if (fileType == MyFileType.json) {
          final List<dynamic> jsonData = jsonDecode(content);
          contacts = jsonData.map((item) => Contact.fromJson(item)).toList();
        } else {
          final List<List<dynamic>> csvData =
          const CsvToListConverter().convert(content);
          contacts = csvData.map((item) => Contact.fromCsv(item)).toList();
        }

        // Open the Hive box and clear old data
        final box = await Hive.openBox<Contact>('contacts');
        await box.clear();
        // Add all data to the box
        await box.addAll(contacts);

        // Set the flag to indicate data has been loaded
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('dataLoaded', true);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Database updated successfully')),
        );
      }
    } catch (e) {
      print('Error updating database: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error updating database')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Database'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => pickAndUpdateDb(context, MyFileType.json),
              child: const Text('Pick .json File'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => pickAndUpdateDb(context, MyFileType.csv),
              child: const Text('Pick .csv File'),
            ),
          ],
        ),
      ),
    );
  }
}
