
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../firebase_options.dart';

class TranslatorService {
  static final TranslatorService _instance = TranslatorService._internal();
  factory TranslatorService() => _instance;
  TranslatorService._internal();

  bool _initialized = false;
  late final GenerativeModel _model;

  Future<void> initialize() async {
    if (_initialized) return;
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    _model = FirebaseAI.googleAI().generativeModel(model: 'gemini-2.0-flash');
    _initialized = true;
  }

  Future<String> translate(String text, {int retryCount = 2}) async {
    await initialize();
    final prompt = [
      Content.text(
        'Translate the following text to Persian (Farsi). Just return the translation, nothing else.\nText: $text'
      ),
    ];
    int attempt = 0;
    while (true) {
      try {
        final response = await _model.generateContent(prompt);
        return response.text?.trim() ?? '';
      } catch (e) {
        if (attempt >= retryCount) rethrow;
        await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
        attempt++;
      }
    }
  }
}
