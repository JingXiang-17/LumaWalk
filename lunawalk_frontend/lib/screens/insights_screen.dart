import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/telemetry_provider.dart';
import '../theme/app_colors.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

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
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  "Simulated: Power failure reported. Safety weights recalculated.",
                                                  style:
                                                      TextStyle(fontSize: 12),
                                                ),
                                              ),
                                            );
                                          },
                                          icon: const Icon(Icons.flash_off,
                                              color: Colors.amber, size: 14),
                                          label: const Text(
                                            "Lighting Failure",
                                            style: TextStyle(
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
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  "Simulated: Time shifted to 3:00 AM.",
                                                  style:
                                                      TextStyle(fontSize: 12),
                                                ),
                                              ),
                                            );
                                          },
                                          icon: const Icon(
                                              Icons.nightlight_round,
                                              color: Colors.cyanAccent,
                                              size: 14),
                                          label: const Text(
                                            "3:00 AM Shift",
                                            style: TextStyle(
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

                          // 1. CAMPUS SAFETY INDEX WITH GLOWING RADIAL NEON GAUGE
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Radial Glowing Meter
                              const SizedBox(
                                width: 110,
                                height: 110,
                                child: _GlowingSafetyGauge(percentage: 0.94),
                              ),
                              const SizedBox(width: 18),

                              // Text Description
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "CAMPUS\nSAFETY INDEX",
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
                                      "Optimal lighting & high patrol density on primary routes",
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
                                  onChanged: (val) =>
                                      telemetry.toggleLightingOverlay(val),
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
                                      "Display anonymous pedestrian density streams",
                                  icon: Icons.groups_outlined,
                                  value: telemetry.showCrowdOverlay,
                                  onChanged: (val) =>
                                      telemetry.toggleCrowdOverlay(val),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // 3. RECENT REPORTS FEED
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Recent Reports Feed",
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
                          const SizedBox(height: 12),

                          // Report 1: Dim Streetlight
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
  final double percentage;

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
              "${(percentage * 100).toInt()}%",
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
  final double percentage;
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

    final sweepAngle = 2 * math.pi * percentage;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
