import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_risk_detector/flutter_risk_detector.dart';

class StaleUiTestScreen extends StatefulWidget {
  const StaleUiTestScreen({super.key});

  @override
  State<StaleUiTestScreen> createState() => _StaleUiTestScreenState();
}

class _StaleUiTestScreenState extends State<StaleUiTestScreen> {
  late final TrackedState<int> _counterState;
  late final ValueNotifier<int> _displayValueNotifier;
  late final ValueNotifier<int> _actualValueNotifier;

  @override
  void initState() {
    super.initState();
    _counterState = TrackedState<int>(
      0,
      tag: 'StaleUIExample',
      description: 'Demo state for stale UI detection',
    );
    _displayValueNotifier = ValueNotifier<int>(_counterState.value);
    _actualValueNotifier = ValueNotifier<int>(_counterState.value);
  }

  @override
  void dispose() {
    _displayValueNotifier.dispose();
    _actualValueNotifier.dispose();
    super.dispose();
  }

  void _incrementWithoutRebuild() {
    _counterState.value += 1;
    _actualValueNotifier.value = _counterState.value;
  }

  void _incrementWithRebuild() {
    _counterState.value += 1;
    _displayValueNotifier.value = _counterState.value;
    _actualValueNotifier.value = _counterState.value;
  }

  void _refreshDisplay() {
    _displayValueNotifier.value = _counterState.value;
  }

  @override
  Widget build(BuildContext context) {
    return RiskRebuildTracker(
      tag: 'StaleUIExample',
      child: Scaffold(
        appBar: AppBar(title: const Text('Stale UI Detection')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _InfoCard(
                color: Colors.amber.shade50,
                icon: Icons.warning,
                title: 'Stale UI Demo',
                body:
                    'Increment the tracked state without calling setState(). '
                    'The UI will not update, and the detector will log a warning after '
                    'the configured threshold.',
              ),
              const SizedBox(height: 16),
              ValueListenableBuilder<int>(
                valueListenable: _displayValueNotifier,
                builder: (context, displayedValue, _) {
                  return Text(
                    'Displayed UI value: $displayedValue',
                    style: Theme.of(context).textTheme.headlineSmall,
                  );
                },
              ),
              const SizedBox(height: 8),
              ValueListenableBuilder<int>(
                valueListenable: _actualValueNotifier,
                builder: (context, trackedValue, _) {
                  return Text(
                    'Actual tracked state: $trackedValue',
                    style: Theme.of(context).textTheme.bodyLarge,
                  );
                },
              ),
              const SizedBox(height: 12),
              _SyncIndicator(
                displayValueListenable: _displayValueNotifier,
                actualValueListenable: _actualValueNotifier,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.remove_red_eye),
                label: const Text('Increment state without rebuild'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                ),
                onPressed: _incrementWithoutRebuild,
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh UI manually'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  foregroundColor: Colors.white,
                ),
                onPressed: _refreshDisplay,
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.check_circle),
                label: const Text('Increment state with rebuild'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                ),
                onPressed: _incrementWithRebuild,
              ),
              const SizedBox(height: 24),
              Text(
                'Console warning appears after ${RiskDetector.config.uiUpdateThresholdSeconds} seconds when the state updates but the UI does not rebuild.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SyncIndicator extends StatelessWidget {
  final ValueListenable<int> displayValueListenable;
  final ValueListenable<int> actualValueListenable;

  const _SyncIndicator({
    required this.displayValueListenable,
    required this.actualValueListenable,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: displayValueListenable,
      builder: (context, displayValue, _) {
        return ValueListenableBuilder<int>(
          valueListenable: actualValueListenable,
          builder: (context, actualValue, __) {
            final isSynced = displayValue == actualValue;
            final color = isSynced ? Colors.green : Colors.red;
            final icon = isSynced ? Icons.check_circle : Icons.error;
            final text = isSynced ? 'UI is synced' : 'UI is stale';

            return Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  text,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            );
          },
        );
      },
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(body, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
