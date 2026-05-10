import 'package:flutter/foundation.dart';

import 'overflow_result.dart';

class OverflowAnalyzer {
  static bool isOverflow(String error) {
    return error.contains('RenderFlex overflowed');
  }

  static OverflowResult analyze(FlutterErrorDetails details) {
    final error = details.exceptionAsString();

    final stack = details.stack?.toString() ?? '';

    final widgetName = _extractWidgetName(error);

    final fileName = _extractFileName(stack);

    return OverflowResult(
      widgetName: widgetName ?? 'Unknown Widget',

      fileName: fileName ?? 'Unknown File',

      suggestion: _generateSuggestion(error),
    );
  }

  static String? _extractWidgetName(String error) {
    if (error.contains('RenderFlex')) {
      return 'Row/Column/Flex';
    }

    if (error.contains('Row')) {
      return 'Row';
    }

    if (error.contains('Column')) {
      return 'Column';
    }

    return null;
  }

  static String? _extractFileName(String stack) {
    final regex = RegExp(r'lib\/.*\.dart:\d+:\d+');

    final match = regex.firstMatch(stack);

    return match?.group(0);
  }

  static String _generateSuggestion(String error) {
    if (error.contains('RenderFlex')) {
      return '''
RenderFlex overflow detected.

Possible Fixes:
- Wrap child with Expanded
- Use Flexible
- Use Wrap instead of Row
- Avoid fixed widths
''';
    }

    return '''
General Overflow Fixes:
- Check widget constraints
- Avoid hardcoded dimensions
- Use responsive layouts
''';
  }
}
