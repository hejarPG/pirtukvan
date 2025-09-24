
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/services/llm_service.dart';
import '../../../data/services/settings_service.dart';
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

                final vm = Provider.of<ReaderSelectionViewModel>(context, listen: false);
                final translator = LlmService();
                // set translating state so UI shows loader
                vm.setTranslating(true);
                // capture text before awaiting to avoid using context/VM across async gap
                final textToTranslate = selectionVM.selectedText;
                // Ask user to choose a prompt template if any are saved
                final prompts = SettingsService.getPrompts();
                String? chosenTemplate;
                if (prompts.isNotEmpty) {
                  final sel = await showDialog<PromptItem?>(
                    context: context,
                    builder: (_) => SimpleDialog(
                      title: const Text('Choose prompt'),
                      children: prompts
                          .map((p) => SimpleDialogOption(
                                onPressed: () => Navigator.of(context).pop(p),
                                child: Text(p.name),
                              ))
                          .toList(),
                    ),
                  );
                  chosenTemplate = sel?.text;
                }

                // Stream translation so UI updates as chunks arrive
                final stream = translator.generateStream(
                  textToTranslate ?? '',
                  promptTemplate: chosenTemplate,
                );
                final buffer = StringBuffer();
                try {
                  await for (final chunk in stream) {
                    if (chunk.isNotEmpty) {
                      buffer.write(chunk);
                      // Update overlay as we receive chunks so the viewer shows progress
                      vm.setOverlayText(buffer.toString());
                    }
                  }
                } catch (e) {
                  // On error, clear translating state and optionally set an error message
                  vm.setOverlayText('');
                } finally {
                  vm.setTranslating(false);
                }
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
