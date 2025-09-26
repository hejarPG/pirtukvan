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
  static const _keyOverlayFontSize = 'overlay_font_size';

  static const String defaultPrompt =
    'Translate the following text to Persian (Farsi). Detect the source language automatically. First normalize common PDF extraction artifacts: remove hyphenation caused by line breaks (e.g. "exam-\nple" -> "example"), join lines that belong to the same paragraph while preserving paragraph breaks, collapse multiple spaces to a single space, and trim leading/trailing whitespace. Preserve intentional formatting (lists, headings) when clearly present. After normalization, translate while preserving punctuation and basic formatting. Do not add explanations or commentary — return only the translated text.\nText: {text}';
  static const String defaultModel = 'gemini-2.5-flash';
  static const double defaultOverlayFontSize = 12.0;

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
    // Ensure default prompt items exist in storage. This keeps the prompts
    // consistent with how other prompts are saved (as a list of maps).
    try {
      final raw = _box.get(_keyPrompts);
      final current = <PromptItem>[];
      if (raw is List) {
        for (final itm in raw) {
          if (itm is Map) {
            current.add(PromptItem.fromMap(itm));
          } else if (itm is String) {
            try {
              final m = json.decode(itm);
              if (m is Map) current.add(PromptItem.fromMap(m));
            } catch (_) {}
          }
        }
      }

  final translatePrompt = PromptItem(
    id: 'seed-translate',
    name: 'Translate text',
    text:
      'Translate the following text to Persian (Farsi). Detect the source language automatically. First normalize common PDF extraction artifacts: remove hyphenation from broken lines (e.g. "exam-\nple" -> "example"), join lines belonging to the same paragraph while keeping paragraph breaks, collapse repeated spaces, and trim leading/trailing whitespace. Preserve intentional line breaks for lists or verses when clearly present. After normalization, translate the text and preserve punctuation and basic formatting. Return only the translated text with no additional commentary. If names or specialized terms appear, keep them unchanged unless a well-known Persian equivalent exists.\nText: {text}',
  );

      final explainPrompt = PromptItem(
        id: 'seed-explain',
        name: 'Explain simply in Persian with examples',
        text:
            'Explain the following text in Persian (Farsi) using simple words and short sentences. Provide 2-3 short examples that illustrate the explanation. Only output Persian, nothing else.\nText: {text}',
      );

        final translateWordPrompt = PromptItem(
          id: 'seed-translate-word',
          name: 'Translate single word to Persian',
      text:
        'Translate the following single word to Persian (Farsi). Return all common translations ordered from most common to least common, separated by commas. If multiple senses exist, include translations for each sense in order. Do not include explanations—only the translations.\nWord: {text}',
        );

      var needSave = false;
      if (!current.any((p) => p.id == translatePrompt.id)) {
        current.add(translatePrompt);
        needSave = true;
      }
      if (!current.any((p) => p.id == explainPrompt.id)) {
        current.add(explainPrompt);
        needSave = true;
      }
        if (!current.any((p) => p.id == translateWordPrompt.id)) {
          current.add(translateWordPrompt);
          needSave = true;
        }

      if (needSave) await _savePrompts(current);
    } catch (_) {}
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

  static double getOverlayFontSize() {
    try {
      final v = _box.get(_keyOverlayFontSize);
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? defaultOverlayFontSize;
      return defaultOverlayFontSize;
    } catch (_) {
      return defaultOverlayFontSize;
    }
  }

  static Future<void> setOverlayFontSize(double size) async {
    try {
      await _box.put(_keyOverlayFontSize, size);
    } catch (_) {}
  }

  static Future<void> setModel(String model) async {
    try {
      await _box.put(_keyModel, model);
    } catch (_) {}
  }
}
