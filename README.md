# flutter_risk_detector

[![pub version](https://img.shields.io/pub/v/flutter_risk_detector.svg)](https://pub.dev/packages/flutter_risk_detector)
[![license](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/SwetaTheBest/flutter_risk_detector/blob/main/LICENSE)
[![flutter](https://img.shields.io/badge/flutter-%3E%3D3.10.0-blue.svg)](https://flutter.dev)

A Flutter debugging toolkit for surfacing common development-time risks: **RenderFlex overflows**, **rebuild storms**, **jank**, **async lifecycle errors**, and lightweight static lint findings.

Runtime detection is debug-only. Static lint scanning runs only when `dart:io` is available; on Flutter Web the package remains importable and the lint analyzer returns an empty result.

---

## ✨ Features

| Feature | What it detects |
|---|---|
| 🔴 Overflow detection | Best-effort widget, file, line, direction, and pixel amount |
| 🔄 Rebuild storm detection | Rebuild rate reports + likely cause suggestions |
| 🟠 Jank detection | Frame build/raster time via `SchedulerBinding` |
| ⚡ Async risk detection | `setState` after dispose and common async lifecycle errors |
| 🧠 Memory leak hints | Controllers and subscriptions not disposed in static scans |
| 🔍 Static lint analysis | 18 rules: sync I/O, hardcoded values, empty catches, and more |
| 📋 Log buffer | Throttled in-memory buffer, zero output in release builds |

---

## 📦 Installation

```yaml
dependencies:
  flutter_risk_detector: ^1.0.0
```

```bash
flutter pub get
```

---

## 🚀 Quick Start

Call `ErrorCapture.initialize()` before `runApp()`:

```dart
import 'package:flutter_risk_detector/flutter_risk_detector.dart';

void main() {
  ErrorCapture.initialize();
  runApp(const MyApp());
}
```

All detectors are enabled by default and are **automatically disabled in release builds**.

`ErrorCapture` preserves any existing `FlutterError.onError` and `PlatformDispatcher.onError` handlers, then delegates to them after recording diagnostics.

---

## 🧪 Example app

A fully working example is included in the `example/` folder. To run it:

```bash
cd example
flutter run
```

The example demonstrates overflow detection, rebuild tracking, async risk reporting, and lint scanning in a debug build.

## ✅ Testing

Run package tests from the package root:

```bash
flutter test
```

This package is designed for development-time diagnostics, so all runtime checks are active only in debug mode.

---

## ⚙️ Configuration

Customise every threshold via `RiskDetectorConfig`:

```dart
void main() {
  ErrorCapture.initialize(
    config: const RiskDetectorConfig(
      detectOverflows: true,
      detectAsyncRisks: true,
      detectRebuilds: true,
      detectLintIssues: true,
      lintScanDirectory: 'lib',   // directory to scan on startup
      rebuildWarningThreshold: 10, // rebuilds before warning
      rebuildStormThreshold: 20,   // rebuilds before storm alert
      jankThresholdMs: 16,         // ms per frame (16 = 60fps)
    ),
  );
  runApp(const MyApp());
}
```

---

## 🔴 Overflow Detection

Overflows are caught automatically via `FlutterError.onError`. Reports are best-effort because Flutter overflow messages and stack traces vary by framework version and build context:

```
⚠ OVERFLOW RISK DETECTED

Widget: Row
Parent Widget: CheckoutScreen
Overflow: 42.5px on the right side

Location: lib/screens/checkout_screen.dart:87:12

Suggestion:
Row is overflowing horizontally.
- Wrap child with Expanded or Flexible
- Use Wrap instead of Row
- Clip with overflow: TextOverflow.ellipsis for Text
```

---

## 🔄 Rebuild Storm Detection

Wrap any widget with `RiskRebuildTracker` to monitor its rebuild rate:

```dart
RiskRebuildTracker(
  tag: 'CheckoutScreen',
  child: Scaffold(...),
)
```

When rebuilds exceed the threshold, a report is printed with rate-based hints:

```
🔴 REBUILD STORM — CheckoutScreen

Rebuilds : 34 in 3s (~11.3/s)

Possible Causes:
  • setState called inside build() or initState() loop
  • Ancestor widget rebuilding and propagating down the tree

Suggestions:
  → Move setState calls to event handlers, never inside build()
  → Extract the stable subtree into a separate StatelessWidget
  → Use const constructors wherever possible
```

You can override thresholds per widget:

```dart
RiskRebuildTracker(
  tag: 'HeavyList',
  warningThreshold: 5,
  jankThresholdMs: 8, // 120fps threshold
  child: MyHeavyList(),
)
```

---

## 🟠 Jank Detection

`RiskRebuildTracker` also monitors frame timings via `SchedulerBinding`. Any frame that takes longer than `jankThresholdMs` is logged:

```
🟠 JANK [CheckoutScreen] build=34ms raster=12ms (>16ms threshold)
```

---

## ⚡ Async Risk Detection

Async errors are caught automatically via `PlatformDispatcher.onError`. Each risk type gets a specific cause and fix:

```
⚠ ASYNC RISK: setState() after dispose
  Cause : An async callback called setState() after the widget was removed.
  Fix   : Guard every setState() with:  if (!mounted) return;
  Fix   : Cancel Futures/Timers in dispose() to prevent late callbacks.
```

Detected risk types:

- `setState()` called after dispose
- `StreamSubscription` not cancelled
- `Timer` not cancelled
- `Future` completed after dispose

You can also classify errors manually:

```dart
final type = AsyncRiskAnalyzer.classify(error.toString());
if (type == AsyncRiskType.setStateAfterDispose) {
  // handle specifically
}
```

---

## 🔍 Static Lint Analysis

On startup, `LintAnalyzer` scans your `lib/` directory and reports heuristic issues with file and line numbers. This scan requires `dart:io`; on platforms without `dart:io`, `LintAnalyzer` returns an empty result instead of breaking imports.

```
🔍 LINT ANALYSIS REPORT
Errors: 3  Warnings: 2  Info: 5
──────────────────────────────────────────────────

📄 lib/screens/checkout_screen.dart
❌ [controller_not_disposed] lib/screens/checkout_screen.dart:12
  Code : TextEditingController _ctrl = TextEditingController();
  Issue: TextEditingController declared but .dispose() not found — memory leak risk
  Fix  : Override dispose() and call _ctrl.dispose()

⚠ [avoid_print] lib/screens/checkout_screen.dart:34
  Code : print('debug: $value');
  Issue: print() leaks output in release builds
  Fix  : Replace with debugPrint() or a proper logger
```

You can also run it manually and filter by severity:

```dart
final result = await LintAnalyzer.analyzeDirectory('lib');

// Only errors and warnings
final filtered = result.filtered(LintSeverity.warning);
print(filtered.formattedMessage);

// Access by file
for (final entry in result.byFile.entries) {
  print('${entry.key}: ${entry.value.length} issues');
}
```

### Lint Rules

| Rule | Severity | Description |
|---|---|---|
| `avoid_print` | ⚠ Warning | `print()` leaks in release builds |
| `prefer_const_constructors` | ℹ Info | Widget constructors missing `const` |
| `prefer_typed_declarations` | ℹ Info | `var` used instead of explicit type |
| `avoid_hardcoded_colors` | ⚠ Warning | Raw `Color(0x...)` values |
| `avoid_hardcoded_strings` | ℹ Info | Plain strings in `Text()` widgets |
| `empty_catches` | ❌ Error | Empty `catch` blocks |
| `todo_comment` | ℹ Info | Unresolved `TODO`/`FIXME` comments |
| `unawaited_futures` | ⚠ Warning | Async calls without `await` |
| `setState_after_async` | ❌ Error | `setState()` after `await` without `mounted` check |
| `missing_key_in_list` | ℹ Info | `ListView/GridView.builder` without item keys |
| `lines_longer_than_120_chars` | ℹ Info | Lines exceeding 120 characters |
| `trailing_whitespace` | ℹ Info | Trailing spaces or tabs |
| `debug_code_in_release` | ⚠ Warning | Negated `kDebugMode` check |
| `controller_not_disposed` | ❌ Error | `AnimationController`, `TextEditingController`, etc. not disposed |
| `stream_subscription_leak` | ❌ Error | `StreamSubscription` without `cancel()` |
| `timer_not_cancelled` | ❌ Error | `Timer` without `cancel()` |
| `sync_io_on_ui_thread` | ⚠ Warning | `readAsStringSync`, `jsonDecode` on UI thread |
| `context_across_async` | ❌ Error | `BuildContext` used after `await` without `mounted` check |

---

## 📋 Log Buffer

All risk events are stored in an in-memory buffer (max 200 entries) with 2-second throttling to prevent flooding:

```dart
// Read all logged events
final logs = RiskLogger.logBuffer;

// Clear the buffer
RiskLogger.clear();
```

---

## 🧪 Testing

The package ships with 81 unit tests covering every analyzer, model, and edge case:

```bash
flutter test
```

---

## 🛡 Release Safety

Runtime hooks and logs are guarded with `kDebugMode`. In release builds:

- `ErrorCapture` returns before registering global error hooks
- `RiskLogger` produces no output
- Startup lint scanning is skipped
- `LintAnalyzer` uses an IO implementation only where `dart:io` is available
- Zero performance impact on your users

---

## ⚠️ Limitations

- Diagnostics are heuristics intended for development feedback, not compiler-accurate analysis.
- Static lint scanning is regex/source based and can produce false positives or miss context-sensitive cases.
- Rebuild cause suggestions are inferred from rebuild counts and frame timing, not from a full widget-tree profiler.
- For production crash reporting, keep using tools such as Crashlytics or Sentry; this package delegates to existing handlers instead of replacing them.

---

## 📁 Package Structure

```
lib/
├── analyzers/
│   ├── async/          AsyncRiskAnalyzer, AsyncRiskType
│   ├── lint/           LintAnalyzer, LintIssue, LintResult, LintSeverity
│   ├── overflow/       OverflowAnalyzer, OverflowResult
│   └── rebuild/        RebuildAnalyzer, RebuildResult, RiskRebuildTracker
├── core/
│   ├── config.dart     RiskDetectorConfig
│   ├── detector.dart   RiskDetector
│   ├── error_capture.dart  ErrorCapture
│   └── logger.dart     RiskLogger
└── models/
    ├── risk_level.dart  RiskLevel
    └── risk_result.dart RiskResult
```

---

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Add tests for any new functionality
4. Submit a pull request

Report bugs and request features via [GitHub Issues](https://github.com/SwetaTheBest/flutter_risk_detector/issues).

---

## 📄 License

MIT License © 2026 Sweta Jain

See [LICENSE](LICENSE) for full text.
