import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

class ReaderPage extends StatelessWidget {
  final File file;
  const ReaderPage({super.key, required this.file});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(file.path.split('/').last),
      ),
      body: PdfViewer.file(
        file.path,
        params: const PdfViewerParams(),
      ),
    );
  }
}
