import 'package:flutter/material.dart';
import 'package:impetus/core/ui_constants.dart';

void main() {
  runApp(const ImpetusApp());
}

class ImpetusApp extends StatelessWidget {
  const ImpetusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IMPETUS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: UIConstants.primaryCyan,
        scaffoldBackgroundColor: UIConstants.deepBlack,
        cardColor: UIConstants.cardGrey,
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text('IMPETUS - Inizializzazione'),
        ),
      ),
    );
  }
}
