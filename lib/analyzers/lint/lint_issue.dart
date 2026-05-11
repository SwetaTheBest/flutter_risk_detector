enum LintSeverity { info, warning, error }

class LintIssue {
  final String file;
  final int line;
  final String rule;
  final String description;
  final String suggestion;
  final LintSeverity severity;
  final String? offendingCode;

  const LintIssue({
    required this.file,
    required this.line,
    required this.rule,
    required this.description,
    required this.suggestion,
    required this.severity,
    this.offendingCode,
  });

  LintIssue copyWith({
    String? file,
    int? line,
    String? rule,
    String? description,
    String? suggestion,
    LintSeverity? severity,
    String? offendingCode,
  }) =>
      LintIssue(
        file: file ?? this.file,
        line: line ?? this.line,
        rule: rule ?? this.rule,
        description: description ?? this.description,
        suggestion: suggestion ?? this.suggestion,
        severity: severity ?? this.severity,
        offendingCode: offendingCode ?? this.offendingCode,
      );

  @override
  bool operator ==(Object other) =>
      other is LintIssue &&
      file == other.file &&
      line == other.line &&
      rule == other.rule &&
      severity == other.severity;

  @override
  int get hashCode => Object.hash(file, line, rule, severity);

  String get icon => switch (severity) {
        LintSeverity.error => '❌',
        LintSeverity.warning => '⚠',
        LintSeverity.info => 'ℹ',
      };

  String get formattedMessage {
    final code = offendingCode != null ? '\n  Code : ${offendingCode!.trim()}' : '';
    return '$icon [$rule] $file:$line$code\n  Issue: $description\n  Fix  : $suggestion';
  }
}
