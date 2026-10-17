import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/telemetry_provider.dart';
import '../theme/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  final VoidCallback? onLogout;

  const SettingsScreen({super.key, this.onLogout});

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.inputBackground,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.primaryGold.withOpacity(0.6))),
        title: const Text("Log Out",
            style: TextStyle(
                color: AppColors.primaryGold, fontWeight: FontWeight.bold)),
        content: const Text("Are you sure you want to log out?",
            style: TextStyle(color: AppColors.textMain, fontSize: 14)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel",
                  style: TextStyle(color: AppColors.textSecondary))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(ctx);
              if (onLogout != null) {
                onLogout!();
              }
            },
            child: const Text("Logout",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(
      BuildContext context, TelemetryProvider telemetry) {
    final nameController = TextEditingController(text: telemetry.userName);
    final idController = TextEditingController(text: telemetry.studentId);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.inputBackground,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: AppColors.primaryGold.withOpacity(0.6))),
        title: const Row(
          children: [
            Icon(Icons.edit_note, color: AppColors.primaryGold),
            SizedBox(width: 8),
            Text("Edit Profile",
                style: TextStyle(
                    color: AppColors.primaryGold,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.background,
                        border: Border.all(
                            color: AppColors.primaryGold, width: 1.5)),
                    child: ClipOval(
                      child: ColorFiltered(
                        colorFilter: const ColorFilter.matrix(<double>[
                          0.2126,
                          0.7152,
                          0.0722,
                          0,
                          0,
                          0.2126,
                          0.7152,
                          0.0722,
                          0,
                          0,
                          0.2126,
                          0.7152,
                          0.0722,
                          0,
                          0,
                          0,
                          0,
                          0,
                          1,
                          0
                        ]),
                        child: Image.asset('assets/images/logo.png',
                            fit: BoxFit.cover),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Profile avatar updated!")));
                      },
                      child: const CircleAvatar(
                          radius: 12,
                          backgroundColor: AppColors.primaryGold,
                          child: Icon(Icons.camera_alt,
                              size: 12, color: Colors.black)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text("User Name",
                style: TextStyle(color: AppColors.textMain, fontSize: 12)),
            const SizedBox(height: 4),
            TextField(
                controller: nameController,
                style: const TextStyle(color: AppColors.textMain),
                decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none))),
            const SizedBox(height: 12),
            const Text("Student / User ID",
                style: TextStyle(color: AppColors.textMain, fontSize: 12)),
            const SizedBox(height: 4),
            TextField(
                controller: idController,
                style: const TextStyle(color: AppColors.textMain),
                decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none))),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel",
                  style: TextStyle(color: AppColors.textSecondary))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGold),
            onPressed: () {
              telemetry.updateProfileInfo(
                  nameController.text, idController.text);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text("Profile details updated successfully.")));
            },
            child: const Text("Save",
                style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _editEmergencyPhone(BuildContext context, TelemetryProvider telemetry) {
    final phoneController = TextEditingController(text: telemetry.phoneNumber);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.inputBackground,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.primaryGold.withOpacity(0.6))),
        title: const Text("Linked Emergency Phone",
            style: TextStyle(
                color: AppColors.primaryGold,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        content: TextField(
          controller: phoneController,
          style: const TextStyle(color: AppColors.textMain),
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.background,
              hintText: "+60 12-345 6789",
              hintStyle: const TextStyle(color: AppColors.textSecondary),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none)),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel",
                  style: TextStyle(color: AppColors.textSecondary))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGold),
            onPressed: () {
              telemetry.updatePhoneNumber(phoneController.text);
              Navigator.pop(ctx);
            },
            child: const Text("Update",
                style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _selectLocationSharingMode(
      BuildContext context, TelemetryProvider telemetry) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        backgroundColor: AppColors.inputBackground,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.primaryGold.withOpacity(0.6))),
        title: const Text("Privacy & Location Sharing",
            style: TextStyle(
                color: AppColors.primaryGold,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        children: [
          "Active during night journeys only",
          "Always ON during active SOS",
          "Only when Virtual Buddy is active",
        ].map((option) {
          return SimpleDialogOption(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            onPressed: () {
              telemetry.setLocationSharingSetting(option);
              Navigator.pop(ctx);
            },
            child: Text(
              option,
              style: TextStyle(
                  color: telemetry.locationSharingSetting == option
                      ? AppColors.primaryGold
                      : AppColors.textMain,
                  fontWeight: telemetry.locationSharingSetting == option
                      ? FontWeight.bold
                      : FontWeight.normal),
            ),
          );
        }).toList(),
      ),
    );
  }

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
                  color: AppColors.primaryGold.withOpacity(0.85), width: 2.0),
              boxShadow: [
                BoxShadow(
                    color: AppColors.primaryGold.withOpacity(0.35),
                    blurRadius: 20,
                    spreadRadius: 2)
              ],
            ),
            child: Stack(
              children: [
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
                Positioned.fill(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18.0, vertical: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Settings & Profile",
                                style: TextStyle(
                                    color: AppColors.primaryGold,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 22)),
                            IconButton(
                              icon: const Icon(Icons.edit,
                                  color: AppColors.primaryGold, size: 22),
                              tooltip: "Edit Profile",
                              onPressed: () =>
                                  _showEditProfileDialog(context, telemetry),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // USER PROFILE SECTION
                        Center(
                          child: Column(
                            children: [
                              Container(
                                width: 85,
                                height: 85,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.inputBackground,
                                  border: Border.all(
                                      color: AppColors.primaryGold
                                          .withOpacity(0.6),
                                      width: 2),
                                ),
                                child: ClipOval(
                                  child: ColorFiltered(
                                    colorFilter:
                                        const ColorFilter.matrix(<double>[
                                      0.2126,
                                      0.7152,
                                      0.0722,
                                      0,
                                      0,
                                      0.2126,
                                      0.7152,
                                      0.0722,
                                      0,
                                      0,
                                      0.2126,
                                      0.7152,
                                      0.0722,
                                      0,
                                      0,
                                      0,
                                      0,
                                      0,
                                      1,
                                      0
                                    ]),
                                    child: Image.asset('assets/images/logo.png',
                                        fit: BoxFit.cover),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(telemetry.userName,
                                  style: const TextStyle(
                                      color: AppColors.textMain,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              Text("ID: ${telemetry.studentId}",
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // SIMULATION ONLY: ALGORITHM TUNING
                        if (telemetry.isSimulationMode) ...[
                          const Text("Algorithm Tuning (Sim Mode)",
                              style: TextStyle(
                                  color: AppColors.textMain,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15)),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                                color: AppColors.inputBackground,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: AppColors.primaryGold
                                        .withOpacity(0.2))),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text("Max Detour Allowance",
                                        style: TextStyle(
                                            color: AppColors.textMain,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold)),
                                    Text("${telemetry.detourCapPct}%",
                                        style: const TextStyle(
                                            color: AppColors.primaryGold,
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                Slider(
                                  value: telemetry.detourCapPct.toDouble(),
                                  min: 5,
                                  max: 50,
                                  divisions: 9,
                                  activeColor: AppColors.primaryGold,
                                  inactiveColor:
                                      AppColors.primaryGold.withOpacity(0.2),
                                  onChanged: (val) =>
                                      telemetry.setDetourCap(val.toInt()),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          SwitchListTile(
                            value: telemetry.preferClassAHavens,
                            onChanged: (val) =>
                                telemetry.setPreferClassAHavens(val),
                            activeColor: AppColors.primaryGold,
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                    color: AppColors.primaryGold
                                        .withOpacity(0.2))),
                            tileColor: AppColors.inputBackground,
                            title: const Text("Prioritize Class A Havens",
                                style: TextStyle(
                                    color: AppColors.textMain,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold)),
                            subtitle: const Text(
                                "Force routes near 24/7 monitored locations.",
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 11)),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // EMERGENCY PREFERENCES
                        const Text("Emergency Preferences",
                            style: TextStyle(
                                color: AppColors.textMain,
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                        const SizedBox(height: 10),

                        InkWell(
                          onTap: () => _editEmergencyPhone(context, telemetry),
                          borderRadius: BorderRadius.circular(12),
                          child: _buildSettingTile(
                              icon: Icons.phone_android,
                              title: "Linked Emergency Phone",
                              subtitle: telemetry.phoneNumber),
                        ),
                        const SizedBox(height: 10),

                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                              color: AppColors.inputBackground,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color:
                                      AppColors.primaryGold.withOpacity(0.2))),
                          child: Row(
                            children: [
                              const Icon(Icons.notifications,
                                  color: AppColors.primaryGold, size: 22),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("Push Safety Alerts",
                                        style: TextStyle(
                                            color: AppColors.textMain,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13)),
                                    Text(
                                        telemetry.pushAlertsEnabled
                                            ? "Enabled"
                                            : "Disabled",
                                        style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 11)),
                                  ],
                                ),
                              ),
                              Switch(
                                  value: telemetry.pushAlertsEnabled,
                                  activeColor: AppColors.primaryGold,
                                  onChanged: (val) =>
                                      telemetry.togglePushAlerts()),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),

                        InkWell(
                          onTap: () =>
                              _selectLocationSharingMode(context, telemetry),
                          borderRadius: BorderRadius.circular(12),
                          child: _buildSettingTile(
                              icon: Icons.security,
                              title: "Privacy & Location Sharing",
                              subtitle: telemetry.locationSharingSetting),
                        ),
                        const SizedBox(height: 32),

                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                    color: Colors.redAccent, width: 1.5),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14))),
                            onPressed: () => _confirmLogout(context),
                            icon: const Icon(Icons.logout,
                                color: Colors.redAccent, size: 18),
                            label: const Text("Log Out",
                                style: TextStyle(
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)),
                          ),
                        ),
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

  Widget _buildSettingTile(
      {required IconData icon,
      required String title,
      required String subtitle}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryGold.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryGold, size: 22),
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
                Text(subtitle,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios,
              color: AppColors.textSecondary, size: 14),
        ],
      ),
    );
  }
}
