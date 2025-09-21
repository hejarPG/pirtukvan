
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdfrx/pdfrx.dart';
import '../../../data/services/translator_service.dart';
import '../view_model/reader_selection_view_model.dart';
import '../widgets/selectable_pdf_viewer.dart';


class ReaderPage extends StatelessWidget {
  final File file;
  const ReaderPage({super.key, required this.file});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ReaderSelectionViewModel(),
      child: _ReaderPageContent(file: file),
    );
  }
}

class _ReaderPageContent extends StatelessWidget {
  final File file;
  const _ReaderPageContent({required this.file});

  @override
  Widget build(BuildContext context) {
    final selectionVM = Provider.of<ReaderSelectionViewModel>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(file.path.split('/').last),
      ),
      body: SelectablePdfViewer(
        filePath: file.path,
        pdfViewer: PdfViewer.file(
          file.path,
          params: const PdfViewerParams(),
        ),
      ),
      floatingActionButton: selectionVM.selectedText != null && selectionVM.selectedText!.isNotEmpty
          ? FloatingActionButton(
              onPressed: () async {
                final translator = TranslatorService(apiKey: 'YOUR_GEMINI_API_KEY');
                final translation = await translator.translateToPersian(selectionVM.selectedText!);
                if (context.mounted) {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Translation'),
                      content: Text(translation),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                }
              },
              child: const Icon(Icons.translate),
            )
          : null,
    );
  }
}
