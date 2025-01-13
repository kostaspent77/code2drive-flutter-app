import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  Database? _database;
  String _username = '';
  String _email = '';
  String _profilePicPath = 'assets/5.png';
  final TextEditingController _usernameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeProfile();
  }

  Future<void> _initializeProfile() async {
    await _initDatabase();
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      _email = user.email ?? '';

      // Ελέγξτε αν υπάρχει ο πίνακας `user`
      await _checkIfTableExists();

      // Ελέγξτε αν ο χρήστης υπάρχει ήδη στη βάση δεδομένων
      final List<Map<String, dynamic>> existingUser = await _database!.query(
        'user',
        where: 'email = ?',
        whereArgs: [_email],
      );

      if (existingUser.isEmpty) {
        // Αν ο χρήστης δεν υπάρχει, προσθέστε νέα εγγραφή
        print("Inserting new user into database");
        await _database!.insert('user', {
          'email': _email,
          'username': 'New User',
          'profpic': 'assets/5.png',
          'Time1': '',
          'Date1': '',
          'Time2': '',
          'Date2': '',
          'Time3': '',
          'Date3': '',
          'Time4': '',
          'Date4': '',
          'best_score': '0',
        });
        print("User inserted successfully");
        setState(() {
          _username = 'New User';
          _profilePicPath = 'assets/defaultprof.png';
        });
      } else {
        // Αν ο χρήστης υπάρχει, φορτώστε τα δεδομένα του
        final userData = existingUser.first;
        setState(() {
          _username = userData['username'];
          _profilePicPath = userData['profpic'];
        });
      }
    }
  }

  Future<void> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'Testing.db');

    _database = await openDatabase(
      path,
      version: 2, // Αύξησε την έκδοση αν κάνεις αλλαγές στο σχήμα
      onCreate: (db, version) async {
        print("Creating user table");
        await db.execute('''
          CREATE TABLE IF NOT EXISTS user (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT NOT NULL UNIQUE,
            username TEXT NOT NULL,
            profpic TEXT NOT NULL,
            Time1 TEXT,
            Date1 TEXT,
            Time2 TEXT,
            Date2 TEXT,
            Time3 TEXT,
            Date3 TEXT,
            Time4 TEXT,
            Date4 TEXT,
            best_score TEXT
          )
        ''');
        print("User table created");
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS user (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              email TEXT NOT NULL UNIQUE,
              username TEXT NOT NULL,
              profpic TEXT NOT NULL,
              Time1 TEXT,
              Date1 TEXT,
              Time2 TEXT,
              Date2 TEXT,
              Time3 TEXT,
              Date3 TEXT,
              Time4 TEXT,
              Date4 TEXT,
              best_score TEXT
            )
          ''');
          print("Database upgraded to version $newVersion");
        }
      },
    );
  }

  Future<void> _checkIfTableExists() async {
    final tables = await _database!.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='user'");
    print('Tables found: $tables');
  }

  Future<void> _updateUsername(String newUsername) async {
    await _database!.update(
      'user',
      {'username': newUsername},
      where: 'email = ?',
      whereArgs: [_email],
    );

    setState(() {
      _username = newUsername;
    });
  }

  Future<void> _updateProfilePicture(String newPicPath) async {
    await _database!.update(
      'user',
      {'profpic': newPicPath},
      where: 'email = ?',
      whereArgs: [_email],
    );

    setState(() {
      _profilePicPath = newPicPath;
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = join(directory.path, basename(pickedFile.path));
      final file = File(pickedFile.path);
      await file.copy(filePath);

      await _updateProfilePicture(filePath);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile',
        style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),),
        backgroundColor: Colors.deepOrange,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: _profilePicPath.startsWith('assets/')
                  ? AssetImage(_profilePicPath) as ImageProvider
                  : FileImage(File(_profilePicPath)),
            ),
            const SizedBox(height: 20),
            Text(
              _username,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                await _pickImage();
              },
              child: const Text('Change Profile Picture'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                _usernameController.text = _username;
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Edit Username'),
                    content: TextField(
                      controller: _usernameController,
                      decoration: const InputDecoration(labelText: 'Username'),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          _updateUsername(_usernameController.text);
                          Navigator.of(context).pop();
                        },
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Edit Username'),
            ),
          ],
        ),
      ),
    );
  }
}
