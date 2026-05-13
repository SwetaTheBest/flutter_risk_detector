import 'package:flutter/foundation.dart';

class RiskLogger {
  static const int _maxBuffer = 200;
  static const Duration _throttle = Duration(seconds: 2);

  static final List<String> _buffer = [];
  static final Map<String, DateTime> _lastSeen = {};

  static List<String> get logBuffer => List.unmodifiable(_buffer);

  /// Logs an informational message. Not throttled — use for one-off events.
  static void log(String message) {
    if (!kDebugMode) return;
    _record(message);
    debugPrint(message);
  }

  /// Logs a warning. Throttled to avoid flooding on repeated events.
  static void warning(String message) {
    if (!kDebugMode) return;
    if (_isThrottled(message)) return;
    _record('⚠ $message');
    debugPrint('⚠ $message');
  }

  /// Logs an error. Throttled to avoid flooding on repeated events.
  static void error(String message) {
    if (!kDebugMode) return;
    if (_isThrottled(message)) return;
    _record('❌ $message');
    debugPrint('❌ $message');
  }

  static void clear() {
    _buffer.clear();
    _lastSeen.clear();
  }

  static bool _isThrottled(String message) {
    if (_lastSeen.length > 500) {
      final cutoff = DateTime.now().subtract(_throttle * 10);
      _lastSeen.removeWhere((_, t) => t.isBefore(cutoff));
    }
    final key = message.length > 60 ? message.substring(0, 60) : message;
    final last = _lastSeen[key];
    if (last != null && DateTime.now().difference(last) < _throttle) return true;
    _lastSeen[key] = DateTime.now();
    return false;
  }

  static void _record(String message) {
    if (_buffer.length >= _maxBuffer) _buffer.removeAt(0);
    _buffer.add('[${DateTime.now().toIso8601String()}] $message');
  }
}
