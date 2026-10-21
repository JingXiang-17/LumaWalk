import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/telemetry_provider.dart';
import '../theme/app_colors.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  void _showReportHazardDialog(BuildContext context) {
    String selectedType = 'Poor Lighting';
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.inputBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: AppColors.primaryGold.withOpacity(0.5)),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.amber),
              SizedBox(width: 8),
              Text(
                "Report Hazard",
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
              const Text(
                "Hazard Category",
                style: TextStyle(color: AppColors.textMain, fontSize: 13),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: selectedType,
                dropdownColor: AppColors.inputBackground,
                style: const TextStyle(
                  color: AppColors.primaryGold,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: [
                  'Poor Lighting',
                  'Pathway Obstacle',
                  'Suspicious Activity',
                  'Broken Callbox',
                  'Unsafe Alleyway'
                ]
                    .map((type) =>
                        DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedType = val);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                style: const TextStyle(color: AppColors.textMain, fontSize: 13),
                decoration: InputDecoration(
                  hintText: "Location or description details...",
                  hintStyle: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                  filled: true,
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
              child: const Text("Cancel",
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade800,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        "Hazard ($selectedType) dispatched to campus safety patrol."),
                    backgroundColor: Colors.amber.shade900,
                  ),
                );
              },
              child: const Text("Submit",
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showCenteredContactsDialog(
      BuildContext context, TelemetryProvider telemetry) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.inputBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.primaryGold.withOpacity(0.5)),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Emergency Directory",
              style: TextStyle(
                color: AppColors.primaryGold,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle,
                  color: AppColors.primaryGold, size: 22),
              tooltip: "Add Contact",
              onPressed: () {
                Navigator.pop(dialogCtx);
                _showAddContactDialog(context, telemetry);
              },
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...telemetry.emergencyContacts.map((contact) {
                final String name = contact["name"] ?? "Contact";
                final String phone = contact["phone"] ?? "";
                final bool isDefault = contact["type"] == "default";

                return Container(
                  margin: const EdgeInsets.only(bottom: 8.0),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.primaryGold.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isDefault ? Icons.shield : Icons.person,
                        color: AppColors.primaryGold,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                color: AppColors.textMain,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              phone,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.phone,
                            color: AppColors.routeSafe, size: 20),
                        onPressed: () {
                          Navigator.pop(dialogCtx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text("Calling $name ($phone)...")),
                          );
                        },
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text("Close",
                style: TextStyle(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  void _showAddContactDialog(
      BuildContext context, TelemetryProvider telemetry) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.inputBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Add Emergency Contact",
          style: TextStyle(
              color: AppColors.primaryGold, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: AppColors.textMain),
              decoration: InputDecoration(
                hintText: "Contact Name",
                hintStyle: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phoneController,
              style: const TextStyle(color: AppColors.textMain),
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: "Phone Number",
                hintStyle: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel",
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGold),
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  phoneController.text.isNotEmpty) {
                telemetry.addEmergencyContact(
                    nameController.text, phoneController.text);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text("Added ${nameController.text} to contacts.")),
                );
              }
            },
            child: const Text("Save",
                style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _triggerDeterrentSiren(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2B1015),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Colors.redAccent),
        ),
        icon: const Icon(Icons.volume_up, color: Colors.redAccent, size: 40),
        title: const Text(
          "Loud Siren & Strobe Alarm",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Trigger maximum volume alarm tone and strobe alert to deter nearby threats.",
          style: TextStyle(color: Colors.white70, fontSize: 13),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text("Cancel", style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("🔊 Deterrent Siren Activated!"),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text("Sound Siren",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
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
          padding: const EdgeInsets.fromLTRB(4.0, 4.0, 4.0, 6.0),
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

                  // 2. INNER SCROLLABLE CONTENT
                  Positioned.fill(
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      padding:
                          const EdgeInsets.fromLTRB(26.0, 26.0, 26.0, 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 6),

                          // Header Title & Monitoring Badge
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Support & Safety",
                                      style: TextStyle(
                                        color: telemetry.isSosActive
                                            ? Colors.redAccent
                                            : AppColors.primaryGold,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      "Active guardian assistance & emergency dispatch",
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 11,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: telemetry.isSosActive
                                      ? Colors.redAccent.withOpacity(0.2)
                                      : AppColors.routeSafe.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: telemetry.isSosActive
                                        ? Colors.redAccent
                                        : AppColors.routeSafe,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: telemetry.isSosActive
                                            ? Colors.redAccent
                                            : AppColors.routeSafe,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      telemetry.isSosActive
                                          ? "SOS"
                                          : telemetry.buddyConsoleStatus,
                                      style: TextStyle(
                                        color: telemetry.isSosActive
                                            ? Colors.redAccent
                                            : AppColors.routeSafe,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // =========================================================
                          // 1. HERO ANGEL WITH OPAQUE SOS BUTTON COVERING THE MOON
                          // =========================================================
                          Center(
                            child: SizedBox(
                              width: 250,
                              height: 260,
                              child: Stack(
                                alignment: Alignment.topCenter,
                                children: [
                                  // Angel Artwork Background
                                  Positioned(
                                    top: 0,
                                    left: 0,
                                    right: 0,
                                    child: Image.asset(
                                      'assets/images/angel.jpeg',
                                      width: 250,
                                      height: 260,
                                      fit: BoxFit.contain,
                                    ),
                                  ),

                                  // 100% Solid/Opaque Darker Golden Amber SOS Circle
                                  // Positioned exactly where the moon sits so the angel lies along the top arc
                                  Positioned(
                                    bottom: 0,
                                    child: GestureDetector(
                                      onTap: () => telemetry.toggleSosAlert(),
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 250),
                                        width: 172,
                                        height: 172,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          // 100% opaque gradients with no translucency
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: telemetry.isSosActive
                                                ? const [
                                                    Color(0xFFE53935),
                                                    Color(0xFFC62828),
                                                    Color(0xFF8E0000),
                                                  ]
                                                : const [
                                                    Color(
                                                        0xFFF0C852), // Luminous rich top highlight
                                                    Color(
                                                        0xFFD49C1E), // Solid deep golden center
                                                    Color(
                                                        0xFF9E6E0B), // Warm dark amber bottom
                                                  ],
                                          ),
                                          border: Border.all(
                                            color: telemetry.isSosActive
                                                ? Colors.white
                                                : const Color(0xFFFFE8A3),
                                            width: 2.6,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: (telemetry.isSosActive
                                                      ? Colors.redAccent
                                                      : const Color(0xFFD49C1E))
                                                  .withOpacity(0.65),
                                              blurRadius: telemetry.isSosActive
                                                  ? 32
                                                  : 20,
                                              spreadRadius:
                                                  telemetry.isSosActive ? 4 : 2,
                                            ),
                                          ],
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 14),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                "SOS",
                                                style: TextStyle(
                                                  color: telemetry.isSosActive
                                                      ? Colors.white
                                                      : const Color(0xFF140D2B),
                                                  fontSize: 28,
                                                  fontWeight: FontWeight.w900,
                                                  letterSpacing: 2.2,
                                                  shadows: [
                                                    Shadow(
                                                      color: Colors.black
                                                          .withOpacity(0.25),
                                                      blurRadius: 3,
                                                      offset:
                                                          const Offset(0, 1),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                "ONE-TAP ALERT",
                                                style: TextStyle(
                                                  color: telemetry.isSosActive
                                                      ? Colors.white
                                                      : const Color(0xFF281C5C),
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: 0.6,
                                                ),
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                "Tap in case of immediate\ndanger to alert patrol\nand contacts",
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: telemetry.isSosActive
                                                      ? Colors.white70
                                                      : const Color(0xFF382963),
                                                  fontSize: 8.5,
                                                  fontWeight: FontWeight.w700,
                                                  height: 1.15,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // 2. IMMEDIATE SAFETY ACTIONS
                          const Text(
                            "Immediate Safety Actions",
                            style: TextStyle(
                              color: AppColors.primaryGold,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 8),

                          Row(
                            children: [
                              Expanded(
                                child: _buildFiligreeActionTile(
                                  icon: Icons.shield_outlined,
                                  iconColor: AppColors.primaryGold,
                                  title: "Campus Patrol",
                                  subtitle: "Direct Call Escort",
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              "Calling Campus Security Escort...")),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildFiligreeActionTile(
                                  icon: Icons.volume_up_outlined,
                                  iconColor: Colors.redAccent,
                                  title: "Loud Siren",
                                  subtitle: "Deterrent Alarm",
                                  onTap: () => _triggerDeterrentSiren(context),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          Row(
                            children: [
                              Expanded(
                                child: _buildFiligreeActionTile(
                                  icon: Icons.contact_phone_outlined,
                                  iconColor: Colors.cyanAccent,
                                  title: "Contacts",
                                  subtitle:
                                      "${telemetry.emergencyContacts.length} Linked Numbers",
                                  onTap: () => _showCenteredContactsDialog(
                                      context, telemetry),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildFiligreeActionTile(
                                  icon: Icons.warning_amber_rounded,
                                  iconColor: Colors.amber,
                                  title: "Report Hazard",
                                  subtitle: "Log Incident",
                                  onTap: () => _showReportHazardDialog(context),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // 3. VIRTUAL BUDDY ACTIVE JOURNEY CARD
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0x38121F3D),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: telemetry.isOffTrack
                                    ? Colors.redAccent
                                    : AppColors.primaryGold.withOpacity(0.35),
                                width: 1.0,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      "Virtual Buddy Telemetry",
                                      style: TextStyle(
                                        color: AppColors.primaryGold,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      telemetry.isNavigating
                                          ? "NAVIGATING"
                                          : "STANDBY",
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  telemetry.isNavigating
                                      ? "Guiding along safe corridor to ${telemetry.destinationName}."
                                      : "Virtual Buddy is actively scanning route deviations & unplanned stops.",
                                  style: TextStyle(
                                    color: AppColors.textSecondary
                                        .withOpacity(0.85),
                                    fontSize: 10,
                                  ),
                                ),
                                const SizedBox(height: 10),

                                // "I'm Safe Check-in" Action Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 34,
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                          color: Colors.cyanAccent, width: 1.2),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(17),
                                      ),
                                      backgroundColor:
                                          Colors.cyanAccent.withOpacity(0.06),
                                    ),
                                    onPressed: () {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              "Check-in recorded: User reported safe."),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      "I'm Safe Check-in",
                                      style: TextStyle(
                                        color: Colors.cyanAccent,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
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

  Widget _buildFiligreeActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0x38121F3D),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primaryGold.withOpacity(0.35),
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textMain,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 9,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
