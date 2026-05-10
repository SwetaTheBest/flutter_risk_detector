import 'package:flutter/material.dart';

import 'rebuild_analyzer.dart';

class RiskRebuildTracker extends StatefulWidget {
  final Widget child;
  final String tag;

  const RiskRebuildTracker({required this.child, required this.tag, super.key});

  @override
  State<RiskRebuildTracker> createState() => _RiskRebuildTrackerState();
}

class _RiskRebuildTrackerState extends State<RiskRebuildTracker> {
  int _rebuildCount = 0;
  late DateTime _startTime;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    _rebuildCount++;
    debugPrint('🔄 ${widget.tag} rebuilt $_rebuildCount times');

    if (RebuildAnalyzer.shouldReport(_rebuildCount)) {
      final result = RebuildAnalyzer.analyze(
        tag: widget.tag,
        rebuildCount: _rebuildCount,
        window: DateTime.now().difference(_startTime),
      );
      debugPrint(result.formattedMessage);
    }

    return widget.child;
  }
}
