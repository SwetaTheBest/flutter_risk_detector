import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_risk_detector/flutter_risk_detector.dart';

void main() {
  // ─── AsyncRiskAnalyzer ────────────────────────────────────────────────────
  group('AsyncRiskAnalyzer', () {
    test('isAsyncRisk false for empty string', () {
      expect(AsyncRiskAnalyzer.isAsyncRisk(''), isFalse);
    });

    test('isAsyncRisk false for unrelated error', () {
      expect(AsyncRiskAnalyzer.isAsyncRisk('NullPointerException'), isFalse);
    });

    test('classifies setState after dispose', () {
      const e = 'setState() called after dispose';
      expect(AsyncRiskAnalyzer.classify(e), AsyncRiskType.setStateAfterDispose);
      expect(AsyncRiskAnalyzer.isAsyncRisk(e), isTrue);
    });

    test('classifies future after dispose', () {
      expect(
        AsyncRiskAnalyzer.classify('Future completed after widget dispose'),
        AsyncRiskType.futureAfterDispose,
      );
    });

    test('returns unknown for unrecognised error', () {
      expect(AsyncRiskAnalyzer.classify('random crash'), AsyncRiskType.unknown);
    });

    test('suggestion contains Fix for every type', () {
      for (final type in AsyncRiskType.values) {
        final msg = AsyncRiskAnalyzer.suggestion(
          type == AsyncRiskType.setStateAfterDispose
              ? 'setState() called after dispose'
              : type == AsyncRiskType.futureAfterDispose
                  ? 'Future completed after widget dispose'
                  : null,
        );
        expect(msg, contains('Fix'));
      }
    });

    test('isDisposeError is backwards-compatible alias', () {
      expect(
        AsyncRiskAnalyzer.isDisposeError('setState() called after dispose'),
        isTrue,
      );
    });
  });

  // ─── OverflowAnalyzer ─────────────────────────────────────────────────────
  group('OverflowAnalyzer', () {
    test('isOverflow true for RenderFlex error', () {
      expect(
        OverflowAnalyzer.isOverflow(
            'A RenderFlex overflowed by 42 pixels on the right side.'),
        isTrue,
      );
    });

    test('isOverflow false for unrelated error', () {
      expect(OverflowAnalyzer.isOverflow('NullPointerException'), isFalse);
    });
  });

  // ─── OverflowResult ───────────────────────────────────────────────────────
  group('OverflowResult', () {
    const r = OverflowResult(
      widgetName: 'Row',
      fileName: 'lib/screens/home.dart',
      suggestion: 'Use Expanded',
      overflowDirection: 'right',
      overflowPixels: 42.5,
      line: 10,
      column: 5,
    );

    test('formattedMessage contains widget name', () {
      expect(r.formattedMessage, contains('Row'));
    });

    test('formattedMessage contains file:line:column', () {
      expect(r.formattedMessage, contains('lib/screens/home.dart:10:5'));
    });

    test('formattedMessage contains overflow pixels', () {
      expect(r.formattedMessage, contains('42.5px'));
    });

    test('formattedMessage contains direction', () {
      expect(r.formattedMessage, contains('right'));
    });

    test('equality works', () {
      const same = OverflowResult(
        widgetName: 'Row',
        fileName: 'lib/screens/home.dart',
        suggestion: 'Use Expanded',
        overflowDirection: 'right',
        overflowPixels: 42.5,
        line: 10,
        column: 5,
      );
      expect(r, equals(same));
    });

    test('different widgetName is not equal', () {
      const other = OverflowResult(
        widgetName: 'Column',
        fileName: 'lib/screens/home.dart',
        suggestion: 'Use Expanded',
      );
      expect(r, isNot(equals(other)));
    });

    test('minimal result omits parent and overflow sections', () {
      const m = OverflowResult(
        widgetName: 'Flex',
        fileName: 'lib/main.dart',
        suggestion: 'fix it',
      );
      expect(m.formattedMessage, isNot(contains('Parent Widget')));
      expect(m.formattedMessage, isNot(contains('px on')));
    });
  });

  // ─── RebuildAnalyzer ──────────────────────────────────────────────────────
  group('RebuildAnalyzer', () {
    setUp(() => RebuildAnalyzer.configure(10, 20));

    test('shouldReport false below threshold', () {
      expect(RebuildAnalyzer.shouldReport(5), isFalse);
    });

    test('shouldReport true above threshold', () {
      expect(RebuildAnalyzer.shouldReport(11), isTrue);
    });

    test('analyze returns non-empty causes and suggestions for high rate', () {
      final result = RebuildAnalyzer.analyze(
        tag: 'TestWidget',
        rebuildCount: 50,
        window: const Duration(seconds: 1),
      );
      expect(result.possibleCauses, isNotEmpty);
      expect(result.suggestions, isNotEmpty);
    });

    test('isStorm true when count exceeds stormThreshold', () {
      final result = RebuildAnalyzer.analyze(
        tag: 'StormWidget',
        rebuildCount: 25,
        window: const Duration(seconds: 5),
      );
      expect(result.isStorm, isTrue);
    });

    test('isStorm false when count below stormThreshold', () {
      final result = RebuildAnalyzer.analyze(
        tag: 'OkWidget',
        rebuildCount: 15,
        window: const Duration(seconds: 5),
      );
      expect(result.isStorm, isFalse);
    });

    test('configure changes thresholds', () {
      RebuildAnalyzer.configure(5, 10);
      expect(RebuildAnalyzer.shouldReport(6), isTrue);
      expect(RebuildAnalyzer.shouldReport(4), isFalse);
      RebuildAnalyzer.configure(10, 20);
    });

    test('zero-second window does not throw', () {
      expect(
        () => RebuildAnalyzer.analyze(
          tag: 'ZeroWindow',
          rebuildCount: 30,
          window: Duration.zero,
        ),
        returnsNormally,
      );
    });

    test('formattedMessage contains tag', () {
      final result = RebuildAnalyzer.analyze(
        tag: 'MyScreen',
        rebuildCount: 25,
        window: const Duration(seconds: 3),
      );
      expect(result.formattedMessage, contains('MyScreen'));
    });
  });

  // ─── RebuildResult ────────────────────────────────────────────────────────
  group('RebuildResult', () {
    test('equality based on tag, count, window', () {
      final a = RebuildResult(
        tag: 'A',
        rebuildCount: 10,
        window: const Duration(seconds: 2),
        possibleCauses: const [],
        suggestions: const [],
      );
      final b = RebuildResult(
        tag: 'A',
        rebuildCount: 10,
        window: const Duration(seconds: 2),
        possibleCauses: const ['x'],
        suggestions: const ['y'],
      );
      expect(a, equals(b));
    });

    test('rebuildsPerSecond computed correctly', () {
      final r = RebuildResult(
        tag: 'T',
        rebuildCount: 20,
        window: const Duration(seconds: 4),
        possibleCauses: const [],
        suggestions: const [],
      );
      expect(r.rebuildsPerSecond, closeTo(5.0, 0.01));
    });
  });

  // ─── LintIssue ────────────────────────────────────────────────────────────
  group('LintIssue', () {
    const issue = LintIssue(
      file: 'lib/main.dart',
      line: 5,
      rule: 'avoid_print',
      description: 'print() leaks',
      suggestion: 'use debugPrint',
      severity: LintSeverity.warning,
      offendingCode: '  print("hello");',
    );

    test('icon correct for each severity', () {
      expect(issue.icon, '\u26a0');
      expect(issue.copyWith(severity: LintSeverity.error).icon, '\u274c');
      expect(issue.copyWith(severity: LintSeverity.info).icon, '\u2139');
    });

    test('formattedMessage contains file and line', () {
      expect(issue.formattedMessage, contains('lib/main.dart:5'));
    });

    test('formattedMessage contains offending code', () {
      expect(issue.formattedMessage, contains('print("hello")'));
    });

    test('copyWith overrides only specified fields', () {
      final copy = issue.copyWith(line: 99);
      expect(copy.line, 99);
      expect(copy.rule, issue.rule);
      expect(copy.severity, issue.severity);
    });

    test('equality based on file, line, rule, severity', () {
      expect(issue, equals(issue.copyWith(description: 'different')));
    });

    test('different line is not equal', () {
      expect(issue, isNot(equals(issue.copyWith(line: 10))));
    });
  });

  // ─── LintResult ───────────────────────────────────────────────────────────
  group('LintResult', () {
    final issues = [
      const LintIssue(
        file: 'lib/a.dart',
        line: 3,
        rule: 'avoid_print',
        description: 'd',
        suggestion: 's',
        severity: LintSeverity.warning,
      ),
      const LintIssue(
        file: 'lib/a.dart',
        line: 1,
        rule: 'empty_catches',
        description: 'd',
        suggestion: 's',
        severity: LintSeverity.error,
      ),
      const LintIssue(
        file: 'lib/b.dart',
        line: 7,
        rule: 'todo_comment',
        description: 'd',
        suggestion: 's',
        severity: LintSeverity.info,
      ),
    ];

    late LintResult result;
    setUp(() => result = LintResult(issues));

    test('counts are correct', () {
      expect(result.errorCount, 1);
      expect(result.warningCount, 1);
      expect(result.infoCount, 1);
    });

    test('hasIssues true when issues present', () {
      expect(result.hasIssues, isTrue);
    });

    test('hasIssues false for empty result', () {
      expect(LintResult([]).hasIssues, isFalse);
    });

    test('byFile groups correctly', () {
      expect(result.byFile.keys, containsAll(['lib/a.dart', 'lib/b.dart']));
      expect(result.byFile['lib/a.dart']!.length, 2);
    });

    test('byFile sorts by line number', () {
      final a = result.byFile['lib/a.dart']!;
      expect(a.first.line, lessThan(a.last.line));
    });

    test('byFile is cached', () {
      expect(identical(result.byFile, result.byFile), isTrue);
    });

    test('filtered returns only errors', () {
      final f = result.filtered(LintSeverity.error);
      expect(f.errorCount, 1);
      expect(f.warningCount, 0);
      expect(f.infoCount, 0);
    });

    test('filtered returns warnings and above', () {
      expect(result.filtered(LintSeverity.warning).issues.length, 2);
    });

    test('formattedMessage for empty result', () {
      expect(LintResult([]).formattedMessage, contains('No lint issues'));
    });

    test('formattedMessage contains file names', () {
      expect(result.formattedMessage, contains('lib/a.dart'));
      expect(result.formattedMessage, contains('lib/b.dart'));
    });

    test('issues list is unmodifiable', () {
      expect(
        () => (result.issues as List).add(issues.first),
        throwsUnsupportedError,
      );
    });
  });

  // ─── LintAnalyzer ─────────────────────────────────────────────────────────
  group('LintAnalyzer', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('lint_test_');
    });

    tearDown(() async {
      if (tempDir.existsSync()) await tempDir.delete(recursive: true);
    });

    Future<List<LintIssue>> scan(String source) async {
      final file = File('${tempDir.path}/test.dart');
      await file.writeAsString(source);
      return LintAnalyzer.analyzeFile(file.path);
    }

    test('detects avoid_print', () async {
      final issues = await scan('void f() { print("hi"); }');
      expect(issues.any((i) => i.rule == 'avoid_print'), isTrue);
    });

    test('does not flag debugPrint', () async {
      final issues = await scan('void f() { debugPrint("hi"); }');
      expect(issues.any((i) => i.rule == 'avoid_print'), isFalse);
    });

    test('does not flag print in comment', () async {
      final issues = await scan('// print("hi");');
      expect(issues.any((i) => i.rule == 'avoid_print'), isFalse);
    });

    test('detects prefer_typed_declarations', () async {
      final issues = await scan('void f() {\n  var x = 1;\n}');
      expect(issues.any((i) => i.rule == 'prefer_typed_declarations'), isTrue);
    });

    test('detects avoid_hardcoded_colors', () async {
      final issues = await scan('final c = Color(0xFF123456);');
      expect(issues.any((i) => i.rule == 'avoid_hardcoded_colors'), isTrue);
    });

    test('detects todo_comment', () async {
      final issues = await scan('// TODO: fix this');
      expect(issues.any((i) => i.rule == 'todo_comment'), isTrue);
    });

    test('detects fixme_comment', () async {
      final issues = await scan('// FIXME: broken');
      expect(issues.any((i) => i.rule == 'todo_comment'), isTrue);
    });

    test('detects empty_catches', () async {
      final issues = await scan(
        'void f() {\n  try {\n  } catch (e) {\n  }\n}',
      );
      expect(issues.any((i) => i.rule == 'empty_catches'), isTrue);
    });

    test('detects missing_key_in_list', () async {
      final issues = await scan(
          'Widget b() => ListView.builder(itemBuilder: (_,i) => Text("x"));');
      expect(issues.any((i) => i.rule == 'missing_key_in_list'), isTrue);
    });

    test('detects sync_io readAsStringSync', () async {
      final issues = await scan('void f() { file.readAsStringSync(); }');
      expect(issues.any((i) => i.rule == 'sync_io_on_ui_thread'), isTrue);
    });

    test('detects sync_io jsonDecode', () async {
      final issues = await scan('void f() { jsonDecode(data); }');
      expect(issues.any((i) => i.rule == 'sync_io_on_ui_thread'), isTrue);
    });

    test('detects stream_subscription_leak', () async {
      final issues =
          await scan('class W {\n  StreamSubscription<int> _sub;\n}');
      expect(issues.any((i) => i.rule == 'stream_subscription_leak'), isTrue);
    });

    test('no stream_subscription_leak when cancel present', () async {
      final issues = await scan(
        'class W {\n  StreamSubscription<int> _sub;\n'
        '  void dispose() { _sub.cancel(); }\n}',
      );
      expect(issues.any((i) => i.rule == 'stream_subscription_leak'), isFalse);
    });

    test('detects timer_not_cancelled', () async {
      final issues = await scan(
        'class W {\n'
        '  void start() { Timer.periodic(Duration(seconds:1), (_){}); }\n'
        '}',
      );
      expect(issues.any((i) => i.rule == 'timer_not_cancelled'), isTrue);
    });

    test('no timer_not_cancelled when cancel present', () async {
      final issues = await scan(
        'class W {\n  late Timer _t;\n'
        '  void start() { _t = Timer(Duration(seconds:1), (){}); }\n'
        '  void dispose() { _t.cancel(); }\n}',
      );
      expect(issues.any((i) => i.rule == 'timer_not_cancelled'), isFalse);
    });

    test('detects controller_not_disposed', () async {
      final issues = await scan(
        'class W extends State {\n'
        '  TextEditingController _ctrl = TextEditingController();\n}',
      );
      expect(issues.any((i) => i.rule == 'controller_not_disposed'), isTrue);
    });

    test('no controller_not_disposed when dispose calls .dispose()', () async {
      final issues = await scan(
        'class W extends State {\n'
        '  TextEditingController _ctrl = TextEditingController();\n'
        '  void dispose() { _ctrl.dispose(); super.dispose(); }\n}',
      );
      expect(issues.any((i) => i.rule == 'controller_not_disposed'), isFalse);
    });

    test('returns empty for non-existent file', () async {
      expect(await LintAnalyzer.analyzeFile('/no/such/file.dart'), isEmpty);
    });

    test('analyzeDirectory empty for non-existent dir', () async {
      final r = await LintAnalyzer.analyzeDirectory('/no/such/dir');
      expect(r.hasIssues, isFalse);
    });

    test('analyzeDirectory scans multiple files', () async {
      await File('${tempDir.path}/a.dart')
          .writeAsString('void f() { print("a"); }');
      await File('${tempDir.path}/b.dart')
          .writeAsString('void g() { print("b"); }');
      final r = await LintAnalyzer.analyzeDirectory(tempDir.path);
      expect(r.warningCount, greaterThanOrEqualTo(2));
    });

    test('analyzeDirectory skips .g.dart files', () async {
      await File('${tempDir.path}/gen.g.dart')
          .writeAsString('void f() { print("x"); }');
      final r = await LintAnalyzer.analyzeDirectory(tempDir.path);
      expect(r.hasIssues, isFalse);
    });

    test('line numbers are 1-based', () async {
      final issues = await scan('void f() {\n  print("hi");\n}');
      final p = issues.firstWhere((i) => i.rule == 'avoid_print');
      expect(p.line, 2);
    });
  });

  // ─── RiskDetectorConfig ───────────────────────────────────────────────────
  group('RiskDetectorConfig', () {
    const d = RiskDetectorConfig();

    test('default values', () {
      expect(d.detectOverflows, isTrue);
      expect(d.detectAsyncRisks, isTrue);
      expect(d.detectRebuilds, isTrue);
      expect(d.detectLintIssues, isTrue);
      expect(d.rebuildWarningThreshold, 10);
      expect(d.rebuildStormThreshold, 20);
      expect(d.jankThresholdMs, 16);
    });

    test('copyWith overrides single field', () {
      final c = d.copyWith(detectOverflows: false);
      expect(c.detectOverflows, isFalse);
      expect(c.detectAsyncRisks, isTrue);
    });

    test('equality for identical configs', () {
      expect(d, equals(const RiskDetectorConfig()));
    });

    test('inequality when field differs', () {
      expect(d, isNot(equals(d.copyWith(jankThresholdMs: 32))));
    });

    test('hashCode is consistent', () {
      expect(d.hashCode, equals(const RiskDetectorConfig().hashCode));
    });
  });

  // ─── RiskLogger ───────────────────────────────────────────────────────────
  group('RiskLogger', () {
    setUp(() => RiskLogger.clear());

    test('buffer empty after clear', () {
      RiskLogger.log('test');
      RiskLogger.clear();
      expect(RiskLogger.logBuffer, isEmpty);
    });

    test('logBuffer is unmodifiable', () {
      expect(
        () => (RiskLogger.logBuffer as List).add('x'),
        throwsUnsupportedError,
      );
    });

    test('buffer does not exceed 200 entries', () {
      for (var i = 0; i < 250; i++) {
        RiskLogger.log('msg $i');
      }
      expect(RiskLogger.logBuffer.length, lessThanOrEqualTo(200));
    });
  });

  // ─── RiskLevel ────────────────────────────────────────────────────────────
  group('RiskLevel', () {
    test('each level has a non-empty icon', () {
      for (final level in RiskLevel.values) {
        expect(level.icon, isNotEmpty);
      }
    });

    test('icons are distinct', () {
      final icons = RiskLevel.values.map((l) => l.icon).toSet();
      expect(icons.length, RiskLevel.values.length);
    });
  });

  // ─── RiskResult ───────────────────────────────────────────────────────────
  group('RiskResult', () {
    final r = RiskResult(
      category: 'overflow',
      title: 'Row overflow',
      description: 'Row overflowed by 42px',
      suggestion: 'Use Expanded',
      level: RiskLevel.high,
      file: 'lib/home.dart',
      line: 12,
    );

    test('formattedMessage contains category', () {
      expect(r.formattedMessage, contains('overflow'));
    });

    test('formattedMessage contains file and line', () {
      expect(r.formattedMessage, contains('lib/home.dart:12'));
    });

    test('copyWith overrides level', () {
      final c = r.copyWith(level: RiskLevel.critical);
      expect(c.level, RiskLevel.critical);
      expect(c.title, r.title);
    });

    test('equality ignores description', () {
      expect(r, equals(r.copyWith(description: 'different')));
    });

    test('inequality when line differs', () {
      expect(r, isNot(equals(r.copyWith(line: 99))));
    });

    test('no @ symbol when file is null', () {
      final noFile = RiskResult(
        category: 'rebuild',
        title: 'storm',
        description: 'desc',
        suggestion: 'fix',
        level: RiskLevel.medium,
      );
      expect(noFile.formattedMessage, isNot(contains('@')));
    });
  });
}
