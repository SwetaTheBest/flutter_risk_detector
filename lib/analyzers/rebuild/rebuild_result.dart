import 'rebuild_analyzer.dart';

class RebuildResult {
  final String tag;
  final int rebuildCount;
  final Duration window;
  final List<String> possibleCauses;
  final List<String> suggestions;

  /// Snapshotted at construction so it is stable even if thresholds are
  /// reconfigured later via [RebuildAnalyzer.configure].
  final bool isStorm;

  RebuildResult({
    required this.tag,
    required this.rebuildCount,
    required this.window,
    required this.possibleCauses,
    required this.suggestions,
  }) : isStorm = rebuildCount > RebuildAnalyzer.stormThreshold;

  double get rebuildsPerSecond =>
      rebuildCount / window.inSeconds.clamp(1, 9999);

  @override
  bool operator ==(Object other) =>
      other is RebuildResult &&
      tag == other.tag &&
      rebuildCount == other.rebuildCount &&
      window == other.window;

  @override
  int get hashCode => Object.hash(tag, rebuildCount, window);

  String get formattedMessage {
    final rate = rebuildsPerSecond.toStringAsFixed(1);
    return '''
${isStorm ? '🔴 REBUILD STORM' : '🟡 EXCESSIVE REBUILDS'} — $tag

Rebuilds : $rebuildCount in ${window.inSeconds}s (~$rate/s)

Possible Causes:
${possibleCauses.map((c) => '  • $c').join('\n')}

Suggestions:
${suggestions.map((s) => '  → $s').join('\n')}
''';
  }
}
