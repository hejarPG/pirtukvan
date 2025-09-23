import 'package:hive_flutter/hive_flutter.dart';

/// Simple settings service using Hive. Stores user prompt template and chosen model.
class SettingsService {
  static const _boxName = 'app_settings_box';
  static const _keyPrompt = 'prompt_template';
  static const _keyModel = 'llm_model';

  static const String defaultPrompt =
      'Translate the following text to Persian (Farsi). Just return the translation, nothing else.\nText: {text}';
  static const String defaultModel = 'gemini-2.5-flash';

  static const List<String> availableModels = [
    'gemini-2.5-pro',
    'gemini-2.5-flash',
    'gemini-2.5-flash-lite',
    'gemini-live-2.5-flash-preview',
    'gemini-2.0-flash',
    'gemini-2.0-flash-lite',
  ];

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    // Hive should already be initialized by other services, but open the box if not
    await Hive.openBox<String>(_boxName);
    _initialized = true;
  }

  static Box<String> get _box => Hive.box<String>(_boxName);

  static String getPromptTemplate() {
    try {
      return _box.get(_keyPrompt) ?? defaultPrompt;
    } catch (_) {
      return defaultPrompt;
    }
  }

  static Future<void> setPromptTemplate(String template) async {
    try {
      await _box.put(_keyPrompt, template);
    } catch (_) {}
  }

  static String getModel() {
    try {
      return _box.get(_keyModel) ?? defaultModel;
    } catch (_) {
      return defaultModel;
    }
  }

  static Future<void> setModel(String model) async {
    try {
      await _box.put(_keyModel, model);
    } catch (_) {}
  }
}
