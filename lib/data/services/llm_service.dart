
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
  // System prompt instructing the LLM to return responses in Markdown format.
  static const String _systemPrompt =
      'You are an assistant that MUST return all answers strictly in Markdown format. Use Markdown for emphasis (e.g. **bold**), lists, headings, links, inline code and code blocks. Do not include any text outside of valid Markdown.';

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

  Future<String> generate(String text, {String? promptTemplate, int retryCount = 2}) async {
    await initialize();
    final template = promptTemplate ?? SettingsService.getPromptTemplate();
    final filled = template.replaceAll('{text}', text);
  // Prepend a system-style prompt so the model returns Markdown-formatted output.
  final prompt = [Content.text(_systemPrompt), Content.text(filled)];
    int attempt = 0;
    while (true) {
      try {
        // Collect response from streaming API to preserve current behavior
        final buffer = StringBuffer();
        final stream = _model.generateContentStream(prompt);
        await for (final chunk in stream) {
          final chunkText = chunk.text?.trim() ?? '';
          if (chunkText.isNotEmpty) buffer.write(chunkText);
        }
        return buffer.toString();
      } catch (e) {
        if (attempt >= retryCount) rethrow;
        await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
        attempt++;
      }
    }
  }

  /// Streams chunks of the generated content as they arrive.
  ///
  /// Yields each chunk's text (as-is, trimmed). This method does not perform
  /// automatic retries; callers who need retries should collect the stream and
  /// implement their own retry logic if required.
  Stream<String> generateStream(String text, {String? promptTemplate}) async* {
    await initialize();
    final template = promptTemplate ?? SettingsService.getPromptTemplate();
    final filled = template.replaceAll('{text}', text);
  // Prepend a system-style prompt so the model returns Markdown-formatted output.
  final prompt = [Content.text(_systemPrompt), Content.text(filled)];

    final responseStream = _model.generateContentStream(prompt);
    await for (final chunk in responseStream) {
      final chunkText = chunk.text ?? '';
      yield chunkText;
    }
  }
}
