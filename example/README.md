# flutter_risk_detector example

This example app demonstrates the package's development-time diagnostics:

- RenderFlex overflow detection
- rebuild storm and jank tracking
- async lifecycle risks such as `setState()` after dispose
- static lint findings for common code-quality and lifecycle issues

Run it with:

```bash
flutter run
```

The app intentionally includes risky screens. Open a scenario, trigger the issue, and check the debug console for the formatted report.

The package is debug-only at runtime. Release builds return before installing global error hooks or frame timing callbacks.
