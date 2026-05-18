import 'package:flutter/foundation.dart';

/// Metadata describing a tracked state update.
@immutable
class StateChangeMetadata {
  /// Identifier used to associate the tracked state with a rebuild target.
  final String tag;

  /// Optional description for diagnostics.
  final String? description;

  /// Timestamp of the most recent state assignment.
  final DateTime lastUpdated;

  /// Number of updates applied to this tracked state.
  final int updateCount;

  const StateChangeMetadata({
    required this.tag,
    required this.lastUpdated,
    required this.updateCount,
    this.description,
  });

  @override
  String toString() {
    return 'StateChangeMetadata(tag: $tag, updateCount: $updateCount, lastUpdated: $lastUpdated)';
  }
}

/// Registry for tracked state update metadata.
class StateChangeTracker {
  static final Map<String, StateChangeMetadata> _registry =
      <String, StateChangeMetadata>{};

  /// Records a state change with the given [tag].
  static void registerStateChange({
    required String tag,
    required DateTime lastUpdated,
    required int updateCount,
    String? description,
  }) {
    _registry[tag] = StateChangeMetadata(
      tag: tag,
      description: description,
      lastUpdated: lastUpdated,
      updateCount: updateCount,
    );
  }

  /// Returns the most recent state change metadata for [tag].
  static StateChangeMetadata? metadataFor(String tag) => _registry[tag];

  /// Clears all tracked state metadata.
  @visibleForTesting
  static void clear() => _registry.clear();
}
