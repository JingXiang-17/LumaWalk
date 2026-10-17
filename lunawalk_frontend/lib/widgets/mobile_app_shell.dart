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

  @override
  Widget build(BuildContext context) {
    if (!isLoggedIn) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(6.0),
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
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Icon(Icons.auto_awesome,
                        color: AppColors.primaryGold.withOpacity(0.8),
                        size: 18),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Icon(Icons.auto_awesome,
                        color: AppColors.primaryGold.withOpacity(0.8),
                        size: 18),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Icon(Icons.auto_awesome,
                        color: AppColors.primaryGold.withOpacity(0.8),
                        size: 18),
                  ),
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Icon(Icons.auto_awesome,
                        color: AppColors.primaryGold.withOpacity(0.8),
                        size: 18),
                  ),
                  Positioned.fill(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20.0, vertical: 24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),
                          Image.asset(
                            'assets/images/logo.png',
                            height: 130,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "LunaWalk",
                            style: TextStyle(
                              color: AppColors.primaryGold,
                              fontSize: 30,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            "Find your way under the moonlight.",
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 13),
                          ),
                          const SizedBox(height: 32),
                          TextField(
                            style: const TextStyle(color: AppColors.textMain),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppColors.inputBackground,
                              hintText: "Email or Student ID",
                              hintStyle: const TextStyle(
                                  color: AppColors.textSecondary),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            obscureText: true,
                            style: const TextStyle(color: AppColors.textMain),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppColors.inputBackground,
                              hintText: "Password",
                              hintStyle: const TextStyle(
                                  color: AppColors.textSecondary),
                              suffixIcon: const Icon(Icons.visibility_off,
                                  color: AppColors.textSecondary),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Align(
                            alignment: Alignment.centerRight,
                            child: Text("Forgot Password?",
                                style: TextStyle(
                                    color: AppColors.primaryGold,
                                    fontSize: 12)),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryGold,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24)),
                              ),
                              onPressed: () => _doLogin(false),
                              child: const Text(
                                "Log In",
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            height: 36,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                    color:
                                        AppColors.primaryGold.withOpacity(0.6),
                                    width: 1.2),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18)),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                              ),
                              onPressed: () => _doLogin(true),
                              icon: const Icon(Icons.play_arrow_rounded,
                                  color: AppColors.primaryGold, size: 18),
                              label: const Text(
                                "Simulation Mode",
                                style: TextStyle(
                                  color: AppColors.primaryGold,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
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
      );
    }

    final List<Widget> pages = [
      const LunaMapScreen(),
      const InsightsScreen(),
      const SupportScreen(),
      SettingsScreen(onLogout: _doLogout),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppColors.background,
        selectedItemColor: AppColors.primaryGold,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.map), label: "Map"),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart), label: "Insights"),
          BottomNavigationBarItem(icon: Icon(Icons.shield), label: "Support"),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: "Settings"),
        ],
      ),
    );
  }
}
