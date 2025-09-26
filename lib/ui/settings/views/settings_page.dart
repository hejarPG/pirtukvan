import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_model/settings_view_model.dart';
// ...existing code...
import '../widgets/prompt_widgets.dart';

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
  // prompt text is now managed via saved prompts; no single template input here

  @override
  void initState() {
    super.initState();
    final vm = context.read<SettingsViewModel>();
    WidgetsBinding.instance.addPostFrameCallback((_) => vm.loadPrompts());
  }

  @override
  void dispose() {
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
          // Overlay font size control
          const Text('Overlay font size:'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: vm.overlayFontSize,
                  min: 8.0,
                  max: 24.0,
                  divisions: 16,
                  label: vm.overlayFontSize.toStringAsFixed(0),
                  onChanged: (v) => vm.updateOverlayFontSize(v),
                ),
              ),
              SizedBox(
                width: 48,
                child: Text('${vm.overlayFontSize.toStringAsFixed(0)}sp'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const SizedBox(height: 8),
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
          const SizedBox(height: 16),
          const Text('Saved prompts:'),
          const SizedBox(height: 8),
          AddPromptButton(vm: vm),

          Expanded(
            child: PromptList(vm: vm),
          ),
        ],
      ),
    );
  }
}
