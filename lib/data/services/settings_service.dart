import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';

/// Simple settings service using Hive. Stores user prompt template and chosen model.
class PromptItem {
  final String id;
  final String name;
  final String text;

  PromptItem({required this.id, required this.name, required this.text});

  Map<String, String> toMap() => {'id': id, 'name': name, 'text': text};

  factory PromptItem.fromMap(Map<dynamic, dynamic> m) => PromptItem(
        id: m['id']?.toString() ?? '',
        name: m['name']?.toString() ?? '',
        text: m['text']?.toString() ?? '',
      );
}

class SettingsService {
  static const _boxName = 'app_settings_box';
  static const _keyPrompt = 'prompt_template';
  static const _keyPrompts = 'prompt_items';
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
    await Hive.openBox(_boxName);
    _initialized = true;
  }

  static Box get _box => Hive.box(_boxName);

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

  /// Prompts management
  static List<PromptItem> getPrompts() {
    try {
      final raw = _box.get(_keyPrompts);
      if (raw == null) return [];
      // raw is expected to be a List of Maps
      final list = <PromptItem>[];
      if (raw is List) {
        for (final itm in raw) {
          if (itm is Map) {
            list.add(PromptItem.fromMap(itm));
          } else if (itm is String) {
            try {
              final m = json.decode(itm);
              if (m is Map) list.add(PromptItem.fromMap(m));
            } catch (_) {}
          }
        }
      }
      return list;
    } catch (_) {
      return [];
    }
  }

  static Future<void> _savePrompts(List<PromptItem> prompts) async {
    try {
      final asMaps = prompts.map((p) => p.toMap()).toList();
      await _box.put(_keyPrompts, asMaps);
    } catch (_) {}
  }

  static Future<PromptItem> addPrompt(String name, String text) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final p = PromptItem(id: id, name: name, text: text);
    final list = getPrompts();
    list.add(p);
    await _savePrompts(list);
    return p;
  }

  static Future<void> updatePrompt(PromptItem prompt) async {
    final list = getPrompts();
    final idx = list.indexWhere((p) => p.id == prompt.id);
    if (idx >= 0) {
      list[idx] = prompt;
      await _savePrompts(list);
    }
  }

  static Future<void> deletePrompt(String id) async {
    final list = getPrompts();
    list.removeWhere((p) => p.id == id);
    await _savePrompts(list);
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
