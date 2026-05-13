import 'dart:io';

import 'lint_issue.dart';
import 'lint_result.dart';

class LintAnalyzer {
  // All patterns compiled once — never inside loops
  static final _printRegex = RegExp(r'\bprint\s*\(');
  static final _constWidgetRegex = RegExp(
      r'(?<!const\s)\b(EdgeInsets|SizedBox|Padding|Text|Icon|Divider|Center|Align)\s*\(');
  static final _varRegex = RegExp(r'^\s*var\s+\w+\s*=');
  static final _hardcodedColorRegex = RegExp(r'Color\s*\(\s*0x');
  static final _hardcodedStringRegex = RegExp(r"\bText\s*\(\s*'[^']{3,}'");
  static final _catchRegex = RegExp(r'\}\s*catch\s*\(');
  static final _todoRegex =
      RegExp(r'//\s*(TODO|FIXME|HACK|XXX)', caseSensitive: false);
  static final _unawaitedCallRegex = RegExp(r'^\s{2,}[a-z]\w+\(.*\);\s*$');
  static final _unawaitedNameRegex =
      RegExp(r'(fetch|load|save|delete|update|post|get|upload|download)\w*\s*\(');
  static final _listBuilderRegex =
      RegExp(r'\b(ListView|GridView|PageView)\.builder\s*\(');
  static final _debugModeRegex = RegExp(r'\bkDebugMode\b|\bkReleaseMode\b');
  static final _asyncFuncRegex = RegExp(r'async\s*(\{|=>');
  static final _contextRegex = RegExp(r'\bcontext\b');
  static final _syncReadStringRegex = RegExp(r'\.readAsStringSync\(');
  static final _syncReadBytesRegex = RegExp(r'\.readAsBytesSync\(');
  static final _syncWriteRegex = RegExp(r'\.writeAsStringSync\(');
  static final _jsonDecodeRegex = RegExp(r'\bjsonDecode\s*\(');
  static final _jsonEncodeRegex = RegExp(r'\bjsonEncode\s*\(');
  static final _timerRegex = RegExp(r'Timer(\.|\s*\()');

  // Per-controller patterns — compiled once, not inside the nested loop
  static final _controllerDeclRegexes = <String, RegExp>{
    for (final c in [
      'AnimationController',
      'ScrollController',
      'TextEditingController',
      'FocusNode',
      'PageController',
      'TabController',
      'VideoPlayerController',
    ])
      c: RegExp('(late\\s+)?${c}[?]?\\s+(\\w+)'),
  };
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

    // Whole-file checks (need full source)
    final source = lines.join('\n');
    _checkControllerNotDisposed(lines, relativePath, issues);
    _checkStreamSubscriptionLeak(source, relativePath, issues, lines);
    _checkTimerLeak(source, relativePath, issues, lines);
    _checkSyncIoOnUiThread(lines, relativePath, issues);
    _checkBuildContextAcrossAsync(lines, relativePath, issues);

    return issues;
  }

  // ─── Individual rule checks ───────────────────────────────────────────────

  static void _checkPrintStatement(
      String line, int lineNum, String file, List<LintIssue> issues) {
    if (_printRegex.hasMatch(line) && !_isComment(line)) {
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
    if (_constWidgetRegex.hasMatch(line) && !line.contains('const') && !_isComment(line)) {
      final match = _constWidgetRegex.firstMatch(line)!;
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
    if (_varRegex.hasMatch(line) && !_isComment(line)) {
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
    if (_hardcodedColorRegex.hasMatch(line) && !_isComment(line)) {
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
    if (_hardcodedStringRegex.hasMatch(line) && !_isComment(line)) {
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
    if (_catchRegex.hasMatch(line) || line.trimLeft().startsWith('catch (')) {
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
    if (_todoRegex.hasMatch(line)) {
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
    if (_unawaitedCallRegex.hasMatch(line) &&
        !line.contains('await') &&
        !line.contains('return') &&
        !line.contains('=') &&
        !_isComment(line) &&
        _unawaitedNameRegex.hasMatch(line)) {
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
    if (_listBuilderRegex.hasMatch(line) && !_isComment(line)) {
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
    if (_debugModeRegex.hasMatch(line) && line.contains('if') && !_isComment(line)) {
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

  // ─── Memory leak checks ───────────────────────────────────────────────────

  /// Detects controllers declared as fields but not disposed.
  static void _checkControllerNotDisposed(
      List<String> lines, String file, List<LintIssue> issues) {
    final source = lines.join('\n');
    final hasDispose = source.contains('void dispose()');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (_isComment(line)) continue;

      for (final entry in _controllerDeclRegexes.entries) {
        final ctrl = entry.key;
        final regex = entry.value;
        final match = regex.firstMatch(line);
        if (match == null) continue;

        final ctrlName = match.group(2);
        final isDisposed = ctrlName != null &&
            hasDispose &&
            source.contains('$ctrlName.dispose()');

        if (!isDisposed) {
          issues.add(LintIssue(
            file: file,
            line: i + 1,
            rule: 'controller_not_disposed',
            description: '$ctrl declared but .dispose() not found — memory leak risk',
            suggestion:
                'Override dispose() and call ${ctrlName ?? 'controller'}.dispose()',
            severity: LintSeverity.error,
            offendingCode: line,
          ));
        }
      }
    }
  }

  /// Detects StreamSubscription fields without a cancel() call.
  static void _checkStreamSubscriptionLeak(
      String source, String file, List<LintIssue> issues, List<String> lines) {
    if (!source.contains('StreamSubscription')) return;
    final hasCancelInDispose = source.contains('cancel()');
    if (hasCancelInDispose) return;

    for (int i = 0; i < lines.length; i++) {
      if (lines[i].contains('StreamSubscription') && !_isComment(lines[i])) {
        issues.add(LintIssue(
          file: file,
          line: i + 1,
          rule: 'stream_subscription_leak',
          description: 'StreamSubscription declared but cancel() not found — memory leak',
          suggestion:
              'Store the subscription and call subscription.cancel() inside dispose()',
          severity: LintSeverity.error,
          offendingCode: lines[i],
        ));
        break; // one report per file is enough
      }
    }
  }

  /// Detects Timer.periodic without a cancel() call.
  static void _checkTimerLeak(
      String source, String file, List<LintIssue> issues, List<String> lines) {
    if (!source.contains('Timer.periodic') && !source.contains('Timer(')) return;
    if (source.contains('timer.cancel()') || source.contains('.cancel()')) return;

    for (int i = 0; i < lines.length; i++) {
      if (_timerRegex.hasMatch(lines[i]) && !_isComment(lines[i])) {
        issues.add(LintIssue(
          file: file,
          line: i + 1,
          rule: 'timer_not_cancelled',
          description: 'Timer created but cancel() not found — will fire after dispose',
          suggestion: 'Store the Timer and call timer.cancel() inside dispose()',
          severity: LintSeverity.error,
          offendingCode: lines[i],
        ));
        break;
      }
    }
  }

  // ─── Jank / performance checks ────────────────────────────────────────────

  /// Flags synchronous file/JSON operations that block the UI thread.
  static void _checkSyncIoOnUiThread(
      List<String> lines, String file, List<LintIssue> issues) {
    final syncPatterns = {
      _syncReadStringRegex: 'File.readAsStringSync() blocks the UI thread',
      _syncReadBytesRegex: 'File.readAsBytesSync() blocks the UI thread',
      _syncWriteRegex: 'File.writeAsStringSync() blocks the UI thread',
      _jsonDecodeRegex: 'jsonDecode() on large payloads can cause jank',
      _jsonEncodeRegex: 'jsonEncode() on large payloads can cause jank',
    };

    for (int i = 0; i < lines.length; i++) {
      if (_isComment(lines[i])) continue;
      for (final entry in syncPatterns.entries) {
        if (entry.key.hasMatch(lines[i])) {
          issues.add(LintIssue(
            file: file,
            line: i + 1,
            rule: 'sync_io_on_ui_thread',
            description: entry.value,
            suggestion:
                'Move to an isolate using compute() or use the async variant (readAsString, etc.)',
            severity: LintSeverity.warning,
            offendingCode: lines[i],
          ));
        }
      }
    }
  }

  /// Flags BuildContext used after an await gap (context across async).
  static void _checkBuildContextAcrossAsync(
      List<String> lines, String file, List<LintIssue> issues) {
    bool seenAwait = false;
    bool inAsyncFunction = false;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (_isComment(line)) continue;

      if (_asyncFuncRegex.hasMatch(line)) {
        inAsyncFunction = true;
        seenAwait = false;
      }
      if (line.contains('}') && inAsyncFunction) {
        inAsyncFunction = false;
        seenAwait = false;
      }
      if (inAsyncFunction && line.contains('await ')) seenAwait = true;

      if (seenAwait &&
          inAsyncFunction &&
          _contextRegex.hasMatch(line) &&
          !line.contains('mounted') &&
          !line.contains('if (') ) {
        issues.add(LintIssue(
          file: file,
          line: i + 1,
          rule: 'context_across_async',
          description: 'BuildContext used after await without mounted check',
          suggestion:
              'Add: if (!context.mounted) return; before using context after await',
          severity: LintSeverity.error,
          offendingCode: line,
        ));
      }
    }
  }
}
