import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class PracticeQuestionsPage extends StatefulWidget {
  const PracticeQuestionsPage({super.key});

  @override
  State<PracticeQuestionsPage> createState() => _PracticeQuestionsPageState();
}

class _PracticeQuestionsPageState extends State<PracticeQuestionsPage> {
  Database? _database;
  Map<String, dynamic>? questionData; // Δεδομένα της τρέχουσας ερώτησης
  int? selectedAnswerIndex; // Δείκτης για την επιλεγμένη απάντηση
  bool showAnswer = false; // Καθορίζει αν έχει πατηθεί το κουμπί "Answer"
  List<String> options = []; // Προσθήκη της options ως ιδιότητας

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

Future<void> _initDatabase() async {
  final databasePath = await getDatabasesPath();
  final path = join(databasePath, 'Testing.db');

  // Έλεγχος αν η βάση υπάρχει ήδη
  final exists = await databaseExists(path);
  
  if (!exists) {
    print('Copying database from assets...');
    try {
      // Αντιγραφή της βάσης από τα assets
      final data = await rootBundle.load('assets/Testing.db');
      final bytes = data.buffer.asUint8List();

      // Δημιουργία τοπικού αρχείου
      await File(path).writeAsBytes(bytes);
      print('Database successfully copied to $path');
    } catch (e) {
      print('Error copying database: $e');
      return;
    }
  } else {
    print('Database already exists at $path');
  }

final data = await rootBundle.load('assets/Testing.db');
final bytes = data.buffer.asUint8List();
await File(path).writeAsBytes(bytes);


  // Άνοιγμα της βάσης
  _database = await openDatabase(path);
  print('Database opened successfully');
  await _loadRandomQuestion();



final tables = await _database!.rawQuery(
    "SELECT name FROM sqlite_master WHERE type='table'");

if (tables.isEmpty) {
  print('No tables found in the database!');
} else {
  for (var table in tables) {
    print('Table: ${table['name']}');
  }
}

}


  Future<void> _loadRandomQuestion() async {
    if (_database != null) {
      // Ανάκτηση τυχαίας εγγραφής από τον πίνακα "traffic_signs"
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
          ]..shuffle(); // Ανακάτεμα επιλογών
          selectedAnswerIndex = null;
          showAnswer = false;
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
        title: const Text('Practice Questions',
        style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Εικόνα του σήματος
            Center(
              child: Image.asset(
                'assets/${questionData!['image']}', // Το μονοπάτι για την εικόνα
                height: 150,
                width: 150,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 20),
            // Ερώτηση
            Text(
              'What does this sign mean?', // Ερώτηση από τη βάση δεδομένων
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            // Επιλογές απάντησης
            for (int i = 0; i < options.length; i++) ...[
              OptionButton(
                text: options[i],
                color: getOptionColor(options[i]),
                onTap: () {
                  setState(() {
                    selectedAnswerIndex = i; // Καταγράφει την επιλεγμένη απάντηση
                  });
                },
              ),
              const SizedBox(height: 10),
            ],
            const Spacer(),
            // Κουμπιά "Answer" και "Next"
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      showAnswer = true; // Εμφανίζει την απάντηση
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                  child: const Text('Answer'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _loadRandomQuestion(); // Φόρτωση νέας τυχαίας ερώτησης
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                  child: const Text('Next'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Επιστρέφει το χρώμα για κάθε επιλογή
  Color getOptionColor(String option) {
    if (showAnswer) {
      // Λογική για το "Answer"
      if (option == questionData!['right']) {
        return Colors.green; // Σωστή απάντηση
      } else {
        return Colors.red; // Λανθασμένη απάντηση
      }
    }
    // Επιστρέφει γκρι για την επιλογή που πατήθηκε
    if (selectedAnswerIndex != null &&
        option == options[selectedAnswerIndex!]) {
      return Colors.grey.shade300;
    }
    return Colors.white; // Αρχικό χρώμα
  }
}

// Widget για κουμπιά επιλογών
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
        minimumSize: const Size(double.infinity, 50), // Ορίζει το οριζόντιο μήκος ίσο
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Colors.blue),
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

