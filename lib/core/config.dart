class RiskDetectorConfig {
  final bool detectOverflows;
  final bool detectAsyncRisks;
  final bool detectRebuilds;
  final bool detectLintIssues;
  final String? lintScanDirectory;

  const RiskDetectorConfig({
    this.detectOverflows = true,
    this.detectAsyncRisks = true,
    this.detectRebuilds = true,
    this.detectLintIssues = true,
    this.lintScanDirectory,
  });
}
