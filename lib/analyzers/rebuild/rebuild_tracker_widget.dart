import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'rebuild_analyzer.dart';

class RiskRebuildTracker extends StatefulWidget {
  final Widget child;
  final String tag;

  /// Override the rebuild count that triggers warnings. Defaults to
  /// [RebuildAnalyzer.warningThreshold].
  final int? warningThreshold;

  /// Override the jank frame threshold in milliseconds. Defaults to 16ms.
  final int jankThresholdMs;

  const RiskRebuildTracker({
    required this.child,
    required this.tag,
    this.warningThreshold,
    this.jankThresholdMs = 16,
    super.key,
  });

  @override
  State<RiskRebuildTracker> createState() => _RiskRebuildTrackerState();
}

class _RiskRebuildTrackerState extends State<RiskRebuildTracker> {
  int _rebuildCount = 0;
  late DateTime _startTime;
  DateTime? _lastReport;

  static const Duration _reportCooldown = Duration(seconds: 3);

  // Milestones at which we log even below the warning threshold
  static const _milestones = {5, 10, 20, 50, 100};

  int get _effectiveWarningThreshold =>
      widget.warningThreshold ?? RebuildAnalyzer.warningThreshold;

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
    final threshold = Duration(milliseconds: widget.jankThresholdMs);
    for (final timing in timings) {
      if (timing.buildDuration > threshold) {
        debugPrint(
          '🟠 JANK [${widget.tag}] '
          'build=${timing.buildDuration.inMilliseconds}ms '
          'raster=${timing.rasterDuration.inMilliseconds}ms '
          '(>${widget.jankThresholdMs}ms threshold)',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _rebuildCount++;

    if (_rebuildCount > _effectiveWarningThreshold) {
      final now = DateTime.now();
      if (_lastReport == null || now.difference(_lastReport!) >= _reportCooldown) {
        _lastReport = now;
        final result = RebuildAnalyzer.analyze(
          tag: widget.tag,
          rebuildCount: _rebuildCount,
          window: now.difference(_startTime),
        );
        debugPrint(result.formattedMessage);
      }
    } else if (_milestones.contains(_rebuildCount)) {
      // Log only at milestones — not on every single rebuild
      debugPrint('🔄 [${widget.tag}] rebuild #$_rebuildCount');
    }

    return widget.child;
  }
}
