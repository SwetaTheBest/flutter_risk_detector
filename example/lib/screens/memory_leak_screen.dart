import 'package:flutter/material.dart';

/// This screen intentionally declares controllers without disposing them.
/// The LintAnalyzer scans this file at startup and reports:
///   ❌ [controller_not_disposed] AnimationController declared but .dispose() not found
///   ❌ [controller_not_disposed] TextEditingController declared but .dispose() not found
///   ❌ [controller_not_disposed] ScrollController declared but .dispose() not found
class MemoryLeakScreen extends StatefulWidget {
  const MemoryLeakScreen({super.key});

  @override
  State<MemoryLeakScreen> createState() => _MemoryLeakScreenState();
}

class _MemoryLeakScreenState extends State<MemoryLeakScreen>
    with SingleTickerProviderStateMixin {
  // ❌ Memory leak: AnimationController never disposed
  late AnimationController _animController;

  // ❌ Memory leak: TextEditingController never disposed
  final TextEditingController _textController = TextEditingController();

  // ❌ Memory leak: ScrollController never disposed (intentional demo)
  // ignore: unused_field
  final ScrollController _scrollController = ScrollController();

  // ✅ Correct: FocusNode that IS disposed
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  // Intentional: no dispose() override for _animController, _textController, _scrollController

  @override
  void dispose() {
    // Only _focusNode is correctly disposed — the others are leaking
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Memory Leak Demo')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _LeakRow(
              isLeaking: true,
              label: 'AnimationController',
              detail: 'Declared — dispose() NOT called',
            ),
            _LeakRow(
              isLeaking: true,
              label: 'TextEditingController',
              detail: 'Declared — dispose() NOT called',
            ),
            _LeakRow(
              isLeaking: true,
              label: 'ScrollController',
              detail: 'Declared — dispose() NOT called',
            ),
            _LeakRow(
              isLeaking: false,
              label: 'FocusNode',
              detail: 'Declared — dispose() IS called ✓',
            ),
            const Divider(height: 32),
            const Text(
              'The LintAnalyzer scans this file at app startup and reports '
              'the three leaking controllers in the debug console.\n\n'
              'Check console output for:\n'
              '  ❌ [controller_not_disposed]',
            ),
            const SizedBox(height: 24),
            // Show the animation to prove the controller is running
            AnimatedBuilder(
              animation: _animController,
              builder: (_, __) => LinearProgressIndicator(
                value: _animController.value,
                backgroundColor: Colors.grey.shade200,
                color: Colors.purple,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _textController,
              focusNode: _focusNode,
              decoration: const InputDecoration(
                labelText: 'TextEditingController (leaking)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeakRow extends StatelessWidget {
  final bool isLeaking;
  final String label;
  final String detail;

  const _LeakRow({
    required this.isLeaking,
    required this.label,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            isLeaking ? Icons.leak_add : Icons.check_circle,
            color: isLeaking ? Colors.red : Colors.green,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(detail,
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
