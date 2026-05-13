import 'package:flutter/foundation.dart';

import '../analyzers/async/async_risk_analyzer.dart';
import '../analyzers/overflow/overflow_analyzer.dart';
import '../analyzers/rebuild/rebuild_analyzer.dart';
import 'config.dart';
import 'logger.dart';

class RiskDetector {
  static RiskDetectorConfig _config = const RiskDetectorConfig();

  static void configure(RiskDetectorConfig config) {
    _config = config;
    // Push thresholds into RebuildAnalyzer so the tracker widget picks them up
    RebuildAnalyzer.configure(
      config.rebuildWarningThreshold,
      config.rebuildStormThreshold,
    );
  }

  static void analyzeFlutterError(FlutterErrorDetails details) {
    if (!kDebugMode) return; // never run in release builds

    final error = details.exceptionAsString();

    if (_config.detectOverflows && OverflowAnalyzer.isOverflow(error)) {
      final result = OverflowAnalyzer.analyze(details);
      RiskLogger.warning(result.formattedMessage);
      return; // overflow identified — no need to check further
    }

    if (_config.detectAsyncRisks && AsyncRiskAnalyzer.isAsyncRisk(error)) {
      RiskLogger.warning(AsyncRiskAnalyzer.suggestion(error));
      return;
    }

    // Unknown Flutter error — log it once without duplication
    RiskLogger.error('Flutter error: $error');
  }

  static void analyzeAsyncError(Object error) {
    if (!kDebugMode) return;

    final errorString = error.toString();

    if (_config.detectAsyncRisks && AsyncRiskAnalyzer.isAsyncRisk(errorString)) {
      RiskLogger.warning(AsyncRiskAnalyzer.suggestion(errorString));
      return;
    }

    RiskLogger.error('Unhandled async error: $errorString');
  }
}
