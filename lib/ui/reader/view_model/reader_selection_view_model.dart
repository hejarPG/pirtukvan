import 'package:flutter/material.dart';

class ReaderSelectionViewModel extends ChangeNotifier {
  String? _selectedText;
  String? get selectedText => _selectedText;
  bool _isTranslating = false;
  bool get isTranslating => _isTranslating;

  void setSelectedText(String? text) {
    _selectedText = text;
    notifyListeners();
  }

  void clearSelection() {
    _selectedText = null;
    notifyListeners();
  }

  void setTranslating(bool v) {
    _isTranslating = v;
    notifyListeners();
  }
}
