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

  RiskResult copyWith({
    String? category,
    String? title,
    String? description,
    String? suggestion,
    RiskLevel? level,
    String? file,
    int? line,
    DateTime? timestamp,
  }) =>
      RiskResult(
        category: category ?? this.category,
        title: title ?? this.title,
        description: description ?? this.description,
        suggestion: suggestion ?? this.suggestion,
        level: level ?? this.level,
        file: file ?? this.file,
        line: line ?? this.line,
        timestamp: timestamp ?? this.timestamp,
      );

  @override
  bool operator ==(Object other) =>
      other is RiskResult &&
      category == other.category &&
      title == other.title &&
      level == other.level &&
      file == other.file &&
      line == other.line;

  @override
  int get hashCode => Object.hash(category, title, level, file, line);

  String get formattedMessage {
    final loc = file != null ? ' @ $file${line != null ? ':$line' : ''}' : '';
    return '${level.icon} [$category]$loc\n  $title\n  $description\n  → $suggestion';
  }
}
