class RebuildResult {
  final String tag;
  final int rebuildCount;
  final Duration window;
  final List<String> possibleCauses;
  final List<String> suggestions;

  RebuildResult({
    required this.tag,
    required this.rebuildCount,
    required this.window,
    required this.possibleCauses,
    required this.suggestions,
  });

  bool get isStorm => rebuildCount > 20;

  String get formattedMessage {
    final rate = (rebuildCount / window.inSeconds.clamp(1, 9999)).toStringAsFixed(1);
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
