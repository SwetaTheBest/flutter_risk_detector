import 'package:flutter/foundation.dart';

import '../analyzers/async/async_risk_analyzer.dart';
import '../analyzers/overflow/overflow_analyzer.dart';
import 'logger.dart';

class RiskDetector {
  static void analyzeFlutterError(FlutterErrorDetails details) {
    final error = details.exceptionAsString();

    RiskLogger.error(error);

    if (OverflowAnalyzer.isOverflow(error)) {
      final result = OverflowAnalyzer.analyze(details);

      RiskLogger.warning(result.formattedMessage);
    }

    if (AsyncRiskAnalyzer.isDisposeError(error)) {
      RiskLogger.warning(AsyncRiskAnalyzer.suggestion());
    }
  }

  static void analyzeAsyncError(Object error) {
    final errorString = error.toString();

    RiskLogger.error(errorString);

    if (AsyncRiskAnalyzer.isDisposeError(errorString)) {
      RiskLogger.warning(AsyncRiskAnalyzer.suggestion());
    }
  }
}
