import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Simple service to store and retrieve last-opened PDF page using Hive.
class PdfPageStorageService {
  static const _boxName = 'pdf_last_page_box';

  /// Initialize Hive (call once at app startup)
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<int>(_boxName);
  }

  static Box<int> get _box => Hive.box<int>(_boxName);

  /// Compute a stable hash (sha1) for the given file. If file exists, hash
  /// its bytes; otherwise hash the path string.
  static Future<String> hashForFilePath(String path) async {
    final file = File(path);
    if (await file.exists()) {
      try {
        final bytes = await file.readAsBytes();
        final digest = sha1.convert(bytes);
        return digest.toString();
      } catch (_) {
        // fallback to path-based hash
      }
    }
    final digest = sha1.convert(Uint8List.fromList(path.codeUnits));
    return digest.toString();
  }

  /// Save last page (1-based page number) for a file path
  static Future<void> saveLastPage(String filePath, int pageNumber) async {
    final key = await hashForFilePath(filePath);
    try {
      await _box.put(key, pageNumber);
    } catch (_) {
      // ignore write errors
    }
  }

  /// Save last page for a precomputed key (avoid re-hashing file)
  static Future<void> saveLastPageForKey(String key, int pageNumber) async {
    try {
      await _box.put(key, pageNumber);
    } catch (_) {
      // ignore write errors
    }
  }

  /// Load last page for a file path, returns null if not found
  static Future<int?> loadLastPage(String filePath) async {
    final key = await hashForFilePath(filePath);
    try {
      final v = _box.get(key);
      return v;
    } catch (_) {
      return null;
    }
  }

  /// Load last page for a precomputed key (avoid re-hashing file)
  static Future<int?> loadLastPageForKey(String key) async {
    try {
      final v = _box.get(key);
      return v;
    } catch (_) {
      return null;
    }
  }

  /// Remove stored last page (optional)
  static Future<void> clearLastPage(String filePath) async {
    final key = await hashForFilePath(filePath);
    await _box.delete(key);
  }
}
