import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart'; // Navigates to MainNavigator to preserve the 5-tab bottom navigation shell
import '../utils/tactile_feedback.dart'; // Tactile sound and haptic feedback utility

/// Palette constants matching the Cozy Pastel Stationery design system.
class WelcomeColors {
  static const Color textDark = Color(0xFF5D534A);
  static const Color textMuted = Color(0xFF8B8076);
  static const Color inputBg = Color(0xFFFDF8F3);
  static const Color buttonBg = Color(0xFF986B4D); // Warm terracotta brown
  static const Color buttonDisabled = Color(
    0xFFC6B8A5,
  ); // Muted taupe when name is empty
  static const Color buttonBgPressed = Color(0xFF855B3E);
}

/// Welcome Screen (Frame 178)
///
/// Features & Guidelines:
/// 1. Strict First-Time Name Requirement:
///    - Learners cannot enter the app without providing a valid name (at least 2 characters).
///    - Shows dynamic inline error alerts if whitespace or empty values are submitted.
/// 2. Data Persistence & Synchronization:
///    - Dual-writes to both `'user_name'` and `'profile_username'` in [SharedPreferences].
///    - Marks `'has_completed_onboarding'` as `true` so returning users boot straight to Home.
///    - If a user selects "Clear All Data" in Settings, this screen automatically re-triggers.
/// 3. Navigation Integrity:
///    - Transitions to [MainNavigator] (not a isolated screen) to guarantee the 5-tab
///      bottom navigation bar remains active and responsive.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _isButtonPressed = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// Evaluates whether the entered name satisfies the minimum requirements.
  bool get _isValidName => _nameController.text.trim().length >= 2;

  /// Validates input, saves user identity to storage, and navigates to the main app.
  Future<void> _handleGetStarted() async {
    if (_isSubmitting) return;

    final String enteredName = _nameController.text.trim();

    // Strict validation checks
    if (enteredName.isEmpty) {
      TactileFeedback.error();
      setState(() {
        _errorMessage = 'Please enter your name to get started';
      });
      return;
    } else if (enteredName.length < 2) {
      TactileFeedback.error();
      setState(() {
        _errorMessage = 'Name must be at least 2 characters long';
      });
      return;
    }

    setState(() => _isSubmitting = true);
    TactileFeedback.press();

    // Persist learner identity across all app screens
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', enteredName);
    await prefs.setString('profile_username', enteredName);
    await prefs.setBool('has_completed_onboarding', true);

    if (!mounted) return;

    // Route directly to MainNavigator with a gentle fade transition
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, __, ___) => const MainNavigator(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final bool canProceed = _isValidName;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Illustrated Scenery Background (Mt. Fuji & Sakura)
          Positioned.fill(
            child: Image.asset(
              'assets/image/Welcome_Bg.jpeg',
              fit: BoxFit.cover,
            ),
          ),

          // 2. Interactive Input Layer
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: screenSize.height * 0.04),

                    // Centered Logo Badge
                    Center(
                      child: Image.asset(
                        'assets/image/cozy_kana_logo.png',
                        width: 125,
                        height: 125,
                        fit: BoxFit.contain,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Welcome Headline
                    const Text(
                      'Welcome to\nKana Learning',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: WelcomeColors.textDark,
                        height: 1.25,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Name Label with Required Indicator
                    const Row(
                      children: [
                        Text(
                          'Name',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: WelcomeColors.textDark,
                          ),
                        ),
                        SizedBox(width: 4),
                        Text(
                          '*',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Input Field Container
                    Container(
                      decoration: BoxDecoration(
                        color: WelcomeColors.inputBg,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: _errorMessage != null
                              ? Colors.red.shade400
                              : WelcomeColors.textDark,
                          width: 1.5,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: WelcomeColors.textDark,
                        ),
                        decoration: const InputDecoration(
                          icon: Icon(
                            Icons.person_outline_rounded,
                            color: WelcomeColors.textMuted,
                            size: 22,
                          ),
                          hintText: 'Enter your name',
                          hintStyle: TextStyle(
                            color: WelcomeColors.textMuted,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 14),
                        ),
                        onChanged: (_) {
                          setState(() {
                            if (_errorMessage != null) _errorMessage = null;
                          });
                        },
                        onSubmitted: (_) => _handleGetStarted(),
                      ),
                    ),

                    // Inline Error Feedback Message
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.only(left: 14),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // "Let's get started" Tactile Action Button
                    GestureDetector(
                      onTapDown: (_) {
                        if (!_isSubmitting) {
                          setState(() => _isButtonPressed = true);
                        }
                      },
                      onTapUp: (_) {
                        setState(() => _isButtonPressed = false);
                        _handleGetStarted();
                      },
                      onTapCancel: () =>
                          setState(() => _isButtonPressed = false),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        height: 52,
                        decoration: BoxDecoration(
                          color: !canProceed
                              ? WelcomeColors.buttonDisabled
                              : (_isButtonPressed
                                    ? WelcomeColors.buttonBgPressed
                                    : WelcomeColors.buttonBg),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: WelcomeColors.textDark,
                            width: 1.5,
                          ),
                          boxShadow: canProceed
                              ? [
                                  BoxShadow(
                                    color: WelcomeColors.textDark.withOpacity(
                                      0.35,
                                    ),
                                    offset: Offset(0, _isButtonPressed ? 1 : 3),
                                    blurRadius: 0,
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Let's get started",
                              style: TextStyle(
                                color: canProceed
                                    ? Colors.white
                                    : WelcomeColors.textDark.withOpacity(0.7),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: canProceed
                                  ? Colors.white
                                  : WelcomeColors.textDark.withOpacity(0.7),
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: screenSize.height * 0.08),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
