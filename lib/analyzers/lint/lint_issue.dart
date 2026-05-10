enum LintSeverity { info, warning, error }

class LintIssue {
  final String file;
  final int line;
  final String rule;
  final String description;
  final String suggestion;
  final LintSeverity severity;
  final String? offendingCode;

  LintIssue({
    required this.file,
    required this.line,
    required this.rule,
    required this.description,
    required this.suggestion,
    required this.severity,
    this.offendingCode,
  });

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
