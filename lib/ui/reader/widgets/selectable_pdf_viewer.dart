import 'package:flutter/material.dart';
// no extra imports required here

class SelectablePdfViewer extends StatefulWidget {
  final String filePath;
  final Widget pdfViewer;
  final void Function(String?)? onSelection;
  const SelectablePdfViewer({super.key, required this.filePath, required this.pdfViewer, this.onSelection});

  @override
  State<SelectablePdfViewer> createState() => _SelectablePdfViewerState();
}

class _SelectablePdfViewerState extends State<SelectablePdfViewer> {
  @override
  Widget build(BuildContext context) {
    // The actual PDF viewer widget (pdfrx) handles selection internally.
    // We only expose a hook via `onSelection` and keep the child viewer.
    return widget.pdfViewer;
  }
}
