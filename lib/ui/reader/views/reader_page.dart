
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdfrx/pdfrx.dart';
import '../../../data/services/translator_service.dart';
import 'package:pirtukvan/data/config.dart';
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
        onSelection: (text) {
          // optional hook, provider already updated by the viewer widget
        },
        pdfViewer: PdfViewer.file(
          file.path,
          params: PdfViewerParams(
            textSelectionParams: PdfTextSelectionParams(
              onTextSelectionChange: (selection) async {
                try {
                  final selected = await selection.getSelectedText();
                  if (selected.isNotEmpty) {
                    if (context.mounted) {
                      // Only update provider so the floating translate button appears; do not show dialog
                      Provider.of<ReaderSelectionViewModel>(context, listen: false).setSelectedText(selected);
                    }
                  }
                } catch (e) {
                  // ignore errors when fetching selected text
                }
              },
            ),
          ),
        ),
      ),
      floatingActionButton: selectionVM.selectedText != null && selectionVM.selectedText!.isNotEmpty
          ? FloatingActionButton(
              onPressed: () async {
                // Use centralized config so developers can set it in one place.
                // See `lib/data/config.dart`.
                final configuredKey = geminiApiKey;
                if (configuredKey == 'YOUR_GEMINI_API_KEY' || configuredKey.isEmpty) {
                  if (context.mounted) {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Translation'),
                        content: const Text('Translation failed: missing or invalid Gemini API key. Please set your API key in lib/data/config.dart or initialize Gemini in main().'),
                        actions: [
                          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK')),
                        ],
                      ),
                    );
                  }
                  return;
                }

                final translator = TranslatorService(apiKey: configuredKey);
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
