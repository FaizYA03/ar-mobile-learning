import 'package:flutter/foundation.dart';

class ArDebugLog {
  static const bool _enabled = kDebugMode;
  static const int _maxEntries = 200;
  static final List<String> _buffer = [];

  static void log(String message) {
    if (!_enabled) return;
    final entry = '[AR] $message';
    debugPrint(entry);
    _buffer.add(entry);
    if (_buffer.length > _maxEntries) {
      _buffer.removeRange(0, _buffer.length - _maxEntries);
    }
  }

  static void error(String message) {
    if (!_enabled) return;
    final entry = '[AR][ERROR] $message';
    debugPrint(entry);
    _buffer.add(entry);
    if (_buffer.length > _maxEntries) {
      _buffer.removeRange(0, _buffer.length - _maxEntries);
    }
  }

  static List<String> get entries => List.unmodifiable(_buffer);

  static void clear() {
    _buffer.clear();
  }
}
