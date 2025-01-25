import 'package:firebase_core/firebase_core.dart';
import 'package:giftapp/auth/loginscreen.dart';
import 'package:giftapp/shops/menu_list/add_item.dart';
import 'package:giftapp/shops/menu_list/my_ads.dart';

import 'firebase_options.dart';
import 'package:flutter/material.dart';



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
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,

      ),
      initialRoute: '/',
      routes: {
        '/my-products': (context) => PostScreen(),
        '/add-item': (context) => AddItemScreen(),
        // Add other routes here
      },
      home: LoginScreen(), // Display the RegisterScreen directly
    );

  }
}

