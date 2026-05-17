import 'dart:async';

import 'package:flutter/material.dart';

class AsyncRiskScreen extends StatelessWidget {
  const AsyncRiskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Async Risks')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _RiskTile(
            color: Colors.red.shade50,
            icon: Icons.dangerous,
            title: 'setState After Dispose',
            description:
                'Navigates to a widget that starts a 2s Future, then immediately pops. '
                'The Future completes after dispose and calls setState — triggers the detector.',
            onTest: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const _SetStateAfterDisposeWidget(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _RiskTile(
            color: Colors.orange.shade50,
            icon: Icons.stream,
            title: 'Stream Subscription Leak',
            description:
                'Opens a widget that subscribes to a Stream but never cancels it in dispose(). '
                'The subscription keeps firing after the widget is gone.',
            onTest: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const _StreamLeakWidget()),
            ),
          ),
          const SizedBox(height: 12),
          _RiskTile(
            color: Colors.purple.shade50,
            icon: Icons.timer_off,
            title: 'Timer Not Cancelled',
            description:
                'Opens a widget with a Timer.periodic that is never cancelled in dispose(). '
                'The timer keeps ticking after the widget is removed.',
            onTest: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const _TimerLeakWidget()),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── setState after dispose ───────────────────────────────────────────────────

class _SetStateAfterDisposeWidget extends StatefulWidget {
  const _SetStateAfterDisposeWidget();

  @override
  State<_SetStateAfterDisposeWidget> createState() =>
      _SetStateAfterDisposeState();
}

class _SetStateAfterDisposeState extends State<_SetStateAfterDisposeWidget> {
  String _status = 'Waiting for Future…';

  @override
  void initState() {
    super.initState();
    // Intentional: no mounted check — will call setState after dispose
    Future.delayed(const Duration(seconds: 2), () {
      setState(() => _status = 'Future completed!'); // ← risk: no mounted check
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('setState After Dispose')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_status, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 24),
            const Text(
              'Pop immediately to trigger setState-after-dispose.\n'
              'Check the debug console for the async risk report.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Pop Now (trigger risk)'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Stream subscription leak ─────────────────────────────────────────────────

class _StreamLeakWidget extends StatefulWidget {
  const _StreamLeakWidget();

  @override
  State<_StreamLeakWidget> createState() => _StreamLeakState();
}

class _StreamLeakState extends State<_StreamLeakWidget> {
  int _ticks = 0;
  // Intentional: subscription stored but never cancelled in dispose()
  late StreamSubscription<int> _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = Stream.periodic(const Duration(seconds: 1), (i) => i)
        .listen((tick) {
          if (mounted) setState(() => _ticks = tick);
          debugPrint('🔴 Stream tick $tick — still firing even after dispose!');
        });
  }

  // Intentional: no dispose() override — _subscription.cancel() never called

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stream Leak')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Stream ticks: $_ticks', style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 16),
            const Text(
              'Pop this screen — the stream keeps printing to console\n'
              'because cancel() is never called.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Intentional: not cancelling before pop
                Navigator.pop(context);
              },
              child: const Text('Pop (leak the subscription)'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () {
                _subscription.cancel(); // correct fix
                Navigator.pop(context);
              },
              child: const Text('Pop + Cancel (correct fix)'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Timer leak ───────────────────────────────────────────────────────────────

class _TimerLeakWidget extends StatefulWidget {
  const _TimerLeakWidget();

  @override
  State<_TimerLeakWidget> createState() => _TimerLeakState();
}

class _TimerLeakState extends State<_TimerLeakWidget> {
  int _ticks = 0;
  // Intentional: Timer stored but never cancelled in dispose()
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _ticks++);
      debugPrint('🔴 Timer tick $_ticks — still firing after dispose!');
    });
  }

  // Intentional: no dispose() — _timer.cancel() never called

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Timer Leak')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Timer ticks: $_ticks', style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 16),
            const Text(
              'Pop this screen — the timer keeps printing to console\n'
              'because cancel() is never called in dispose().',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context), // leak
              child: const Text('Pop (leak the timer)'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () {
                _timer.cancel(); // correct fix
                Navigator.pop(context);
              },
              child: const Text('Pop + Cancel (correct fix)'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared tile widget ───────────────────────────────────────────────────────

class _RiskTile extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTest;

  const _RiskTile({
    required this.color,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTest,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(description, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onTest, child: const Text('Run Test →')),
        ],
      ),
    );
  }
}
