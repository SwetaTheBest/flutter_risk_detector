class AsyncRiskAnalyzer {
  static bool isDisposeError(String error) {
    return error.contains('setState() called after dispose');
  }

  static String suggestion() {
    return '''
Async State Risk Detected

Possible Fixes:
- Check mounted before setState
- Cancel timers on dispose
- Dispose stream subscriptions
''';
  }
}
