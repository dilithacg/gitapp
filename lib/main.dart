import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import 'package:giftapp/auth/loginscreen.dart';
import 'package:giftapp/shops/menu_list/add_item.dart';
import 'package:giftapp/shops/menu_list/my_ads.dart';
import 'package:giftapp/shops/menu_list/orders.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set Stripe Publishable Key before initializing Firebase
  Stripe.publishableKey = "pk_test_51QsIuMG65mskaWEQN84vjGgIhXQEPKj6wVtRBSOnqnJsN9MBHt8CfI9rmUvNPGj6ALmM0M7BneJnwXC1wcYLJZ3p00gIWMyeFf";

  // Initialize Firebase
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          iconTheme: IconThemeData(color: Colors.white), // Change back arrow color
        ),
      ),
      initialRoute: '/',
      routes: {
        '/my-products': (context) => PostScreen(),
        '/add-item': (context) => AddItemScreen(),
        '/orders': (context) => OrdersScreen(),
        // Add other routes here
      },
      home: LoginScreen(), // Display the RegisterScreen directly
    );
  }
}
