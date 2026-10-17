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
              side: BorderSide(color: AppColors.primaryGold.withOpacity(0.6))),
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.amber),
              SizedBox(width: 8),
              Text("Report Hazard",
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
              const Text("Hazard Type:",
                  style: TextStyle(color: AppColors.textMain, fontSize: 13)),
              const SizedBox(height: 6),
              DropdownButton<String>(
                value: selectedType,
                dropdownColor: AppColors.inputBackground,
                isExpanded: true,
                style: const TextStyle(
                    color: AppColors.primaryGold, fontWeight: FontWeight.bold),
                items: [
                  'Poor Lighting',
                  'Path Obstacle',
                  'Suspicious Activity',
                  'Broken Callbox'
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
                style: const TextStyle(color: AppColors.textMain),
                decoration: InputDecoration(
                  hintText: "Location details or description...",
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
                    style: TextStyle(color: AppColors.textSecondary))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade800),
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                        "Hazard report ($selectedType) dispatched to Campus Security."),
                    backgroundColor: Colors.amber.shade900));
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

  void _showAddContactDialog(
      BuildContext context, TelemetryProvider telemetry) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.inputBackground,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.primaryGold.withOpacity(0.6))),
        title: const Text("Add Emergency Contact",
            style: TextStyle(
                color: AppColors.primaryGold,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
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
                      borderSide: BorderSide.none)),
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
                      borderSide: BorderSide.none)),
            ),
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
              if (nameController.text.isNotEmpty &&
                  phoneController.text.isNotEmpty) {
                telemetry.addEmergencyContact(
                    nameController.text, phoneController.text);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content:
                        Text("Added ${nameController.text} to contacts.")));
              }
            },
            child: const Text("Add",
                style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
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
            side: BorderSide(
                color: AppColors.primaryGold.withOpacity(0.8), width: 1.5)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Emergency Contacts",
                style: TextStyle(
                    color: AppColors.primaryGold,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              onPressed: () {
                Navigator.pop(dialogCtx);
                _showAddContactDialog(context, telemetry);
              },
              icon: const Icon(Icons.add, size: 16, color: Colors.black),
              label: const Text("Add",
                  style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
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

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.primaryGold.withOpacity(0.3))),
                    child: Row(
                      children: [
                        Icon(isDefault ? Icons.shield : Icons.person,
                            color: AppColors.primaryGold, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name,
                                  style: const TextStyle(
                                      color: AppColors.textMain,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)),
                              Text(phone,
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 11)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.phone_forwarded,
                              color: AppColors.routeSafe, size: 20),
                          onPressed: () {
                            Navigator.pop(dialogCtx);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text("Calling $name ($phone)...")));
                          },
                        ),
                      ],
                    ),
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
                  style: TextStyle(color: AppColors.textSecondary)))
        ],
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
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                  color: telemetry.isSosActive
                      ? Colors.redAccent
                      : AppColors.primaryGold.withOpacity(0.85),
                  width: telemetry.isSosActive ? 2.8 : 2.0),
              boxShadow: [
                BoxShadow(
                    color: telemetry.isSosActive
                        ? Colors.redAccent.withOpacity(0.75)
                        : AppColors.primaryGold.withOpacity(0.35),
                    blurRadius: telemetry.isSosActive ? 28 : 18,
                    spreadRadius: telemetry.isSosActive ? 4 : 2)
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                    top: 12,
                    left: 12,
                    child: Icon(Icons.auto_awesome,
                        color: telemetry.isSosActive
                            ? Colors.redAccent
                            : AppColors.primaryGold,
                        size: 18)),
                Positioned(
                    top: 12,
                    right: 12,
                    child: Icon(Icons.auto_awesome,
                        color: telemetry.isSosActive
                            ? Colors.redAccent
                            : AppColors.primaryGold,
                        size: 18)),
                Positioned(
                    bottom: 12,
                    left: 12,
                    child: Icon(Icons.auto_awesome,
                        color: telemetry.isSosActive
                            ? Colors.redAccent
                            : AppColors.primaryGold,
                        size: 18)),
                Positioned(
                    bottom: 12,
                    right: 12,
                    child: Icon(Icons.auto_awesome,
                        color: telemetry.isSosActive
                            ? Colors.redAccent
                            : AppColors.primaryGold,
                        size: 18)),

                Positioned.fill(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18.0, vertical: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        Text("Support and Emergency",
                            style: TextStyle(
                                color: telemetry.isSosActive
                                    ? Colors.redAccent
                                    : AppColors.primaryGold,
                                fontWeight: FontWeight.bold,
                                fontSize: 22)),
                        const SizedBox(height: 18),

                        // Virtual Buddy Console Card
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.inputBackground,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: telemetry.isSosActive
                                    ? Colors.redAccent.withOpacity(0.6)
                                    : AppColors.primaryGold.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Virtual Buddy Console",
                                      style: TextStyle(
                                          color: AppColors.primaryGold,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15)),
                                  SizedBox(height: 4),
                                  Text("Active Journey Telemetry Stream",
                                      style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 11)),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: telemetry.isSosActive
                                      ? Colors.redAccent.withOpacity(0.2)
                                      : AppColors.routeSafe.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: telemetry.isSosActive
                                          ? Colors.redAccent
                                          : AppColors.routeSafe),
                                ),
                                child: Text(
                                  telemetry.isSosActive
                                      ? "🔴 SOS ACTIVE"
                                      : "🟢 ${telemetry.buddyConsoleStatus}",
                                  style: TextStyle(
                                      color: telemetry.isSosActive
                                          ? Colors.redAccent
                                          : AppColors.routeSafe,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        const Text("User Action",
                            style: TextStyle(
                                color: AppColors.textMain,
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                        const SizedBox(height: 10),

                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber.shade800,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 11),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12))),
                                onPressed: () =>
                                    _showReportHazardDialog(context),
                                icon: const Icon(Icons.warning,
                                    color: Colors.black, size: 18),
                                label: const Text("Report Hazard",
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.inputBackground,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 11),
                                    side: const BorderSide(
                                        color: AppColors.primaryGold),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12))),
                                onPressed: () => _showCenteredContactsDialog(
                                    context, telemetry),
                                icon: const Icon(Icons.people,
                                    color: AppColors.primaryGold, size: 18),
                                label: const Text("Contacts",
                                    style: TextStyle(
                                        color: AppColors.primaryGold,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13)),
                              ),
                            ),
                          ],
                        ),

                        // SIMULATION ONLY: GPS DRIFT TRIGGER
                        if (telemetry.isSimulationMode) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 42,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.inputBackground,
                                  side:
                                      const BorderSide(color: Colors.redAccent),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12))),
                              onPressed: () {
                                if (!telemetry.showAreYouOkModal &&
                                    !telemetry.isSosActive) {
                                  telemetry.simulateWalkGpsDrift();
                                }
                              },
                              icon: const Icon(Icons.satellite_alt,
                                  color: Colors.redAccent, size: 18),
                              label: const Text(
                                  "Simulate GPS Signal Drift (Test Virtual Buddy)",
                                  style: TextStyle(
                                      color: Colors.redAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12)),
                            ),
                          ),
                        ],
                        const SizedBox(height: 22),

                        // Seamless Feathered Guardian Graphic & SOS Orb
                        Center(
                          child: SizedBox(
                            height: 310,
                            width: 310,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                ShaderMask(
                                  shaderCallback: (rect) {
                                    return const RadialGradient(
                                        center: Alignment.center,
                                        radius: 0.48,
                                        colors: [
                                          Colors.black,
                                          Colors.transparent
                                        ],
                                        stops: [
                                          0.68,
                                          1.0
                                        ]).createShader(rect);
                                  },
                                  blendMode: BlendMode.dstIn,
                                  child: Image.asset(
                                      telemetry.isSosActive
                                          ? 'assets/images/logo3.jpeg'
                                          : 'assets/images/logo2.jpeg',
                                      height: 310,
                                      width: 310,
                                      fit: BoxFit.cover),
                                ),
                                Positioned(
                                  top: 26,
                                  child: GestureDetector(
                                    onTap: () => telemetry.toggleSosAlert(),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      width: 130,
                                      height: 130,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: telemetry.isSosActive
                                            ? Colors.red.shade900
                                                .withOpacity(0.65)
                                            : AppColors.primaryGold
                                                .withOpacity(0.85),
                                        border: Border.all(
                                            color: telemetry.isSosActive
                                                ? Colors.redAccent
                                                : AppColors.highlightCream,
                                            width: 3.5),
                                        boxShadow: [
                                          BoxShadow(
                                              color: telemetry.isSosActive
                                                  ? Colors.redAccent
                                                      .withOpacity(0.95)
                                                  : AppColors.primaryGold
                                                      .withOpacity(0.8),
                                              blurRadius: telemetry.isSosActive
                                                  ? 40
                                                  : 22,
                                              spreadRadius:
                                                  telemetry.isSosActive
                                                      ? 10
                                                      : 4),
                                          if (telemetry.isSosActive)
                                            const BoxShadow(
                                                color: Colors.red,
                                                blurRadius: 20,
                                                spreadRadius: 4),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          "SOS",
                                          style: TextStyle(
                                            color: telemetry.isSosActive
                                                ? Colors.white
                                                : Colors.black,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 28,
                                            letterSpacing: 2.0,
                                            shadows: telemetry.isSosActive
                                                ? const [
                                                    Shadow(
                                                        color: Colors.black,
                                                        blurRadius: 10)
                                                  ]
                                                : null,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                // SIMULATION ONLY: THE "ARE YOU OK?" COUNTDOWN MODAL OVERLAY
                if (telemetry.isSimulationMode && telemetry.showAreYouOkModal)
                  Positioned(
                    top: 20,
                    left: 16,
                    right: 16,
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.inputBackground,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.amber, width: 2),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.amber.withOpacity(0.3),
                                blurRadius: 20)
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.timer,
                                color: Colors.amber, size: 42),
                            const SizedBox(height: 10),
                            const Text("Unplanned Stop Detected",
                                style: TextStyle(
                                    color: Colors.amber,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            const Text(
                                "Virtual Buddy noticed you stopped moving. Escalating to SOS in:",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: AppColors.textMain, fontSize: 13)),
                            const SizedBox(height: 12),
                            Text("${telemetry.areYouOkCountdown}s",
                                style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900)),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryGold),
                                onPressed: () =>
                                    telemetry.dismissAreYouOkModal(),
                                child: const Text("I'm Safe (Cancel)",
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
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
}
