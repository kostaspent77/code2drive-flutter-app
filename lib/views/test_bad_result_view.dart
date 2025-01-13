import 'package:code2drive/main.dart';
import 'package:flutter/material.dart';
import 'package:code2drive/views/Test_view.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TestBadResultPage extends StatelessWidget {
  final int correctAnswers;
  final int elapsedSeconds;

  const TestBadResultPage({super.key, required this.correctAnswers, required this.elapsedSeconds});

  Future<void> _updateUserResults() async {
    final String dbPath = join(await getDatabasesPath(), 'Testing.db');
    final Database db = await openDatabase(dbPath);

    final User? firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      return; // Χρήστης δεν είναι συνδεδεμένος
    }

    final String userEmail = firebaseUser.email ?? '';
    List<Map<String, dynamic>> users = await db.query(
      'user',
      where: 'email = ?',
      whereArgs: [userEmail],
    );

    if (users.isEmpty) {
      // Δημιουργία νέας εγγραφής
      await db.insert('user', {
        'email': userEmail,
        'Time1': elapsedSeconds.toString(),
        'Date1': DateTime.now().toIso8601String(),
        'Time2': '',
        'Date2': '',
        'Time3': '',
        'Date3': '',
        'Time4': '',
        'Date4': '',
        'username': firebaseUser.displayName ?? 'Unknown',
        'best_score': '0',
        'profpic': '',
      });
    } else {
      // Ενημέρωση υπάρχουσας εγγραφής
      Map<String, dynamic> user = users.first;
      String timeField = 'Time1';
      String dateField = 'Date1';

      if (user['Date1'].isNotEmpty && user['Time1'].isNotEmpty) {
        if (user['Date2'].isEmpty && user['Time2'].isEmpty) {
          timeField = 'Time2';
          dateField = 'Date2';
        } else if (user['Date3'].isEmpty && user['Time3'].isEmpty) {
          timeField = 'Time3';
          dateField = 'Date3';
        } else if (user['Date4'].isEmpty && user['Time4'].isEmpty) {
          timeField = 'Time4';
          dateField = 'Date4';
        } else {
          // Κύλιση παλιών τιμών
          await db.update(
            'user',
            {
              'Time1': user['Time2'],
              'Date1': user['Date2'],
              'Time2': user['Time3'],
              'Date2': user['Date3'],
              'Time3': user['Time4'],
              'Date3': user['Date4'],
            },
            where: 'email = ?',
            whereArgs: [userEmail],
          );
          timeField = 'Time4';
          dateField = 'Date4';
        }
      }

      await db.update(
        'user',
        {
          timeField: elapsedSeconds.toString(),
          dateField: DateTime.now().toIso8601String(),
        },
        where: 'email = ?',
        whereArgs: [userEmail],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    int percentage = correctAnswers * 10;
    _updateUserResults(); // Κλήση της μεθόδου ενημέρωσης

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Better luck next time...',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.redAccent,
              child: Text(
                '$percentage%',
                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Driving Test Failed',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Text(
                      '$correctAnswers/10',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Text('Results'),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      '${elapsedSeconds ~/ 60}:${(elapsedSeconds % 60).toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Text('Time'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const TestPage()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 50),
              ),
              child: const Text(
                'Start New Test',
                style: TextStyle(fontSize: 18, color: Colors.black),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const HomePage()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(color: Colors.green),
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 50),
              ),
              child: const Text(
                'Back to Home',
                style: TextStyle(fontSize: 18, color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
