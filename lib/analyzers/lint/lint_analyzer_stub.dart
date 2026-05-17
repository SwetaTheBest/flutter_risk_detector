import 'lint_issue.dart';
import 'lint_result.dart';

/// Fallback lint analyzer used on platforms where `dart:io` is unavailable.
///
/// The public API remains importable on Flutter Web and other non-IO targets,
/// but static file scanning returns empty results.
class LintAnalyzer {
  /// Static lint scanning needs dart:io and is unavailable on this platform.
  static Future<LintResult> analyzeDirectory(String directory) async {
    return LintResult([]);
  }

  /// Static lint scanning needs dart:io and is unavailable on this platform.
  static Future<List<LintIssue>> analyzeFile(String filePath) async {
    return const [];
  }
}
