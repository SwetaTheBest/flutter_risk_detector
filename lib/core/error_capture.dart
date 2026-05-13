import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

import '../analyzers/lint/lint_analyzer.dart';
import 'config.dart';
import 'detector.dart';
import 'logger.dart';

class ErrorCapture {
  static late RiskDetectorConfig _config;

  static void initialize({
    RiskDetectorConfig config = const RiskDetectorConfig(),
  }) {
    _config = config;
    RiskDetector.configure(config);

    FlutterError.onError = (FlutterErrorDetails details) {
      RiskDetector.analyzeFlutterError(details);
    };

    ui.PlatformDispatcher.instance.onError = (error, stack) {
      RiskDetector.analyzeAsyncError(error);
      return true;
    };

    if (_config.detectLintIssues) {
      _runLintScan();
    }
  }

  static void _runLintScan() async {
    final dir = _config.lintScanDirectory ?? 'lib';
    final result = await LintAnalyzer.analyzeDirectory(dir);
    if (result.hasIssues) {
      RiskLogger.warning(result.formattedMessage);
    } else {
      RiskLogger.log(result.formattedMessage);
    }
  }
}