import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:pirtukvan/firebase_options.dart';
import 'ui/home/views/home_page.dart';
import 'data/services/pdf_page_storage_service.dart';
import 'data/services/settings_service.dart';
import 'data/services/intent_handler_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Hive for storing PDF last-opened page info
  await PdfPageStorageService.init();
  // Initialize app settings (uses Hive)
  await SettingsService.init();

  runApp(const MyApp());
  // Initialize intent handler after the app is running so it can navigate
  // when the Android activity forwards an opened-file path.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    IntentHandler.init(MyApp.navigatorKey);
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pirtukvan',
      navigatorKey: navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const HomePage(),
    );
  }
}
