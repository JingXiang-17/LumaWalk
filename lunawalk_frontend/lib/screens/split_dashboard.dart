import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/telemetry_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/mobile_app_shell.dart';

class SplitDashboard extends StatelessWidget {
  const SplitDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final telemetry = Provider.of<TelemetryProvider>(context);

    final mobilePanel = Container(
      width: 400,
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          right: BorderSide(
            color: AppColors.primaryGold.withOpacity(0.3),
            width: 2,
          ),
        ),
      ),
      child: const MobileAppShell(),
    );

    final telemetryPanel = Container(
      color: const Color(0xFF08101E),
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "LunaWalk B2B Developer Telemetry",
                        style: TextStyle(
                          color: AppColors.primaryGold,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        telemetry.isSosActive
                            ? "POST /v1/telemetry/sos-alert • Critical Broadcast Engine"
                            : "POST /v1/directions • Mock Route Preview",
                        style: TextStyle(
                          color: telemetry.isSosActive
                              ? Colors.redAccent
                              : AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.copy,
                          color: AppColors.primaryGold, size: 20),
                      tooltip: "Copy JSON Payload",
                      onPressed: () {
                        Clipboard.setData(ClipboardData(
                            text: telemetry.formattedJsonPayload));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("JSON copied to clipboard!"),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: telemetry.isSosActive
                            ? Colors.red.withOpacity(0.2)
                            : Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color:
                              telemetry.isSosActive ? Colors.red : Colors.green,
                        ),
                      ),
                      child: Text(
                        telemetry.isSosActive
                            ? "STATUS: EMERGENCY ALERT (CRITICAL)"
                            : "STATUS: 200 OK (${telemetry.lastResponseMs}ms)",
                        style: TextStyle(
                          color:
                              telemetry.isSosActive ? Colors.red : Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      "Safety Weight (α Alpha): ",
                      style: const TextStyle(
                        color: AppColors.textMain,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    telemetry.alphaSafetyWeight.toStringAsFixed(1),
                    style: const TextStyle(
                      color: AppColors.primaryGold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Slider(
                      value: telemetry.alphaSafetyWeight,
                      min: 0.0,
                      max: 5.0,
                      divisions: 50,
                      activeColor: AppColors.primaryGold,
                      inactiveColor: Colors.white24,
                      onChanged: (val) {
                        telemetry.setAlphaWeight(val);
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 240),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: telemetry.isSosActive
                      ? Colors.red.withOpacity(0.5)
                      : Colors.white12,
                  width: telemetry.isSosActive ? 1.5 : 1.0,
                ),
              ),
              child: SelectableText(
                telemetry.formattedJsonPayload,
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: telemetry.isSosActive
                      ? Colors.redAccent
                      : Colors.cyanAccent,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final useTwoColumnLayout = constraints.maxWidth >= 900;

        if (useTwoColumnLayout) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: Row(
              children: [
                mobilePanel,
                Expanded(child: telemetryPanel),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Column(
              children: [
                SizedBox(
                  height: 420,
                  child: mobilePanel,
                ),
                Expanded(child: telemetryPanel),
              ],
            ),
          ),
        );
      },
    );
  }
}
