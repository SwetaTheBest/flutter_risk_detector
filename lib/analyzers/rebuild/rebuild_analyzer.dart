import 'rebuild_result.dart';

enum _RebuildCause {
  setStateInBuild,
  streamEmittingFast,
  ancestorRebuilding,
  providerNotifying,
  animationControllerNoConst,
  objectCreatedInBuild,
  parentSetState,
}

class RebuildAnalyzer {
  static int stormThreshold = 20;
  static int warningThreshold = 10;

  /// Called by ErrorCapture to apply config thresholds.
  static void configure(int warningAt, int stormAt) {
    warningThreshold = warningAt;
    stormThreshold = stormAt;
  }

  static bool shouldReport(int count) => count > warningThreshold;

  static RebuildResult analyze({
    required String tag,
    required int rebuildCount,
    required Duration window,
  }) {
    final rebuildsPerSecond = rebuildCount / window.inSeconds.clamp(1, 9999);
    final causes = _detectCauses(rebuildCount, rebuildsPerSecond);
    final suggestions = _suggestionsFor(causes);

    return RebuildResult(
      tag: tag,
      rebuildCount: rebuildCount,
      window: window,
      possibleCauses: causes.map(_causeLabel).toList(),
      suggestions: suggestions,
    );
  }

  static Set<_RebuildCause> _detectCauses(int count, double rate) {
    final causes = <_RebuildCause>{};

    if (rate > 10) causes.add(_RebuildCause.setStateInBuild);
    if (rate > 5) causes.add(_RebuildCause.streamEmittingFast);
    if (count > stormThreshold) {
      causes.add(_RebuildCause.ancestorRebuilding);
      causes.add(_RebuildCause.providerNotifying);
    }
    if (count > warningThreshold) {
      causes.add(_RebuildCause.animationControllerNoConst);
      causes.add(_RebuildCause.objectCreatedInBuild);
    }
    if (causes.isEmpty) causes.add(_RebuildCause.parentSetState);

    return causes;
  }

  static String _causeLabel(_RebuildCause cause) => switch (cause) {
        _RebuildCause.setStateInBuild =>
          'setState called inside build() or initState() loop',
        _RebuildCause.streamEmittingFast =>
          'Stream or ValueNotifier emitting too frequently',
        _RebuildCause.ancestorRebuilding =>
          'Ancestor widget rebuilding and propagating down the tree',
        _RebuildCause.providerNotifying =>
          'InheritedWidget / Provider notifying on every frame',
        _RebuildCause.animationControllerNoConst =>
          'AnimationController ticking without const subtrees',
        _RebuildCause.objectCreatedInBuild =>
          'Object instance created inside build() used as a key or value',
        _RebuildCause.parentSetState =>
          'Frequent parent setState triggering unnecessary child rebuilds',
      };

  static const _causeToSuggestions = <_RebuildCause, List<String>>{
    _RebuildCause.setStateInBuild: [
      'Move setState calls to event handlers, never inside build()',
    ],
    _RebuildCause.streamEmittingFast: [
      'Debounce stream events or use distinctUntilChanged()',
      'Replace StreamBuilder with more granular listeners',
    ],
    _RebuildCause.ancestorRebuilding: [
      'Extract the stable subtree into a separate StatelessWidget',
      'Use const constructors wherever possible',
    ],
    _RebuildCause.providerNotifying: [
      'Use select() to listen to only the specific field you need',
      'Split large providers into smaller, focused ones',
    ],
    _RebuildCause.animationControllerNoConst: [
      'Mark non-animated children as const to skip their rebuild',
      'Use AnimatedBuilder and keep the builder scope minimal',
    ],
    _RebuildCause.objectCreatedInBuild: [
      'Move object/list/map creation outside build() or use const',
    ],
    _RebuildCause.parentSetState: [
      'Lift only the changing state up; keep the rest in child widgets',
      'Consider using ValueListenableBuilder for fine-grained updates',
    ],
  };

  static List<String> _suggestionsFor(Set<_RebuildCause> causes) => causes
      .expand((c) => _causeToSuggestions[c] ?? const <String>[])
      .toSet()
      .toList();
}
