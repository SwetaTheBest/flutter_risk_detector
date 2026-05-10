class RiskDetectorConfig {
  final bool detectOverflows;
  final bool detectAsyncRisks;
  final bool detectRebuilds;

  const RiskDetectorConfig({
    this.detectOverflows = true,
    this.detectAsyncRisks = true,
    this.detectRebuilds = true,
  });
}
