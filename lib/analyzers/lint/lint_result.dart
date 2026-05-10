import 'lint_issue.dart';

class LintResult {
  final List<LintIssue> issues;

  LintResult(this.issues);

  bool get hasIssues => issues.isNotEmpty;

  int get errorCount => issues.where((i) => i.severity == LintSeverity.error).length;
  int get warningCount => issues.where((i) => i.severity == LintSeverity.warning).length;
  int get infoCount => issues.where((i) => i.severity == LintSeverity.info).length;

  String get formattedMessage {
    if (!hasIssues) return '✅ No lint issues found.';

    final buffer = StringBuffer();
    buffer.writeln('🔍 LINT ANALYSIS REPORT');
    buffer.writeln('Errors: $errorCount  Warnings: $warningCount  Info: $infoCount');
    buffer.writeln('─' * 50);

    // Group by file
    final byFile = <String, List<LintIssue>>{};
    for (final issue in issues) {
      byFile.putIfAbsent(issue.file, () => []).add(issue);
    }

    for (final entry in byFile.entries) {
      buffer.writeln('\n📄 ${entry.key}');
      final sorted = entry.value..sort((a, b) => a.line.compareTo(b.line));
      for (final issue in sorted) {
        buffer.writeln(issue.formattedMessage);
      }
    }

    return buffer.toString();
  }
}
