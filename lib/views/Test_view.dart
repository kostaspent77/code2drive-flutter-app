import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:code2drive/views/test_good_result_view.dart';
import 'package:code2drive/views/test_bad_result_view.dart';

class TestPage extends StatefulWidget {
  const TestPage({super.key});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  Database? _database;
  Map<String, dynamic>? questionData;
  int? selectedAnswerIndex;
  List<String> options = [];
  int correctAnswers = 0;
  int questionsSoFar = 0;

  // Χρονόμετρο
  late Timer _timer;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _initDatabase();

    // Ξεκινάει το χρονόμετρο όταν φορτώνεται η σελίδα
    _startTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;
      });
    });
  }

  Future<void> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'Testing.db');

    final exists = await databaseExists(path);
    if (!exists) {
      try {
        final data = await rootBundle.load('assets/Testing.db');
        final bytes = data.buffer.asUint8List();
        await File(path).writeAsBytes(bytes);
      } catch (e) {
        print('Error copying database: $e');
        return;
      }
    }
    _database = await openDatabase(path);
    await _loadRandomQuestion();
  }

  Future<void> _loadRandomQuestion() async {
    if (_database != null) {
      final List<Map<String, dynamic>> questions =
          await _database!.query('traffic_signs');
      if (questions.isNotEmpty) {
        final randomIndex = Random().nextInt(questions.length);
        setState(() {
          questionData = questions[randomIndex];
          options = [
            questionData!['right'],
            questionData!['wrong1'],
            questionData!['wrong2'],
          ]..shuffle();
          selectedAnswerIndex = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (questionData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Test',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.deepOrange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Χρονόμετρο
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.timer, color: Colors.deepOrange, size: 28),
                const SizedBox(width: 10),
                Text(
                  '${_elapsedSeconds ~/ 60}:${(_elapsedSeconds % 60).toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: Image.asset(
                'assets/${questionData!['image']}',
                height: 150,
                width: 150,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'What does this sign mean?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            for (int i = 0; i < options.length; i++) ...[
              OptionButton(
                text: options[i],
                color: getOptionColor(options[i]),
                onTap: () {
                  setState(() {
                    selectedAnswerIndex = i;
                  });
                },
              ),
              const SizedBox(height: 10),
            ],
            const Spacer(),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  if (selectedAnswerIndex != null &&
                      options[selectedAnswerIndex!] == questionData!['right']) {
                    correctAnswers++;
                  }
                  questionsSoFar++;

                  if ((questionsSoFar == 10) && (correctAnswers > 8)) {
                    _timer.cancel(); // Σταματάει το χρονόμετρο
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TestGoodResultPage(
                          correctAnswers: correctAnswers,
                          elapsedSeconds: _elapsedSeconds, // Μεταφορά χρόνου
                        ),
                      ),
                    );
                  } else if ((questionsSoFar == 10) && (correctAnswers < 9)) {
                    _timer.cancel(); // Σταματάει το χρονόμετρο
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TestBadResultPage(
                          correctAnswers: correctAnswers,
                          elapsedSeconds: _elapsedSeconds, // Μεταφορά χρόνου
                        ),
                      ),
                    );
                  } else {
                    _loadRandomQuestion(); // Εμφανίζει νέα ερώτηση πριν από την ανανέωση
                    setState(() {
                      selectedAnswerIndex = null; // Καθαρίζει την επιλογή απάντησης
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
                ),
                child: const Text('Answer', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color getOptionColor(String option) {
    if (selectedAnswerIndex != null && option == options[selectedAnswerIndex!]) {
      return Colors.grey.shade300;
    }
    return Colors.white;
  }
}

class OptionButton extends StatelessWidget {
  final String text;
  final Color color;
  final VoidCallback onTap;

  const OptionButton({
    super.key,
    required this.text,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 15),
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Colors.deepOrange),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16),
        textAlign: TextAlign.center,
      ),
    );
  }
}
