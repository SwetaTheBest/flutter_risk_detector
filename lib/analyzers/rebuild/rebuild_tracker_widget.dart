import 'package:flutter/material.dart';

class RiskRebuildTracker extends StatefulWidget {
  final Widget child;
  final String tag;

  const RiskRebuildTracker({required this.child, required this.tag, super.key});

  @override
  State<RiskRebuildTracker> createState() => _RiskRebuildTrackerState();
}

class _RiskRebuildTrackerState extends State<RiskRebuildTracker> {
  int rebuildCount = 0;

  @override
  Widget build(BuildContext context) {
    rebuildCount++;

    debugPrint('🔄 ${widget.tag} rebuilt $rebuildCount times');

    if (rebuildCount > 20) {
      debugPrint('⚠ POSSIBLE REBUILD STORM DETECTED in ${widget.tag}');
    }

    return widget.child;
  }
}
