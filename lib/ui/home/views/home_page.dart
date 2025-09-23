
import 'package:flutter/material.dart';
import '../../../data/services/pdf_picker_service.dart';
import '../../reader/views/reader_page.dart';
import '../../settings/views/settings_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _openPdf(BuildContext context) async {
    final picker = PdfPickerService();
    // Capture the Navigator before the async gap to avoid using BuildContext
    // after an await (use_build_context_synchronously lint).
    final navigator = Navigator.of(context);
    final file = await picker.pickPdf();
    if (file != null) {
      navigator.push(
        MaterialPageRoute(
          builder: (_) => ReaderPage(file: file),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            ),
          )
        ],
        centerTitle: true,
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _openPdf(context),
          child: const Text('Open PDF'),
        ),
      ),
    );
  }
}
