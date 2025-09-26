import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'dart:math' as math;

class SelectionOverlay extends StatelessWidget {
  final Rect pageRect;
  final Rect localRect;
  final String? overlayText;
  final double minHeight;
  final double largeBreakpoint;
  final double fixedLargeWidthFactor;
  final double gap;

  const SelectionOverlay({
    super.key,
    required this.pageRect,
    required this.localRect,
    required this.overlayText,
    this.minHeight = 120.0,
    this.largeBreakpoint = 1024.0,
    this.fixedLargeWidthFactor = 0.7,
    this.gap = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    final availableWidth = pageRect.width;
    final fixedLargeWidth = fixedLargeWidthFactor * availableWidth;
    final maxAllowedWidth = availableWidth < largeBreakpoint ? availableWidth : math.min(fixedLargeWidth, availableWidth);

    final selectionCenterX = localRect.left + localRect.width / 2.0;
    final alignmentX = ((selectionCenterX / pageRect.width) * 2.0) - 1.0;

    final spaceAbove = localRect.top;
    final spaceBelow = pageRect.height - localRect.bottom;
    final showBelow = spaceBelow >= spaceAbove;
    final availableSpace = showBelow ? spaceBelow : spaceAbove;

    // Only enforce minHeight when available space is less than minHeight.
    // Otherwise allow the overlay to size to its content (so small content
    // won't produce an unnecessarily large overlay).
    final enforceMin = availableSpace < minHeight;
    final effectiveHeight = math.min(availableSpace, pageRect.height);
    final enforcedHeight = enforceMin ? math.min(minHeight, pageRect.height) : effectiveHeight;

    double top = 0.0;
    if (showBelow) {
      top = localRect.bottom + gap;
      if (top + enforcedHeight > pageRect.height) {
        // Move up to fit; this may cause overlap with selection if enforcedHeight > availableSpace
        top = math.max(0.0, pageRect.height - enforcedHeight);
      }
    } else {
      top = localRect.top - gap - enforcedHeight;
      if (top < 0.0) top = 0.0;
    }

    // Pre-process markdown to detect optional leading direction marker and
    // strip it from the content before rendering.
    String mdData = overlayText ?? '';
    TextDirection mdDirection = TextDirection.rtl;
    final dirReg = RegExp(r'^\s*(?:<!--\s*dir\s*:\s*(rtl|ltr)\s*-->|:dir=(rtl|ltr)|\[dir=(rtl|ltr)\])', caseSensitive: false);
    final m = dirReg.firstMatch(mdData);
    if (m != null) {
      final d = (m.group(1) ?? m.group(2) ?? m.group(3) ?? '').toLowerCase();
      if (d == 'ltr') mdDirection = TextDirection.ltr;
      if (d == 'rtl') mdDirection = TextDirection.rtl;
      mdData = mdData.substring(m.end).trimLeft();
    }

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
            padding: const EdgeInsets.all(8),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxAllowedWidth,
                maxHeight: enforcedHeight,
                minHeight: enforceMin ? math.min(minHeight, enforcedHeight) : 0.0,
              ),
              child: SingleChildScrollView(
                child: IntrinsicWidth(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Directionality(
                      textDirection: mdDirection,
                      child: MarkdownBody(
                        data: mdData,
                        selectable: false,
                        styleSheet: MarkdownStyleSheet(
                          p: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                        shrinkWrap: true,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (showBelow) {
      return Positioned(
        left: 0,
        right: 0,
        top: top,
        child: overlayChild,
      );
    }

    final bottom = pageRect.height - localRect.top + gap;
    return Positioned(
      left: 0,
      right: 0,
      bottom: bottom,
      child: Align(
        alignment: Alignment(alignmentX.clamp(-1.0, 1.0), 1.0),
        child: overlayChild,
      ),
    );
  }
}
