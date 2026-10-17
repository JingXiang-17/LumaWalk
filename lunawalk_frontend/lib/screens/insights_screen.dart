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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6.0, 6.0, 6.0, 4.0),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: AppColors.primaryGold.withOpacity(0.85),
                width: 2.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryGold.withOpacity(0.35),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Starlight Corner Accents
                Positioned(
                    top: 12,
                    left: 12,
                    child: Icon(Icons.auto_awesome,
                        color: AppColors.primaryGold.withOpacity(0.8),
                        size: 18)),
                Positioned(
                    top: 12,
                    right: 12,
                    child: Icon(Icons.auto_awesome,
                        color: AppColors.primaryGold.withOpacity(0.8),
                        size: 18)),
                Positioned(
                    bottom: 12,
                    left: 12,
                    child: Icon(Icons.auto_awesome,
                        color: AppColors.primaryGold.withOpacity(0.8),
                        size: 18)),
                Positioned(
                    bottom: 12,
                    right: 12,
                    child: Icon(Icons.auto_awesome,
                        color: AppColors.primaryGold.withOpacity(0.8),
                        size: 18)),

                // Main Scrollable Content
                Positioned.fill(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18.0, vertical: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        const Text(
                          "Community Insights",
                          style: TextStyle(
                            color: AppColors.primaryGold,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(height: 18),

                        // SIMULATION ONLY: ENVIRONMENTAL INJECTION
                        if (telemetry.isSimulationMode) ...[
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGold.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: AppColors.primaryGold, width: 1.5),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.science,
                                        color: AppColors.primaryGold, size: 20),
                                    SizedBox(width: 8),
                                    Text("Simulation Tools: Data Injection",
                                        style: TextStyle(
                                            color: AppColors.primaryGold,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14)),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  height: 38,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            AppColors.inputBackground,
                                        side: const BorderSide(
                                            color: Colors.amber)),
                                    onPressed: () {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                              content: Text(
                                                  "Simulated: Localized power failure reported. Weight matrix recalculated.",
                                                  style: TextStyle(
                                                      fontSize: 12))));
                                    },
                                    icon: const Icon(Icons.flash_off,
                                        color: Colors.amber, size: 16),
                                    label: const Text(
                                        "Inject Mass Lighting Failure",
                                        style: TextStyle(
                                            color: Colors.amber, fontSize: 12)),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  height: 38,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            AppColors.inputBackground,
                                        side: const BorderSide(
                                            color: Colors.cyanAccent)),
                                    onPressed: () {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                              content: Text(
                                                  "Simulated: Time advanced to 3:00 AM. Crowd density weights lowered.",
                                                  style: TextStyle(
                                                      fontSize: 12))));
                                    },
                                    icon: const Icon(Icons.nightlight_round,
                                        color: Colors.cyanAccent, size: 16),
                                    label: const Text(
                                        "Simulate Time: 3:00 AM Shift",
                                        style: TextStyle(
                                            color: Colors.cyanAccent,
                                            fontSize: 12)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Safety Score Metric
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.inputBackground,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: AppColors.primaryGold.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: const BoxDecoration(
                                  color: AppColors.routeSafe,
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Text("94%",
                                      style: TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16)),
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Campus Safety Index",
                                        style: TextStyle(
                                            color: AppColors.primaryGold,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15)),
                                    SizedBox(height: 4),
                                    Text(
                                        "Optimal lighting & high patrol density on primary routes.",
                                        style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 12)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Live Layer Controls
                        const Text("Live Layer Controls",
                            style: TextStyle(
                                color: AppColors.textMain,
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                        const SizedBox(height: 10),

                        SwitchListTile(
                          value: telemetry.showLightingOverlay,
                          onChanged: (val) =>
                              telemetry.toggleLightingOverlay(val),
                          activeColor: AppColors.primaryGold,
                          title: const Text("Lighting Infrastructure Layer",
                              style: TextStyle(
                                  color: AppColors.textMain, fontSize: 14)),
                          subtitle: const Text(
                              "Display smart lamp coverage intensity",
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11)),
                        ),
                        SwitchListTile(
                          value: telemetry.showCrowdOverlay,
                          onChanged: (val) => telemetry.toggleCrowdOverlay(val),
                          activeColor: AppColors.primaryGold,
                          title: const Text("Crowd Activity Heatmap",
                              style: TextStyle(
                                  color: AppColors.textMain, fontSize: 14)),
                          subtitle: const Text(
                              "Display anonymous pedestrian density streams",
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11)),
                        ),
                        const SizedBox(height: 20),

                        // Recent Reports Feed
                        const Text("Recent Reports Feed",
                            style: TextStyle(
                                color: AppColors.textMain,
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                        const SizedBox(height: 10),

                        _buildReportCard(
                            icon: Icons.lightbulb_outline,
                            title: "Dim Streetlight Reported",
                            time: "10 mins ago • Science Quad",
                            status: "In Progress",
                            statusColor: Colors.amber),
                        const SizedBox(height: 10),
                        _buildReportCard(
                            icon: Icons.construction,
                            title: "Pathway Obstacle Cleared",
                            time: "45 mins ago • Library West Walkway",
                            status: "Resolved",
                            statusColor: AppColors.routeSafe),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReportCard(
      {required IconData icon,
      required String title,
      required String time,
      required String status,
      required Color statusColor}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryGold.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryGold, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: AppColors.textMain,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
                const SizedBox(height: 2),
                Text(time,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor, width: 0.8),
            ),
            child: Text(status,
                style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
