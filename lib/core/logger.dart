import 'package:flutter/foundation.dart';

class RiskLogger {
  static void log(String message) {
    debugPrint(message);
  }

  static void warning(String message) {
    debugPrint('⚠ $message');
  }

  static void error(String message) {
    debugPrint('❌ $message');
  }
}
