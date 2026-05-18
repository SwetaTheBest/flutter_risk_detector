import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _scenarios = [
    _Scenario(
      route: '/overflow',
      icon: Icons.swap_horiz,
      color: Colors.orange,
      title: 'Overflow Detection',
      subtitle: 'Triggers RenderFlex horizontal & vertical overflow',
    ),
    _Scenario(
      route: '/rebuild',
      icon: Icons.refresh,
      color: Colors.blue,
      title: 'Rebuild Storm + Jank',
      subtitle: 'Rapid setState and heavy sync work on UI thread',
    ),
    _Scenario(
      route: '/async',
      icon: Icons.timer_off,
      color: Colors.red,
      title: 'Async Risks',
      subtitle: 'setState after dispose, stream leak, timer leak',
    ),
    _Scenario(
      route: '/stale-ui',
      icon: Icons.broken_image,
      color: Colors.amber,
      title: 'Stale UI Detection',
      subtitle: 'State updates without setState or rebuild triggers',
    ),
    _Scenario(
      route: '/memory',
      icon: Icons.memory,
      color: Colors.purple,
      title: 'Memory Leaks',
      subtitle: 'Controllers and subscriptions not disposed (intentional demo)',
    ),
    _Scenario(
      route: '/lint',
      icon: Icons.code,
      color: Colors.teal,
      title: 'Lint Issues',
      subtitle: 'Sync I/O, context across async, hardcoded values',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🛡 Risk Detector — Test Suite'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Tooltip(
              message: 'Clean up leaked resources from Memory Leaks demo',
              child: IconButton(
                icon: const Icon(Icons.cleaning_services),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Resources cleaned up (if Memory Leaks screen was visited)',
                      ),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _scenarios.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final s = _scenarios[i];
          return Card(
            elevation: 2,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: CircleAvatar(
                backgroundColor: s.color.withValues(alpha: 0.15),
                child: Icon(s.icon, color: s.color),
              ),
              title: Text(
                s.title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(s.subtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pushNamed(context, s.route),
            ),
          );
        },
      ),
    );
  }
}

class _Scenario {
  final String route;
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _Scenario({
    required this.route,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });
}
