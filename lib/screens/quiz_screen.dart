import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart'; // Native text-to-speech engine[cite: 13]
import 'package:shared_preferences/shared_preferences.dart'; // Persistent storage for audio settings and SRS ratings[cite: 13]
import 'dart:math';
import '../services/progress_service.dart'; // Progress persistence and row unlock service[cite: 13]
import '../utils/tactile_feedback.dart'; // Tactile haptic and audio click feedback[cite: 13]

// --- COLOR PALETTE ---
class AppColors {
  static const Color cream = Color(0xFFFDF8F3);
  static const Color beige = Color(0xFFEADFD1);
  static const Color sand = Color(0xFFDCC6A8);
  static const Color taupe = Color(0xFFC6B8A5);
  static const Color textDark = Color(0xFF5D534A);
  static const Color textLight = Color(0xFF8B8076);
  static const Color sage = Color(0xFFB7C9B2);

  // Validation Colors[cite: 13]
  static const Color correctBg = Color(
    0xFFB4CDB4,
  ); // Soft pastel green[cite: 13]
  static const Color correctIcon = Color(0xFF5CA95C);
  static const Color incorrectBg = Color(
    0xFFD88A82,
  ); // Soft pastel red[cite: 13]
  static const Color incorrectIcon = Color(0xFFC95B50);

  // Difficulty Selector Colors (matching Flashcard SRS palette)[cite: 13]
  static const Color ratingAgain = Color(0xFFD88A82); // Soft red[cite: 13]
  static const Color ratingHard = Color(0xFFE29E57); // Warm orange[cite: 13]
  static const Color ratingGood = Color(0xFF9FB89A); // Soft green[cite: 13]
  static const Color ratingEasy = Color(0xFFA5C4E5); // Soft blue[cite: 13]
}

// The 4 distinct types of questions in the quiz[cite: 13]
enum QuizType {
  seeKanaPickRomaji, // Visual: Kana -> Romaji[cite: 13]
  seeRomajiPickKana, // Visual: Romaji -> Kana[cite: 13]
  listenPickRomaji, // Audio: Sound -> Romaji[cite: 13]
  listenPickKana, // Audio: Sound -> Kana[cite: 13]
}

// Button states for feedback rendering[cite: 13]
enum ButtonState { idle, correct, incorrect, revealedCorrect }

class QuizQuestion {
  final QuizType type;
  final String targetKana;
  final String targetRomaji;
  final List<String> options;

  QuizQuestion({
    required this.type,
    required this.targetKana,
    required this.targetRomaji,
    required this.options,
  });
}

/// Interactive Kana Quiz Screen with Persistent Audio & Pronunciation Consistency.
///
/// Features & Guidelines:
/// 1. **Audio & Pronunciation Consistency**:
///    - Synchronizes directly with user preferences saved in Settings/Profile:
///      `settings_speech_rate` (default: 0.5), `settings_speech_volume` (default: 1.0),
///      and master sound toggles (`settings_sound_enabled`, `settings_master_sound`, or `settings_sound_fx`).
///    - Re-applies rate and volume parameters prior to any pronunciation to ensure consistent playback.
///    - Centralizes TTS calls through [_speakKana] to prevent overlapping speech queues and honor mute toggles.
/// 2. **Difficulty Selector Isolation**:
///    - [enableDifficultySelector] defaults to `false` for Learn lessons (clean header, no sliders icon)[cite: 13].
///    - Set to `true` exclusively when launched from Practice Hub to show the difficulty selector and tune button[cite: 13].
class QuizScreen extends StatefulWidget {
  final String rowTitle;
  final String writingSystem; // e.g., "Hiragana" or "Katakana"[cite: 13]
  final List<Map<String, String>> characters;
  final String
  difficulty; // Initial difficulty setting (defaults to 'All')[cite: 13]
  final bool
  enableDifficultySelector; // True ONLY when launched from Practice Hub quiz[cite: 13]

  const QuizScreen({
    super.key,
    required this.rowTitle,
    required this.writingSystem,
    required this.characters,
    this.difficulty = 'All',
    this.enableDifficultySelector =
        false, // Defaults to false for Learn lessons[cite: 13]
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  // Pre-initialized to empty list to avoid LateInitializationError during async init[cite: 13]
  List<QuizQuestion> _questions = [];
  int _currentQuestionIndex = 0;
  final Random _random = Random();

  // Answer validation states[cite: 13]
  bool _hasAnswered = false;
  String? _selectedOption;
  bool _isQuizComplete = false;

  // Difficulty filter state[cite: 13]
  String _selectedDifficulty = 'All';
  bool _showDifficultySelector = false;
  Map<String, String> _difficultyRatingMap = {};

  // Native text-to-speech engine instance and persistent audio settings[cite: 13]
  final FlutterTts _flutterTts = FlutterTts();
  double _speechRate = 0.5;
  double _speechVolume = 1.0;
  bool _isSoundEnabled = true;

  // Score tracking per category[cite: 13]
  final Map<QuizType, int> _scores = {
    QuizType.seeKanaPickRomaji: 0,
    QuizType.seeRomajiPickKana: 0,
    QuizType.listenPickRomaji: 0,
    QuizType.listenPickKana: 0,
  };

  @override
  void initState() {
    super.initState();
    _selectedDifficulty = widget.difficulty;
    _initQuiz();
  }

  /// Concurrently initializes audio settings, loads stored SRS difficulty ratings, and generates questions[cite: 13]
  Future<void> _initQuiz() async {
    await Future.wait([_initTts(), _loadDifficultyRatings()]);

    if (!mounted) return;
    setState(() {
      _generateQuestions();
    });

    // Automatically trigger audio if the first question is an audio listening question[cite: 13]
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speakCurrentQuestion();
    });
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  /// Configures native TTS engine synchronized with user audio preferences from SharedPreferences
  Future<void> _initTts() async {
    final prefs = await SharedPreferences.getInstance();
    _speechRate = prefs.getDouble('settings_speech_rate') ?? 0.5;
    _speechVolume = prefs.getDouble('settings_speech_volume') ?? 1.0;
    _isSoundEnabled =
        prefs.getBool('settings_sound_enabled') ??
        prefs.getBool('settings_master_sound') ??
        prefs.getBool('settings_sound_fx') ??
        true;

    await _flutterTts.setLanguage("ja-JP");
    await _flutterTts.setSpeechRate(_speechRate);
    await _flutterTts.setVolume(_isSoundEnabled ? _speechVolume : 0.0);
    await _flutterTts.setPitch(1.0);
  }

  /// Speaks the target kana aloud using synchronized speech rate, volume, and master sound settings.
  Future<void> _speakKana(String kana) async {
    if (!_isSoundEnabled || _speechVolume <= 0.0 || kana.isEmpty) return;
    await _flutterTts.stop();
    await _flutterTts.setSpeechRate(_speechRate);
    await _flutterTts.setVolume(_speechVolume);
    await _flutterTts.speak(kana);
  }

  /// Loads individual Kana SRS difficulty history from persistent storage[cite: 13]
  Future<void> _loadDifficultyRatings() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, String> ratings = {};

    for (final char in widget.characters) {
      final kana = char['kana'];
      if (kana != null && kana.isNotEmpty) {
        final rating = prefs.getString('kana_difficulty_$kana');
        if (rating != null) {
          ratings[kana] = rating;
        }
      }
    }
    _difficultyRatingMap = ratings;
  }

  /// Speaks the target kana aloud if the current question requires audio[cite: 13]
  Future<void> _speakCurrentQuestion() async {
    if (_questions.isEmpty ||
        _isQuizComplete ||
        _showDifficultySelector ||
        _currentQuestionIndex >= _questions.length) {
      return;
    }
    final currentQ = _questions[_currentQuestionIndex];
    if (currentQ.type == QuizType.listenPickRomaji ||
        currentQ.type == QuizType.listenPickKana) {
      await _speakKana(currentQ.targetKana);
    }
  }

  /// Generates questions. When opened from Learn (enableDifficultySelector == false),
  /// all row characters are tested directly without filtering by SRS difficulty[cite: 13].
  void _generateQuestions() {
    _questions = [];
    final validChars = widget.characters
        .where((c) => c['kana'] != null && c['kana']!.trim().isNotEmpty)
        .toList();

    if (validChars.isEmpty) return;

    final ps = ProgressService.instance;
    List<Map<String, String>> targetPool = [];

    // Filter characters according to selected difficulty only if difficulty mode is enabled[cite: 13]
    if (!widget.enableDifficultySelector || _selectedDifficulty == 'All') {
      targetPool = List.from(validChars);
    } else {
      // 1. Direct match: Kana tagged explicitly with this difficulty during Flashcards[cite: 13]
      targetPool = validChars.where((c) {
        final kana = c['kana']!;
        return _difficultyRatingMap[kana] == _selectedDifficulty;
      }).toList();

      // 2. Secondary heuristic fallback if no cards have been tagged with this difficulty yet[cite: 13]
      if (targetPool.isEmpty) {
        if (_selectedDifficulty == 'Easy' || _selectedDifficulty == 'Good') {
          targetPool = validChars
              .where((c) => ps.isKanaMastered(c['kana']!))
              .toList();
        } else if (_selectedDifficulty == 'Hard' ||
            _selectedDifficulty == 'Again') {
          targetPool = validChars
              .where((c) => !ps.isKanaMastered(c['kana']!))
              .toList();
        }
      }
    }

    // Graceful fallback to all available characters if the filtered pool is empty[cite: 13]
    if (targetPool.isEmpty) {
      targetPool = List.from(validChars);
    }

    // Build exactly 5 questions per QuizType (20 questions total)[cite: 13]
    for (var type in QuizType.values) {
      for (int i = 0; i < 5; i++) {
        final targetChar = targetPool[_random.nextInt(targetPool.length)];
        final List<String> options = [];

        final bool isRomajiOptions =
            (type == QuizType.seeKanaPickRomaji ||
            type == QuizType.listenPickRomaji);

        final String correctOption = isRomajiOptions
            ? targetChar['romaji']!
            : targetChar['kana']!;
        options.add(correctOption);

        // Filter and pick distractors without cloning the entire array multiple times[cite: 13]
        final availableDistractors = validChars
            .where((c) => c['kana'] != targetChar['kana'])
            .toList();
        availableDistractors.shuffle(_random);

        for (int j = 0; j < min(3, availableDistractors.length); j++) {
          options.add(
            isRomajiOptions
                ? availableDistractors[j]['romaji']!
                : availableDistractors[j]['kana']!,
          );
        }

        // Pad up to 4 options if the dataset has fewer than 4 distinct characters[cite: 13]
        while (options.length < 4) {
          options.add("");
        }

        options.shuffle(_random);

        _questions.add(
          QuizQuestion(
            type: type,
            targetKana: targetChar['kana']!,
            targetRomaji: targetChar['romaji']!,
            options: options,
          ),
        );
      }
    }

    _questions.shuffle(_random);
  }

  /// Saves the current question checkpoint to local storage when exiting[cite: 13]
  void _exitAndSaveProgress() {
    final int totalQuestions = _questions.isEmpty ? 20 : _questions.length;
    final int progressCount = _isQuizComplete
        ? totalQuestions
        : min(_currentQuestionIndex + 1, totalQuestions);

    ProgressService.instance.saveRowProgress(
      writingSystem: widget.writingSystem,
      rowTitle: widget.rowTitle,
      currentQuestion: progressCount,
      totalQuestions: totalQuestions,
    );

    Navigator.pop(context);
  }

  /// Processes user answer, logs mastery in ProgressService, updates ratings, and advances[cite: 13]
  void _handleAnswer(String selectedOption) async {
    if (_hasAnswered || _questions.isEmpty)
      return; // Prevent double-clicking[cite: 13]

    final currentQ = _questions[_currentQuestionIndex];
    final bool isRomajiOptions =
        (currentQ.type == QuizType.seeKanaPickRomaji ||
        currentQ.type == QuizType.listenPickRomaji);
    final String correctAnswer = isRomajiOptions
        ? currentQ.targetRomaji
        : currentQ.targetKana;

    final bool isCorrect = (selectedOption == correctAnswer);

    setState(() {
      _hasAnswered = true;
      _selectedOption = selectedOption;

      if (isCorrect) {
        _scores[currentQ.type] = _scores[currentQ.type]! + 1;

        // Persist character mastery in real time[cite: 13]
        ProgressService.instance.markKanaMastered(currentQ.targetKana);
        TactileFeedback.success();
      } else {
        TactileFeedback.error();
      }
    });

    // Update SRS difficulty rating in local storage if difficulty mode is enabled[cite: 13]
    if (widget.enableDifficultySelector) {
      final prefs = await SharedPreferences.getInstance();
      final currentRating = _difficultyRatingMap[currentQ.targetKana];
      final String newRating = isCorrect ? (currentRating ?? 'Good') : 'Again';
      if (newRating != currentRating) {
        await prefs.setString(
          'kana_difficulty_${currentQ.targetKana}',
          newRating,
        );
        _difficultyRatingMap[currentQ.targetKana] = newRating;
      }
    }

    // Display validation visual feedback for 1.5 seconds[cite: 13]
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;
    setState(() {
      if (_currentQuestionIndex < _questions.length - 1) {
        _currentQuestionIndex++;
        _hasAnswered = false;
        _selectedOption = null;
        _speakCurrentQuestion(); // Audio trigger for upcoming listening questions[cite: 13]
      } else {
        _isQuizComplete = true;

        // Save full row completion checkpoint (e.g., 20/20)[cite: 13]
        ProgressService.instance.saveRowProgress(
          writingSystem: widget.writingSystem,
          rowTitle: widget.rowTitle,
          currentQuestion: _questions.length,
          totalQuestions: _questions.length,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Gracefully shows loading indicator until async question generation completes[cite: 13]
    if (_questions.isEmpty && !_showDifficultySelector) {
      return const Scaffold(
        backgroundColor: AppColors.beige,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.textDark),
        ),
      );
    }

    if (_isQuizComplete) {
      return _buildSummaryScreen();
    }

    return Scaffold(
      backgroundColor: AppColors.beige,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTopHeader(),

            // Show Difficulty Type selection ONLY if enabled by Practice Hub[cite: 13]
            if (_showDifficultySelector && widget.enableDifficultySelector)
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.cream,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.textDark, width: 2),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.textDark,
                          offset: Offset(0, 4),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: _buildDifficultySelectionView(),
                  ),
                ),
              )
            else ...[
              // 1. Progress Bar[cite: 13]
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.cream,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: AppColors.textDark,
                            width: 1.5,
                          ),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: _questions.isEmpty
                              ? 0.0
                              : (_currentQuestionIndex + 1) / _questions.length,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.taupe,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${_currentQuestionIndex + 1}/${_questions.length} question',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Main Question Area[cite: 13]
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.cream,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.textDark, width: 2),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.beige,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.textDark,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            _getInstructionText(
                              _questions[_currentQuestionIndex].type,
                            ),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: _buildQuestionContent(
                              _questions[_currentQuestionIndex],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 3. Answer Grid (2x2)[cite: 13]
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildChoiceButton(
                            _questions[_currentQuestionIndex],
                            _questions[_currentQuestionIndex].options[0],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildChoiceButton(
                            _questions[_currentQuestionIndex],
                            _questions[_currentQuestionIndex].options[1],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildChoiceButton(
                            _questions[_currentQuestionIndex],
                            _questions[_currentQuestionIndex].options[2],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildChoiceButton(
                            _questions[_currentQuestionIndex],
                            _questions[_currentQuestionIndex].options[3],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // TOP HEADER BAR (CLEANED: NO DIFFICULTY TUNE ICON FOR LEARN TAB)[cite: 13]
  // ===========================================================================
  Widget _buildTopHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: AppColors.sand,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        border: Border(bottom: BorderSide(color: AppColors.textDark, width: 2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.textDark, size: 28),
            onPressed: () {
              TactileFeedback.toggle();
              _exitAndSaveProgress();
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.writingSystem,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                // Only displays '• Difficulty' if launched from Practice Hub[cite: 13]
                Text(
                  widget.enableDifficultySelector
                      ? '${widget.rowTitle} • $_selectedDifficulty'
                      : widget.rowTitle,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
          // Sliders / Tune Icon Button: Rendered ONLY in Practice Hub quiz[cite: 13]
          if (widget.enableDifficultySelector)
            GestureDetector(
              onTap: () {
                TactileFeedback.toggle();
                setState(() {
                  _showDifficultySelector = !_showDifficultySelector;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _showDifficultySelector
                      ? AppColors.taupe
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: AppColors.textDark,
                  size: 24,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ===========================================================================
  // DIFFICULTY TYPE SELECTOR (FOR PRACTICE HUB QUIZ ONLY)[cite: 13]
  // ===========================================================================
  Widget _buildDifficultySelectionView() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Difficulty type',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.beige.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.textDark, width: 1.8),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildCircularDifficultyButton(
                      'Easy',
                      AppColors.ratingEasy,
                    ),
                    _buildCircularDifficultyButton(
                      'Hard',
                      AppColors.ratingHard,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildCircularDifficultyButton(
                      'Good',
                      AppColors.ratingGood,
                    ),
                    _buildCircularDifficultyButton(
                      'Again',
                      AppColors.ratingAgain,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Center(
                  child: _buildCircularDifficultyButton('All', AppColors.sand),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: TextButton(
              onPressed: () {
                TactileFeedback.toggle();
                setState(() => _showDifficultySelector = false);
              },
              child: const Text(
                'Back to options',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularDifficultyButton(String label, Color color) {
    final bool isSelected = _selectedDifficulty == label;
    return GestureDetector(
      onTap: () {
        TactileFeedback.press();
        setState(() {
          _selectedDifficulty = label;
          _showDifficultySelector = false;
          _currentQuestionIndex = 0;
          _hasAnswered = false;
          _selectedOption = null;
          _isQuizComplete = false;
          _scores.updateAll((key, value) => 0);
          _generateQuestions();
        });
        _speakCurrentQuestion();
      },
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.textDark,
            width: isSelected ? 3.5 : 2.0,
          ),
          boxShadow: const [
            BoxShadow(
              color: AppColors.textDark,
              offset: Offset(0, 4),
              blurRadius: 0,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 18,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceButton(QuizQuestion currentQ, String option) {
    if (option.isEmpty) return const SizedBox();

    ButtonState state = ButtonState.idle;

    if (_hasAnswered) {
      final bool isRomajiOptions =
          (currentQ.type == QuizType.seeKanaPickRomaji ||
          currentQ.type == QuizType.listenPickRomaji);
      final String correctAnswer = isRomajiOptions
          ? currentQ.targetRomaji
          : currentQ.targetKana;

      if (option == correctAnswer) {
        state = (_selectedOption == option)
            ? ButtonState.correct
            : ButtonState.revealedCorrect;
      } else if (option == _selectedOption) {
        state = ButtonState.incorrect;
      }
    }

    return Interactive3DChoiceButton(
      label: option,
      state: state,
      onTap: () => _handleAnswer(option),
    );
  }

  Widget _buildSummaryScreen() {
    final int totalCorrect = _scores.values.fold(0, (sum, val) => sum + val);

    return Scaffold(
      backgroundColor: AppColors.beige,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: const BoxDecoration(
                color: AppColors.sand,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
                border: Border(
                  bottom: BorderSide(color: AppColors.textDark, width: 2),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.textDark,
                      size: 28,
                    ),
                    onPressed: () {
                      TactileFeedback.toggle();
                      _exitAndSaveProgress();
                    },
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.writingSystem,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        widget.enableDifficultySelector
                            ? '${widget.rowTitle} • $_selectedDifficulty'
                            : widget.rowTitle,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.cream,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.textDark, width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Total score',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$totalCorrect/${_questions.length}',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 32),

                      _buildScoreRow(
                        "Pick the romaji",
                        QuizType.seeKanaPickRomaji,
                      ),
                      const SizedBox(height: 12),
                      _buildScoreRow(
                        "Pick the kana",
                        QuizType.seeRomajiPickKana,
                      ),
                      const SizedBox(height: 12),
                      _buildScoreRow(
                        "Listen, then pick the romaji",
                        QuizType.listenPickRomaji,
                      ),
                      const SizedBox(height: 12),
                      _buildScoreRow(
                        "Listen, then pick the kana",
                        QuizType.listenPickKana,
                      ),

                      const Spacer(),

                      GestureDetector(
                        onTap: () {
                          TactileFeedback.press();
                          _exitAndSaveProgress();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.taupe,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.textDark,
                              width: 1.5,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: AppColors.textDark,
                                offset: Offset(0, 3),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'Continue >',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreRow(String label, QuizType type) {
    final int totalForType = _questions.where((q) => q.type == type).length;
    final int scoreForType = _scores[type] ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.textDark, width: 1.2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: AppColors.textDark),
          ),
          Text(
            '$scoreForType/$totalForType',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textDark,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _getInstructionText(QuizType type) {
    switch (type) {
      case QuizType.seeKanaPickRomaji:
        return "Pick the romaji";
      case QuizType.seeRomajiPickKana:
        return "Pick the kana";
      case QuizType.listenPickRomaji:
        return "Listen, then pick the romaji";
      case QuizType.listenPickKana:
        return "Listen, then pick the kana";
    }
  }

  Widget _buildQuestionContent(QuizQuestion q) {
    if (q.type == QuizType.listenPickRomaji ||
        q.type == QuizType.listenPickKana) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Interactive3DSpeakerButton(onTap: () => _speakKana(q.targetKana)),
          const SizedBox(height: 16),
          const Text(
            "Tap to hear it again",
            style: TextStyle(fontSize: 16, color: AppColors.textDark),
          ),
        ],
      );
    } else {
      final bool isKana = q.type == QuizType.seeKanaPickRomaji;
      return Text(
        isKana ? q.targetKana : q.targetRomaji,
        style: TextStyle(
          fontSize: isKana ? 120 : 100,
          color: AppColors.textDark,
          height: 1.0,
          fontWeight: isKana ? FontWeight.normal : FontWeight.w500,
        ),
      );
    }
  }
}

// -----------------------------------------------------------------------------
// INTERACTIVE 3D BUTTON COMPONENTS WITH TACTILE CLICKS & HAPTICS[cite: 13]
// -----------------------------------------------------------------------------

/// The animated 2x2 grid choice buttons with validation colors and tactile feedback[cite: 13]
class Interactive3DChoiceButton extends StatefulWidget {
  final String label;
  final ButtonState state;
  final VoidCallback onTap;

  const Interactive3DChoiceButton({
    super.key,
    required this.label,
    required this.state,
    required this.onTap,
  });

  @override
  State<Interactive3DChoiceButton> createState() =>
      _Interactive3DChoiceButtonState();
}

class _Interactive3DChoiceButtonState extends State<Interactive3DChoiceButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    switch (widget.state) {
      case ButtonState.correct:
      case ButtonState.revealedCorrect:
        bgColor = AppColors.correctBg;
        break;
      case ButtonState.incorrect:
        bgColor = AppColors.incorrectBg;
        break;
      case ButtonState.idle:
      default:
        bgColor = AppColors.beige;
        break;
    }

    return GestureDetector(
      onTapDown: (_) {
        if (widget.state == ButtonState.idle) {
          TactileFeedback.press();
          setState(() => _isPressed = true);
        }
      },
      onTapUp: (_) {
        if (widget.state == ButtonState.idle) {
          setState(() => _isPressed = false);
          widget.onTap();
        }
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        height: 80,
        transform: Matrix4.translationValues(0, _isPressed ? 6.0 : 0.0, 0),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.textDark, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.textDark,
              offset: Offset(0, _isPressed ? 0 : 6.0),
              blurRadius: 0,
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                widget.label,
                style: const TextStyle(fontSize: 40, color: AppColors.textDark),
              ),
            ),
            if (widget.state == ButtonState.correct ||
                widget.state == ButtonState.revealedCorrect)
              const Positioned(
                top: 8,
                right: 8,
                child: Icon(
                  Icons.check,
                  color: AppColors.correctIcon,
                  size: 24,
                ),
              ),
            if (widget.state == ButtonState.incorrect)
              const Positioned(
                top: 8,
                right: 8,
                child: Icon(
                  Icons.close,
                  color: AppColors.incorrectIcon,
                  size: 24,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The animated large speaker button for audio questions with tactile feedback[cite: 13]
class Interactive3DSpeakerButton extends StatefulWidget {
  final VoidCallback onTap;

  const Interactive3DSpeakerButton({super.key, required this.onTap});

  @override
  State<Interactive3DSpeakerButton> createState() =>
      _Interactive3DSpeakerButtonState();
}

class _Interactive3DSpeakerButtonState
    extends State<Interactive3DSpeakerButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        width: 140,
        height: 140,
        transform: Matrix4.translationValues(0, _isPressed ? 8.0 : 0.0, 0),
        decoration: BoxDecoration(
          color: AppColors.sand,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.textDark, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.textDark,
              offset: Offset(0, _isPressed ? 0 : 8.0),
              blurRadius: 0,
            ),
          ],
        ),
        child: const Icon(Icons.volume_up, size: 80, color: AppColors.textDark),
      ),
    );
  }
}
