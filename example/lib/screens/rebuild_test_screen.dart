import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_risk_detector/flutter_risk_detector.dart';

class RebuildTestScreen extends StatefulWidget {
  const RebuildTestScreen({super.key});

  @override
  State<RebuildTestScreen> createState() => _RebuildTestScreenState();
}

class _RebuildTestScreenState extends State<RebuildTestScreen> {
  int _counter = 0;
  bool _stormRunning = false;
  String _jankResult = '';

  // Triggers 30 rapid setState calls to simulate a rebuild storm
  Future<void> _triggerRebuildStorm() async {
    setState(() => _stormRunning = true);
    for (int i = 0; i < 30; i++) {
      await Future.delayed(const Duration(milliseconds: 16));
      if (!mounted) return;
      setState(() => _counter++);
    }
    if (!mounted) return;
    setState(() => _stormRunning = false);
  }

  // Blocks the UI thread with heavy synchronous work — causes jank
  void _triggerJank() {
    // Intentional: heavy sync computation on UI thread
    final result = _heavySyncWork();
    setState(() => _jankResult = 'Computed: $result');
  }

  int _heavySyncWork() {
    // Simulates expensive sync work (e.g. large JSON parse, image processing)
    var sum = 0;
    for (int i = 0; i < 50000000; i++) {
      sum += sqrt(i).toInt();
    }
    return sum;
  }

  @override
  Widget build(BuildContext context) {
    return RiskRebuildTracker(
      tag: 'RebuildTestScreen',
      child: Scaffold(
        appBar: AppBar(title: const Text('Rebuild Storm + Jank')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _InfoCard(
                color: Colors.blue.shade50,
                icon: Icons.refresh,
                title: 'Rebuild Storm Test',
                body: 'Fires 30 setState() calls at 60fps cadence. '
                    'Watch the console for 🔴 REBUILD STORM report with causes and suggestions.',
              ),
              const SizedBox(height: 12),
              Text('Rebuild counter: $_counter',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                icon: _stormRunning
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.bolt),
                label: Text(_stormRunning ? 'Storm running…' : 'Trigger Rebuild Storm'),
                onPressed: _stormRunning ? null : _triggerRebuildStorm,
              ),
              const Divider(height: 40),
              _InfoCard(
                color: Colors.orange.shade50,
                icon: Icons.slow_motion_video,
                title: 'Jank Test',
                body: 'Runs 50M iterations synchronously on the UI thread. '
                    'The frame timing callback in RiskRebuildTracker will log build duration > 16ms.',
              ),
              const SizedBox(height: 12),
              if (_jankResult.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(_jankResult,
                      style: const TextStyle(fontFamily: 'monospace')),
                ),
              ElevatedButton.icon(
                icon: const Icon(Icons.warning_amber),
                label: const Text('Trigger Jank (Heavy Sync Work)'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade700,
                    foregroundColor: Colors.white),
                onPressed: _triggerJank,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String body;

  const _InfoCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(body,
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
