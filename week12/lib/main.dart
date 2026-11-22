import 'package:flutter/material.dart';
import 'pages/task_page.dart';

void main() {
  runApp(const Week12TestingApp());
}

class Week12TestingApp extends StatelessWidget {
  const Week12TestingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Week 12 - Testing & QA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
      ),
      home: const TaskPage(),
    );
  }
}
