/// Configuration for runtime risk detection and optional static lint scanning.
///
/// All runtime detectors are debug-only. In release builds, error capture
/// returns before registering global error hooks.
class RiskDetectorConfig {
  /// Whether Flutter framework errors should be inspected for RenderFlex
  /// overflow diagnostics.
  final bool detectOverflows;

  /// Whether async-style Flutter errors should be classified and logged with
  /// targeted suggestions.
  final bool detectAsyncRisks;

  /// Whether rebuild and jank tracking should be enabled.
  final bool detectRebuilds;

  /// Whether startup initialization should run the lint scan.
  final bool detectLintIssues;

  /// Whether stale UI detection should be enabled.
  final bool enableUiUpdateDetection;

  /// Threshold in seconds used to evaluate whether a tracked state update should
  /// have produced a rebuild.
  final int uiUpdateThresholdSeconds;

  /// Directory scanned by the lint analyzer when [detectLintIssues] is true.
  ///
  /// Defaults to `lib` when omitted. Static lint scanning requires `dart:io`;
  /// on platforms without `dart:io`, the analyzer returns an empty result.
  final String? lintScanDirectory;

  /// Rebuild count before warnings start. Defaults to 10.
  final int rebuildWarningThreshold;

  /// Rebuild count before storm is declared. Defaults to 20.
  final int rebuildStormThreshold;

  /// Jank frame threshold in milliseconds. Defaults to 16ms (60fps).
  final int jankThresholdMs;

  /// Creates an immutable detector configuration.
  const RiskDetectorConfig({
    this.detectOverflows = true,
    this.detectAsyncRisks = true,
    this.detectRebuilds = true,
    this.detectLintIssues = true,
    this.enableUiUpdateDetection = true,
    this.uiUpdateThresholdSeconds = 2,
    this.lintScanDirectory,
    this.rebuildWarningThreshold = 10,
    this.rebuildStormThreshold = 20,
    this.jankThresholdMs = 16,
  });

  /// Returns a copy with selected fields replaced.
  RiskDetectorConfig copyWith({
    bool? detectOverflows,
    bool? detectAsyncRisks,
    bool? detectRebuilds,
    bool? detectLintIssues,
    bool? enableUiUpdateDetection,
    int? uiUpdateThresholdSeconds,
    String? lintScanDirectory,
    int? rebuildWarningThreshold,
    int? rebuildStormThreshold,
    int? jankThresholdMs,
  }) {
    return RiskDetectorConfig(
      detectOverflows: detectOverflows ?? this.detectOverflows,
      detectAsyncRisks: detectAsyncRisks ?? this.detectAsyncRisks,
      detectRebuilds: detectRebuilds ?? this.detectRebuilds,
      detectLintIssues: detectLintIssues ?? this.detectLintIssues,
      enableUiUpdateDetection:
          enableUiUpdateDetection ?? this.enableUiUpdateDetection,
      uiUpdateThresholdSeconds:
          uiUpdateThresholdSeconds ?? this.uiUpdateThresholdSeconds,
      lintScanDirectory: lintScanDirectory ?? this.lintScanDirectory,
      rebuildWarningThreshold:
          rebuildWarningThreshold ?? this.rebuildWarningThreshold,
      rebuildStormThreshold:
          rebuildStormThreshold ?? this.rebuildStormThreshold,
      jankThresholdMs: jankThresholdMs ?? this.jankThresholdMs,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is RiskDetectorConfig &&
      detectOverflows == other.detectOverflows &&
      detectAsyncRisks == other.detectAsyncRisks &&
      detectRebuilds == other.detectRebuilds &&
      detectLintIssues == other.detectLintIssues &&
      enableUiUpdateDetection == other.enableUiUpdateDetection &&
      uiUpdateThresholdSeconds == other.uiUpdateThresholdSeconds &&
      lintScanDirectory == other.lintScanDirectory &&
      rebuildWarningThreshold == other.rebuildWarningThreshold &&
      rebuildStormThreshold == other.rebuildStormThreshold &&
      jankThresholdMs == other.jankThresholdMs;

  @override
  int get hashCode => Object.hash(
        detectOverflows,
        detectAsyncRisks,
        detectRebuilds,
        detectLintIssues,
        enableUiUpdateDetection,
        uiUpdateThresholdSeconds,
        lintScanDirectory,
        rebuildWarningThreshold,
        rebuildStormThreshold,
        jankThresholdMs,
      );
}
