import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:provider/provider.dart';
import '../view_model/reader_selection_view_model.dart';
import 'scroll_thumbs.dart';

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
          // Add scroll thumbs on the right side
          ScrollThumbs(controller: _controller, orientation: ScrollbarOrientation.right),
        ],
        pageOverlaysBuilder: (context, pageRect, page) {
          // Render overlay when selection belongs to this page
          final widgets = <Widget>[];
          if (selectionVM.selectedPageNumber == page.pageNumber && selectionVM.selectedBounds != null && selectionVM.isOverlayVisible) {
            // Convert PdfRect (PDF page coords) to Flutter Rect in viewer coordinates
            final bounds = selectionVM.selectedBounds!;
            // toRectInDocument will map PDF coords to the provided pageRect
            // Use a page-local pageRect (origin at 0,0) so the conversion returns
            // coordinates relative to the page. This avoids offsets and keeps the
            // overlay scrolling in sync with the page.
            final pageLocalRect = Rect.fromLTWH(0, 0, pageRect.width, pageRect.height);
            final localRect = bounds.toRectInDocument(page: page, pageRect: pageLocalRect);

            // Debug logging to help diagnose offset/scroll mismatch
            assert(() {
              // only log in debug mode
              // ignore: avoid_print
              print('--- pdfrx overlay debug ---');
              // ignore: avoid_print
              print('pdf bounds: left=${bounds.left}, top=${bounds.top}, width=${bounds.width}, height=${bounds.height}, page=${selectionVM.selectedPageNumber}');
              // ignore: avoid_print
              print('pageRect (viewer): $pageRect');
              // ignore: avoid_print
              print('localRect (page-local): $localRect');
              return true;
            }());

            widgets.add(Positioned(
              left: localRect.left,
              top: localRect.top,
              width: localRect.width,
              height: localRect.height,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black87.withOpacity(0.85),
                  ),
                  constraints: const BoxConstraints(
                    maxWidth: 320,
                  ),
                  padding: const EdgeInsets.all(12),
                  child: AutoSizeText(
                    selectionVM.overlayText ?? '',
                    style: const TextStyle(color: Colors.white, fontSize: 200),
                    textAlign: TextAlign.right,
                    maxLines: 100,
                    // softWrap: true,
                  ),
                ),
              ),
            ));
          }
          return widgets;
        },
      ),
    );
  }
}
