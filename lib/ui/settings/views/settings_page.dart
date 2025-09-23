import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_model/settings_view_model.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SettingsViewModel(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          centerTitle: true,
        ),
        body: const _SettingsForm(),
      ),
    );
  }
}

class _SettingsForm extends StatefulWidget {
  const _SettingsForm();

  @override
  State<_SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends State<_SettingsForm> {
  late TextEditingController _promptController;

  @override
  void initState() {
    super.initState();
    final vm = context.read<SettingsViewModel>();
    _promptController = TextEditingController(text: vm.promptTemplate);
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SettingsViewModel>();
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Prompt template (use {text} where the input should be):'),
          const SizedBox(height: 8),
          TextField(
            controller: _promptController,
            maxLines: 4,
            onChanged: vm.updatePrompt,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Choose LLM model:'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: vm.selectedModel,
            items: vm.availableModels
                .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                .toList(),
            onChanged: (v) {
              if (v != null) vm.updateModel(v);
            },
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () async {
              vm.updatePrompt(_promptController.text);
              // Capture navigator before async work to avoid using BuildContext
              // across an await (use_build_context_synchronously lint).
              final navigator = Navigator.of(context);
              await vm.save();
              if (mounted) navigator.pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
