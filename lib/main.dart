import 'package:firebase_core/firebase_core.dart';
import 'auth/auth_screen.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:giftapp/registerscreen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: AuthScreen(), // Display the RegisterScreen directly
    );

  }
}

