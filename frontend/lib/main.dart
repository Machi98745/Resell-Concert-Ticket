import 'package:flutter/material.dart';

import 'screens/sell_page.dart';

void main() {
  runApp(const ResellCertApp());
}

class ResellCertApp extends StatelessWidget {
  const ResellCertApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Resell Cert Ticket',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pinkAccent),
        useMaterial3: true,
      ),
      home: const SellPage(),
    );
  }
}
