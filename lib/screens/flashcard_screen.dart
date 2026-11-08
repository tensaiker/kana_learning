import '../theme/cozy_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Persists individual Kana difficulty ratings and audio settings
import 'dart:math' as math;
import 'practice_screen.dart'; // Imports FlashcardQuestionType enum
import '../services/progress_service.dart'; // Persistence service for kana mastery and review counts
import '../utils/tactile_feedback.dart'; // Tactile haptics and mechanical sound feedback

// --- COLOR PALETTE ---
class AppColors {
  static Color get cream => CozyPalette.cream;
  static Color get beige => CozyPalette.beige;
  static Color get sand => CozyPalette.sand;
  static Color get taupe => CozyPalette.taupe;
  static Color get textDark => CozyPalette.textDark;
  static Color get textLight => CozyPalette.textLight;

  // 3D Rating button colors matching the stationery palette
  static Color get ratingAgain =>
      CozyPalette.flashcardRatingAgain; // Soft pastel red
  static Color get ratingHard =>
      CozyPalette.flashcardRatingHard; // Soft pastel orange
  static Color get ratingGood => CozyPalette.sage; // Sage green
  static Color get ratingEasy => CozyPalette.ratingEasy; // Soft pastel blue
}

/// Interactive 3D Flashcard Screen with Audio & Pronunciation Consistency.
///
/// Features & Guidance:
/// 1. Synchronized Audio Playback:
///    - Reads `settings_speech_rate`, `settings_speech_volume`, and master sound toggles
///      (`settings_sound_enabled`, `settings_master_sound`, or `settings_sound_fx`) from
///      SharedPreferences, maintaining exact pronunciation consistency with Quiz and Profile settings.
///    - All audio triggers strictly route through [_speakKana] to honor mute preferences and volume limits.
/// 2. 3D Perspective Flip:
///    - Flips seamlessly between question and answer with depth perspective.
/// 3. Spaced Repetition Tags:
///    - Rating a card persists `kana_difficulty_<kana>` (Again, Hard, Good, Easy) for Practice Hub Quiz filtering
///      without interrupting or leaving the flashcard deck.
class FlashcardScreen extends StatefulWidget {
  final String title;
  final List<Map<String, String>> cards;
  final FlashcardQuestionType questionType;

  const FlashcardScreen({
    super.key,
    required this.title,
    this.cards = const [
      {'kana': 'あ', 'romaji': 'a'},
      {'kana': 'い', 'romaji': 'i'},
      {'kana': 'う', 'romaji': 'u'},
      {'kana': 'え', 'romaji': 'e'},
      {'kana': 'お', 'romaji': 'o'},
    ],
    this.questionType = FlashcardQuestionType.kanaToRomaji,
  });

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen>
    with SingleTickerProviderStateMixin {
  late List<Map<String, String>> _flashcards;
  int _currentIndex = 0;
  bool _isFlipped = false;

  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  // Integrated native speech engine
  final FlutterTts _flutterTts = FlutterTts();

  // Persistent audio configuration matching Profile/Settings
  double _speechRate = 0.5;
  double _speechVolume = 1.0;
  bool _isSoundEnabled = true;

  // Cached SharedPreferences reference for fast O(1) rating saves
  SharedPreferences? _prefs;

  // These counts describe only the current flashcard round. They do NOT
  // replace or modify the per-Kana SRS ratings saved in SharedPreferences.
  final Map<String, int> _sessionRatings = {
    'Again': 0,
    'Hard': 0,
    'Good': 0,
    'Easy': 0,
  };
  bool _isReviewComplete = false;
  bool _isSavingRating = false; // Ignore rapid repeat taps while saving.

  @override
  void initState() {
    super.initState();
    _flashcards = widget.cards.isNotEmpty
        ? List.from(widget.cards)
        : const [
            {'kana': 'あ', 'romaji': 'a'},
          ];

    _initTtsAndStorage();

    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );

    // If initial question mode is audio-only, speak immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndPlayCurrentCardAudio(isInitial: true);
    });
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _flipController.dispose();
    super.dispose();
  }

  /// Initializes TTS audio preferences and pre-caches SharedPreferences
  Future<void> _initTtsAndStorage() async {
    _prefs = await SharedPreferences.getInstance();
    _speechRate = _prefs?.getDouble('settings_speech_rate') ?? 0.5;
    _speechVolume = _prefs?.getDouble('settings_speech_volume') ?? 1.0;
    _isSoundEnabled =
        _prefs?.getBool('settings_sound_enabled') ??
        _prefs?.getBool('settings_master_sound') ??
        _prefs?.getBool('settings_sound_fx') ??
        true;

    await _flutterTts.setLanguage("ja-JP");
    await _flutterTts.setSpeechRate(_speechRate);
    await _flutterTts.setVolume(_isSoundEnabled ? _speechVolume : 0.0);
    await _flutterTts.setPitch(1.0);
  }

  /// Speaks the target kana character using persistent speech settings.
  Future<void> _speakKana(String kana) async {
    if (!_isSoundEnabled || _speechVolume <= 0.0 || kana.isEmpty) return;
    await _flutterTts.stop();
    await _flutterTts.setSpeechRate(_speechRate);
    await _flutterTts.setVolume(_speechVolume);
    await _flutterTts.speak(kana);
  }

  void _checkAndPlayCurrentCardAudio({bool isInitial = false}) {
    final currentType = _resolveQuestionTypeForCurrentCard();
    if (currentType == FlashcardQuestionType.listening) {
      _speakKana(_flashcards[_currentIndex]['kana'] ?? '');
    }
  }

  /// Determines question type (handles mix mode dynamically per card index)
  FlashcardQuestionType _resolveQuestionTypeForCurrentCard() {
    if (widget.questionType == FlashcardQuestionType.mix) {
      const modes = [
        FlashcardQuestionType.kanaToRomaji,
        FlashcardQuestionType.listening,
        FlashcardQuestionType.romajiToKana,
      ];
      return modes[_currentIndex % modes.length];
    }
    return widget.questionType;
  }

  void _toggleFlip() {
    if (_flipController.isAnimating) return;

    // Tactile tick when flipping card
    TactileFeedback.toggle();

    setState(() => _isFlipped = !_isFlipped);
    if (_isFlipped) {
      _flipController.forward();
      // Speak audio when card flips to reveal answer
      _speakKana(_flashcards[_currentIndex]['kana'] ?? '');
    } else {
      _flipController.reverse();
    }
  }

  /// Rates memory recall, logs activity in ProgressService, saves difficulty tag
  /// for the Quiz filter, and advances directly to the next card (NO quiz navigation).
  Future<void> _rateCard(String rating) async {
    if (_isSavingRating || _isReviewComplete) return;
    _isSavingRating = true;

    try {
      // Same existing progress and storage behavior as before this UI change.
      ProgressService.instance.recordFlashcardReviewed();
      final currentCard = _flashcards[_currentIndex];
      final currentKana = currentCard['kana'] ?? '';

      if (currentKana.isNotEmpty) {
        final prefs = _prefs ?? await SharedPreferences.getInstance();
        await prefs.setString('kana_difficulty_$currentKana', rating);

        // Only Good/Easy contribute to mastery, exactly as before.
        if (rating == 'Good' || rating == 'Easy') {
          ProgressService.instance.markKanaMastered(currentKana);
        }
      }

      if (rating == 'Good' || rating == 'Easy') {
        TactileFeedback.success();
      } else {
        TactileFeedback.error();
      }

      if (!mounted) return;
      // Record this session's rating only after persistence finishes.
      _sessionRatings[rating] = (_sessionRatings[rating] ?? 0) + 1;

      if (_currentIndex < _flashcards.length - 1) {
        await _flipController.reverse();
        if (!mounted) return;
        setState(() {
          _currentIndex++;
          _isFlipped = false;
        });
        _checkAndPlayCurrentCardAudio();
      } else {
        // Display results in this same screen: no dialog or extra route.
        setState(() => _isReviewComplete = true);
      }
    } finally {
      _isSavingRating = false;
    }
  }

  /// Replay the same selected deck. The session counts start fresh, but the
  /// learner's previously saved SRS ratings and app progress remain intact.
  void _restartReview() {
    TactileFeedback.press();
    _flipController.reset();
    setState(() {
      _currentIndex = 0;
      _isFlipped = false;
      _isReviewComplete = false;
      for (final key in _sessionRatings.keys) {
        _sessionRatings[key] = 0;
      }
    });
    _checkAndPlayCurrentCardAudio();
  }

  Widget _buildCompletionScreen() {
    final reviewed = _sessionRatings.values.fold<int>(
      0,
      (total, count) => total + count,
    );
    final remembered =
        (_sessionRatings['Good'] ?? 0) + (_sessionRatings['Easy'] ?? 0);
    final toReview =
        (_sessionRatings['Again'] ?? 0) + (_sessionRatings['Hard'] ?? 0);

    return Scaffold(
      backgroundColor: AppColors.beige,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 12, 20, 14),
              decoration: BoxDecoration(
                color: AppColors.sand,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
                border: Border(
                  bottom: BorderSide(color: CozyPalette.outline, width: 2),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Back to practice',
                    icon: Icon(Icons.close, color: AppColors.textDark),
                    onPressed: _leaveFlashcards,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Flashcard Results',
                          style: TextStyle(
                            color: AppColors.textDark,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.textLight,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.style_outlined, color: AppColors.textDark),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _completionCard(
                      child: Column(
                        children: [
                          Container(
                            width: 62,
                            height: 62,
                            decoration: BoxDecoration(
                              color: CozyPalette.lightSageShade,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: CozyPalette.outline,
                                width: 1.2,
                              ),
                            ),
                            child: Icon(
                              Icons.auto_awesome_outlined,
                              size: 33,
                              color: CozyPalette.basicGreen,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Review Complete!',
                            style: TextStyle(
                              color: AppColors.textDark,
                              fontSize: 23,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Nice work reviewing your Japanese Kana.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textLight,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '$reviewed/${_flashcards.length}',
                            style: TextStyle(
                              color: AppColors.textDark,
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            'Cards reviewed',
                            style: TextStyle(
                              color: AppColors.textLight,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 14),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: reviewed / _flashcards.length,
                              minHeight: 9,
                              backgroundColor: AppColors.beige,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                CozyPalette.basicGreen,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _flashcardStat(
                                  icon: Icons.check_circle_outline,
                                  label: 'Remembered',
                                  value: '$remembered',
                                  color: CozyPalette.basicGreen,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _flashcardStat(
                                  icon: Icons.refresh_rounded,
                                  label: 'Review again',
                                  value: '$toReview',
                                  color: AppColors.ratingHard,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Remembered = Good or Easy ratings. '
                            'This is self-rated recall, not quiz accuracy.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textLight,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _completionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Recall Ratings',
                            style: TextStyle(
                              color: AppColors.textDark,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _ratingRow(
                            label: 'Again',
                            description: 'Needs more practice',
                            count: _sessionRatings['Again'] ?? 0,
                            icon: Icons.refresh_rounded,
                            color: AppColors.ratingAgain,
                          ),
                          const SizedBox(height: 10),
                          _ratingRow(
                            label: 'Hard',
                            description: 'Difficult to remember',
                            count: _sessionRatings['Hard'] ?? 0,
                            icon: Icons.sentiment_dissatisfied_outlined,
                            color: AppColors.ratingHard,
                          ),
                          const SizedBox(height: 10),
                          _ratingRow(
                            label: 'Good',
                            description: 'Remembered correctly',
                            count: _sessionRatings['Good'] ?? 0,
                            icon: Icons.sentiment_satisfied_outlined,
                            color: AppColors.ratingGood,
                          ),
                          const SizedBox(height: 10),
                          _ratingRow(
                            label: 'Easy',
                            description: 'Remembered easily',
                            count: _sessionRatings['Easy'] ?? 0,
                            icon: Icons.sentiment_very_satisfied_outlined,
                            color: AppColors.ratingEasy,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _completionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Characters Practiced',
                            style: TextStyle(
                              color: AppColors.textDark,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final word in _flashcards.take(16))
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: CozyPalette.lightSageShade,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: CozyPalette.outline,
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    word['kana'] ?? '',
                                    style: TextStyle(
                                      color: AppColors.textDark,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              if (_flashcards.length > 16)
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Text(
                                    '+${_flashcards.length - 16} more',
                                    style: TextStyle(
                                      color: AppColors.textLight,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Keep the primary action visible on compact phones.
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
              decoration: BoxDecoration(
                color: AppColors.beige,
                border: Border(
                  top: BorderSide(color: CozyPalette.outline, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _resultAction(
                      label: 'Review Again',
                      icon: Icons.replay_rounded,
                      color: AppColors.sand,
                      onPressed: _restartReview,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _resultAction(
                      label: 'Done',
                      icon: Icons.check_rounded,
                      color: AppColors.taupe,
                      onPressed: _leaveFlashcards,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _leaveFlashcards() {
    TactileFeedback.press();
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      // Consistent with the old completion dialog's root-route fallback.
      _restartReview();
    }
  }

  Widget _completionCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CozyPalette.outline, width: 1.8),
        boxShadow: [
          BoxShadow(
            color: CozyPalette.shadow,
            offset: const Offset(0, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _flashcardStat({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.beige.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CozyPalette.outline, width: 1.2),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 21),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textLight, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _ratingRow({
    required String label,
    required String description,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.beige.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CozyPalette.outline, width: 1.1),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 23),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(color: AppColors.textLight, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            '$count',
            style: TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultAction({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: AppColors.textDark,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: CozyPalette.outline, width: 1.8),
          ),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    CozyPalette.watch(
      context,
    ); // Repaint on light/dark or system theme changes.
    // Results are part of this screen instead of an AlertDialog over the card.
    if (_isReviewComplete) return _buildCompletionScreen();
    final currentType = _resolveQuestionTypeForCurrentCard();
    // Allow 4 equal rating cells with room for padding. Keep the old 60px
    // visual size on normal phones and shrink gently on compact devices.
    final double ratingDiameter = ((MediaQuery.sizeOf(context).width - 64) / 4)
        .clamp(36.0, 60.0)
        .toDouble();

    return Scaffold(
      backgroundColor: AppColors.beige,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: AppColors.sand,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
                border: Border(
                  bottom: BorderSide(color: CozyPalette.outline, width: 2),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new,
                      color: AppColors.textDark,
                      size: 22,
                    ),
                    onPressed: () {
                      TactileFeedback.toggle();
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.title,
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_currentIndex + 1}/${_flashcards.length}',
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Keep the 3D card centered, but scale it down if the device is
            // short. This prevents the bottom controls from pushing the card
            // outside the visible screen on smaller Android phones.
            Expanded(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: GestureDetector(
                    onTap: _toggleFlip,
                    child: AnimatedBuilder(
                      animation: _flipAnimation,
                      builder: (context, child) {
                        final angle = _flipAnimation.value * math.pi;
                        final isFrontVisible = angle < (math.pi / 2);

                        return Transform(
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.001) // Existing 3D perspective
                            ..rotateY(angle),
                          alignment: Alignment.center,
                          child: isFrontVisible
                              ? _buildCardSide(isFront: true, type: currentType)
                              : Transform(
                                  transform: Matrix4.identity()
                                    ..rotateY(math.pi),
                                  alignment: Alignment.center,
                                  child: _buildCardSide(
                                    isFront: false,
                                    type: currentType,
                                  ),
                                ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),

            // Render exactly ONE state at a time. AnimatedCrossFade previously
            // kept both the hint and rating controls alive during transitions,
            // allowing text to overlap the buttons on some devices.
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
              child: SizedBox(
                width: double.infinity,
                height: 126, // Same space before and after flipping the card.
                child: _isFlipped
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Rate recall:',
                            style: TextStyle(
                              color: AppColors.textDark,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Four flexible cells divide the real available width.
                          // The circles also shrink on narrow phones, rather than
                          // overflowing with four fixed 62px buttons.
                          Row(
                            children: [
                              Expanded(
                                child: Center(
                                  child: _build3DRatingButton(
                                    'Again',
                                    AppColors.ratingAgain,
                                    Icons.refresh,
                                    diameter: ratingDiameter,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: _build3DRatingButton(
                                    'Hard',
                                    AppColors.ratingHard,
                                    Icons.sentiment_dissatisfied,
                                    diameter: ratingDiameter,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: _build3DRatingButton(
                                    'Good',
                                    AppColors.ratingGood,
                                    Icons.sentiment_satisfied,
                                    diameter: ratingDiameter,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: _build3DRatingButton(
                                    'Easy',
                                    AppColors.ratingEasy,
                                    Icons.sentiment_very_satisfied,
                                    diameter: ratingDiameter,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    : Center(
                        child: Text(
                          'Tap the card to reveal answer',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textDark,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds Front or Back card view depending on current active question type
  Widget _buildCardSide({
    required bool isFront,
    required FlashcardQuestionType type,
  }) {
    final currentCard = _flashcards[_currentIndex];
    final kana = currentCard['kana'] ?? '';
    final romaji = currentCard['romaji'] ?? '';

    Widget content;

    if (isFront) {
      // Front View
      switch (type) {
        case FlashcardQuestionType.kanaToRomaji:
          content = Text(
            kana,
            style: TextStyle(
              fontSize: 120,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          );
          break;

        case FlashcardQuestionType.romajiToKana:
          content = Text(
            romaji,
            style: TextStyle(
              fontSize: 90,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          );
          break;

        case FlashcardQuestionType.listening:
          content = Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                iconSize: 72,
                icon: Icon(Icons.volume_up_rounded, color: AppColors.textDark),
                onPressed: () {
                  TactileFeedback.press();
                  _speakKana(kana);
                },
              ),
              const SizedBox(height: 8),
              Text(
                'Tap to listen again',
                style: TextStyle(color: AppColors.textLight, fontSize: 14),
              ),
            ],
          );
          break;

        case FlashcardQuestionType.mix:
          content = Text(
            kana,
            style: TextStyle(fontSize: 120, color: AppColors.textDark),
          );
          break;
      }
    } else {
      // Back View: Shows full character, romaji translation, and audio replay
      content = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            kana,
            style: TextStyle(
              fontSize: 100,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                romaji,
                style: TextStyle(
                  fontSize: 32,
                  color: AppColors.textLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () {
                  TactileFeedback.press();
                  _speakKana(kana);
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.sand,
                    shape: BoxShape.circle,
                    border: Border.all(color: CozyPalette.outline, width: 1.5),
                  ),
                  child: Icon(
                    Icons.volume_up_rounded,
                    color: AppColors.textDark,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Container(
      width: 290,
      height: 380,
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: CozyPalette.outline, width: 2),
        boxShadow: [
          BoxShadow(
            color: CozyPalette.shadow,
            offset: Offset(0, 5),
            blurRadius: 0,
          ),
        ],
      ),
      child: Center(child: content),
    );
  }

  /// 3D tactile button for spaced repetition ratings
  Widget _build3DRatingButton(
    String label,
    Color color,
    IconData icon, {
    required double diameter,
  }) {
    return _Interactive3DRatingButton(
      label: label,
      color: color,
      icon: icon,
      diameter: diameter,
      onTap: () => _rateCard(label),
    );
  }
}

class _Interactive3DRatingButton extends StatefulWidget {
  final String label;
  final Color color;
  final IconData icon;
  final double diameter;
  final VoidCallback onTap;

  const _Interactive3DRatingButton({
    required this.label,
    required this.color,
    required this.icon,
    required this.diameter,
    required this.onTap,
  });

  @override
  State<_Interactive3DRatingButton> createState() =>
      _Interactive3DRatingButtonState();
}

class _Interactive3DRatingButtonState
    extends State<_Interactive3DRatingButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    CozyPalette.watch(
      context,
    ); // Repaint on light/dark or system theme changes.
    return GestureDetector(
      onTapDown: (_) {
        TactileFeedback.press();
        setState(() => _isPressed = true);
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeInOut,
            width: widget.diameter,
            height: widget.diameter,
            transform: Matrix4.translationValues(0, _isPressed ? 4.0 : 0.0, 0),
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
              border: Border.all(color: CozyPalette.outline, width: 2),
              boxShadow: [
                BoxShadow(
                  color: CozyPalette.shadow,
                  offset: Offset(0, _isPressed ? 0 : 4.0),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Icon(
              widget.icon,
              color: AppColors.textDark,
              size: widget.diameter < 48 ? 22 : 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
