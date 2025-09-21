
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
          // provider updated by the viewer widget; no extra action needed here
          if (text != null && text.isNotEmpty) {
            Provider.of<ReaderSelectionViewModel>(context, listen: false).setSelectedText(text);
          }
        },
      ),
    floatingActionButton: selectionVM.selectedText != null && selectionVM.selectedText!.isNotEmpty
      ? FloatingActionButton(
        onPressed: selectionVM.isTranslating
          ? null
          : () async {
                // Use centralized config so developers can set it in one place.
                // See `lib/data/config.dart`.
                final configuredKey = geminiApiKey;
                if (configuredKey == 'YOUR_GEMINI_API_KEY' || configuredKey.isEmpty) {
                  // If API key missing, show overlay with error message anchored to selection
                  if (context.mounted) {
                    Provider.of<ReaderSelectionViewModel>(context, listen: false).setOverlayText(
                      'Translation failed: missing Gemini API key. Set it in lib/data/config.dart.',
                    );
                  }
                  return;
                }

                final vm = Provider.of<ReaderSelectionViewModel>(context, listen: false);
                final translator = TranslatorService();
                // set translating state so UI shows loader
                vm.setTranslating(true);
                // capture text before awaiting to avoid using context/VM across async gap
                final textToTranslate = selectionVM.selectedText;
                final translation = await translator.translate(
                   textToTranslate ?? '',
                );
                vm.setTranslating(false);
                // Set overlay text in view model so the SelectablePdfViewer will render it
                vm.setOverlayText(translation);
              },
              child: selectionVM.isTranslating
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Icon(Icons.translate),
            )
          : null,
    );
  }
}
