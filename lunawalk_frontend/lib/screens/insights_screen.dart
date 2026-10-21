import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/telemetry_provider.dart';
import '../theme/app_colors.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  void _showSimulationStatus(
    BuildContext context, {
    required String title,
    required bool enabled,
    required String description,
  }) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.inputBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: AppColors.primaryGold.withOpacity(0.5)),
        ),
        title: Row(
          children: [
            Icon(
              enabled ? Icons.play_circle_outline : Icons.pause_circle_outline,
              color: enabled ? AppColors.routeSafe : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                enabled ? '$title is on' : '$title is off',
                style: const TextStyle(
                  color: AppColors.primaryGold,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          description,
          style: const TextStyle(color: AppColors.textMain, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Close',
              style: TextStyle(color: AppColors.primaryGold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final telemetry = Provider.of<TelemetryProvider>(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(20),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 1. FRAME ASSET BACKGROUND (frame2.jpeg)
                  Image.asset(
                    'assets/images/frame2.jpeg',
                    fit: BoxFit.fill,
                  ),

                  // 2. INNER SCROLLABLE CONTENT (Padded away from frame borders)
                  Positioned.fill(
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 26.0,
                        vertical: 32.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),

                          // Header Title
                          const Text(
                            "Community Insights",
                            style: TextStyle(
                              color: AppColors.primaryGold,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 22),

                          // SIMULATION ONLY: ENVIRONMENTAL INJECTION (Maintained from your logic)
                          if (telemetry.isSimulationMode) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0x33121F3D),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: AppColors.primaryGold.withOpacity(0.6),
                                  width: 1.2,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(
                                        Icons.science,
                                        color: AppColors.primaryGold,
                                        size: 18,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        "Simulation Tools: Data Injection",
                                        style: TextStyle(
                                          color: AppColors.primaryGold,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFF141D32),
                                            side: const BorderSide(
                                                color: Colors.amber),
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 8),
                                          ),
                                          onPressed: () {
                                            final enabled = !telemetry
                                                .lightingFailureSimulation;
                                            telemetry
                                                .setLightingFailureSimulation(
                                                    enabled);
                                            _showSimulationStatus(
                                              context,
                                              title: 'Lighting failure',
                                              enabled: enabled,
                                              description: enabled
                                                  ? 'One or two lights on the route are marked broken. Safe route lighting and route recommendations are recalculated around the outages.'
                                                  : 'The simulated light outages are cleared and routes are recalculated.',
                                            );
                                          },
                                          icon: Icon(
                                              telemetry
                                                      .lightingFailureSimulation
                                                  ? Icons.flash_on
                                                  : Icons.flash_off,
                                              color: Colors.amber,
                                              size: 14),
                                          label: Text(
                                            telemetry.lightingFailureSimulation
                                                ? "Failure Active"
                                                : "Lighting Failure",
                                            style: const TextStyle(
                                                color: Colors.amber,
                                                fontSize: 11),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFF141D32),
                                            side: const BorderSide(
                                                color: Colors.cyanAccent),
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 8),
                                          ),
                                          onPressed: () {
                                            final enabled =
                                                !telemetry.nightShiftSimulation;
                                            telemetry.setNightShiftSimulation(
                                                enabled);
                                            _showSimulationStatus(
                                              context,
                                              title: '3:00 AM shift',
                                              enabled: enabled,
                                              description: enabled
                                                  ? 'The 3:00 AM scenario is active in this demo. It does not currently change live traffic or backend route data.'
                                                  : 'The 3:00 AM scenario has been turned off.',
                                            );
                                          },
                                          icon: const Icon(
                                              Icons.nightlight_round,
                                              color: Colors.cyanAccent,
                                              size: 14),
                                          label: Text(
                                            telemetry.nightShiftSimulation
                                                ? "3 AM Active"
                                                : "3:00 AM Shift",
                                            style: const TextStyle(
                                                color: Colors.cyanAccent,
                                                fontSize: 11),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // 1. SAFE-ROUTE LIGHTING COVERAGE
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Radial Glowing Meter
                              SizedBox(
                                width: 110,
                                height: 110,
                                child: _GlowingSafetyGauge(
                                  percentage:
                                      telemetry.safeRoute?.lightingScore,
                                ),
                              ),
                              const SizedBox(width: 18),

                              // Text Description
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "SAFE-ROUTE\nLIGHTING",
                                      style: TextStyle(
                                        color: AppColors.primaryGold,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.8,
                                        height: 1.15,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      telemetry.safeRoute == null
                                          ? telemetry.routeError == null
                                              ? "Choose a destination to calculate route lighting from the backend."
                                              : "Route lighting is unavailable until the backend reconnects."
                                          : telemetry.lightingFailureSimulation
                                              ? "${telemetry.failedLightingPoints.length} simulated light outage(s). Coverage shows the lit share of the recommended Safe route."
                                              : "Coverage is the share of recommended Safe-route distance marked lit by the routing network.",
                                      style: TextStyle(
                                        color: AppColors.textSecondary
                                            .withOpacity(0.9),
                                        fontSize: 12,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // 2. LIVE LAYER CONTROLS (Glassmorphic card with decorative header)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              color: const Color(0x33121F3D),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.primaryGold.withOpacity(0.4),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      "Live Layer Controls",
                                      style: TextStyle(
                                        color: AppColors.primaryGold,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Icon(
                                      Icons.keyboard_arrow_up,
                                      color: AppColors.primaryGold
                                          .withOpacity(0.8),
                                      size: 18,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Lighting Layer Switch
                                _buildLayerSwitchRow(
                                  title: "Lighting Infrastructure Layer",
                                  subtitle:
                                      "Display smart lamp coverage intensity",
                                  icon: Icons.wb_incandescent_outlined,
                                  value: telemetry.showLightingOverlay,
                                  onChanged: telemetry.toggleLightingOverlay,
                                ),
                                const Divider(
                                  color: Color(0x22F2DF99),
                                  height: 20,
                                  thickness: 1,
                                ),

                                // Crowd Activity Heatmap Switch
                                _buildLayerSwitchRow(
                                  title: "Crowd Activity Heatmap",
                                  subtitle:
                                      "Show sample pedestrian density along the route",
                                  icon: Icons.groups_outlined,
                                  value: telemetry.showCrowdOverlay,
                                  onChanged: telemetry.toggleCrowdOverlay,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // 3. RECENT REPORTS
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Reports",
                                style: TextStyle(
                                  color: AppColors.primaryGold,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Icon(
                                Icons.near_me,
                                color: AppColors.primaryGold.withOpacity(0.8),
                                size: 16,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Recent community safety reports',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (telemetry.hazardReports.isEmpty)
                            _buildReportCard(
                              icon: Icons.info_outline,
                              iconColor: AppColors.textSecondary,
                              title: 'No reports submitted yet',
                              timeAndLocation:
                                  'Use Report Hazard on the Support page to add one.',
                              status: 'Community',
                              statusColor: AppColors.textSecondary,
                              glowColor: Colors.transparent,
                            ),
                          for (final report in telemetry.hazardReports) ...[
                            _buildReportCard(
                              icon: Icons.warning_amber_rounded,
                              iconColor: Colors.amber,
                              title: '${report.category} reported',
                              timeAndLocation:
                                  '${report.ageLabel} • ${report.description.isEmpty ? report.locationLabel : '${report.description} • ${report.locationLabel}'}',
                              status: 'New',
                              statusColor: Colors.amber,
                              glowColor: Colors.amber.withOpacity(0.12),
                            ),
                            const SizedBox(height: 10),
                          ],

                          // Sample community reports
                          _buildReportCard(
                            icon: Icons.lightbulb_outline,
                            iconColor: AppColors.primaryGold,
                            title: "Dim Streetlight Reported",
                            timeAndLocation: "10 mins ago • Science Quad",
                            status: "In Progress",
                            statusColor: Colors.amber,
                            glowColor: Colors.amber.withOpacity(0.2),
                          ),
                          const SizedBox(height: 12),

                          // Report 2: Pathway Obstacle Cleared
                          _buildReportCard(
                            icon: Icons.build_outlined,
                            iconColor: Colors.cyanAccent,
                            title: "Pathway Obstacle Cleared",
                            timeAndLocation:
                                "45 mins ago • Library West Walkway",
                            status: "Resolved",
                            statusColor: Colors.cyanAccent,
                            glowColor: Colors.cyanAccent.withOpacity(0.18),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLayerSwitchRow({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textMain,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),

        // Custom Celestial Moon Toggle
        GestureDetector(
          onTap: () => onChanged(!value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 48,
            height: 26,
            padding: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              color: value
                  ? AppColors.primaryGold.withOpacity(0.85)
                  : const Color(0x33AFA7CE),
              border: Border.all(
                color: value ? AppColors.primaryGold : Colors.white24,
                width: 1.2,
              ),
            ),
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF1E1547),
              ),
              child: Icon(
                value ? Icons.nightlight_round : Icons.dark_mode_outlined,
                color: value ? AppColors.primaryGold : Colors.white54,
                size: 12,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Icon(
          icon,
          color: AppColors.primaryGold,
          size: 18,
        ),
      ],
    );
  }

  Widget _buildReportCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String timeAndLocation,
    required String status,
    required Color statusColor,
    required Color glowColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0x2E121F3D),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: statusColor.withOpacity(0.55),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: glowColor,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textMain,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  timeAndLocation,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Status Badge Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: statusColor,
                width: 1.0,
              ),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

}

/// Custom painter rendering the glowing gradient circular radial gauge
class _GlowingSafetyGauge extends StatelessWidget {
  final double? percentage;

  const _GlowingSafetyGauge({required this.percentage});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GaugePainter(percentage: percentage),
      child: Center(
        child: Container(
          width: 74,
          height: 74,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFE2C979),
                Color(0xFF86E2D5),
                Color(0xFF4EE2D0),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.cyanAccent.withOpacity(0.4),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Text(
              percentage == null ? '--' : "${(percentage! * 100).round()}%",
              style: const TextStyle(
                color: Color(0xFF0C192E),
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double? percentage;
  _GaugePainter({required this.percentage});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Track arc
    final trackPaint = Paint()
      ..color = const Color(0x334EE2D0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Glowing active progress arc
    final progressPaint = Paint()
      ..shader = const SweepGradient(
        colors: [
          Colors.cyanAccent,
          Color(0xFF4EE2D0),
          Color(0xFFF2DF99),
          Colors.cyanAccent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;

    final sweepAngle =
        (2 * math.pi * (percentage ?? 0).clamp(0.0, 1.0)).toDouble();
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) =>
      oldDelegate.percentage != percentage;
}
