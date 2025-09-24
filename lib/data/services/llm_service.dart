
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../firebase_options.dart';
import 'settings_service.dart';

class LlmService {
  static final LlmService _instance = LlmService._internal();
  factory LlmService() => _instance;
  LlmService._internal();

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
  _model = FirebaseAI.googleAI().generativeModel(model: modelName, tools: [Tool.googleSearch()]);
    _initialized = true;
  }

  Future<String> translate(String text, {String? promptTemplate, int retryCount = 2}) async {
    await initialize();
    final template = promptTemplate ?? SettingsService.getPromptTemplate();
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
