import 'state_change_tracker.dart';
import 'ui_update_detector.dart';

/// Generic wrapper around state values that records update metadata.
///
/// Use this when you want to surface stale UI risk diagnostics for state that
/// should trigger a widget rebuild.
class TrackedState<T> {
  static int _nextId = 0;

  /// Tag used to associate the state with a rebuild target.
  final String tag;

  /// Optional human-readable description for diagnostics.
  final String? description;

  T _value;

  /// Timestamp of the most recent assignment.
  DateTime lastUpdated;

  /// Number of updates applied to this tracked state instance.
  int updateCount = 0;

  TrackedState(
    T initialValue, {
    String? tag,
    this.description,
  })  : _value = initialValue,
        tag = tag ?? 'TrackedState#${_nextId++}',
        lastUpdated = DateTime.now() {
    StateChangeTracker.registerStateChange(
      tag: this.tag,
      lastUpdated: lastUpdated,
      updateCount: updateCount,
      description: description,
    );
  }

  /// Current state value.
  T get value => _value;

  /// Updates the value and records timing metadata for stale UI detection.
  set value(T newValue) {
    _value = newValue;
    lastUpdated = DateTime.now();
    updateCount += 1;

    StateChangeTracker.registerStateChange(
      tag: tag,
      lastUpdated: lastUpdated,
      updateCount: updateCount,
      description: description,
    );

    UIUpdateDetector.scheduleStateUpdate(
      tag: tag,
      updateTime: lastUpdated,
    );
  }

  /// Latest metadata for this tracked state instance.
  StateChangeMetadata get metadata =>
      StateChangeTracker.metadataFor(tag) ??
      StateChangeMetadata(
        tag: tag,
        lastUpdated: lastUpdated,
        updateCount: updateCount,
        description: description,
      );
}
