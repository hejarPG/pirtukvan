
import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter_gemini/flutter_gemini.dart';

class TranslatorService {

  final Gemini gemini;

  /// If an [apiKey] is provided, will init Gemini with it; otherwise uses
  /// the existing `Gemini.instance` (which should be initialized in `main`).
  TranslatorService({String? apiKey}) : gemini = (apiKey != null && apiKey.isNotEmpty)
      ? Gemini.init(apiKey: apiKey)
      : Gemini.instance;

  /// Translates the given [text] to Persian using Gemini.
  ///
  /// This method adds safe logging around the request/response so we can
  /// diagnose HTTP 4xx/5xx issues without leaking secrets.
  Future<String> translateToPersian(String text) async {
  final prompt =
    'Translate the following text to Persian (Farsi) and return only the translation, no explanation.\nText: "$text"';

    try {
      // Note: we can't/shouldn't log the actual API key. Ensure callers set it.
      developer.log('TranslatorService: calling gemini.prompt', name: 'translator', level: 800);
      developer.log('TranslatorService: preparing prompt', name: 'translator');
      // Log only the prompt length and a trimmed preview to avoid leaking
      // the full content in logs for long or sensitive texts.
      final preview = text.length > 200 ? '${text.substring(0, 200)}...' : text;
      developer.log('Prompt preview: $preview', name: 'translator', level: 800);

  final result = await gemini.prompt(parts: [Part.text(prompt)]);

      if (result == null) {
        developer.log('TranslatorService: gemini.prompt returned null', name: 'translator', level: 900);
        return 'Translation failed: empty response from translation service.';
      }

      // Log some metadata about the response but not the full text.
      developer.log('TranslatorService: received response', name: 'translator', level: 800);

      return result.output ?? '';
    } catch (e, st) {
      developer.log('TranslatorService: exception during translate', name: 'translator', error: e, stackTrace: st, level: 1000);

      // If the error is a DioError, try to extract the HTTP status and body
      // returned by the Gemini service to provide a more actionable message.
      if (e is DioError) {
        final status = e.response?.statusCode;
        final data = e.response?.data;
        final body = data is String ? data : data?.toString();
        final preview = body != null && body.length > 800 ? '${body.substring(0, 800)}...' : body;
        developer.log('TranslatorService: DioError response preview: $preview', name: 'translator', level: 1000);
        return 'Translation failed: ${e.type}${status != null ? ' (HTTP $status)' : ''} — ${preview ?? 'no response body'}';
      }

      // Fall back to showing the exception's toString (truncated) for other errors
      final text = e.toString();
      final short = text.length > 300 ? '${text.substring(0, 300)}...' : text;
      return 'Translation failed: $short';
    }
  }
}
