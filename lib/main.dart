import 'package:ev_charger/screens/Signin.dart';
import 'package:ev_charger/screens/profile.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

const backgroundblue = Color(0xFF535FFD);
const backgroundwhite = Color(0xFFFAFAFA);

Future<void> main() async {
  runApp(const MyApp());
  await Firebase.initializeApp();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return const MaterialApp(
      home: sign_in(),
    );
  }
}
