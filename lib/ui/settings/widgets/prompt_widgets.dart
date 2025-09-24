import 'package:flutter/material.dart';
import '../view_model/settings_view_model.dart';
import '../../../data/services/settings_service.dart';

Future<Map<String, String>?> showPromptEditorDialog(BuildContext context, {required String title, String? initialName, String? initialText}) {
  final nameCtl = TextEditingController(text: initialName);
  final textCtl = TextEditingController(text: initialText);
  return showDialog<Map<String, String>>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
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
        ElevatedButton(onPressed: () => Navigator.of(context).pop({'name': nameCtl.text, 'text': textCtl.text}), child: const Text('Save')),
      ],
    ),
  );
}

class AddPromptButton extends StatelessWidget {
  final SettingsViewModel vm;
  const AddPromptButton({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () async {
        final res = await showPromptEditorDialog(context, title: 'Add prompt');
        if (res != null && (res['name']?.isNotEmpty ?? false)) {
          await vm.addPrompt(res['name']!, res['text'] ?? '');
        }
      },
      icon: const Icon(Icons.add),
      label: const Text('Add prompt'),
    );
  }
}

class PromptList extends StatelessWidget {
  final SettingsViewModel vm;
  const PromptList({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: vm.prompts.isEmpty
          ? const Center(child: Text('No saved prompts'))
          : ListView.separated(
              itemCount: vm.prompts.length,
              separatorBuilder: (_, _) => const Divider(height: 8),
              itemBuilder: (context, idx) {
                final p = vm.prompts[idx];
                return ListTile(
                  title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                          final res = await showPromptEditorDialog(context, title: 'Edit prompt', initialName: p.name, initialText: p.text);
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
    );
  }
}
