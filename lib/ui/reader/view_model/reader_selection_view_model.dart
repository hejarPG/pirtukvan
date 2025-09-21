import 'package:flutter/material.dart';

class ReaderSelectionViewModel extends ChangeNotifier {
  String? _selectedText;
  String? get selectedText => _selectedText;

  void setSelectedText(String? text) {
    _selectedText = text;
    notifyListeners();
  }

  void clearSelection() {
    _selectedText = null;
    notifyListeners();
  }
}
