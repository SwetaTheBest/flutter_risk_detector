import 'package:flutter/foundation.dart';

/// Metadata describing a tracked widget rebuild event.
@immutable
class RebuildMetadata {
  /// Identifier used to associate the rebuild event with tracked state.
  final String tag;

  /// Timestamp of the first recorded rebuild.
  final DateTime firstRebuildTime;

  /// Timestamp of the most recent rebuild.
  final DateTime lastRebuildTime;

  /// Total rebuild count observed for the widget tag.
  final int rebuildCount;

  const RebuildMetadata({
    required this.tag,
    required this.firstRebuildTime,
    required this.lastRebuildTime,
    required this.rebuildCount,
  });

  /// Duration between the first and latest rebuild events.
  Duration get span => lastRebuildTime.difference(firstRebuildTime);

  /// Average rebuild frequency expressed as rebuilds per second.
  double get rebuildsPerSecond {
    final milliseconds = span.inMilliseconds;
    if (milliseconds <= 0) {
      return rebuildCount.toDouble();
    }
    return rebuildCount * 1000 / milliseconds;
  }
}

/// Registry of rebuild timestamps and counts for monitored widgets.
class RebuildMonitor {
  static final Map<String, RebuildMetadata> _registry =
      <String, RebuildMetadata>{};

  /// Records a rebuild event for [tag].
  static void registerRebuild({
    required String tag,
    required DateTime timestamp,
  }) {
    final existing = _registry[tag];
    if (existing == null) {
      _registry[tag] = RebuildMetadata(
        tag: tag,
        firstRebuildTime: timestamp,
        lastRebuildTime: timestamp,
        rebuildCount: 1,
      );
      return;
    }

    _registry[tag] = RebuildMetadata(
      tag: tag,
      firstRebuildTime: existing.firstRebuildTime,
      lastRebuildTime: timestamp,
      rebuildCount: existing.rebuildCount + 1,
    );
  }

  /// Returns the latest rebuild metadata for [tag].
  static RebuildMetadata? metadataFor(String tag) => _registry[tag];

  /// Clears all tracked rebuild metadata.
  @visibleForTesting
  static void clear() => _registry.clear();
}
