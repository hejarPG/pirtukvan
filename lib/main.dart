import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'ui/home/views/home_page.dart';
import 'package:pirtukvan/data/config.dart';

void main() {
  // Initialize Gemini globally if an API key has been configured.
  if (geminiApiKey.isNotEmpty && geminiApiKey != 'YOUR_GEMINI_API_KEY') {
    Gemini.init(apiKey: geminiApiKey);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const HomePage(),
    );
  }
}
