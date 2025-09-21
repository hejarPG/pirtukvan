
import 'package:flutter_gemini/flutter_gemini.dart';

class TranslatorService {

  final Gemini gemini;

  TranslatorService({required String apiKey})
    : gemini = Gemini.init(apiKey: apiKey);

  /// Translates the given [text] to Persian using Gemini Flash-2.0 model.
  Future<String> translateToPersian(String text) async {
    final prompt =
        'Translate the following text to Persian (Farsi) and return only the translation, no explanation.\nText: "$text"';
    try {
      final result = await gemini.prompt(parts: [Part.text(prompt)]);
      return result?.output ?? '';
    } catch (e) {
      return 'Translation failed: $e';
    }
  }
}
