import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:provider/provider.dart';
import '../view_model/reader_selection_view_model.dart';

// This widget wraps a pdfrx PdfViewer and provides selection -> overlay
// wiring. It uses PdfViewerParams.viewerOverlayBuilder and
// pageOverlaysBuilder to render overlays anchored to the selected text.

class SelectablePdfViewer extends StatefulWidget {
  final String filePath;
  final void Function(String?)? onSelection;
  const SelectablePdfViewer({super.key, required this.filePath, this.onSelection});

  @override
  State<SelectablePdfViewer> createState() => _SelectablePdfViewerState();
}

class _SelectablePdfViewerState extends State<SelectablePdfViewer> {
  final _controller = PdfViewerController();
  // no need to keep lastRange field; selection bounds are stored in ViewModel
  @override
  Widget build(BuildContext context) {
    final selectionVM = Provider.of<ReaderSelectionViewModel>(context);

    return PdfViewer.file(
      widget.filePath,
      controller: _controller,
      params: PdfViewerParams(
        textSelectionParams: PdfTextSelectionParams(
          onTextSelectionChange: (selection) async {
            try {
              final selected = await selection.getSelectedText();
              if (widget.onSelection != null) widget.onSelection!(selected);
              // also compute selected bounds to position overlay
              final ranges = await selection.getSelectedTextRanges();
              if (ranges.isNotEmpty) {
                // take first range (could be multi-page; take first page)
                final r = ranges.first;
                // save to viewmodel in PDF page coordinates
                selectionVM.setSelectionBounds(r.pageNumber, r.bounds);
              } else {
                // cleared selection
                selectionVM.clearSelection();
              }
            } catch (e) {
              // ignore
            }
          },
        ),
        // viewer-level overlay: capture taps to rebuild overlays if needed
        viewerOverlayBuilder: (context, size, handleLinkTap) => [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                // tap on viewer should hide overlay
                selectionVM.setOverlayText(null);
              },
            ),
          ),
        ],
        pageOverlaysBuilder: (context, pageRect, page) {
          // Render overlay when selection belongs to this page
          final widgets = <Widget>[];
          if (selectionVM.selectedPageNumber == page.pageNumber && selectionVM.selectedBounds != null && selectionVM.isOverlayVisible) {
            // convert PDF page coords to view coords: pageRect is scaled/positioned rectangle
            final bounds = selectionVM.selectedBounds!;
            // bounds is PdfRect (pdf coords). To position inside pageRect we compute
            // left/top relative to pageRect using pageRect.width/height vs PDF page size.
            // pdfrx provides controller.currentZoom which already applied to pageRect.
            // We'll compute normalized position using page.pageSize (PdfPage.size)
            final pageSize = page.size;
            if (pageSize.width > 0 && pageSize.height > 0) {
              final dx = (bounds.left / pageSize.width) * pageRect.width;
              final dy = (bounds.top / pageSize.height) * pageRect.height;

              widgets.add(Positioned(
                left: pageRect.left + dx,
                top: pageRect.top + dy - 44 /* offset above selection */,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 240),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      selectionVM.overlayText ?? '',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ));
            }
          }
          return widgets;
        },
      ),
    );
  }
}
