import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

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
  DateTime? _lastReport;

  // Jank detection
  static const Duration _jankThreshold = Duration(milliseconds: 16);
  static const Duration _reportCooldown = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    SchedulerBinding.instance.addTimingsCallback(_onFrameTimings);
  }

  @override
  void dispose() {
    SchedulerBinding.instance.removeTimingsCallback(_onFrameTimings);
    super.dispose();
  }

  void _onFrameTimings(List<FrameTiming> timings) {
    for (final timing in timings) {
      final buildDuration = timing.buildDuration;
      final rasterDuration = timing.rasterDuration;
      if (buildDuration > _jankThreshold) {
        debugPrint(
          '🟠 JANK [${widget.tag}] '
          'build=${buildDuration.inMilliseconds}ms '
          'raster=${rasterDuration.inMilliseconds}ms '
          '(>${_jankThreshold.inMilliseconds}ms threshold)',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _rebuildCount++;

    if (RebuildAnalyzer.shouldReport(_rebuildCount)) {
      final now = DateTime.now();
      // Throttle: only report once per cooldown window
      if (_lastReport == null || now.difference(_lastReport!) >= _reportCooldown) {
        _lastReport = now;
        final result = RebuildAnalyzer.analyze(
          tag: widget.tag,
          rebuildCount: _rebuildCount,
          window: now.difference(_startTime),
        );
        debugPrint(result.formattedMessage);
      }
    } else {
      debugPrint('🔄 ${widget.tag} rebuilt $_rebuildCount times');
    }

    return widget.child;
  }
}
