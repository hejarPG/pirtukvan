
import 'package:flutter/material.dart';
import '../../../data/services/pdf_picker_service.dart';
import '../../reader/views/reader_page.dart';
import '../../settings/views/settings_page.dart';
import 'package:url_launcher/url_launcher_string.dart';

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
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed: () => _openPdf(context),
                    child: const Text('Open PDF'),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'About us',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Pirtukvan is a lightweight PDF reader created and maintained by HejarPG. It combines a clean, focused reading experience with optional LLM-powered tools to help you summarize, search, and interact with documents as you read.",
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.justify,
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () async {
                                const url = 'https://github.com/hejarpg';
                                final scaffold = ScaffoldMessenger.of(context);
                                try {
                                  final launched = await launchUrlString(url);
                                  if (!launched) {
                                    scaffold.showSnackBar(
                                      const SnackBar(content: Text('Could not open URL.')),
                                    );
                                  }
                                } catch (_) {
                                  scaffold.showSnackBar(
                                    const SnackBar(content: Text('Could not open URL.')),
                                  );
                                }
                              },
                              icon: const Icon(Icons.link),
                              label: const Text('GitHub'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "The name 'Pirtukvan' is inspired by Kurdish: 'pirtuk' means 'book' and the suffix '-van' denotes someone skilled or engaged in an activity—together conveying the idea of a 'book expert' or 'librarian'.",
                            style: Theme.of(context).textTheme.bodySmall,
                            textAlign: TextAlign.justify,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
