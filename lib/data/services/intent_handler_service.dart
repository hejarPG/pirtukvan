import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../ui/reader/views/reader_page.dart';

/// Listens to Android MethodChannel messages from MainActivity when a file is opened
/// via the system "Open with" menu. When a file path is received it navigates to
/// the ReaderPage.
class IntentHandler {
  static const MethodChannel _channel = MethodChannel('pirtukvan/opened_file');
  static GlobalKey<NavigatorState>? _navigatorKey;

  static Future<void> init(GlobalKey<NavigatorState> navigatorKey) async {
    _navigatorKey = navigatorKey;

    // Set up incoming method call handler for any calls MainActivity invokes.
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onFileOpened') {
        final path = call.arguments as String?;
        if (path != null && path.isNotEmpty) {
          _openFileAtPath(path);
        }
      }
      return null;
    });

    // Try to get an initial value synchronously from the platform (optional)
    try {
      final result = await _channel.invokeMethod<String>('getInitialFile');
      if (result != null && result.isNotEmpty) {
        _openFileAtPath(result);
      }
    } catch (_) {}
  }

  static void _openFileAtPath(String path) {
    if (_navigatorKey == null) return;
    final nav = _navigatorKey!.currentState;
    if (nav == null) return;

    final file = File(path);
    if (!file.existsSync()) return;

    // Push ReaderPage
    nav.push(MaterialPageRoute(builder: (_) => ReaderPage(file: file)));
  }
}
