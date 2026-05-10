class OverflowResult {
  final String widgetName;
  final String fileName;
  final String suggestion;

  OverflowResult({
    required this.widgetName,
    required this.fileName,
    required this.suggestion,
  });

  String get formattedMessage {
    return '''
⚠ OVERFLOW RISK DETECTED

Widget:
$widgetName

File:
$fileName

Suggestion:
$suggestion
''';
  }
}
