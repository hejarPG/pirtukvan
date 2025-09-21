import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

class ReaderSelectionViewModel extends ChangeNotifier {
  String? _selectedText;
  String? get selectedText => _selectedText;
  bool _isTranslating = false;
  bool get isTranslating => _isTranslating;

  // Overlay/selection geometry saved when user selects text so we can
  // render a floating overlay at the correct page/position.
  PdfRect? _selectedBounds; // bounds in PDF page coordinates
  PdfRect? get selectedBounds => _selectedBounds;
  int? _selectedPageNumber;
  int? get selectedPageNumber => _selectedPageNumber;

  // The translation/overlay text to show above the selected text.
  String? _overlayText;
  String? get overlayText => _overlayText;
  bool get isOverlayVisible => _overlayText != null && _overlayText!.isNotEmpty;

  void setSelectedText(String? text) {
    _selectedText = text;
    notifyListeners();
  }

  void setSelectionBounds(int pageNumber, PdfRect bounds) {
    _selectedPageNumber = pageNumber;
    _selectedBounds = bounds;
    notifyListeners();
  }

  void setOverlayText(String? text) {
    _overlayText = text;
    notifyListeners();
  }

  void clearSelection() {
    _selectedText = null;
    _selectedBounds = null;
    _selectedPageNumber = null;
    _overlayText = null;
    notifyListeners();
  }

  void setTranslating(bool v) {
    _isTranslating = v;
    notifyListeners();
  }
}
