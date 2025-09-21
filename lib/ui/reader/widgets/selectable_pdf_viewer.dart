import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_model/reader_selection_view_model.dart';

class SelectablePdfViewer extends StatefulWidget {
  final String filePath;
  final Widget pdfViewer;
  const SelectablePdfViewer({super.key, required this.filePath, required this.pdfViewer});

  @override
  State<SelectablePdfViewer> createState() => _SelectablePdfViewerState();
}

class _SelectablePdfViewerState extends State<SelectablePdfViewer> {
  void _onSelectionChanged(String? text) {
    Provider.of<ReaderSelectionViewModel>(context, listen: false).setSelectedText(text);
  }

  @override
  Widget build(BuildContext context) {
    // This is a placeholder for PDF text selection logic.
    // Replace with actual PDF text selection widget if available.
    return GestureDetector(
      onLongPress: () async {
        // Simulate text selection for demo
        _onSelectionChanged('Sample selected text');
      },
      child: widget.pdfViewer,
    );
  }
}
