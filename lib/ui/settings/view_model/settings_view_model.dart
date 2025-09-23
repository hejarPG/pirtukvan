import 'package:flutter/foundation.dart';
import '../../../data/services/settings_service.dart';

class SettingsViewModel extends ChangeNotifier {
  String promptTemplate = SettingsService.getPromptTemplate();
  String selectedModel = SettingsService.getModel();

  List<String> get availableModels => SettingsService.availableModels;

  void updatePrompt(String v) {
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
