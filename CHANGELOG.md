## 0.1.0 — 2026-05-17

### Added

**Overflow Detection**
- Detects `RenderFlex overflowed` errors via `FlutterError.onError`
- Reports best-effort widget name, parent widget, file path, line, column, overflow direction, and pixel amount
- Direction-specific fix suggestions (horizontal vs vertical)
- Skips generated `.g.dart` and framework stack frames to surface user code location

**Rebuild Storm Detection**
- `RiskRebuildTracker` widget wraps any subtree and monitors rebuild rate
- Reports storm when rebuild count exceeds configurable threshold (default: 20)
- Detects 7 cause categories: `setState` in build loop, stream flooding, ancestor propagation, Provider over-notification, AnimationController without const subtrees, object creation in build, parent setState
- Each cause maps to specific, actionable fix suggestions
- Reports throttled to once per 3 seconds to prevent log flooding
- Logs only at milestone counts (5, 10, 20, 50, 100) below the warning threshold

**Jank Detection**
- `RiskRebuildTracker` registers a `SchedulerBinding.addTimingsCallback`
- Logs any frame where `buildDuration` exceeds the configurable threshold (default: 16ms / 60fps)
- Reports build and raster duration in milliseconds
- Callback removed in `dispose()` — no memory leak

**Async Risk Detection**
- Catches `setState() called after dispose` via `FlutterError.onError`
- Catches unhandled async errors via `PlatformDispatcher.onError`
- Preserves and delegates to existing Flutter and platform error handlers
- Classifies 4 risk types: `setStateAfterDispose`, `streamNotCancelled`, `timerNotCancelled`, `futureAfterDispose`
- Each type produces a specific cause + fix message
- Public `classify()` method for custom handling

**Static Lint Analysis**
- `LintAnalyzer.analyzeDirectory()` scans all `.dart` files under a directory
- `LintAnalyzer.analyzeFile()` scans a single file
- 18 lint rules across 3 categories: code quality, memory leaks, jank/performance
- Results grouped by file, sorted by line number, with lazy-cached `byFile` map
- `filtered(LintSeverity)` to narrow results by minimum severity
- Graceful handling of permission errors and missing files via `FileSystemException` catch
- Skips `.g.dart` generated files automatically
- Default import remains safe on non-IO platforms through a no-op analyzer stub

**Configuration**
- `RiskDetectorConfig` with `copyWith`, `==`, and `hashCode`
- Configurable: `rebuildWarningThreshold`, `rebuildStormThreshold`, `jankThresholdMs`, `lintScanDirectory`
- Per-widget threshold overrides on `RiskRebuildTracker`

**Logging**
- `RiskLogger` with throttled `warning()` and `error()` methods (2-second dedup window)
- Circular in-memory buffer capped at 200 entries with timestamps
- Stale throttle entries pruned automatically to prevent unbounded map growth
- All methods are no-ops when `kDebugMode` is false

**Models**
- `OverflowResult` — const constructor, `==`, `hashCode`
- `RebuildResult` — `isStorm` snapshotted at construction, `rebuildsPerSecond` getter
- `LintIssue` — const constructor, `copyWith`, `==`, `hashCode`
- `LintResult` — single-pass severity counts, lazy-cached `byFile`, `filtered()`, immutable issues list
- `RiskResult` — `copyWith`, `==`, `hashCode`
- `RiskLevel` — 4-tier enum with icons

**Testing**
- 81 unit tests covering all analyzers, models, config, and logger
- Temp-file based integration tests for `LintAnalyzer` rules
- Edge cases: empty strings, non-existent files/directories, zero-duration windows, unmodifiable collections
