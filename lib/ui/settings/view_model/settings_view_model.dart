import 'package:flutter/foundation.dart';
import '../../../data/services/settings_service.dart';

class PromptListItem {
  final PromptItem item;
  PromptListItem(this.item);
}

class SettingsViewModel extends ChangeNotifier {
  String promptTemplate = SettingsService.getPromptTemplate();
  String selectedModel = SettingsService.getModel();
  List<PromptItem> prompts = [];

  List<String> get availableModels => SettingsService.availableModels;

  Future<void> loadPrompts() async {
    prompts = SettingsService.getPrompts();
    notifyListeners();
  }

  Future<void> addPrompt(String name, String text) async {
    await SettingsService.addPrompt(name, text);
    await loadPrompts();
  }

  Future<void> updatePrompt(PromptItem p) async {
    await SettingsService.updatePrompt(p);
    await loadPrompts();
  }

  Future<void> deletePrompt(String id) async {
    await SettingsService.deletePrompt(id);
    await loadPrompts();
  }

  void updatePromptTemplate(String v) {
    promptTemplate = v;
    notifyListeners();
  }

  void updateModel(String v) {
    selectedModel = v;
    notifyListeners();
  }

  Future<void> save() async {
    await SettingsService.setPromptTemplate(promptTemplate);
    await SettingsService.setModel(selectedModel);
  }
}
