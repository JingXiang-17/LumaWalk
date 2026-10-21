import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/telemetry_provider.dart';
import '../theme/app_colors.dart';
import '../screens/luna_map_screen.dart';
import '../screens/insights_screen.dart';
import '../screens/support_screen.dart';
import '../screens/settings_screen.dart';

class MobileAppShell extends StatefulWidget {
  const MobileAppShell({super.key});

  @override
  State<MobileAppShell> createState() => _MobileAppShellState();
}

class _MobileAppShellState extends State<MobileAppShell> {
  bool isLoggedIn = false;
  int _currentIndex = 0;

  void _doLogin(bool isSimMode) {
    final telemetry = Provider.of<TelemetryProvider>(context, listen: false);
    telemetry.setSimulationMode(isSimMode);
    setState(() {
      isLoggedIn = true;
    });
  }

  void _doLogout() {
    final telemetry = Provider.of<TelemetryProvider>(context, listen: false);
    telemetry.setSimulationMode(false);
    setState(() {
      isLoggedIn = false;
      _currentIndex = 0;
    });
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? AppColors.primaryGold : AppColors.textSecondary;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!isLoggedIn) {
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
                    Image.asset(
                      'assets/images/login_frame.jpeg',
                      fit: BoxFit.fill,
                    ),
                    Positioned.fill(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Center(
                            child: SingleChildScrollView(
                              physics: const ClampingScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(
                                48.0,
                                24.0,
                                48.0,
                                32.0,
                              ),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 290,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      'assets/images/logo_b.jpeg',
                                      key: const Key('app_logo_identifier'),
                                      height: 165,
                                      fit: BoxFit.contain,
                                    ),
                                    const SizedBox(height: 10),
                                    const Text(
                                      "LumaWalk",
                                      style: TextStyle(
                                        color: AppColors.primaryGold,
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      "Find your way under the moonlight.",
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 24),
                                    SizedBox(
                                      height: 44,
                                      child: TextField(
                                        style: const TextStyle(
                                          color: AppColors.textMain,
                                          fontSize: 13,
                                        ),
                                        decoration: InputDecoration(
                                          isDense: true,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 12,
                                          ),
                                          filled: true,
                                          fillColor: AppColors.inputBackground
                                              .withOpacity(0.9),
                                          hintText: "Email or Student ID",
                                          hintStyle: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 12,
                                          ),
                                          prefixIcon: const Icon(
                                            Icons.person_outline,
                                            color: AppColors.primaryGold,
                                            size: 18,
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            borderSide: BorderSide(
                                              color: AppColors.primaryGold
                                                  .withOpacity(0.35),
                                              width: 1.0,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            borderSide: const BorderSide(
                                              color: AppColors.primaryGold,
                                              width: 1.3,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      height: 44,
                                      child: TextField(
                                        obscureText: true,
                                        style: const TextStyle(
                                          color: AppColors.textMain,
                                          fontSize: 13,
                                        ),
                                        decoration: InputDecoration(
                                          isDense: true,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 12,
                                          ),
                                          filled: true,
                                          fillColor: AppColors.inputBackground
                                              .withOpacity(0.9),
                                          hintText: "Password",
                                          hintStyle: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 12,
                                          ),
                                          prefixIcon: const Icon(
                                            Icons.lock_outline,
                                            color: AppColors.primaryGold,
                                            size: 18,
                                          ),
                                          suffixIcon: const Icon(
                                            Icons.visibility_off,
                                            color: AppColors.textSecondary,
                                            size: 16,
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            borderSide: BorderSide(
                                              color: AppColors.primaryGold
                                                  .withOpacity(0.35),
                                              width: 1.0,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            borderSide: const BorderSide(
                                              color: AppColors.primaryGold,
                                              width: 1.3,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        "Forgot Password?",
                                        style: TextStyle(
                                          color: AppColors.primaryGold,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 44,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              AppColors.primaryGold,
                                          elevation: 3,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(22),
                                          ),
                                        ),
                                        onPressed: () => _doLogin(false),
                                        child: const Text(
                                          "Log In",
                                          style: TextStyle(
                                            color: Color(0xFF1E1547),
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      height: 34,
                                      child: OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(
                                            color: AppColors.primaryGold
                                                .withOpacity(0.8),
                                            width: 1.0,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(17),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 14),
                                        ),
                                        onPressed: () => _doLogin(true),
                                        icon: const Icon(
                                          Icons.play_arrow_rounded,
                                          color: AppColors.primaryGold,
                                          size: 16,
                                        ),
                                        label: const Text(
                                          "Simulation Mode",
                                          style: TextStyle(
                                            color: AppColors.primaryGold,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
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

    final List<Widget> pages = [
      const LunaMapScreen(),
      const InsightsScreen(),
      const SupportScreen(),
      SettingsScreen(onLogout: _doLogout),
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      body: pages[_currentIndex],
      // Bottom navigation container expanded to fill screen width cleanly
      bottomNavigationBar: Container(
        color: Colors.black,
        width: double.infinity,
        height: 78, // Expanded height so frame3 looks full and fits the screen
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. FRAME3 ASSET BACKGROUND (Edge-to-edge)
            Image.asset(
              'assets/images/frame3.jpeg',
              fit: BoxFit.fill,
            ),

            // 2. NAVIGATION BUTTONS POSITIONED SAFELY WITHIN FRAME'S INNER WINDOW
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(Icons.map, "Map", 0),
                  _buildNavItem(Icons.bar_chart, "Insights", 1),
                  _buildNavItem(Icons.shield, "Support", 2),
                  _buildNavItem(Icons.settings, "Settings", 3),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
