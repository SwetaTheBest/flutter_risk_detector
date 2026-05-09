# flutter_risk_detector

A powerful Flutter debugging and runtime risk detection toolkit that helps identify release-mode issues, UI overflows, rebuild storms, async risks, and CI pipeline failures before they reach production.

---

## ✨ Features

✅ RenderFlex overflow detection  
✅ Release-risk analysis  
✅ Async exception tracking  
✅ Rebuild storm detection  
✅ Smart error suggestions  
✅ CI failure prediction  
✅ Lint and formatting checks  
✅ Git pre-commit validation  
✅ Debug overlay (coming soon)

---

## 🚀 Why flutter_risk_detector?

Flutter apps often behave differently in debug and release modes.

Some issues:
- only appear in release builds
- fail CI pipelines unexpectedly
- are difficult to debug
- silently affect performance

`flutter_risk_detector` helps catch these problems early during development.

---

# 📦 Installation

Add dependency:

```yaml
dependencies:
  flutter_risk_detector: latest_version
