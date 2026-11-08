// lib/screens/onboarding_screen.dart
// Cozy Kana — three-page introduction (shown only before registration).
// Pictures are separate transparent artwork assets; all controls below are
// REAL Flutter widgets, not buttons baked into images.

import '../theme/cozy_palette.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/tactile_feedback.dart';
import 'welcome_screen.dart';

class _IntroColors {
  static Color get cream => CozyPalette.cream;
  static Color get brown => CozyPalette.textDark;
  static Color get muted => CozyPalette.textLight;
  static Color get sage => CozyPalette.introSage;
  static Color get paleSage => CozyPalette.lightSageShade;
  static Color get sand => CozyPalette.sand;
}

/// Introductory pages for first-time learners.
///
/// This is not account registration. Completing/Skipping sets ONLY
/// `has_seen_intro` and navigates to WelcomeScreen for name entry.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _IntroPageData {
  final String image;
  final String title;
  final String description;

  const _IntroPageData({
    required this.image,
    required this.title,
    required this.description,
  });
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _pageIndex = 0;
  bool _isFinishing = false;

  static const _pages = <_IntroPageData>[
    _IntroPageData(
      image: 'assets/image/onboarding_01.png',
      title: 'Learn Kana',
      description: 'Master Hiragana and Katakana step by step.',
    ),
    _IntroPageData(
      image: 'assets/image/onboarding_02.png',
      title: 'Write with Confidence',
      description: 'Watch stroke animations, trace, and write from memory.',
    ),
    _IntroPageData(
      image: 'assets/image/onboarding_03.png',
      title: 'Practice & Progress',
      description: 'Use flashcards, quizzes, and track your progress.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_isFinishing) return;
    if (_pageIndex < _pages.length - 1) {
      TactileFeedback.press();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOut,
      );
    } else {
      _finishIntro();
    }
  }

  /// Save only the intro flag. A learner must still enter a name on Welcome.
  Future<void> _finishIntro() async {
    if (_isFinishing) return;
    TactileFeedback.press();
    setState(() => _isFinishing = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_seen_intro', true);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder<void>(
          transitionDuration: const Duration(milliseconds: 350),
          pageBuilder: (context, animation, secondaryAnimation) =>
              const WelcomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isFinishing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save your intro. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    CozyPalette.watch(
      context,
    ); // Repaint on light/dark or system theme changes.
    return Scaffold(
      backgroundColor: _IntroColors.cream,
      body: Stack(
        children: [
          // Small decorative shapes; do not block any interactions.
          Positioned(
            left: -70,
            top: -80,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                color: _IntroColors.paleSage.withValues(alpha: 0.55),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: -65,
            bottom: -100,
            child: Container(
              width: 210,
              height: 210,
              decoration: BoxDecoration(
                color: _IntroColors.paleSage.withValues(alpha: 0.55),
                shape: BoxShape.circle,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 18),
                  Text(
                    'Cozy Kana',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _IntroColors.brown,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _pages.length,
                      onPageChanged: (index) =>
                          setState(() => _pageIndex = index),
                      itemBuilder: (context, index) {
                        final page = _pages[index];
                        return Column(
                          children: [
                            Expanded(
                              child: Center(
                                child: Image.asset(
                                  page.image,
                                  fit: BoxFit.contain,
                                  width: double.infinity,
                                  // Illustration is an image; the live title
                                  // and description are presented below it.
                                  semanticLabel: page.title,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              page.title,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _IntroColors.brown,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                height: 1.12,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              page.description,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _IntroColors.muted,
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 26),
                          ],
                        );
                      },
                    ),
                  ),
                  // Page indicators are controlled by PageView's current index.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (index) {
                      final isActive = index == _pageIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 22 : 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: isActive
                              ? _IntroColors.sage
                              : _IntroColors.sand,
                          borderRadius: BorderRadius.circular(9),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isFinishing ? null : _finishIntro,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: _IntroColors.brown,
                              width: 1.4,
                            ),
                            foregroundColor: _IntroColors.brown,
                            minimumSize: const Size.fromHeight(54),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: const Text(
                            'Skip',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: _isFinishing ? null : _nextPage,
                          style: FilledButton.styleFrom(
                            backgroundColor: _IntroColors.sage,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(54),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  _pageIndex == _pages.length - 1
                                      ? 'Start Learning'
                                      : 'Next',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 5),
                              const Icon(Icons.arrow_forward_rounded, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
