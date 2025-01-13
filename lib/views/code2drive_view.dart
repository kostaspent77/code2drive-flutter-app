import 'package:code2drive/constants/routes.dart';
import 'package:code2drive/enums/menu_action.dart';
import 'package:code2drive/services/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:code2drive/views/practice_questions_view.dart';
import 'package:code2drive/views/Test_view.dart';
import 'package:code2drive/views/camera_view.dart';
import 'package:code2drive/views/study_view.dart';
import 'package:code2drive/views/user_profile_view.dart';
import 'package:code2drive/views/test_history_view.dart';
import 'package:code2drive/views/videos_view.dart';

class Code2driveView extends StatefulWidget {
  const Code2driveView({super.key});

  @override
  State<Code2driveView> createState() => _Code2driveViewState();
}

class _Code2driveViewState extends State<Code2driveView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        title: const Text('Code2Drive Home',
        style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),),
        backgroundColor: Colors.green,
        elevation: 0,
        actions: [
          IconButton(
        icon: const Icon(Icons.person),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const UserProfilePage(),
            ),
          );
        },
      ),
          PopupMenuButton<MenuAction>(
            onSelected: (value) async {
              switch (value) {
                case MenuAction.logout:
                  final shouldLogout = await showLogOutDialog(context);
                  if(shouldLogout) {
                    await AuthService.firebase().logOut();
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      loginRoute,
                      (_) => false,
                    );
                  }
              }
            }, 
            itemBuilder: (context) {
            return const [
              PopupMenuItem<MenuAction>(
                value: MenuAction.logout, 
                child: Text('Log out'),
              ),
            ];
          },
          )
        ],
      ),
      body: Container(
        color: Colors.lightBlue[50],
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 10.0),
          children: [
            MenuItem(
              title: 'Practice Questions',
              icon: Icons.question_answer,
              color: Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PracticeQuestionsPage()),
                );
              },
            ),
            MenuItem(
              title: 'Test',
              icon: Icons.assessment,
              color: Colors.orange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TestPage()),
                );
              },
            ),
            MenuItem(
              title: 'Study',
              icon: Icons.book,
              color: Colors.red,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const StudyPage()),
                );
              },
            ),
            MenuItem(
              title: 'Watch and learn!',
              icon: Icons.movie,
              color: Colors.green,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => VideoPage()),
                );
              },
            ),
            MenuItem(
              title: 'Test History',
              icon: Icons.history,
              color: Colors.orangeAccent,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TestHistoryPage()),
                );
              },
            ),
            MenuItem(
              title: 'Find road signs with your camera!',
              icon: Icons.camera_alt,
              color: Colors.purple,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CameraPage()),
                );
              },
            ),
          ],
        ),
      ),
      //const Text('Hello World'),

    );
  }
}

Future<bool> showLogOutDialog(BuildContext context) {
  return showDialog<bool> (
  context: context, 
  builder: (context) {
    return AlertDialog(
      title: const Text('Sign out'),
      content: const Text('Are you sure you want to sign out?'),
      actions: [
        TextButton(onPressed: () {
          Navigator.of(context).pop(false);
        }, 
        child: const Text('Cancel')
        ),
        TextButton(onPressed: () {
          Navigator.of(context).pop(true);
        }, 
        child: const Text('Log out')
        ),
      ],
    );
  },
  ).then((value) => value ?? false);
}


class MenuItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const MenuItem({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
        onTap: onTap, // Χειρίζεται την πλοήγηση
      ),
    );
  }
}