import 'package:flutter/foundation.dart';

import '../analyzers/async/async_risk_analyzer.dart';
import '../analyzers/overflow/overflow_analyzer.dart';
import 'config.dart';
import 'logger.dart';

class RiskDetector {
  static RiskDetectorConfig _config = const RiskDetectorConfig();

  static void configure(RiskDetectorConfig config) => _config = config;

  static void analyzeFlutterError(FlutterErrorDetails details) {
    final error = details.exceptionAsString();
    RiskLogger.error(error);

    if (_config.detectOverflows && OverflowAnalyzer.isOverflow(error)) {
      final result = OverflowAnalyzer.analyze(details);
      RiskLogger.warning(result.formattedMessage);
    }

    if (_config.detectAsyncRisks && AsyncRiskAnalyzer.isAsyncRisk(error)) {
      RiskLogger.warning(AsyncRiskAnalyzer.suggestion(error));
    }
  }

  static void analyzeAsyncError(Object error) {
    final errorString = error.toString();
    RiskLogger.error(errorString);

    if (_config.detectAsyncRisks && AsyncRiskAnalyzer.isAsyncRisk(errorString)) {
      RiskLogger.warning(AsyncRiskAnalyzer.suggestion(errorString));
    }
  }
}
