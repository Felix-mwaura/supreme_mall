import 'package:flutter/material.dart';

void main() {
  runApp(const SupremeMallApp());
}

class SupremeMallApp extends StatelessWidget {
  const SupremeMallApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Supreme Mall',
      home: Scaffold(
        appBar: AppBar(title: const Text('Supreme Mall')),
        body: const Center(child: Text('Welcome to Supreme Mall')),
      ),
    );
  }
}