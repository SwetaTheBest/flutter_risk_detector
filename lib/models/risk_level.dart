enum RiskLevel { low, medium, high, critical }

extension RiskLevelX on RiskLevel {
  String get icon => switch (this) {
        RiskLevel.low => 'ℹ',
        RiskLevel.medium => '🟡',
        RiskLevel.high => '⚠',
        RiskLevel.critical => '🔴',
      };
}
