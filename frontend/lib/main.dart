import 'package:flutter/material.dart';
import 'views/login.dart';
void main() {
  runApp(const ResellCertApp());
}

class ResellCertApp extends StatelessWidget {
  const ResellCertApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Resell Concert Ticket',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const Login(),
    );
  }
}
