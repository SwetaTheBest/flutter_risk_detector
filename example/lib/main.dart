import 'package:flutter/material.dart';
import 'package:flutter_risk_detector/flutter_risk_detector.dart';

void main() {
  ErrorCapture.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Risk Detector Demo',
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() =>
      _HomeScreenState();
}

class _HomeScreenState
    extends State<HomeScreen> {
  int counter = 0;

  @override
  Widget build(BuildContext context) {
    return RiskRebuildTracker(
      tag: 'HomeScreen',
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Risk Detector Demo',
          ),
        ),
        body: Column(
          children: [
            ElevatedButton(
              onPressed: () {
                setState(() {
                  counter++;
                });
              },
              child: const Text(
                'Trigger Rebuild',
              ),
            ),

            // Intentional overflow
            Row(
              children: [
                Expanded(
                  child: Container(
                    width: 500,
                    height: 50,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}