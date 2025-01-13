import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:io';
import 'package:flutter/services.dart';

class TestHistoryPage extends StatefulWidget {
  const TestHistoryPage({super.key});

  @override
  _TestHistoryPageState createState() => _TestHistoryPageState();
}

class _TestHistoryPageState extends State<TestHistoryPage> {
  Future<String> getDatabasePath() async {
    var databasesPath = await getDatabasesPath();
    String path = '$databasesPath/Testing.db';

    if (!await File(path).exists()) {
      ByteData data = await rootBundle.load('assets/Testing.db');
      List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await File(path).writeAsBytes(bytes);
    }
    return path;
  }

  Future<List<Map<String, String>>> _fetchAttempts() async {
    final db = await openDatabase(await getDatabasePath());
    int userId = 1; // Replace with dynamic user ID fetching logic

    List<Map<String, dynamic>> users = await db.query('user', where: 'id = ?', whereArgs: [userId]);
    if (users.isNotEmpty) {
      Map<String, dynamic> user = users.first;
      return [
        {'Date': user['Date1'], 'Time': user['Time1']},
        {'Date': user['Date2'], 'Time': user['Time2']},
        {'Date': user['Date3'], 'Time': user['Time3']},
        {'Date': user['Date4'], 'Time': user['Time4']},
      ];
    }
    return [];
  }

  Future<void> _clearAttempt(int attemptIndex) async {
    final db = await openDatabase(await getDatabasePath());
    int userId = 1; // Replace with dynamic user ID fetching logic

    String dateField = 'Date${attemptIndex + 1}';
    String timeField = 'Time${attemptIndex + 1}';

    await db.update(
      'user',
      {
        dateField: '',
        timeField: '',
      },
      where: 'id = ?',
      whereArgs: [userId],
    );

    setState(() {}); // Trigger UI refresh after clearing attempt
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test History'),
      ),
      body: FutureBuilder<List<Map<String, String>>>(
        future: _fetchAttempts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final attempts = snapshot.data ?? [];
            return ListView.builder(
              itemCount: attempts.length,
              itemBuilder: (context, index) {
                final attempt = attempts[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ListTile(
                    title: Text('Attempt ${index + 1}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Date: ${attempt['Date']}'),
                        Text('Time: ${attempt['Time']}'),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _clearAttempt(index),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
