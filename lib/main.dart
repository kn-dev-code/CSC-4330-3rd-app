import 'package:flutter/material.dart';

import 'calendar_page.dart';
import 'home_page.dart';

void main() {
  runApp(const PlanningApp());
}

class PlanningApp extends StatefulWidget {
  const PlanningApp({super.key});

  @override
  State<PlanningApp> createState() => _PlanningAppState();
}

class _PlanningAppState extends State<PlanningApp> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF1F6F5B);

    final lightScheme = ColorScheme.fromSeed(seedColor: seed);
    final darkScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
      surface: const Color(0xFF18221E),
    );
    return MaterialApp(
      title: 'Team Plan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: lightScheme,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF6F4EF),
      ),
      darkTheme: ThemeData(
        colorScheme: darkScheme,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF101713),
        cardColor: const Color(0xFF1A2621),
      ),
      themeMode: _themeMode,
      home: AppShell(
        isDark: _themeMode == ThemeMode.dark,
        onThemeToggle: () => setState(() {
          _themeMode = _themeMode == ThemeMode.dark
              ? ThemeMode.light
              : ThemeMode.dark;
        }),
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.isDark,
    required this.onThemeToggle,
  });

  final bool isDark;
  final VoidCallback onThemeToggle;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  List<Plan> _plans = const [];
  List<TeamMember> _members = const [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          HomePage(
            isDark: widget.isDark,
            onThemeToggle: widget.onThemeToggle,
            onPlansChanged: (plans) => setState(() => _plans = plans),
            onMembersChanged: (members) => setState(() => _members = members),
          ),
          CalendarPage(
            plans: _plans,
            members: _members,
            isDark: widget.isDark,
            onThemeToggle: widget.onThemeToggle,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: 'Calendar',
          ),
        ],
      ),
    );
  }
}
