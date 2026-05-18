import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/detector.dart';
import '../core/logger.dart';
import 'rebuild_monitor.dart';
import 'state_change_tracker.dart';

/// Detects stale UI risk by comparing tracked state updates against rebuild
/// events for the same widget tag.
class UIUpdateDetector {
  static final Map<String, Timer> _pendingChecks = <String, Timer>{};

  /// Schedules stale UI detection for a state update on [tag].
  static void scheduleStateUpdate({
    required String tag,
    required DateTime updateTime,
  }) {
    if (!kDebugMode || !RiskDetector.config.enableUiUpdateDetection) {
      return;
    }

    _pendingChecks[tag]?.cancel();

    final thresholdSeconds = RiskDetector.config.uiUpdateThresholdSeconds;
    final threshold =
        Duration(seconds: thresholdSeconds < 0 ? 0 : thresholdSeconds);
    _pendingChecks[tag] = Timer(threshold, () {
      _pendingChecks.remove(tag);
      _evaluateStateUpdate(tag, updateTime);
    });
  }

  static void _evaluateStateUpdate(String tag, DateTime updateTime) {
    if (!kDebugMode || !RiskDetector.config.enableUiUpdateDetection) {
      return;
    }

    final stateMetadata = StateChangeTracker.metadataFor(tag);
    if (stateMetadata == null) {
      return;
    }

    final rebuildMetadata = RebuildMonitor.metadataFor(tag);

    if (rebuildMetadata != null &&
        rebuildMetadata.lastRebuildTime.isAfter(updateTime)) {
      return;
    }

    final warning = StringBuffer()
      ..writeln('⚠ UI UPDATE RISK DETECTED')
      ..writeln('Widget: $tag')
      ..writeln('State updates: ${stateMetadata.updateCount}')
      ..writeln(
          'Last state update: ${stateMetadata.lastUpdated.toIso8601String()}')
      ..writeln(
          'Last rebuild: ${rebuildMetadata?.lastRebuildTime.toIso8601String() ?? 'none'}')
      ..writeln()
      ..writeln('Reason:')
      ..writeln(
        'State changed successfully but no UI rebuild was observed within '
        '${RiskDetector.config.uiUpdateThresholdSeconds}s.',
      )
      ..writeln()
      ..writeln('Possible Causes:')
      ..writeln('* Missing notifyListeners() or setState()')
      ..writeln('* Widget is not listening to state updates')
      ..writeln('* Incorrect Provider or InheritedWidget scope')
      ..writeln('* Stale FutureBuilder / StreamBuilder usage')
      ..writeln('* Mutable state mutated without change notification')
      ..writeln('* Rebuild not triggered for the widget subtree')
      ..writeln()
      ..writeln('Tip:')
      ..writeln(
        'Align the tracked state tag with the widget rebuild tag, and ensure '
        'the state update is propagated to the rebuild target.',
      );

    RiskLogger.warning(warning.toString());
  }
}
