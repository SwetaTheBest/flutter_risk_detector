import 'package:flutter/foundation.dart';

import 'overflow_result.dart';

class OverflowAnalyzer {
  // Compiled once at class load — not on every call
  static final _locationRegex = RegExp(r'(lib\/[^\s]+\.dart):(\d+):(\d+)');
  static final _pixelsRegex = RegExp(r'overflowed by ([\.\d]+) pixel');
  static final _widgetRegex = RegExp(r'(Row|Column|Flex|ListView|Stack)');
  static final _parentContextRegex = RegExp(r'in ([A-Z]\w+)');
  static final _parentInfoRegex = RegExp(r'([A-Z]\w+)\(');

  static bool isOverflow(String error) =>
      error.contains('RenderFlex overflowed');

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
    final widgetMatch = _widgetRegex.firstMatch(widgetInfo);
    if (widgetMatch != null) return widgetMatch.group(0)!;
    final contextMatch = _widgetRegex.firstMatch(context);
    if (contextMatch != null) return contextMatch.group(0)!;
    if (error.contains('vertical')) return 'Column';
    if (error.contains('horizontal')) return 'Row';
    return 'Row/Column/Flex';
  }

  static Map<String, String>? _extractLocation(String stack) {
    for (final match in _locationRegex.allMatches(stack)) {
      final file = match.group(1)!;
      // Skip generated and framework files
      if (!file.contains('.g.dart') && !file.contains('flutter/')) {
        return {'file': file, 'line': match.group(2)!, 'column': match.group(3)!};
      }
    }
    return null;
  }

  static String? _extractParentWidget(String context, String widgetInfo) {
    final match = _parentContextRegex.firstMatch(context);
    if (match != null) return match.group(1);
    return _parentInfoRegex.firstMatch(widgetInfo)?.group(1);
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
    final match = _pixelsRegex.firstMatch(error);
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
