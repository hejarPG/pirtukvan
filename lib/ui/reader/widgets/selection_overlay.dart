import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import '../../../data/services/settings_service.dart';
import '../../../data/services/llm_service.dart';
import '../view_model/reader_selection_view_model.dart';

class SelectionOverlay extends StatelessWidget {
  final Rect pageRect;
  final Rect localRect;
  final String? overlayText;
  final double minHeight;
  final double minWidth;
  final double largeBreakpoint;
  final double fixedLargeWidthFactor;
  final double gap;
  final VoidCallback? onClose;
  final Future<bool> Function()? onCopySelectedText;

  const SelectionOverlay({
    super.key,
    required this.pageRect,
    required this.localRect,
    required this.overlayText,
    this.onClose,
    this.onCopySelectedText,
    this.minHeight = 120.0,
    this.minWidth = 80.0,
    this.largeBreakpoint = 1024.0,
    this.fixedLargeWidthFactor = 0.7,
    this.gap = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<ReaderSelectionViewModel>(context);
    final availableWidth = pageRect.width;
    final fixedLargeWidth = fixedLargeWidthFactor * availableWidth;
    final maxAllowedWidth = availableWidth < largeBreakpoint ? availableWidth : math.min(fixedLargeWidth, availableWidth);

    final selectionCenterX = localRect.left + localRect.width / 2.0;
    final alignmentX = ((selectionCenterX / pageRect.width) * 2.0) - 1.0;

    final spaceBelow = pageRect.height - localRect.bottom;
    // Always show the overlay below the selection. If there's not enough
    // space below, we will move the overlay up so it fits on the page.
    final availableSpace = spaceBelow;

    // Only enforce minHeight when available space is less than minHeight.
    // Otherwise allow the overlay to size to its content (so small content
    // won't produce an unnecessarily large overlay).
    final enforceMin = availableSpace < minHeight;
    final effectiveHeight = math.min(availableSpace, pageRect.height);
    final enforcedHeight = enforceMin ? math.min(minHeight, pageRect.height) : effectiveHeight;

    double top = localRect.bottom + gap;
    if (top + enforcedHeight > pageRect.height) {
      // Move up to fit; this may cause overlap with selection if enforcedHeight > availableSpace
      top = math.max(0.0, pageRect.height - enforcedHeight);
    }

    // Pre-process markdown to detect optional leading direction marker and
    // strip it from the content before rendering.
    String mdData = overlayText ?? '';
    final dirReg = RegExp(r'^\s*(?:<!--\s*dir\s*:\s*(rtl|ltr)\s*-->|:dir=(rtl|ltr)|\[dir=(rtl|ltr)\])', caseSensitive: false);
    final m = dirReg.firstMatch(mdData);
    if (m != null) {
      // We only strip any leading direction marker; rendering direction
      // is handled below by Directionality widgets already present in the
      // layout (overlay content uses RTL by default).
      mdData = mdData.substring(m.end).trimLeft();
    }

    // Access selected text and prompts from services/view model
    final selectedText = vm.selectedText;
    final prompts = SettingsService.getPrompts();

    final overlayChild = Align(
      alignment: Alignment(alignmentX.clamp(-1.0, 1.0), 0.0),
      child: Material(
        color: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Container(
            decoration: BoxDecoration(
              color: Color.fromARGB((0.95 * 255).round(), 0, 0, 0),
            ),
            // padding: const EdgeInsets.all(8),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxAllowedWidth,
                minWidth: math.min(minWidth, maxAllowedWidth),
                maxHeight: enforcedHeight,
                minHeight: enforceMin ? math.min(minHeight, enforcedHeight) : 0.0,
              ),
              child: Stack(
                children: [
                  // If there is no overlay text yet but a selection exists,
                  // show the prompt chooser. If a translation is in progress,
                  // show a loading indicator. Otherwise render the Markdown result.
                  if ((mdData).isEmpty && selectedText != null && selectedText.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0, top: 28.0),
                      child: vm.isTranslating
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24.0),
                              child: Center(
                                child: SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                ),
                              ),
                            )
                          : ListView(
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              children: _buildPromptTiles(context, prompts, selectedText, vm),
                            ),
                    )
                  else
                    SingleChildScrollView(
                      child: IntrinsicWidth(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0, top: 28.0),
                          child: Directionality(
                            textDirection: TextDirection.rtl,
                            child: MarkdownBody(
                              data: mdData,
                              selectable: false,
                              styleSheet: MarkdownStyleSheet(
                                p: TextStyle(
                                  color: Colors.white,
                                  fontSize: SettingsService.getOverlayFontSize(),
                                  fontFamily: 'Vazirmatn',
                                ),
                              ),
                              shrinkWrap: true,
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Close button in top-right corner of overlay
                  if (onClose != null)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: GestureDetector(
                        onTap: onClose,
                        child: const Icon(
                          Icons.close,
                          size: 18,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  // Copy button in top-left corner of overlay
                  if ((mdData).isNotEmpty)
                    Positioned(
                      left: 4,
                      top: 4,
                      child: GestureDetector(
                        onTap: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            await Clipboard.setData(ClipboardData(text: mdData));
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Copied to clipboard'),
                                duration: Duration(milliseconds: 800),
                              ),
                            );
                          } catch (_) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Unable to copy'),
                                duration: Duration(milliseconds: 800),
                              ),
                            );
                          }
                        },
                        child: const Icon(
                          Icons.copy,
                          size: 18,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  // Copy selected text button (uses viewer's selection delegate)
                  if (onCopySelectedText != null)
                    Positioned(
                      left: 28,
                      top: 4,
                      child: GestureDetector(
                        onTap: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            final ok = await onCopySelectedText!.call();
                            if (ok) {
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Selected text copied'),
                                  duration: Duration(milliseconds: 800),
                                ),
                              );
                            } else {
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Unable to copy selection'),
                                  duration: Duration(milliseconds: 800),
                                ),
                              );
                            }
                          } catch (_) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Unable to copy selection'),
                                duration: Duration(milliseconds: 800),
                              ),
                            );
                          }
                        },
                        child: const Icon(
                          Icons.text_snippet,
                          size: 18,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return Positioned(
      left: 0,
      right: 0,
      top: top,
      child: overlayChild,
    );
  }

  List<Widget> _buildPromptTiles(BuildContext context, List prompts, String selectedText, ReaderSelectionViewModel vm) {
    final llm = LlmService();
    return prompts.map<Widget>((p) {
      final name = (p is Map) ? (p['name']?.toString() ?? '') : (p is PromptItem ? p.name : p.toString());
      final text = (p is Map) ? (p['text']?.toString() ?? '') : (p is PromptItem ? p.text : null);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0),
        child: GestureDetector(
          onTap: vm.isTranslating || text == null
              ? null
              : () async {
                  // start translating using same flow as the FAB
                  vm.setTranslating(true);
                  final genId = vm.startGeneration();
                  final stream = llm.generateStream(selectedText, promptTemplate: text);
                  final buffer = StringBuffer();
                  try {
                    await for (final chunk in stream) {
                      if (!vm.isCurrentGeneration(genId)) break;
                      if (chunk.isNotEmpty) {
                        for (final rune in chunk.runes) {
                          if (!vm.isCurrentGeneration(genId)) break;
                          buffer.write(String.fromCharCode(rune));
                          vm.setOverlayText(buffer.toString());
                          await Future.delayed(const Duration(milliseconds: 1));
                        }
                      }
                    }
                  } catch (e) {
                    if (vm.isCurrentGeneration(genId)) vm.setOverlayText('');
                  } finally {
                    if (vm.isCurrentGeneration(genId)) vm.setTranslating(false);
                  }
                },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(3),
            ),
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
            child: Text(
              name,
              style: TextStyle(
                color: Colors.white,
                fontSize: (SettingsService.getOverlayFontSize() - 2.0).clamp(8.0, 100.0),
                fontFamily: 'Vazirmatn',
              ),
            ),
          ),
        ),
      );
    }).toList();
  }
}
