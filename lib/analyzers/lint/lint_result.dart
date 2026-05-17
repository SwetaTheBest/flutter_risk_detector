import 'lint_issue.dart';

class LintResult {
  final List<LintIssue> issues;
  final int errorCount;
  final int warningCount;
  final int infoCount;

  // Lazy cache for byFile — computed at most once
  Map<String, List<LintIssue>>? _byFileCache;

  LintResult(List<LintIssue> issues) : this._(List.unmodifiable(issues));

  LintResult._(this.issues)
      : errorCount = _count(issues, LintSeverity.error),
        warningCount = _count(issues, LintSeverity.warning),
        infoCount = _count(issues, LintSeverity.info);

  static int _count(List<LintIssue> list, LintSeverity s) {
    var n = 0;
    for (final i in list) {
      if (i.severity == s) n++;
    }
    return n;
  }

  bool get hasIssues => issues.isNotEmpty;

  /// Issues grouped by file, each list sorted by line number. Cached.
  Map<String, List<LintIssue>> get byFile {
    if (_byFileCache != null) return _byFileCache!;
    final map = <String, List<LintIssue>>{};
    for (final issue in issues) {
      map.putIfAbsent(issue.file, () => []).add(issue);
    }
    for (final list in map.values) {
      list.sort((a, b) => a.line.compareTo(b.line));
    }
    return _byFileCache = Map.unmodifiable(map);
  }

  /// Returns only issues at or above [minSeverity].
  LintResult filtered(LintSeverity minSeverity) {
    final minIndex = LintSeverity.values.indexOf(minSeverity);
    return LintResult(
      issues
          .where((i) => LintSeverity.values.indexOf(i.severity) >= minIndex)
          .toList(),
    );
  }

  String get formattedMessage {
    if (!hasIssues) return '\u2705 No lint issues found.';
    final buffer = StringBuffer();
    buffer.writeln('\ud83d\udd0d LINT ANALYSIS REPORT');
    buffer.writeln(
        'Errors: $errorCount  Warnings: $warningCount  Info: $infoCount');
    buffer.writeln('\u2500' * 50);
    for (final entry in byFile.entries) {
      buffer.writeln('\n\ud83d\udcc4 ${entry.key}');
      for (final issue in entry.value) {
        buffer.writeln(issue.formattedMessage);
      }
    }
    return buffer.toString();
  }
}
