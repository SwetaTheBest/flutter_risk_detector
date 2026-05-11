class OverflowResult {
  final String widgetName;
  final String fileName;
  final String suggestion;
  final String? parentWidget;
  final int? line;
  final int? column;
  final String? overflowDirection;
  final double? overflowPixels;

  const OverflowResult({
    required this.widgetName,
    required this.fileName,
    required this.suggestion,
    this.parentWidget,
    this.line,
    this.column,
    this.overflowDirection,
    this.overflowPixels,
  });

  @override
  bool operator ==(Object other) =>
      other is OverflowResult &&
      widgetName == other.widgetName &&
      fileName == other.fileName &&
      line == other.line &&
      column == other.column &&
      overflowDirection == other.overflowDirection &&
      overflowPixels == other.overflowPixels;

  @override
  int get hashCode => Object.hash(
      widgetName, fileName, line, column, overflowDirection, overflowPixels);

  String get formattedMessage {
    final location = line != null ? '$fileName:$line${column != null ? ':$column' : ''}' : fileName;
    final parent = parentWidget != null ? '\nParent Widget:\n$parentWidget' : '';
    final overflow = overflowDirection != null
        ? '\nOverflow: ${overflowPixels?.toStringAsFixed(1) ?? '?'}px on the $overflowDirection side'
        : '';
    return '''
⚠ OVERFLOW RISK DETECTED

Widget:
$widgetName$parent$overflow

Location:
$location

Suggestion:
$suggestion
''';
  }
}
