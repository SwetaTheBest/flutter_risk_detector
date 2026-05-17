import 'dart:convert';

import 'package:flutter/material.dart';

/// This screen intentionally contains patterns caught by LintAnalyzer:
///   ⚠ [sync_io_on_ui_thread]   jsonDecode on UI thread
///   ❌ [context_across_async]   context used after await without mounted check
///   ⚠ [avoid_print]            print() call
///   ℹ [avoid_hardcoded_strings] Text() with plain string literal
class LintTestScreen extends StatefulWidget {
  const LintTestScreen({super.key});

  @override
  State<LintTestScreen> createState() => _LintTestScreenState();
}

class _LintTestScreenState extends State<LintTestScreen> {
  String _output = '';

  // ⚠ [sync_io_on_ui_thread]: jsonDecode called synchronously on UI thread
  void _triggerSyncJsonDecode() {
    final largeJson = jsonEncode(
      List.generate(
        10000,
        (i) => {'id': i, 'name': 'item_$i', 'value': i * 3.14},
      ),
    );
    // Intentional: synchronous decode on UI thread — can cause jank
    final decoded = jsonDecode(largeJson) as List;
    setState(
      () => _output =
          'Decoded ${decoded.length} items synchronously on UI thread',
    );
    // ⚠ [avoid_print]: print() instead of debugPrint()
    print('Decoded ${decoded.length} items'); // ignore: avoid_print
  }

  // ❌ [context_across_async]: context used after await without mounted check
  Future<void> _triggerContextAcrossAsync() async {
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return; // Safety check to prevent crash
    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Context used after await — should have mounted check!'),
      ),
    );
  }

  // ✅ Correct version with mounted check
  Future<void> _safeContextUsage() async {
    await Future.delayed(const Duration(seconds: 1));
    if (!context.mounted) return;
    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Safe: mounted check passed ✓')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lint Issues Demo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _LintTile(
            isRisk: true,
            rule: 'sync_io_on_ui_thread',
            severity: '⚠ Warning',
            description:
                'jsonDecode() called synchronously on the UI thread. '
                'On large payloads this blocks rendering and causes jank.',
            buttonLabel: 'Run jsonDecode on UI Thread',
            onPressed: _triggerSyncJsonDecode,
          ),
          if (_output.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.orange.shade50,
              child: Text(
                _output,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ],
          const SizedBox(height: 16),
          _LintTile(
            isRisk: true,
            rule: 'context_across_async',
            severity: '❌ Error',
            description:
                'BuildContext used after await without if (!context.mounted) check. '
                'If the widget is disposed before the Future completes, this crashes.',
            buttonLabel: 'Use context after await (no mounted check)',
            onPressed: _triggerContextAcrossAsync,
          ),
          const SizedBox(height: 16),
          _LintTile(
            isRisk: false,
            rule: 'context_across_async — fixed',
            severity: '✅ Safe',
            description:
                'Same async operation but guarded with if (!context.mounted) return. '
                'This is the correct pattern.',
            buttonLabel: 'Use context after await (with mounted check)',
            onPressed: _safeContextUsage,
          ),
          const SizedBox(height: 16),
          _LintTile(
            isRisk: true,
            rule: 'avoid_print',
            severity: '⚠ Warning',
            description:
                'print() is called inside _triggerSyncJsonDecode(). '
                'In release builds this leaks internal data to device logs.',
            buttonLabel: 'See print() in source (line 28)',
            onPressed: () => setState(
              () => _output =
                  'See line 28 in lint_test_screen.dart — print() call',
            ),
          ),
        ],
      ),
    );
  }
}

class _LintTile extends StatelessWidget {
  final bool isRisk;
  final String rule;
  final String severity;
  final String description;
  final String buttonLabel;
  final VoidCallback onPressed;

  const _LintTile({
    required this.isRisk,
    required this.rule,
    required this.severity,
    required this.description,
    required this.buttonLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isRisk ? Colors.red.shade50 : Colors.green.shade50;
    final border = isRisk ? Colors.red.shade200 : Colors.green.shade200;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            severity,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isRisk ? Colors.red.shade800 : Colors.green.shade800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '[$rule]',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 6),
          Text(description, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 10),
          ElevatedButton(onPressed: onPressed, child: Text(buttonLabel)),
        ],
      ),
    );
  }
}
