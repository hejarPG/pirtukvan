import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_model/settings_view_model.dart';
import '../../../data/services/settings_service.dart';

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
          ElevatedButton.icon(
            onPressed: () async {
              final res = await showDialog<Map<String, String>>(
                context: context,
                builder: (_) {
                  final nameCtl = TextEditingController();
                  final textCtl = TextEditingController();
                  return AlertDialog(
                    title: const Text('Add prompt'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(controller: nameCtl, decoration: const InputDecoration(labelText: 'Name')),
                        const SizedBox(height: 8),
                        TextField(controller: textCtl, maxLines: 4, decoration: const InputDecoration(labelText: 'Text')),
                      ],
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                      ElevatedButton(onPressed: () => Navigator.of(context).pop({'name': nameCtl.text, 'text': textCtl.text}), child: const Text('Add')),
                    ],
                  );
                },
              );
              if (res != null && (res['name']?.isNotEmpty ?? false)) {
                await vm.addPrompt(res['name']!, res['text'] ?? '');
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Add prompt'),
          ),

          SizedBox(
            height: 180,
            child: Card(
              child: vm.prompts.isEmpty
                  ? const Center(child: Text('No saved prompts'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(8),
                      itemCount: vm.prompts.length,
                      separatorBuilder: (_, __) => const Divider(height: 8),
                      itemBuilder: (context, idx) {
                        final p = vm.prompts[idx];
                        return ListTile(
                          title: Text(p.name),
                          subtitle: Text(
                            p.text,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () async {
                                  final res = await showDialog<Map<String, String>>(
                                      context: context,
                                      builder: (_) {
                                        final nameCtl = TextEditingController(text: p.name);
                                        final textCtl = TextEditingController(text: p.text);
                                        return AlertDialog(
                                          title: const Text('Edit prompt'),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              TextField(controller: nameCtl, decoration: const InputDecoration(labelText: 'Name')),
                                              const SizedBox(height: 8),
                                              TextField(controller: textCtl, maxLines: 4, decoration: const InputDecoration(labelText: 'Text')),
                                            ],
                                          ),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                                            ElevatedButton(
                                              onPressed: () => Navigator.of(context).pop({'name': nameCtl.text, 'text': textCtl.text}),
                                              child: const Text('Save'),
                                            ),
                                          ],
                                        );
                                      });
                                  if (res != null) {
                                    await vm.updatePrompt(PromptItem(id: p.id, name: res['name'] ?? p.name, text: res['text'] ?? p.text));
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () async {
                                  final ok = await showDialog<bool>(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                            title: const Text('Delete prompt'),
                                            content: const Text('Are you sure you want to delete this prompt?'),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('No')),
                                              ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Yes')),
                                            ],
                                          ));
                                  if (ok == true) await vm.deletePrompt(p.id);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () async {
              final res = await showDialog<Map<String, String>>(
                context: context,
                builder: (_) {
                  final nameCtl = TextEditingController();
                  final textCtl = TextEditingController();
                  return AlertDialog(
                    title: const Text('Add prompt'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(controller: nameCtl, decoration: const InputDecoration(labelText: 'Name')),
                        const SizedBox(height: 8),
                        TextField(controller: textCtl, maxLines: 4, decoration: const InputDecoration(labelText: 'Text')),
                      ],
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                      ElevatedButton(onPressed: () => Navigator.of(context).pop({'name': nameCtl.text, 'text': textCtl.text}), child: const Text('Add')),
                    ],
                  );
                },
              );
              if (res != null && (res['name']?.isNotEmpty ?? false)) {
                await vm.addPrompt(res['name']!, res['text'] ?? '');
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Add prompt'),
          ),
          const SizedBox(height: 16),
          const Spacer(),
          ElevatedButton(
            onPressed: () async {
              // Capture navigator before async work to avoid using BuildContext
              // across an await (use_build_context_synchronously lint).
              final navigator = Navigator.of(context);
              await vm.save();
              await vm.loadPrompts();
              if (mounted) navigator.pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
