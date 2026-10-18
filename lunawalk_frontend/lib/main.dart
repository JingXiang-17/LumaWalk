import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/telemetry_provider.dart';
import 'screens/split_dashboard.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TelemetryProvider(),
      child: const LumaWalkDemo(),
    );
  }
}

class LumaWalkDemo extends StatelessWidget {
  const LumaWalkDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LumaWalk Web Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Roboto'),
      home: const SplitDashboard(),
    );
  }
}
