import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

/// Lightweight Scroll Thumbs for the PdfViewer.
///
/// This is adapted from the pdfrx package implementation so the project
/// can render draggable scroll thumbs inside the `PdfViewer` overlay.
class ScrollThumbs extends StatefulWidget {
  const ScrollThumbs({super.key, required this.controller, this.orientation = ScrollbarOrientation.right, this.thumbSize, this.margin = 2.0, this.thumbBuilder});

  final PdfViewerController controller;
  final ScrollbarOrientation orientation;
  final Size? thumbSize;
  final double margin;
  final Widget? Function(BuildContext context, Size thumbSize, int? pageNumber, PdfViewerController controller)? thumbBuilder;

  bool get isVertical => orientation == ScrollbarOrientation.left || orientation == ScrollbarOrientation.right;

  @override
  State<ScrollThumbs> createState() => _ScrollThumbsState();
}

class _ScrollThumbsState extends State<ScrollThumbs> {
  double _panStartOffset = 0;

  @override
  Widget build(BuildContext context) {
    if (!widget.controller.isReady) return const SizedBox();
    return widget.isVertical ? _buildVertical(context) : _buildHorizontal(context);
  }

  Widget _buildVertical(BuildContext context) {
    final thumbSize = widget.thumbSize ?? const Size(25, 40);
    final view = widget.controller.visibleRect;
    final all = widget.controller.documentSize;
    if (all.height <= view.height) return const SizedBox();
    final y = -widget.controller.value.y / (all.height - view.height);
    final vh = view.height * widget.controller.currentZoom - thumbSize.height;
    final top = y * vh;
    return Positioned(
      left: widget.orientation == ScrollbarOrientation.left ? widget.margin : null,
      right: widget.orientation == ScrollbarOrientation.right ? widget.margin : null,
      top: top,
      width: thumbSize.width,
      height: thumbSize.height,
      child: GestureDetector(
        child: widget.thumbBuilder?.call(context, thumbSize, widget.controller.pageNumber, widget.controller) ??
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(127),
                    spreadRadius: 1,
                    blurRadius: 1,
                    offset: const Offset(1, 1),
                  ),
                ],
              ),
              child: Center(child: Text(widget.controller.pageNumber.toString(), style: const TextStyle(color: Colors.black))),
            ),
        onPanStart: (details) {
          _panStartOffset = top - details.localPosition.dy;
        },
        onPanUpdate: (details) {
          final y = (_panStartOffset + details.localPosition.dy) / vh;
          final m = widget.controller.value.clone();
          m.y = -y * (all.height - view.height);
          widget.controller.value = m;
        },
      ),
    );
  }

  Widget _buildHorizontal(BuildContext context) {
    final thumbSize = widget.thumbSize ?? const Size(40, 25);
    final view = widget.controller.visibleRect;
    final all = widget.controller.documentSize;
    if (all.width <= view.width) return const SizedBox();
    final x = -widget.controller.value.x / (all.width - view.width);
    final vw = view.width * widget.controller.currentZoom - thumbSize.width;
    final left = x * vw;
    return Positioned(
      top: widget.orientation == ScrollbarOrientation.top ? widget.margin : null,
      bottom: widget.orientation == ScrollbarOrientation.bottom ? widget.margin : null,
      left: left,
      width: thumbSize.width,
      height: thumbSize.height,
      child: GestureDetector(
        child: widget.thumbBuilder?.call(context, thumbSize, widget.controller.pageNumber, widget.controller) ??
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(127),
                    spreadRadius: 1,
                    blurRadius: 1,
                    offset: const Offset(1, 1),
                  ),
                ],
              ),
              child: Center(child: Text(widget.controller.pageNumber.toString())),
            ),
        onPanStart: (details) {
          _panStartOffset = left - details.localPosition.dx;
        },
        onPanUpdate: (details) {
          final x = (_panStartOffset + details.localPosition.dx) / vw;
          final m = widget.controller.value.clone();
          m.x = -x * (all.width - view.width);
          widget.controller.value = m;
        },
      ),
    );
  }
}
