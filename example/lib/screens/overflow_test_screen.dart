import 'package:flutter/material.dart';
import 'package:flutter_risk_detector/flutter_risk_detector.dart';

class OverflowTestScreen extends StatefulWidget {
  const OverflowTestScreen({super.key});

  @override
  State<OverflowTestScreen> createState() => _OverflowTestScreenState();
}

class _OverflowTestScreenState extends State<OverflowTestScreen> {
  bool _showHorizontal = false;
  bool _showVertical = false;

  @override
  Widget build(BuildContext context) {
    return RiskRebuildTracker(
      tag: 'OverflowTestScreen',
      child: Scaffold(
        appBar: AppBar(title: const Text('Overflow Detection')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(
                icon: '↔',
                label: 'Horizontal Overflow',
                description:
                    'Triggers a Row with a fixed 800px child inside a bounded parent. '
                    'Watch the debug console for the overflow report.',
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow),
                label: const Text('Trigger Horizontal Overflow'),
                onPressed: () => setState(() => _showHorizontal = !_showHorizontal),
              ),
              if (_showHorizontal) ...[
                const SizedBox(height: 12),
                // Intentional overflow: Row with a fixed-width child wider than screen
                Row(
                  children: [
                    Container(
                      width: 800,
                      height: 60,
                      color: Colors.orange.shade300,
                      alignment: Alignment.center,
                      child: const Text('800px wide — overflows right →'),
                    ),
                  ],
                ),
              ],
              const Divider(height: 40),
              _SectionHeader(
                icon: '↕',
                label: 'Vertical Overflow',
                description:
                    'Triggers a Column inside a fixed-height box with too many children.',
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow),
                label: const Text('Trigger Vertical Overflow'),
                onPressed: () => setState(() => _showVertical = !_showVertical),
              ),
              if (_showVertical) ...[
                const SizedBox(height: 12),
                // Intentional overflow: Column inside a constrained box
                SizedBox(
                  height: 100,
                  child: Column(
                    children: List.generate(
                      8,
                      (i) => Container(
                        height: 40,
                        color: i.isEven ? Colors.red.shade200 : Colors.red.shade400,
                        alignment: Alignment.center,
                        child: Text('Item $i — overflows ↓'),
                      ),
                    ),
                  ),
                ),
              ],
              const Divider(height: 40),
              _SectionHeader(
                icon: '✅',
                label: 'Fixed Version',
                description: 'Same content wrapped correctly — no overflow.',
              ),
              const SizedBox(height: 8),
              // Correct: SingleChildScrollView + Expanded
              SizedBox(
                height: 120,
                child: SingleChildScrollView(
                  child: Column(
                    children: List.generate(
                      4,
                      (i) => Container(
                        height: 40,
                        color: Colors.green.shade200,
                        alignment: Alignment.center,
                        child: Text('Item $i — scrollable ✓'),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String icon;
  final String label;
  final String description;

  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$icon $label',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(description, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
