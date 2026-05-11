import 'package:flutter/material.dart';
import 'package:flutter_risk_detector/flutter_risk_detector.dart';

import 'screens/async_risk_screen.dart';
import 'screens/home_screen.dart';
import 'screens/lint_test_screen.dart';
import 'screens/memory_leak_screen.dart';
import 'screens/overflow_test_screen.dart';
import 'screens/rebuild_test_screen.dart';

void main() {
  ErrorCapture.initialize(
    config: const RiskDetectorConfig(
      detectOverflows: true,
      detectAsyncRisks: true,
      detectRebuilds: true,
      detectLintIssues: true,
      lintScanDirectory: 'lib',
    ),
  );

  runApp(const RiskDetectorExampleApp());
}

class RiskDetectorExampleApp extends StatelessWidget {
  const RiskDetectorExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Risk Detector — Test Suite',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => const HomeScreen(),
        '/overflow': (_) => const OverflowTestScreen(),
        '/rebuild': (_) => const RebuildTestScreen(),
        '/async': (_) => const AsyncRiskScreen(),
        '/memory': (_) => const MemoryLeakScreen(),
        '/lint': (_) => const LintTestScreen(),
      },
    );
  }
}
