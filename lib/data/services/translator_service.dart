
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../firebase_options.dart';
import 'settings_service.dart';

class TranslatorService {
  static final TranslatorService _instance = TranslatorService._internal();
  factory TranslatorService() => _instance;
  TranslatorService._internal();

  bool _initialized = false;
  late final GenerativeModel _model;

  Future<void> initialize() async {
    if (_initialized) return;
    // Ensure Firebase is initialized (main.dart initializes Firebase on startup,
    // but calling initializeApp again is safe if already initialized).
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (_) {}
  final modelName = SettingsService.getModel();
  _model = FirebaseAI.googleAI().generativeModel(model: modelName);
    _initialized = true;
  }

  Future<String> translate(String text, {int retryCount = 2}) async {
    await initialize();
    final template = SettingsService.getPromptTemplate();
    final filled = template.replaceAll('{text}', text);
    final prompt = [Content.text(filled)];
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
