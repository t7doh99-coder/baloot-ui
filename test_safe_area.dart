import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Test')),
        body: const Center(child: Text('Body')),
        bottomNavigationBar: Container(
          color: Colors.red,
          child: SafeArea(
            child: SizedBox(
              height: 60,
              child: const Center(child: Text('Bottom Nav')),
            ),
          ),
        ),
      ),
    );
  }
}
