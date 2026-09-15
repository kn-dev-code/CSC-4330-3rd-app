import 'package:flutter/material.dart';

import 'home_page.dart';

void main() {
  runApp(const PlanningApp());
}

class PlanningApp extends StatelessWidget {
  const PlanningApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF1F6F5B);

    return MaterialApp(
      title: 'Team Plan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF6F4EF),
      ),
      home: const HomePage(),
    );
  }
}
