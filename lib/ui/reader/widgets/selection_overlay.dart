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

    final spaceBelow = pageRect.height - localRect.bottom - gap;
    final spaceAbove = localRect.top - gap;

    // Choose whether to show the overlay below or above the selection.
    // Prefer below when there's enough space; otherwise show in the side
    // with more room. This avoids forcing the overlay to a large height
    // when the selection is near the page bottom.
    final showBelow = (spaceBelow >= spaceAbove) || (spaceBelow > 0);
    double maxHeightForOverlay = showBelow ? math.max(0.0, spaceBelow) : math.max(0.0, spaceAbove);
    // As a fallback ensure a small positive max height so the overlay can
    // render compact content even when space calculations are degenerate.
    if (maxHeightForOverlay <= 0) maxHeightForOverlay = math.min(pageRect.height, 200.0);

    final enforcedHeight = math.min(maxHeightForOverlay, pageRect.height);

    double top;
    if (showBelow) {
      top = localRect.bottom + gap;
      // Ensure the overlay fits; if not, clamp it to the top that lets it
      // fit within the page.
      if (top + enforcedHeight > pageRect.height) {
        top = math.max(0.0, pageRect.height - enforcedHeight);
      }
    } else {
      // Show above selection. Place the overlay so its bottom is gap above the selection.
      top = math.max(0.0, localRect.top - gap - enforcedHeight);
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
                minHeight: 0.0,
              ),
              child: Stack(
                children: [
                  // If there is no overlay text yet but a selection exists,
                  // show the prompt chooser. If a translation is in progress,
                  // show a loading indicator. Otherwise render the Markdown result.
                  if ((mdData).isEmpty && selectedText != null && selectedText.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 6.0, right: 6.0, bottom: 6.0, top: 28.0),
                      child: vm.isTranslating
                          ? IntrinsicWidth(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const SizedBox(height: 6.0),
                                  SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  ),
                                  const SizedBox(height: 6.0),
                                ],
                              ),
                            )
                          : SingleChildScrollView(
                              child: IntrinsicWidth(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: _buildPromptTiles(context, prompts, selectedText, vm),
                                ),
                              ),
                            ),
                    )
                  else
                    SingleChildScrollView(
                      child: IntrinsicWidth(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 6.0, right: 6.0, bottom: 6.0, top: 28.0),
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
    final widgets = <Widget>[];
    for (var i = 0; i < prompts.length; i++) {
      final p = prompts[i];
      final name = (p is Map) ? (p['name']?.toString() ?? '') : (p is PromptItem ? p.name : p.toString());
      final text = (p is Map) ? (p['text']?.toString() ?? '') : (p is PromptItem ? p.text : null);
      final tile = Padding(
        padding: const EdgeInsets.symmetric(vertical: 0.5),
        child: Material(
          color: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
          child: InkWell(
            borderRadius: BorderRadius.circular(2),
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
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
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
        ),
      );

      widgets.add(tile);
      if (i != prompts.length - 1) {
        widgets.add(const Padding(
          padding: EdgeInsets.symmetric(vertical: 0.0),
          child: Divider(color: Colors.white24, height: 1, thickness: 0.4),
        ));
      }
    }
    return widgets;
  }
}
