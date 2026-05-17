import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_risk_detector/flutter_risk_detector.dart';

import 'screens/async_risk_screen.dart';
import 'screens/home_screen.dart';
import 'screens/lint_test_screen.dart';
import 'screens/memory_leak_screen.dart';
import 'screens/overflow_test_screen.dart';
import 'screens/rebuild_test_screen.dart';

const _riskDetectorConfig = RiskDetectorConfig(
  detectOverflows: true,
  detectAsyncRisks: true,
  detectRebuilds: true,
  detectLintIssues: true,
  lintScanDirectory: 'lib',
);

void main() {
  runZonedGuarded<void>(
    () {
      WidgetsFlutterBinding.ensureInitialized();
      ErrorCapture.initialize(config: _riskDetectorConfig);
      runApp(const RiskDetectorExampleApp());
    },
    (error, stackTrace) {
      RiskLogger.error('Unhandled app exception: $error');
    },
  );
}

class RiskDetectorExampleApp extends StatelessWidget {
  const RiskDetectorExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return _AppErrorView(details: details);
    };

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

class _AppErrorView extends StatelessWidget {
  const _AppErrorView({required this.details});

  final FlutterErrorDetails details;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                color: Theme.of(context).colorScheme.onErrorContainer,
                size: 40,
              ),
              const SizedBox(height: 12),
              Text(
                'Something went wrong',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                details.exceptionAsString(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
