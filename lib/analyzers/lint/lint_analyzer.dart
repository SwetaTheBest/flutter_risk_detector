import 'dart:io';

import 'lint_issue.dart';
import 'lint_result.dart';

class LintAnalyzer {
  /// Scans all .dart files under [directory] and returns a [LintResult].
  static Future<LintResult> analyzeDirectory(String directory) async {
    final dir = Directory(directory);
    if (!dir.existsSync()) return LintResult([]);

    final issues = <LintIssue>[];
    final dartFiles = dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart') && !f.path.contains('.g.dart'));

    for (final file in dartFiles) {
      issues.addAll(await analyzeFile(file.path));
    }

    return LintResult(issues);
  }

  /// Scans a single file and returns all lint issues found.
  static Future<List<LintIssue>> analyzeFile(String filePath) async {
    final file = File(filePath);
    if (!file.existsSync()) return [];

    final lines = await file.readAsLines();
    final issues = <LintIssue>[];
    final relativePath = _relativePath(filePath);

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lineNum = i + 1;

      _checkPrintStatement(line, lineNum, relativePath, issues);
      _checkMissingConst(line, lineNum, relativePath, issues);
      _checkVarUsage(line, lineNum, relativePath, issues);
      _checkHardcodedColor(line, lineNum, relativePath, issues);
      _checkHardcodedString(line, lineNum, relativePath, issues);
      _checkEmptyCatch(line, lineNum, relativePath, issues, lines, i);
      _checkTodoComment(line, lineNum, relativePath, issues);
      _checkUnawaitedFuture(line, lineNum, relativePath, issues);
      _checkSetStateAfterAsync(line, lineNum, relativePath, issues, lines, i);
      _checkMissingKeyWidget(line, lineNum, relativePath, issues);
      _checkLongLine(line, lineNum, relativePath, issues);
      _checkTrailingWhitespace(line, lineNum, relativePath, issues);
      _checkDebugMode(line, lineNum, relativePath, issues);
    }

    return issues;
  }

  // ─── Individual rule checks ───────────────────────────────────────────────

  static void _checkPrintStatement(
      String line, int lineNum, String file, List<LintIssue> issues) {
    if (RegExp(r'\bprint\s*\(').hasMatch(line) && !_isComment(line)) {
      issues.add(LintIssue(
        file: file,
        line: lineNum,
        rule: 'avoid_print',
        description: 'print() leaks output in release builds',
        suggestion: 'Replace with debugPrint() or a proper logger',
        severity: LintSeverity.warning,
        offendingCode: line,
      ));
    }
  }

  static void _checkMissingConst(
      String line, int lineNum, String file, List<LintIssue> issues) {
    // Detects constructors like EdgeInsets/SizedBox/Padding without const
    final pattern = RegExp(
        r'(?<!const\s)\b(EdgeInsets|SizedBox|Padding|Text|Icon|Divider|Center|Align)\s*\(');
    if (pattern.hasMatch(line) && !line.contains('const') && !_isComment(line)) {
      final match = pattern.firstMatch(line)!;
      issues.add(LintIssue(
        file: file,
        line: lineNum,
        rule: 'prefer_const_constructors',
        description: '${match.group(1)} can be const but is not',
        suggestion: 'Add const before ${match.group(1)}(...)',
        severity: LintSeverity.info,
        offendingCode: line,
      ));
    }
  }

  static void _checkVarUsage(
      String line, int lineNum, String file, List<LintIssue> issues) {
    if (RegExp(r'^\s*var\s+\w+\s*=').hasMatch(line) && !_isComment(line)) {
      issues.add(LintIssue(
        file: file,
        line: lineNum,
        rule: 'prefer_typed_declarations',
        description: 'Avoid var — type is not explicit',
        suggestion: 'Replace var with the explicit type (e.g. String, int, List<...>)',
        severity: LintSeverity.info,
        offendingCode: line,
      ));
    }
  }

  static void _checkHardcodedColor(
      String line, int lineNum, String file, List<LintIssue> issues) {
    if (RegExp(r'Color\s*\(\s*0x').hasMatch(line) && !_isComment(line)) {
      issues.add(LintIssue(
        file: file,
        line: lineNum,
        rule: 'avoid_hardcoded_colors',
        description: 'Hardcoded Color() value found',
        suggestion: 'Define colors in a theme or constants file and reference them',
        severity: LintSeverity.warning,
        offendingCode: line,
      ));
    }
  }

  static void _checkHardcodedString(
      String line, int lineNum, String file, List<LintIssue> issues) {
    // Only flag Text('...') with a plain string literal
    if (RegExp(r"\bText\s*\(\s*'[^']{3,}'").hasMatch(line) && !_isComment(line)) {
      issues.add(LintIssue(
        file: file,
        line: lineNum,
        rule: 'avoid_hardcoded_strings',
        description: 'Hardcoded UI string in Text() widget',
        suggestion: 'Move to an l10n / constants file for localization support',
        severity: LintSeverity.info,
        offendingCode: line,
      ));
    }
  }

  static void _checkEmptyCatch(String line, int lineNum, String file,
      List<LintIssue> issues, List<String> lines, int index) {
    if (RegExp(r'\}\s*catch\s*\(').hasMatch(line) || line.trimLeft().startsWith('catch (')) {
      // Look ahead for an empty catch body
      final next = index + 1 < lines.length ? lines[index + 1].trim() : '';
      if (next == '}') {
        issues.add(LintIssue(
          file: file,
          line: lineNum,
          rule: 'empty_catches',
          description: 'Empty catch block silently swallows exceptions',
          suggestion: 'Log the error or rethrow: debugPrint(e.toString()) or rethrow',
          severity: LintSeverity.error,
          offendingCode: line,
        ));
      }
    }
  }

  static void _checkTodoComment(
      String line, int lineNum, String file, List<LintIssue> issues) {
    if (RegExp(r'//\s*(TODO|FIXME|HACK|XXX)', caseSensitive: false).hasMatch(line)) {
      issues.add(LintIssue(
        file: file,
        line: lineNum,
        rule: 'todo_comment',
        description: 'Unresolved TODO/FIXME comment',
        suggestion: 'Resolve or track this in your issue tracker before release',
        severity: LintSeverity.info,
        offendingCode: line,
      ));
    }
  }

  static void _checkUnawaitedFuture(
      String line, int lineNum, String file, List<LintIssue> issues) {
    // Detects Future-returning calls not preceded by await/return/=
    if (RegExp(r'^\s{2,}[a-z]\w+\(.*\);\s*$').hasMatch(line) &&
        !line.contains('await') &&
        !line.contains('return') &&
        !line.contains('=') &&
        !_isComment(line) &&
        RegExp(r'(fetch|load|save|delete|update|post|get|upload|download)\w*\s*\(')
            .hasMatch(line)) {
      issues.add(LintIssue(
        file: file,
        line: lineNum,
        rule: 'unawaited_futures',
        description: 'Possible unawaited Future — errors will be silently ignored',
        suggestion: 'Add await, or wrap with unawaited() if intentional',
        severity: LintSeverity.warning,
        offendingCode: line,
      ));
    }
  }

  static void _checkSetStateAfterAsync(String line, int lineNum, String file,
      List<LintIssue> issues, List<String> lines, int index) {
    if (line.contains('setState(') && !_isComment(line)) {
      // Check if any prior line in the same function has await
      final start = (index - 10).clamp(0, index);
      final context = lines.sublist(start, index).join('\n');
      if (context.contains('await') && !context.contains('if (mounted)')) {
        issues.add(LintIssue(
          file: file,
          line: lineNum,
          rule: 'setState_after_async',
          description: 'setState() called after async gap without mounted check',
          suggestion: 'Guard with: if (!mounted) return; before setState()',
          severity: LintSeverity.error,
          offendingCode: line,
        ));
      }
    }
  }

  static void _checkMissingKeyWidget(
      String line, int lineNum, String file, List<LintIssue> issues) {
    if (RegExp(r'\b(ListView|GridView|PageView)\.builder\s*\(').hasMatch(line) &&
        !_isComment(line)) {
      // Look ahead 5 lines for itemBuilder key usage
      issues.add(LintIssue(
        file: file,
        line: lineNum,
        rule: 'missing_key_in_list',
        description: 'List builder detected — items may be missing keys',
        suggestion:
            'Provide a Key to each list item widget to help Flutter reconcile the tree efficiently',
        severity: LintSeverity.info,
        offendingCode: line,
      ));
    }
  }

  static void _checkLongLine(
      String line, int lineNum, String file, List<LintIssue> issues) {
    if (line.length > 120 && !_isComment(line)) {
      issues.add(LintIssue(
        file: file,
        line: lineNum,
        rule: 'lines_longer_than_120_chars',
        description: 'Line is ${line.length} characters (limit: 120)',
        suggestion: 'Break into multiple lines for readability',
        severity: LintSeverity.info,
      ));
    }
  }

  static void _checkTrailingWhitespace(
      String line, int lineNum, String file, List<LintIssue> issues) {
    if (line.endsWith(' ') || line.endsWith('\t')) {
      issues.add(LintIssue(
        file: file,
        line: lineNum,
        rule: 'trailing_whitespace',
        description: 'Line has trailing whitespace',
        suggestion: 'Run dart format or enable format-on-save in your IDE',
        severity: LintSeverity.info,
      ));
    }
  }

  static void _checkDebugMode(
      String line, int lineNum, String file, List<LintIssue> issues) {
    if (RegExp(r'\bkDebugMode\b|\bkReleaseMode\b').hasMatch(line) &&
        line.contains('if') &&
        !_isComment(line)) {
      // Not an error, but flag if debug-only code might leak
      if (line.contains('kDebugMode') && line.contains('!')) {
        issues.add(LintIssue(
          file: file,
          line: lineNum,
          rule: 'debug_code_in_release',
          description: 'Negated kDebugMode check — code runs in release',
          suggestion: 'Verify this is intentional; prefer kReleaseMode for release-only logic',
          severity: LintSeverity.warning,
          offendingCode: line,
        ));
      }
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  static bool _isComment(String line) => line.trimLeft().startsWith('//');

  static String _relativePath(String path) {
    final normalized = path.replaceAll('\\', '/');
    final libIndex = normalized.indexOf('lib/');
    return libIndex != -1 ? normalized.substring(libIndex) : normalized.split('/').last;
  }
}
