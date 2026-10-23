import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/telemetry_provider.dart';
import '../theme/app_colors.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  void _showActionDialog(
    BuildContext context, {
    required String title,
    required String message,
    IconData icon = Icons.info_outline,
    Color iconColor = AppColors.primaryGold,
  }) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.inputBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: iconColor.withOpacity(0.55)),
        ),
        icon: Icon(icon, color: iconColor, size: 32),
        title: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.primaryGold,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
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

  void _showReportHazardDialog(
    BuildContext context,
    TelemetryProvider telemetry,
  ) {
    const customCategory = 'Other / New Hazard';
    var selectedType = 'Poor Lighting';
    final categoryController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
                'Report Hazard',
                style: TextStyle(
                  color: AppColors.primaryGold,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 460,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.68,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Choose a category or add a new hazard. Reports are saved in this demo.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Hazard category',
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
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
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
                        'Unsafe Alleyway',
                        customCategory,
                      ]
                          .map((type) =>
                              DropdownMenuItem(value: type, child: Text(type)))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => selectedType = value);
                        }
                      },
                    ),
                    if (selectedType == customCategory) ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: categoryController,
                        style: const TextStyle(
                          color: AppColors.textMain,
                          fontSize: 13,
                        ),
                        decoration: InputDecoration(
                          labelText: 'New hazard category',
                          hintText: 'e.g. Flooded walkway',
                          labelStyle: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      minLines: 2,
                      maxLines: 4,
                      style: const TextStyle(
                        color: AppColors.textMain,
                        fontSize: 13,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Details or location (optional)',
                        hintText: 'Describe what walkers should know...',
                        labelStyle: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Report history',
                            style: TextStyle(
                              color: AppColors.primaryGold,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Text(
                          '${telemetry.hazardReports.length}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (telemetry.hazardReports.isEmpty)
                      const Text(
                        'No hazards reported yet.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      )
                    else
                      ...telemetry.hazardReports.map(
                        (report) => Container(
                          margin: const EdgeInsets.only(bottom: 7),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.primaryGold.withOpacity(0.18),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.amber,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      report.category,
                                      style: const TextStyle(
                                        color: AppColors.textMain,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      [
                                        report.ageLabel,
                                        report.description,
                                        report.locationLabel,
                                      ].where((part) => part.isNotEmpty).join(' • '),
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
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
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade800,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                final category = selectedType == customCategory
                    ? categoryController.text.trim()
                    : selectedType;
                if (category.isEmpty) return;
                telemetry.submitHazardReport(
                  category: category,
                  description: descriptionController.text,
                );
                Navigator.pop(dialogContext);
                _showActionDialog(
                  context,
                  title: 'Report added',
                  message:
                      '$category was added to Report History and Community Reports. This demo does not dispatch reports to campus safety.',
                  icon: Icons.check_circle_outline,
                  iconColor: Colors.amber,
                );
              },
              child: const Text(
                'Submit Report',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      categoryController.dispose();
      descriptionController.dispose();
    });
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
                          _showActionDialog(
                            context,
                            title: 'Call contact',
                            message:
                                'This demo does not place calls. To reach $name, dial $phone using your device.',
                            icon: Icons.phone_outlined,
                            iconColor: AppColors.routeSafe,
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
                _showActionDialog(
                  context,
                  title: 'Contact added',
                  message: '${nameController.text} is now in your contacts.',
                  icon: Icons.contact_phone_outlined,
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

  Future<void> _runDeterrentSiren(BuildContext context) async {
    final player = AudioPlayer();
    try {
      await player.setReleaseMode(ReleaseMode.loop);
      await player.play(AssetSource('audio/siren.wav'));
      if (!context.mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: const Color(0xFF2B1015),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Colors.redAccent),
          ),
          icon: const Icon(Icons.volume_up, color: Colors.redAccent, size: 40),
          title: const Text(
            'Siren is sounding',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'The alarm will sound until you stop it or close this window. It does not contact emergency services.',
            style: TextStyle(color: Colors.white70, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Stop siren',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('Could not play the deterrent siren: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (context.mounted) {
        _showActionDialog(
          context,
          title: 'Siren unavailable',
          message: 'The alarm audio could not be played: $error',
          icon: Icons.volume_off,
          iconColor: Colors.redAccent,
        );
      }
    } finally {
      await player.stop();
      await player.dispose();
    }
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
          "Loud Siren Alarm",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Play an audible alarm until you stop it. The sound level depends on your device volume.",
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
              unawaited(_runDeterrentSiren(context));
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
                                  subtitle: "Escort request (demo)",
                                  onTap: () {
                                    _showActionDialog(
                                      context,
                                      title: 'Campus Patrol',
                                      message:
                                          'This button is a demo placeholder. It does not call or dispatch campus patrol. Open Contacts to reach a listed number.',
                                      icon: Icons.shield_outlined,
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
                                  onTap: () =>
                                      _showReportHazardDialog(context, telemetry),
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
                                      telemetry.dismissAreYouOkModal();
                                      _showActionDialog(
                                        context,
                                        title: "You're checked in",
                                        message:
                                            'Your safe check-in was recorded in this demo.',
                                        icon: Icons.check_circle_outline,
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
