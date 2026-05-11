enum AsyncRiskType {
  setStateAfterDispose,
  streamNotCancelled,
  timerNotCancelled,
  futureAfterDispose,
  unknown,
}

class AsyncRiskAnalyzer {
  static bool isAsyncRisk(String error) {
    return _classify(error) != AsyncRiskType.unknown;
  }

  // Keep old name so RiskDetector compiles without changes
  static bool isDisposeError(String error) => isAsyncRisk(error);

  static AsyncRiskType _classify(String error) {
    if (error.contains('setState() called after dispose')) {
      return AsyncRiskType.setStateAfterDispose;
    }
    if (error.contains('StreamSubscription') && error.contains('cancel')) {
      return AsyncRiskType.streamNotCancelled;
    }
    if (error.contains('Timer') && error.contains('cancel')) {
      return AsyncRiskType.timerNotCancelled;
    }
    if (error.contains('Future') && error.contains('dispose')) {
      return AsyncRiskType.futureAfterDispose;
    }
    return AsyncRiskType.unknown;
  }

  static String suggestion([String? error]) {
    final type = error != null ? _classify(error) : AsyncRiskType.unknown;
    return switch (type) {
      AsyncRiskType.setStateAfterDispose => '''
⚠ ASYNC RISK: setState() after dispose
  Cause : An async callback called setState() after the widget was removed.
  Fix   : Guard every setState() with:  if (!mounted) return;
  Fix   : Cancel Futures/Timers in dispose() to prevent late callbacks.
''',
      AsyncRiskType.streamNotCancelled => '''
⚠ ASYNC RISK: StreamSubscription not cancelled
  Cause : A StreamSubscription is still active after the widget disposed.
  Fix   : Store the subscription and call subscription.cancel() in dispose().
  Fix   : Use StreamBuilder so Flutter manages the lifecycle automatically.
''',
      AsyncRiskType.timerNotCancelled => '''
⚠ ASYNC RISK: Timer not cancelled
  Cause : A Timer or Timer.periodic is firing after the widget was disposed.
  Fix   : Store the Timer and call timer.cancel() in dispose().
''',
      AsyncRiskType.futureAfterDispose => '''
⚠ ASYNC RISK: Future completed after dispose
  Cause : A Future's .then() / await continuation ran after widget disposal.
  Fix   : Check mounted before using context or calling setState() in async code.
''',
      AsyncRiskType.unknown => '''
⚠ ASYNC RISK detected
  Fix   : Check mounted before setState()
  Fix   : Cancel timers and stream subscriptions in dispose()
  Fix   : Avoid storing BuildContext across async gaps
''',
    };
  }
}
