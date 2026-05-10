import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

import 'config.dart';
import 'detector.dart';

class ErrorCapture {
  static late RiskDetectorConfig _config;

  static void initialize({
    RiskDetectorConfig config =
    const RiskDetectorConfig(),
  }) {
    _config = config;

    FlutterError.onError = (
        FlutterErrorDetails details,
        ) {
      RiskDetector.analyzeFlutterError(
        details,
      );
    };

    ui.PlatformDispatcher.instance.onError = (
        error,
        stack,
        ) {
      RiskDetector.analyzeAsyncError(
        error,
      );

      return true;
    };
  }
}