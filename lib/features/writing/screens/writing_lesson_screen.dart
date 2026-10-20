import 'package:flutter/material.dart';
import '../data/kana_data.dart'; // Imports your kana definitions
import '../widgets/writing_canvases.dart'; // Imports the updated painters

class WritingLessonScreen extends StatefulWidget {
  final List<KanaCharacter> lessonCharacters;

  const WritingLessonScreen({super.key, required this.lessonCharacters});

  @override
  State<WritingLessonScreen> createState() => _WritingLessonScreenState();
}

class _WritingLessonScreenState extends State<WritingLessonScreen>
    with SingleTickerProviderStateMixin {
  int _currentCharIndex = 0;

  // 0: Watch Animation, 1: Learn Direction, 2: Guided Tracing, 3: Write From Memory
  int _currentStage = 0;

  final List<Offset?> _userStrokes = [];
  bool _showExampleInMemoryMode = false; // Toggle for peek hint in memory mode

  late AnimationController _animController;
  late Animation<double> _strokeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _strokeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _nextStage() {
    if (_currentStage < 3) {
      setState(() {
        _currentStage++;
        _userStrokes.clear();
        _showExampleInMemoryMode = false;
        if (_currentStage == 0 || _currentStage == 1) _replayAnimation();
      });
    } else {
      // Advance to next character or show completion
      if (_currentCharIndex < widget.lessonCharacters.length - 1) {
        setState(() {
          _currentCharIndex++;
          _currentStage = 0;
          _userStrokes.clear();
          _showExampleInMemoryMode = false;
          _replayAnimation();
        });
      } else {
        _showCompletionDialog();
      }
    }
  }

  void _prevStage() {
    setState(() {
      if (_currentStage > 0) {
        _currentStage--;
        _userStrokes.clear();
        if (_currentStage == 0 || _currentStage == 1) _replayAnimation();
      } else if (_currentCharIndex > 0) {
        _currentCharIndex--;
        _currentStage = 3; // Go to last step of previous character
        _userStrokes.clear();
      }
    });
  }

  void _replayAnimation() {
    _animController.reset();
    _animController.forward();
  }

  void _clearCanvas() {
    setState(() => _userStrokes.clear());
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cream,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.textDark, width: 2),
        ),
        title: const Text(
          'Lesson Complete! 🎉',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Great job! You have completed all writing stages for this lesson.',
          style: TextStyle(color: AppColors.textDark),
        ),
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Return to previous screen
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.taupe,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.textDark, width: 1.5),
              ),
              child: const Text(
                'Back to Lessons',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStageInstruction() {
    switch (_currentStage) {
      case 0:
        return 'Watch the stroke animation';
      case 1:
        return 'Learn stroke order and direction';
      case 2:
        return 'Trace the character';
      case 3:
        return 'Write from memory';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.lessonCharacters.isEmpty) {
      return const Scaffold(
        backgroundColor: AppColors.beige,
        body: Center(
          child: Text(
            'No characters provided.',
            style: TextStyle(color: AppColors.textDark),
          ),
        ),
      );
    }

    final currentChar = widget.lessonCharacters[_currentCharIndex];

    return Scaffold(
      backgroundColor: AppColors.beige,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Bar
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
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    currentChar.kana,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    currentChar.romaji,
                    style: const TextStyle(
                      fontSize: 20,
                      color: AppColors.textDark,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_currentCharIndex + 1} of ${widget.lessonCharacters.length}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // 2. 4-Segment Stage Progress & Dynamic Instruction
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: List.generate(
                      4,
                      (index) => Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          height: 8,
                          decoration: BoxDecoration(
                            color: index <= _currentStage
                                ? AppColors.taupe
                                : AppColors.cream,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: AppColors.textDark,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _getStageInstruction(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),

            // 3. Writing / Animation Canvas Area (Square with Clamping)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: AspectRatio(
                  aspectRatio: 1.0,
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
                    // Clip ensures strokes never draw outside the inner rounded box
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Stack(
                        children: [
                          // Background Guidelines
                          Positioned.fill(
                            child: CustomPaint(painter: GridPainter()),
                          ),

                          // STAGE 0: Animated Character Reveal
                          if (_currentStage == 0)
                            Positioned.fill(
                              child: AnimatedBuilder(
                                animation: _strokeAnimation,
                                builder: (context, child) {
                                  return CustomPaint(
                                    painter: AuthenticFontRevealPainter(
                                      character: currentChar,
                                      progress: _strokeAnimation.value,
                                      textColor: AppColors.textDark,
                                    ),
                                  );
                                },
                              ),
                            ),

                          // STAGE 1: Static / Animated Stroke With Direction Markers
                          if (_currentStage == 1) ...[
                            Positioned.fill(
                              child: AnimatedBuilder(
                                animation: _strokeAnimation,
                                builder: (context, child) {
                                  return CustomPaint(
                                    painter: AuthenticFontRevealPainter(
                                      character: currentChar,
                                      progress: _strokeAnimation.value,
                                      textColor: AppColors.textDark,
                                    ),
                                  );
                                },
                              ),
                            ),
                            Positioned.fill(
                              child: CustomPaint(
                                painter: DirectionMarkerPainter(
                                  character: currentChar,
                                ),
                              ),
                            ),
                          ],

                          // STAGE 2: Guided Tracing (Faint Character Guide in Background)
                          if (_currentStage == 2)
                            Positioned.fill(
                              child: CustomPaint(
                                painter: StaticFontPainter(
                                  character: currentChar,
                                  textColor: AppColors.textLight.withOpacity(
                                    0.22,
                                  ),
                                ),
                              ),
                            ),

                          // STAGE 3: Memory Mode Peek Hint (Optional Guide)
                          if (_currentStage == 3 && _showExampleInMemoryMode)
                            Positioned.fill(
                              child: CustomPaint(
                                painter: StaticFontPainter(
                                  character: currentChar,
                                  textColor: AppColors.textLight.withOpacity(
                                    0.25,
                                  ),
                                ),
                              ),
                            ),

                          // STAGE 2 & STAGE 3: Interactive Freehand Drawing Layer
                          if (_currentStage >= 2)
                            Positioned.fill(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onPanStart: (details) => setState(
                                  () => _userStrokes.add(details.localPosition),
                                ),
                                onPanUpdate: (details) => setState(
                                  () => _userStrokes.add(details.localPosition),
                                ),
                                onPanEnd: (details) =>
                                    setState(() => _userStrokes.add(null)),
                                child: CustomPaint(
                                  painter: UserStrokePainter(
                                    points: _userStrokes,
                                  ),
                                ),
                              ),
                            ),

                          // Upper-Right Canvas Action Controls
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_currentStage ==
                                    3) // Show example hint toggle in memory stage
                                  IconButton(
                                    icon: Icon(
                                      _showExampleInMemoryMode
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: AppColors.textDark,
                                      size: 22,
                                    ),
                                    onPressed: () => setState(
                                      () => _showExampleInMemoryMode =
                                          !_showExampleInMemoryMode,
                                    ),
                                  ),
                                IconButton(
                                  icon: Icon(
                                    _currentStage < 2
                                        ? Icons.replay
                                        : Icons.refresh,
                                    color: AppColors.textDark,
                                    size: 22,
                                  ),
                                  onPressed: _currentStage < 2
                                      ? _replayAnimation
                                      : _clearCanvas,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 4. Bottom Navigation Buttons (Cozy 3D Style)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  if (_currentStage > 0 || _currentCharIndex > 0)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: _buildBottomButton(
                          '< Back',
                          _prevStage,
                          isSecondary: true,
                        ),
                      ),
                    ),
                  Expanded(child: _buildBottomButton('Continue >', _nextStage)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButton(
    String text,
    VoidCallback onTap, {
    bool isSecondary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSecondary ? AppColors.cream : AppColors.taupe,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.textDark, width: 2),
          boxShadow: const [
            BoxShadow(
              color: AppColors.textDark,
              offset: Offset(0, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
        ),
      ),
    );
  }
}
