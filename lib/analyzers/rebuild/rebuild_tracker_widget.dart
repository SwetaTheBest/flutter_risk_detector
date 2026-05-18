import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../core/logger.dart';
import '../../state_tracking/rebuild_monitor.dart';
import 'rebuild_analyzer.dart';

/// Wraps a subtree and logs debug-only rebuild and frame timing diagnostics.
///
/// The tracker has no runtime behavior in release builds. In debug builds it
/// counts rebuilds for the wrapped subtree and reports when counts exceed the
/// configured warning threshold. It also listens to frame timings to surface
/// jank above [jankThresholdMs].
class RiskRebuildTracker extends StatefulWidget {
  /// Widget subtree to monitor.
  final Widget child;

  /// Label used in rebuild and jank log messages.
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
    if (kDebugMode) {
      SchedulerBinding.instance.addTimingsCallback(_onFrameTimings);
    }
  }

  @override
  void dispose() {
    if (kDebugMode) {
      SchedulerBinding.instance.removeTimingsCallback(_onFrameTimings);
    }
    super.dispose();
  }

  void _onFrameTimings(List<FrameTiming> timings) {
    if (!kDebugMode) return;

    final threshold = Duration(milliseconds: widget.jankThresholdMs);
    for (final timing in timings) {
      if (timing.buildDuration > threshold) {
        RiskLogger.warning(
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
    if (!kDebugMode) return widget.child;

    _rebuildCount++;
    RebuildMonitor.registerRebuild(
      tag: widget.tag,
      timestamp: DateTime.now(),
    );

    if (_rebuildCount > _effectiveWarningThreshold) {
      final now = DateTime.now();
      if (_lastReport == null ||
          now.difference(_lastReport!) >= _reportCooldown) {
        _lastReport = now;
        final result = RebuildAnalyzer.analyze(
          tag: widget.tag,
          rebuildCount: _rebuildCount,
          window: now.difference(_startTime),
        );
        RiskLogger.warning(result.formattedMessage);
      }
    } else if (_milestones.contains(_rebuildCount)) {
      // Log only at milestones — not on every single rebuild
      RiskLogger.log('🔄 [${widget.tag}] rebuild #$_rebuildCount');
    }

    return widget.child;
  }
}
