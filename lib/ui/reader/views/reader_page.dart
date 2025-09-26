
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// imports for translation moved into overlay
import '../../settings/views/settings_page.dart';
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

class _ReaderPageContent extends StatefulWidget {
  final File file;
  const _ReaderPageContent({required this.file});

  @override
  State<_ReaderPageContent> createState() => _ReaderPageContentState();
}

class _ReaderPageContentState extends State<_ReaderPageContent> {
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
  // selection VM is consumed by children (overlay/viewer) via provider
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.file.path.split('/').last),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsPage()));
            },
          ),
          IconButton(
            icon: Icon(_darkMode ? Icons.light_mode : Icons.dark_mode),
            tooltip: _darkMode ? 'Light mode' : 'Dark mode',
            onPressed: () => setState(() => _darkMode = !_darkMode),
          ),
        ],
      ),
      body: ColorFiltered(
        colorFilter: ColorFilter.mode(
          Colors.white,
          _darkMode ? BlendMode.difference : BlendMode.dst,
        ),
        child: SelectablePdfViewer(
          filePath: widget.file.path,
          onSelection: (text) {
            // provider updated by the viewer widget; no extra action needed here
            if (text != null && text.isNotEmpty) {
              Provider.of<ReaderSelectionViewModel>(context, listen: false).setSelectedText(text);
            }
          },
        ),
      ),
      // Translation is triggered from the inline overlay now; no FAB.
    );
  }
}
