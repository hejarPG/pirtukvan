import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:provider/provider.dart';
import '../view_model/reader_selection_view_model.dart';
import 'scroll_thumbs.dart';
import '../../../data/services/pdf_page_storage_service.dart';

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

class _SelectablePdfViewerState extends State<SelectablePdfViewer> with WidgetsBindingObserver {
  final _controller = PdfViewerController();
  String? _fileKey;
  int? _lastSeenPage;
  // no need to keep lastRange field; selection bounds are stored in ViewModel
  @override
  void initState() {
    super.initState();
    // compute and cache the file key (hash) once
    () async {
      try {
        _fileKey = await PdfPageStorageService.hashForFilePath(widget.filePath);
      } catch (_) {
        _fileKey = null;
      }
      // if there is a saved page for this key, we don't navigate here because
      // navigation must be done when the viewer reports ready (onViewerReady).
    }();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Persist last seen page when the widget is disposed (viewer closed)
    if (_lastSeenPage != null) {
      if (_fileKey != null) {
        PdfPageStorageService.saveLastPageForKey(_fileKey!, _lastSeenPage!);
      } else {
        PdfPageStorageService.saveLastPage(widget.filePath, _lastSeenPage!);
      }
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Save when app goes to background/paused/inactive so the last seen page is preserved
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached || state == AppLifecycleState.inactive) {
      if (_lastSeenPage != null) {
        if (_fileKey != null) {
          PdfPageStorageService.saveLastPageForKey(_fileKey!, _lastSeenPage!);
        } else {
          PdfPageStorageService.saveLastPage(widget.filePath, _lastSeenPage!);
        }
      }
    }
    super.didChangeAppLifecycleState(state);
  }

  Widget build(BuildContext context) {
    final selectionVM = Provider.of<ReaderSelectionViewModel>(context);

    return PdfViewer.file(
      widget.filePath,
      controller: _controller,
      params: PdfViewerParams(
        // When the viewer notifies a page change, persist it.
        onPageChanged: (page) async {
          if (page != null) {
            // Cache last seen page (1-based page number). Persist only on dispose or lifecycle pause.
            _lastSeenPage = page;
          }
        },
        // When the viewer is ready, try to restore the last saved page
        onViewerReady: (document, controller) async {
          final saved = (_fileKey != null)
              ? await PdfPageStorageService.loadLastPageForKey(_fileKey!)
              : await PdfPageStorageService.loadLastPage(widget.filePath);
          if (saved != null) {
            try {
              // Ensure page number is within bounds
              final pageToGo = saved.clamp(1, document.pages.length);
              await controller.goToPage(pageNumber: pageToGo);
            } catch (_) {
              // ignore navigation errors
            }
          }
        },
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
              onTap: () async {
                try {
                  await _controller.textSelectionDelegate.clearTextSelection();
                } catch (_) {
                  // ignore: no-op
                }
                selectionVM.clearSelection();
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
                  // padding: const EdgeInsets.all(12),
                  child: AutoSizeText(
                    selectionVM.overlayText ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 400,
                      fontFamily: 'Vazirmatn',
                    ),
                    textAlign: TextAlign.justify,
                    textDirection: TextDirection.rtl,
                    maxLines: 100,
                    minFontSize: 5,
                    softWrap: true,
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
