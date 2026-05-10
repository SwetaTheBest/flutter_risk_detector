import 'rebuild_result.dart';

class RebuildAnalyzer {
  static const int _stormThreshold = 20;
  static const int _warningThreshold = 10;

  static bool shouldReport(int count) => count > _warningThreshold;

  static RebuildResult analyze({
    required String tag,
    required int rebuildCount,
    required Duration window,
  }) {
    final rebuildsPerSecond = rebuildCount / window.inSeconds.clamp(1, 9999);
    final causes = _detectCauses(rebuildCount, rebuildsPerSecond);
    final suggestions = _generateSuggestions(causes);

    return RebuildResult(
      tag: tag,
      rebuildCount: rebuildCount,
      window: window,
      possibleCauses: causes,
      suggestions: suggestions,
    );
  }

  static List<String> _detectCauses(int count, double rate) {
    final causes = <String>[];

    if (rate > 10) {
      causes.add('setState called inside build() or initState() loop');
    }

    if (rate > 5) {
      causes.add('Stream or ValueNotifier emitting too frequently');
    }

    if (count > _stormThreshold) {
      causes.add('Ancestor widget rebuilding and propagating down the tree');
      causes.add('InheritedWidget / Provider notifying on every frame');
    }

    if (count > _warningThreshold) {
      causes.add('AnimationController ticking without const subtrees');
      causes.add('Object instance created inside build() used as a key or value');
    }

    if (causes.isEmpty) {
      causes.add('Frequent parent setState triggering unnecessary child rebuilds');
    }

    return causes;
  }

  static List<String> _generateSuggestions(List<String> causes) {
    final suggestions = <String>[];

    for (final cause in causes) {
      if (cause.contains('setState called inside build')) {
        suggestions.add('Move setState calls to event handlers, never inside build()');
      }
      if (cause.contains('Stream or ValueNotifier')) {
        suggestions.add('Debounce stream events or use distinctUntilChanged()');
        suggestions.add('Replace StreamBuilder with more granular listeners');
      }
      if (cause.contains('Ancestor widget rebuilding')) {
        suggestions.add('Extract the stable subtree into a separate StatelessWidget');
        suggestions.add('Use const constructors wherever possible');
      }
      if (cause.contains('InheritedWidget / Provider')) {
        suggestions.add('Use select() to listen to only the specific field you need');
        suggestions.add('Split large providers into smaller, focused ones');
      }
      if (cause.contains('AnimationController')) {
        suggestions.add('Mark non-animated children as const to skip their rebuild');
        suggestions.add('Use AnimatedBuilder and keep the builder scope minimal');
      }
      if (cause.contains('Object instance created inside build')) {
        suggestions.add('Move object/list/map creation outside build() or use const');
      }
      if (cause.contains('parent setState')) {
        suggestions.add('Lift only the changing state up; keep the rest in child widgets');
        suggestions.add('Consider using ValueListenableBuilder for fine-grained updates');
      }
    }

    return suggestions.toSet().toList(); // deduplicate
  }
}
