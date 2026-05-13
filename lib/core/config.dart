class RiskDetectorConfig {
  final bool detectOverflows;
  final bool detectAsyncRisks;
  final bool detectRebuilds;
  final bool detectLintIssues;
  final String? lintScanDirectory;
  /// Rebuild count before warnings start. Defaults to 10.
  final int rebuildWarningThreshold;
  /// Rebuild count before storm is declared. Defaults to 20.
  final int rebuildStormThreshold;
  /// Jank frame threshold in milliseconds. Defaults to 16ms (60fps).
  final int jankThresholdMs;

  const RiskDetectorConfig({
    this.detectOverflows = true,
    this.detectAsyncRisks = true,
    this.detectRebuilds = true,
    this.detectLintIssues = true,
    this.lintScanDirectory,
    this.rebuildWarningThreshold = 10,
    this.rebuildStormThreshold = 20,
    this.jankThresholdMs = 16,
  });

  RiskDetectorConfig copyWith({
    bool? detectOverflows,
    bool? detectAsyncRisks,
    bool? detectRebuilds,
    bool? detectLintIssues,
    String? lintScanDirectory,
    int? rebuildWarningThreshold,
    int? rebuildStormThreshold,
    int? jankThresholdMs,
  }) =>
      RiskDetectorConfig(
        detectOverflows: detectOverflows ?? this.detectOverflows,
        detectAsyncRisks: detectAsyncRisks ?? this.detectAsyncRisks,
        detectRebuilds: detectRebuilds ?? this.detectRebuilds,
        detectLintIssues: detectLintIssues ?? this.detectLintIssues,
        lintScanDirectory: lintScanDirectory ?? this.lintScanDirectory,
        rebuildWarningThreshold:
            rebuildWarningThreshold ?? this.rebuildWarningThreshold,
        rebuildStormThreshold:
            rebuildStormThreshold ?? this.rebuildStormThreshold,
        jankThresholdMs: jankThresholdMs ?? this.jankThresholdMs,
      );

  @override
  bool operator ==(Object other) =>
      other is RiskDetectorConfig &&
      detectOverflows == other.detectOverflows &&
      detectAsyncRisks == other.detectAsyncRisks &&
      detectRebuilds == other.detectRebuilds &&
      detectLintIssues == other.detectLintIssues &&
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
        lintScanDirectory,
        rebuildWarningThreshold,
        rebuildStormThreshold,
        jankThresholdMs,
      );
}
