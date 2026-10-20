import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart'; // Imports native text-to-speech engine
import 'dart:math';
import '../services/progress_service.dart'; // Imports shared_preferences persistence service

// --- COLOR PALETTE ---
class AppColors {
  static const Color cream = Color(0xFFFDF8F3);
  static const Color beige = Color(0xFFEADFD1);
  static const Color sand = Color(0xFFDCC6A8);
  static const Color taupe = Color(0xFFC6B8A5);
  static const Color textDark = Color(0xFF5D534A);
  static const Color textLight = Color(0xFF8B8076);
  static const Color sage = Color(0xFFB7C9B2);

  // Validation Colors
  static const Color correctBg = Color(0xFFB4CDB4); // Soft pastel green
  static const Color correctIcon = Color(0xFF5CA95C);
  static const Color incorrectBg = Color(0xFFD88A82); // Soft pastel red
  static const Color incorrectIcon = Color(0xFFC95B50);
}

// The 4 distinct types of questions in the quiz
enum QuizType {
  seeKanaPickRomaji, // Visual: Kana -> Romaji
  seeRomajiPickKana, // Visual: Romaji -> Kana
  listenPickRomaji, // Audio: Sound -> Romaji
  listenPickKana, // Audio: Sound -> Kana
}

// Button states for feedback rendering
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

class QuizScreen extends StatefulWidget {
  final String rowTitle;
  final String writingSystem; // e.g., "Hiragana" or "Katakana"
  final List<Map<String, String>> characters;

  const QuizScreen({
    super.key,
    required this.rowTitle,
    required this.writingSystem,
    required this.characters,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late List<QuizQuestion> _questions;
  int _currentQuestionIndex = 0;
  final Random _random = Random();

  // Answer validation states
  bool _hasAnswered = false;
  String? _selectedOption;
  bool _isQuizComplete = false;

  // Native text-to-speech engine instance
  final FlutterTts _flutterTts = FlutterTts();

  // Score tracking per category
  final Map<QuizType, int> _scores = {
    QuizType.seeKanaPickRomaji: 0,
    QuizType.seeRomajiPickKana: 0,
    QuizType.listenPickRomaji: 0,
    QuizType.listenPickKana: 0,
  };

  @override
  void initState() {
    super.initState();
    _initTts();
    _generateQuestions();
    // Automatically trigger audio if the first question is a listening question
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speakCurrentQuestion();
    });
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  /// Configures the native TTS engine with Japanese language settings
  Future<void> _initTts() async {
    await _flutterTts.setLanguage("ja-JP");
    await _flutterTts.setSpeechRate(0.5); // Slower rate ideal for learners
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  /// Speaks the target kana aloud if the current question requires audio
  Future<void> _speakCurrentQuestion() async {
    if (_questions.isEmpty || _isQuizComplete) return;
    final currentQ = _questions[_currentQuestionIndex];
    if (currentQ.type == QuizType.listenPickRomaji ||
        currentQ.type == QuizType.listenPickKana) {
      await _flutterTts.stop();
      await _flutterTts.speak(currentQ.targetKana);
    }
  }

  /// Generates exactly 5 questions for each of the 4 quiz types (20 total).
  void _generateQuestions() {
    _questions = [];
    final validChars = widget.characters
        .where((c) => c['kana']!.isNotEmpty)
        .toList();

    if (validChars.isEmpty) return;

    for (var type in QuizType.values) {
      for (int i = 0; i < 5; i++) {
        final targetChar = validChars[_random.nextInt(validChars.length)];
        List<String> options = [];

        bool isRomajiOptions =
            (type == QuizType.seeKanaPickRomaji ||
            type == QuizType.listenPickRomaji);

        String correctOption = isRomajiOptions
            ? targetChar['romaji']!
            : targetChar['kana']!;
        options.add(correctOption);

        List<Map<String, String>> availableDistractors = List.from(validChars)
          ..removeWhere((c) => c['kana'] == targetChar['kana']);

        availableDistractors.shuffle(_random);

        for (int j = 0; j < min(3, availableDistractors.length); j++) {
          options.add(
            isRomajiOptions
                ? availableDistractors[j]['romaji']!
                : availableDistractors[j]['kana']!,
          );
        }

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

  /// Saves the current question checkpoint to local storage when exiting.
  /// For example, exiting on question 5 saves 5/20 so the Home tab and Progress
  /// service immediately reflect 5/20 progress.
  void _exitAndSaveProgress() {
    int progressCount = _isQuizComplete
        ? _questions.length
        : (_currentQuestionIndex + 1);

    ProgressService.instance.saveRowProgress(
      writingSystem: widget.writingSystem,
      rowTitle: widget.rowTitle,
      currentQuestion: progressCount,
      totalQuestions: _questions.length,
    );

    Navigator.pop(context);
  }

  /// Processes the user's answer, logs mastery in local storage, shows validation, and advances.
  void _handleAnswer(String selectedOption) async {
    if (_hasAnswered) return; // Prevent double-clicking

    final currentQ = _questions[_currentQuestionIndex];
    bool isRomajiOptions =
        (currentQ.type == QuizType.seeKanaPickRomaji ||
        currentQ.type == QuizType.listenPickRomaji);
    String correctAnswer = isRomajiOptions
        ? currentQ.targetRomaji
        : currentQ.targetKana;

    setState(() {
      _hasAnswered = true;
      _selectedOption = selectedOption;

      // Update score and persist character mastery when answer is correct
      if (selectedOption == correctAnswer) {
        _scores[currentQ.type] = _scores[currentQ.type]! + 1;

        // Persists the mastered kana to SharedPreferences in real time.
        ProgressService.instance.markKanaMastered(currentQ.targetKana);
      }
    });

    // Wait for 1.5 seconds to let the user see the correct/incorrect colors
    await Future.delayed(const Duration(milliseconds: 1500));

    // Proceed to next question or complete quiz
    if (!mounted) return;
    setState(() {
      if (_currentQuestionIndex < _questions.length - 1) {
        _currentQuestionIndex++;
        _hasAnswered = false;
        _selectedOption = null;
        _speakCurrentQuestion(); // Speak if next question is listening type
      } else {
        _isQuizComplete = true;

        // Mark full row completion (e.g., 20/20) and unlock the prerequisite for the next row
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
    if (_questions.isEmpty) {
      return const Scaffold(
        backgroundColor: AppColors.beige,
        body: Center(child: Text("No quiz data.")),
      );
    }

    if (_isQuizComplete) {
      return _buildSummaryScreen();
    }

    final currentQ = _questions[_currentQuestionIndex];

    return Scaffold(
      backgroundColor: AppColors.beige,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Top Header (Frame 135: Close 'X', Writing System, and '${rowTitle} learn')
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.textDark,
                      size: 28,
                    ),
                    onPressed: _exitAndSaveProgress,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
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
                        Center(
                          child: Text(
                            '${widget.rowTitle} learn',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 2. Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
                        widthFactor:
                            (_currentQuestionIndex + 1) / _questions.length,
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

            // 3. Main Question Area
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
                          _getInstructionText(currentQ.type),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(child: _buildQuestionContent(currentQ)),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 4. Answer Grid (2x2)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildChoiceButton(
                          currentQ,
                          currentQ.options[0],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildChoiceButton(
                          currentQ,
                          currentQ.options[1],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildChoiceButton(
                          currentQ,
                          currentQ.options[2],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildChoiceButton(
                          currentQ,
                          currentQ.options[3],
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
    );
  }

  /// Evaluates the state of a button based on the user's answer to display the correct colors/icons.
  Widget _buildChoiceButton(QuizQuestion currentQ, String option) {
    if (option.isEmpty) return const SizedBox();

    ButtonState state = ButtonState.idle;

    if (_hasAnswered) {
      bool isRomajiOptions =
          (currentQ.type == QuizType.seeKanaPickRomaji ||
          currentQ.type == QuizType.listenPickRomaji);
      String correctAnswer = isRomajiOptions
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

  /// The final score summary screen shown at the end of the quiz
  Widget _buildSummaryScreen() {
    int totalCorrect = _scores.values.fold(0, (sum, val) => sum + val);

    return Scaffold(
      backgroundColor: AppColors.beige,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Header
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
                    onPressed: _exitAndSaveProgress,
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
                        '${widget.rowTitle} learn',
                        style: const TextStyle(
                          fontSize: 16,
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

            // Summary Card
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

                      // Breakdown Rows
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

                      // Continue Button to exit quiz and record full progress
                      GestureDetector(
                        onTap: _exitAndSaveProgress,
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
    int totalForType = _questions.where((q) => q.type == type).length;
    int scoreForType = _scores[type] ?? 0;

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
          Interactive3DSpeakerButton(
            onTap: () async {
              await _flutterTts.stop();
              await _flutterTts.speak(q.targetKana);
            },
          ),
          const SizedBox(height: 16),
          const Text(
            "Tap to hear it again",
            style: TextStyle(fontSize: 16, color: AppColors.textDark),
          ),
        ],
      );
    } else {
      bool isKana = q.type == QuizType.seeKanaPickRomaji;
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
// INTERACTIVE 3D BUTTON COMPONENTS
// -----------------------------------------------------------------------------

/// The animated 2x2 grid choice buttons with validation colors and icons.
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
        if (widget.state == ButtonState.idle) setState(() => _isPressed = true);
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
            // Result Validation Icons
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

/// The animated large speaker button for audio questions.
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
      onTapDown: (_) => setState(() => _isPressed = true),
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
