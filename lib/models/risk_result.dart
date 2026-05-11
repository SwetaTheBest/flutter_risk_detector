import 'risk_level.dart';

class RiskResult {
  final String category;
  final String title;
  final String description;
  final String suggestion;
  final RiskLevel level;
  final String? file;
  final int? line;
  final DateTime timestamp;

  RiskResult({
    required this.category,
    required this.title,
    required this.description,
    required this.suggestion,
    required this.level,
    this.file,
    this.line,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  String get formattedMessage {
    final loc = file != null ? ' @ $file${line != null ? ':$line' : ''}' : '';
    return '${level.icon} [$category]$loc\n  $title\n  $description\n  → $suggestion';
  }
}
