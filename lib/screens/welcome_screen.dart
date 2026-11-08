// lib/screens/welcome_screen.dart
// Cozy Kana — first-time name registration.
// The welcome_UI.png contains the stationery illustrations only.
// The welcome heading, name input and action button are real Flutter widgets
// so they remain readable and interactive on different Android screen sizes.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart'; // MainNavigator preserves all five existing app tabs.
import '../utils/tactile_feedback.dart';

class _WelcomePalette {
  static const cream = Color(0xFFFDF8F3);
  static const brown = Color(0xFF79502F);
  static const muted = Color(0xFF947963);
  static const border = Color(0xFFDCC6A8);
  static const danger = Color(0xFFB14F44);
}

/// Displays the stationery illustration, welcome heading, and name entry form.
///
/// SharedPreferences keys are unchanged to remain compatible with Home/Profile:
///  - 'user_name' and 'profile_username': the same name in both locations.
///  - 'has_completed_onboarding': true only AFTER a valid name was saved.
///  - 'has_seen_intro': whether the separate introductory pages were viewed.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// Validate, persist the name, then replace this page with the five-tab app.
  Future<void> _handleGetStarted() async {
    if (_isSubmitting) return; // Prevent double navigation or duplicate writes.

    final name = _nameController.text.trim();
    if (name.length < 2) {
      TactileFeedback.error();
      setState(() {
        _errorMessage = name.isEmpty
            ? 'Please enter your name to get started.'
            : 'Name must have at least 2 characters.';
      });
      return;
    }

    FocusScope.of(context).unfocus();
    TactileFeedback.press();
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      // Keep these original keys so no other screens need to change.
      await prefs.setString('user_name', name);
      await prefs.setString('profile_username', name);
      await prefs.setBool('has_seen_intro', true);
      // Set this last: a partially saved name is not completed onboarding.
      await prefs.setBool('has_completed_onboarding', true);

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder<void>(
          transitionDuration: const Duration(milliseconds: 350),
          pageBuilder: (context, animation, secondaryAnimation) =>
              const MainNavigator(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
    } catch (_) {
      // If storage fails, keep the user here so they can retry.
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Unable to save your name. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Keep the background full-screen even when the keyboard opens.
    final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: _WelcomePalette.cream,
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // The image contains only decoration (notepad/cat, books, mug, waves).
          // Do not bake the heading into it: Flutter draws the heading below.
          Image.asset(
            'assets/image/welcome_UI.png',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            excludeFromSemantics: true, // Decorative background only.
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final availableHeight = constraints.maxHeight;
                // Reserve space for the notebook-and-cat illustration.
                // This is calculated from the FULL screen (not the smaller
                // keyboard area), so opening the keyboard will not cause the
                // heading and form to jump upward over the illustration.
                // Limit the spacing for unusually short/tall screens.
                final topSpace = (availableHeight * 0.29).clamp(170.0, 250.0);

                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.only(bottom: keyboardHeight + 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: topSpace),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Real text rather than lettering baked into the PNG.
                            // This stays above the form and is accessible to
                            // screen readers and different screen densities.
                            const Text(
                              'Welcome to\nCozy Kana',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _WelcomePalette.brown,
                                fontSize: 30,
                                height: 1.08,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 26),
                            const Row(
                              children: [
                                Icon(
                                  Icons.edit_outlined,
                                  color: _WelcomePalette.brown,
                                  size: 19,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Enter your name',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: _WelcomePalette.brown,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _nameController,
                              enabled: !_isSubmitting,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _handleGetStarted(),
                              onChanged: (_) {
                                // Remove the validation message as soon as the
                                // learner starts correcting their name.
                                if (_errorMessage != null) {
                                  setState(() => _errorMessage = null);
                                }
                              },
                              decoration: InputDecoration(
                                hintText: 'Enter your name',
                                hintStyle: const TextStyle(
                                  color: _WelcomePalette.muted,
                                  fontSize: 14,
                                ),
                                prefixIcon: const Icon(
                                  Icons.person_outline,
                                  color: _WelcomePalette.muted,
                                ),
                                filled: true,
                                fillColor: _WelcomePalette.cream,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(26),
                                  borderSide: const BorderSide(
                                    color: _WelcomePalette.border,
                                    width: 2,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(26),
                                  borderSide: const BorderSide(
                                    color: _WelcomePalette.brown,
                                    width: 2,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(26),
                                  borderSide: const BorderSide(
                                    color: _WelcomePalette.danger,
                                    width: 2,
                                  ),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(26),
                                  borderSide: const BorderSide(
                                    color: _WelcomePalette.danger,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: _WelcomePalette.danger,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: _isSubmitting
                                  ? null
                                  : _handleGetStarted,
                              icon: _isSubmitting
                                  ? const SizedBox(
                                      height: 17,
                                      width: 17,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.arrow_forward_rounded),
                              label: Text(
                                _isSubmitting ? 'Saving...' : 'Get Started',
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: _WelcomePalette.brown,
                                disabledBackgroundColor: _WelcomePalette.muted,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 54),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Extra space lets the form scroll above a small device's
                      // keyboard without moving the fixed illustration.
                      const SizedBox(height: 36),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
