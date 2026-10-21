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
          side: BorderSide(color: AppColors.primaryGold.withOpacity(0.6)),
        ),
        title: const Text(
          "Log Out",
          style: TextStyle(
            color: AppColors.primaryGold,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          "Are you sure you want to log out of LumaWalk?",
          style: TextStyle(color: AppColors.textMain, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              "Cancel",
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(ctx);
              if (onLogout != null) {
                onLogout!();
              }
            },
            child: const Text(
              "Log Out",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(
    BuildContext context,
    TelemetryProvider telemetry,
  ) {
    final nameController = TextEditingController(text: telemetry.userName);
    final idController = TextEditingController(text: telemetry.studentId);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.inputBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: AppColors.primaryGold.withOpacity(0.6)),
        ),
        title: const Row(
          children: [
            Icon(Icons.edit_note, color: AppColors.primaryGold),
            SizedBox(width: 8),
            Text(
              "Edit Profile",
              style: TextStyle(
                color: AppColors.primaryGold,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
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
                    width: 74,
                    height: 74,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.background,
                      border: Border.all(
                        color: AppColors.primaryGold,
                        width: 1.5,
                      ),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/logo_b.jpeg',
                        fit: BoxFit.cover,
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
                            content: Text("Profile avatar updated!"),
                          ),
                        );
                      },
                      child: const CircleAvatar(
                        radius: 12,
                        backgroundColor: AppColors.primaryGold,
                        child: Icon(
                          Icons.camera_alt,
                          size: 12,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "User Name",
              style: TextStyle(color: AppColors.textMain, fontSize: 12),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: nameController,
              style: const TextStyle(color: AppColors.textMain),
              decoration: InputDecoration(
                filled: true,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Student / User ID",
              style: TextStyle(color: AppColors.textMain, fontSize: 12),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: idController,
              style: const TextStyle(color: AppColors.textMain),
              decoration: InputDecoration(
                filled: true,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              "Cancel",
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGold,
            ),
            onPressed: () {
              telemetry.updateProfileInfo(
                nameController.text,
                idController.text,
              );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Profile details updated successfully."),
                ),
              );
            },
            child: const Text(
              "Save",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _editEmergencyPhone(
    BuildContext context,
    TelemetryProvider telemetry,
  ) {
    final phoneController = TextEditingController(text: telemetry.phoneNumber);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.inputBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.primaryGold.withOpacity(0.6)),
        ),
        title: const Text(
          "Linked Emergency Phone",
          style: TextStyle(
            color: AppColors.primaryGold,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
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
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              "Cancel",
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGold,
            ),
            onPressed: () {
              telemetry.updatePhoneNumber(phoneController.text);
              Navigator.pop(ctx);
            },
            child: const Text(
              "Update",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _selectLocationSharingMode(
    BuildContext context,
    TelemetryProvider telemetry,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        backgroundColor: AppColors.inputBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.primaryGold.withOpacity(0.6)),
        ),
        title: const Text(
          "Privacy & Location Sharing",
          style: TextStyle(
            color: AppColors.primaryGold,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        children: [
          "Active during night journeys only",
          "Always ON during active SOS",
          "Only when Virtual Buddy is active",
        ].map((option) {
          return SimpleDialogOption(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 12,
            ),
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
                    : FontWeight.normal,
              ),
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
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4.0, 4.0, 4.0, 4.0),
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

                  // 2. INNER CONTENT SHIFTED UP TO CLEAR BOTTOM BORDER
                  Positioned.fill(
                    child: Padding(
                      // Top 14 and bottom 28 ensure everything fits well above frame lines
                      padding:
                          const EdgeInsets.fromLTRB(25.0, 14.0, 25.0, 28.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Title & Edit Profile Button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Settings & Profile",
                                style: TextStyle(
                                  color: AppColors.primaryGold,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 21,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                icon: const Icon(
                                  Icons.edit_outlined,
                                  color: AppColors.primaryGold,
                                  size: 19,
                                ),
                                tooltip: "Edit Profile",
                                onPressed: () =>
                                    _showEditProfileDialog(context, telemetry),
                              ),
                            ],
                          ),

                          // USER PROFILE AVATAR SECTION
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 76,
                                  height: 76,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFFFE8A3),
                                        Color(0xFFC8972E),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primaryGold
                                            .withOpacity(0.4),
                                        blurRadius: 12,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(2.5),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.background,
                                    ),
                                    child: ClipOval(
                                      child: Image.asset(
                                        'assets/images/logo_b.jpeg',
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  telemetry.userName,
                                  style: const TextStyle(
                                    color: AppColors.textMain,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  "ID: ${telemetry.studentId}",
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // SECTION 1: EMERGENCY PREFERENCES
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                "Emergency Preferences",
                                style: TextStyle(
                                  color: AppColors.primaryGold,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.5,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: () =>
                                    _editEmergencyPhone(context, telemetry),
                                borderRadius: BorderRadius.circular(12),
                                child: _buildSettingTile(
                                  icon: Icons.phone_android_outlined,
                                  title: "Linked Emergency Phone",
                                  subtitle: telemetry.phoneNumber,
                                ),
                              ),
                              const SizedBox(height: 6),
                              _buildSwitchTile(
                                icon: Icons.notifications_outlined,
                                title: "Push Safety Alerts",
                                subtitle: telemetry.pushAlertsEnabled
                                    ? "Enabled (Instant dispatch)"
                                    : "Disabled",
                                value: telemetry.pushAlertsEnabled,
                                onChanged: (_) => telemetry.togglePushAlerts(),
                              ),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: () => _selectLocationSharingMode(
                                  context,
                                  telemetry,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                child: _buildSettingTile(
                                  icon: Icons.security_outlined,
                                  title: "Privacy & Location Sharing",
                                  subtitle: telemetry.locationSharingSetting,
                                ),
                              ),
                            ],
                          ),

                          // SECTION 2: SMART ROUTING PREFERENCES
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                "Routing & Safety Engine",
                                style: TextStyle(
                                  color: AppColors.primaryGold,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.5,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 6),
                              _buildSwitchTile(
                                icon: Icons.lightbulb_outline,
                                title: "Avoid Unlit Alleys",
                                subtitle:
                                    "Prioritize paths with verified smart lighting",
                                value: telemetry.avoidUnlitAlleys,
                                onChanged: (_) =>
                                    telemetry.toggleAvoidUnlitAlleys(),
                              ),
                              const SizedBox(height: 6),
                              _buildSwitchTile(
                                icon: Icons.shield_outlined,
                                title: "Prioritize Class A Havens",
                                subtitle:
                                    "Favor paths adjacent to 24/7 security desks",
                                value: telemetry.preferClassAHavens,
                                onChanged: (val) =>
                                    telemetry.setPreferClassAHavens(val),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0x28121F3D),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color:
                                        AppColors.primaryGold.withOpacity(0.25),
                                    width: 0.9,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle_outline,
                                      color: AppColors.routeSafe,
                                      size: 17,
                                    ),
                                    const SizedBox(width: 9),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            "Petaling Jaya Safe Havens Cache",
                                            style: TextStyle(
                                              color: AppColors.textMain,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                            ),
                                          ),
                                          Text(
                                            "OSM walking network • Offline Ready",
                                            style: TextStyle(
                                              color: AppColors.textSecondary
                                                  .withOpacity(0.8),
                                              fontSize: 9.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          // LOG OUT BUTTON (Clearly above bottom border line)
                          SizedBox(
                            width: double.infinity,
                            height: 42,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Colors.redAccent,
                                  width: 1.3,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                backgroundColor:
                                    Colors.redAccent.withOpacity(0.08),
                                padding: EdgeInsets.zero,
                              ),
                              onPressed: () => _confirmLogout(context),
                              icon: const Icon(
                                Icons.logout,
                                color: Colors.redAccent,
                                size: 17,
                              ),
                              label: const Text(
                                "Log Out",
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
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

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0x38121F3D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryGold.withOpacity(0.35),
          width: 0.9,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryGold, size: 19),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textMain,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 9.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios,
            color: AppColors.textSecondary,
            size: 11,
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x38121F3D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryGold.withOpacity(0.35),
          width: 0.9,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryGold, size: 19),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textMain,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 9.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: AppColors.primaryGold,
            activeTrackColor: AppColors.primaryGold.withOpacity(0.4),
            inactiveThumbColor: AppColors.textSecondary,
            inactiveTrackColor: Colors.black26,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
