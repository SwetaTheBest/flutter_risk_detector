import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

import '../analyzers/lint/lint_analyzer.dart';
import 'config.dart';
import 'detector.dart';
import 'logger.dart';

/// Installs debug-only Flutter error hooks and optional startup lint scanning.
///
/// Existing `FlutterError.onError` and `PlatformDispatcher.onError` handlers
/// are preserved and called after flutter_risk_detector records its diagnostic.
/// In release builds this class only applies the configuration and returns.
class ErrorCapture {
  static late RiskDetectorConfig _config;
  static bool _isInitialized = false;
  static FlutterExceptionHandler? _previousFlutterOnError;
  static ui.ErrorCallback? _previousPlatformOnError;

  /// Applies [config] and installs debug-only error handlers.
  ///
  /// Calling this more than once updates detector configuration. Global error
  /// handlers are installed only once to avoid stacking duplicate callbacks.
  static void initialize({
    RiskDetectorConfig config = const RiskDetectorConfig(),
  }) {
    _config = config;
    RiskDetector.configure(config);

    if (!kDebugMode) return;

    if (!_isInitialized) {
      _previousFlutterOnError = FlutterError.onError;
      _previousPlatformOnError = ui.PlatformDispatcher.instance.onError;

      FlutterError.onError = (FlutterErrorDetails details) {
        RiskDetector.analyzeFlutterError(details);
        final previousHandler = _previousFlutterOnError;
        if (previousHandler != null) {
          previousHandler(details);
        } else {
          FlutterError.presentError(details);
        }
      };

      ui.PlatformDispatcher.instance.onError = (error, stack) {
        RiskDetector.analyzeAsyncError(error);
        return _previousPlatformOnError?.call(error, stack) ?? false;
      };

      _isInitialized = true;
    }

    if (_config.detectLintIssues) {
      _runLintScan();
    }
  }

  static void _runLintScan() async {
    try {
      final dir = _config.lintScanDirectory ?? 'lib';
      final result = await LintAnalyzer.analyzeDirectory(dir);
      if (result.hasIssues) {
        RiskLogger.warning(result.formattedMessage);
      } else {
        RiskLogger.log(result.formattedMessage);
      }
    } on Object catch (error) {
      RiskLogger.error('Lint scan failed: $error');
    }
  }
}
