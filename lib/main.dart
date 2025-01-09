import 'package:code2drive/constants/routes.dart';
import 'package:code2drive/services/auth/auth_service.dart';
import 'package:code2drive/views/code2drive_view.dart';
import 'package:code2drive/views/login_view.dart';
import 'package:code2drive/views/register_view.dart';
import 'package:code2drive/views/verify_email_view.dart'; 
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
      routes: {
        loginRoute: (context) => const LoginView(),
        registerRoute: (context) => const RegisterView(),
        code2drive: (context) => const Code2driveView(),
        verifyEmailRoute: (context) => const VerifyEmailView(),
      },
    ),
  );
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

@override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: AuthService.firebase().initialize(),
        builder: (context, snapshot) {
          switch(snapshot.connectionState) {
            case ConnectionState.done:
              final user = AuthService.firebase().currentUser;
              if (user != null) {
                    if (user.isEmailVerified) {
                      return const Code2driveView();
                    } else {
                      return const VerifyEmailView();
                    }
            } else {
              return const LoginView();
            }
            default: 
              return const CircularProgressIndicator(); 
          }
        },
      );
  }
}
