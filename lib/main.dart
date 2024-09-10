import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:talan_parking_externe/camera.dart';
import 'package:talan_parking_externe/loading.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'Contact.dart';
import 'UpdateDb.dart';

late List<CameraDescription> _cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  /// Default Constructor
  const MyApp({super.key});

  Future<void> initializeHive() async {
    // Initialize Hive
    await Hive.initFlutter();
    Hive.registerAdapter(ContactAdapter()); // Ensure adapter is registered

    // Open shared preferences
    final prefs = await SharedPreferences.getInstance();
    final hasLoadedData = prefs.getBool('dataLoaded') ?? false;

    // Create a Hive box
    final box = await Hive.openBox<Contact>('contacts');

    // Load data from JSON if not already loaded
    if (!hasLoadedData) {
      try {
        final jsonString = await rootBundle.loadString('assets/data.json');
        final List<dynamic> jsonData = jsonDecode(jsonString);

        // Convert JSON data to a list of Contact objects
        final List<Contact> contacts =
        jsonData.map((item) => Contact.fromJson(item)).toList();

        // Add all data to the box
        await box.addAll(contacts);

        // Set the flag to indicate data has been loaded
        await prefs.setBool('dataLoaded', true);
      } catch (e) {
        print('Error loading data: $e');
      }
    }
  }

  Future<void> initializeCameras() async {
    try {
      await Future.delayed(const Duration(seconds: 2));
      _cameras = await availableCameras();
    } catch (e) {
      print('Error initializing cameras: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FutureBuilder(
        future: Future.wait([
          initializeCameras(),
          initializeHive(),
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Loading();
          } else if (snapshot.hasError) {
            return const Center(
              child: Text('Error initializing'),
            );
          } else {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Main Menu'),
              ),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CameraApp(_cameras),
                          ),
                        );
                      },
                      child: const Text('Open Camera'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const UpdateDb(),
                          ),
                        );
                      },
                      child: const Text('Update Database'),
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
