import 'package:flutter/foundation.dart';

import 'overflow_result.dart';

class OverflowAnalyzer {
  static bool isOverflow(String error) {
    return error.contains('RenderFlex overflowed');
  }

  static OverflowResult analyze(FlutterErrorDetails details) {
    final error = details.exceptionAsString();
    final stack = details.stack?.toString() ?? '';
    final context = details.context?.toString() ?? '';
    final informationCollector = details.informationCollector?.call();
    final widgetInfo = informationCollector?.map((e) => e.toStringDeep()).join('\n') ?? '';

    final location = _extractLocation(stack);
    final parentWidget = _extractParentWidget(context, widgetInfo);
    final direction = _extractOverflowDirection(error);
    final pixels = _extractOverflowPixels(error);
    final widgetName = _extractWidgetName(error, context, widgetInfo);

    return OverflowResult(
      widgetName: widgetName,
      fileName: location?['file'] ?? 'Unknown File',
      line: location?['line'] != null ? int.tryParse(location!['line']!) : null,
      column: location?['column'] != null ? int.tryParse(location!['column']!) : null,
      parentWidget: parentWidget,
      overflowDirection: direction,
      overflowPixels: pixels,
      suggestion: _generateSuggestion(direction),
    );
  }

  static String _extractWidgetName(String error, String context, String widgetInfo) {
    // Try to extract from widget tree info (most precise)
    final widgetMatch = RegExp(r'(Row|Column|Flex|ListView|Stack)').firstMatch(widgetInfo);
    if (widgetMatch != null) return widgetMatch.group(0)!;

    // Fall back to context string
    final contextMatch = RegExp(r'(Row|Column|Flex|ListView|Stack)').firstMatch(context);
    if (contextMatch != null) return contextMatch.group(0)!;

    if (error.contains('vertical')) return 'Column';
    if (error.contains('horizontal')) return 'Row';
    return 'Row/Column/Flex';
  }

  static Map<String, String>? _extractLocation(String stack) {
    // Skip framework frames, find first user file in lib/
    final regex = RegExp(r'(lib\/[^\s]+\.dart):(\d+):(\d+)');
    for (final match in regex.allMatches(stack)) {
      final file = match.group(1)!;
      // Skip generated and framework files
      if (!file.contains('.g.dart') && !file.contains('flutter/')) {
        return {'file': file, 'line': match.group(2)!, 'column': match.group(3)!};
      }
    }
    return null;
  }

  static String? _extractParentWidget(String context, String widgetInfo) {
    // Look for "in [WidgetName]" pattern in context
    final match = RegExp(r'in ([A-Z][\w]+)').firstMatch(context);
    if (match != null) return match.group(1);

    // Try widget info for the enclosing widget
    final infoMatch = RegExp(r'([A-Z][\w]+)\(').firstMatch(widgetInfo);
    return infoMatch?.group(1);
  }

  static String? _extractOverflowDirection(String error) {
    if (error.contains('bottom')) return 'bottom';
    if (error.contains('top')) return 'top';
    if (error.contains('right')) return 'right';
    if (error.contains('left')) return 'left';
    if (error.contains('vertical')) return 'bottom';
    if (error.contains('horizontal')) return 'right';
    return null;
  }

  static double? _extractOverflowPixels(String error) {
    final match = RegExp(r'overflowed by ([\d.]+) pixel').firstMatch(error);
    return match != null ? double.tryParse(match.group(1)!) : null;
  }

  static String _generateSuggestion(String? direction) {
    if (direction == 'bottom' || direction == 'top') {
      return 'Column is overflowing vertically.\n- Wrap with SingleChildScrollView\n- Use Expanded/Flexible on children\n- Set shrinkWrap: true on lists';
    }
    if (direction == 'right' || direction == 'left') {
      return 'Row is overflowing horizontally.\n- Wrap child with Expanded or Flexible\n- Use Wrap instead of Row\n- Clip with overflow: TextOverflow.ellipsis for Text';
    }
    return 'RenderFlex overflow detected.\n- Wrap child with Expanded or Flexible\n- Use SingleChildScrollView\n- Avoid fixed dimensions';
  }
}
