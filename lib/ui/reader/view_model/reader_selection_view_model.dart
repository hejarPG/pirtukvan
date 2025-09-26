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

  // Generation counter used to ignore stale overlay updates from previous
  // translation streams. Incrementing the generation invalidates all prior
  // stream updates so they won't re-show after the overlay is closed.
  int _generation = 0;
  /// Start a new generation and return its id. Call this when beginning a
  /// new translation so incoming stream chunks can be validated against it.
  int startGeneration() {
    _generation++;
    return _generation;
  }

  /// Returns true if the given generation id is still the active one.
  bool isCurrentGeneration(int id) => id == _generation;

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
    // If overlay is being cleared/closed, bump generation so any in-flight
    // translation stream will stop updating the overlay.
    if (text == null || text.isEmpty) {
      _generation++;
    }
    notifyListeners();
  }

  void clearSelection() {
    // Stop any UI indication of translating and invalidate any in-flight
    // translation generations so they stop updating the overlay after the
    // selection is closed.
    setTranslating(false);
    _generation++;
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
