import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:image_compare/image_compare.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  Database? _database;
  Map<String, dynamic>? selectedSign;
  File? userImage;

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'Testing.db');
    _database = await openDatabase(path);
    await _loadRandomSign();
  }

  Future<void> _loadRandomSign() async {
    if (_database != null) {
      final List<Map<String, dynamic>> signs = await _database!.query('traffic_signs');
      if (signs.isNotEmpty) {
        final randomIndex = Random().nextInt(signs.length);
        setState(() {
          selectedSign = signs[randomIndex];
        });
      }
    }
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        userImage = File(pickedFile.path);
      });
      bool isSimilar = await _compareImages(userImage!, 'assets/${selectedSign!['image']}');
      String message = isSimilar
          ? 'Great! The signs are similar!'
          : 'Sorry, the signs do not match.';
      _showMessage(message);
    }
  }

  Future<bool> _compareImages(File userImage, String dbImagePath) async {
    try {
      final dbImageBytes = await rootBundle.load(dbImagePath);
      final imageComparison = await compareImages(
        src1: userImage,
        src2: MemoryImage(dbImageBytes.buffer.asUint8List()),
        algorithm: EuclideanColorDistance(),
      );
      return imageComparison < 5.9; // Threshold for similarity (lower is more similar)
    } catch (e) {
      print('Error comparing images: $e');
      return false;
    }
  }

  void _showMessage(String message) {
    showDialog(
      context: this.context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Result'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (selectedSign == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Recognition',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          )),
        backgroundColor: const Color.fromARGB(255, 236, 51, 208),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Find a sign that looks like this:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Image.asset('assets/${selectedSign!['image']}',
                height: 150, width: 150, fit: BoxFit.contain),
            const SizedBox(height: 10),
            Text('Sign Title: ${selectedSign!['sign_title']}',
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _takePhoto,
              child: const Text('Take Photo'),
            ),
            if (userImage != null)
              Column(
                children: [
                  const SizedBox(height: 10),
                  Image.file(userImage!, height: 150, width: 150, fit: BoxFit.contain),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
