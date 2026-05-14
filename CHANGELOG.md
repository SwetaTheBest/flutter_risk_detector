## 1.0.0

- Initial stable release
- RenderFlex overflow detection with exact widget, file, line, direction and pixel amount
- Rebuild storm detection with cause analysis and fix suggestions
- Jank detection via SchedulerBinding frame timings
- Async risk detection: setState-after-dispose, stream leaks, timer leaks, future-after-dispose
- Static lint analysis: 18 rules covering memory leaks, performance, code quality
- Configurable thresholds for rebuild warnings, storm detection, and jank sensitivity
- In-memory log buffer with throttling to prevent log flooding
- All detectors are no-ops in release builds
