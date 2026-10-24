import 'dart:async';
import 'package:flutter/material.dart';
import '../../../services/audio_service.dart'; // Audio pronunciation controller using native TTS
import '../../../utils/tactile_feedback.dart'; // Physical haptic feedback controller
import '../data/kana_data.dart'; // Kana stroke data and models
import '../widgets/writing_canvases.dart'; // Specialized canvas painters

/// Interactive kana handwriting lesson screen with 4 instructional stages:
/// - Stage 0: Watch stroke animation
/// - Stage 1: Learn stroke order & direction
/// - Stage 2: Guided tracing over faint outline
/// - Stage 3: Write from memory with real-time stroke validation & character reveal
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

  // Full point history for rendering on the canvas (separated by nulls between strokes)
  final List<Offset?> _userStrokes = [];

  // Points of the active stroke currently being drawn by the user
  final List<Offset> _activeStrokePoints = [];

  // Tracks the index of the next expected stroke from the user
  int _completedStrokeIndex = 0;

  // True when all strokes of the current character have passed validation
  bool _isCharacterCompleted = false;

  // Toggle for peek hint in memory mode
  bool _showExampleInMemoryMode = false;

  // Managed timer for seamless auto-advance after completion
  Timer? _autoAdvanceTimer;

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
    _cancelAutoAdvance();
    _animController.dispose();
    super.dispose();
  }

  /// Cancels any scheduled auto-advance to prevent race conditions or duplicate transitions
  void _cancelAutoAdvance() {
    _autoAdvanceTimer?.cancel();
    _autoAdvanceTimer = null;
  }

  /// Resets stroke tracing state when switching characters or stages
  void _resetWritingState() {
    _cancelAutoAdvance();
    _userStrokes.clear();
    _activeStrokePoints.clear();
    _completedStrokeIndex = 0;
    _isCharacterCompleted = false;
    _showExampleInMemoryMode = false;
  }

  /// Speaks the active character using integrated on-device Japanese TTS
  void _playCurrentPronunciation() {
    if (widget.lessonCharacters.isNotEmpty) {
      final currentChar = widget.lessonCharacters[_currentCharIndex];
      // Pass the literal kana glyph (e.g. 'あ', 'カ') so the TTS engine pronounces it accurately
      AudioService.speakKana(currentChar.kana);
    }
  }

  void _nextStage() {
    _cancelAutoAdvance();
    TactileFeedback.press();

    if (_currentStage < 3) {
      setState(() {
        _currentStage++;
        _resetWritingState();
        if (_currentStage == 0 || _currentStage == 1) {
          _replayAnimation();
        }
      });
    } else {
      // Advance to next character or show completion dialog
      if (_currentCharIndex < widget.lessonCharacters.length - 1) {
        setState(() {
          _currentCharIndex++;
          _currentStage = 0;
          _resetWritingState();
          _replayAnimation();
        });
      } else {
        _showCompletionDialog();
      }
    }
  }

  void _prevStage() {
    _cancelAutoAdvance();
    TactileFeedback.press();

    setState(() {
      if (_currentStage > 0) {
        _currentStage--;
        _resetWritingState();
        if (_currentStage == 0 || _currentStage == 1) {
          _replayAnimation();
        }
      } else if (_currentCharIndex > 0) {
        _currentCharIndex--;
        _currentStage = 3; // Go to last step of previous character
        _resetWritingState();
      }
    });
  }

  void _replayAnimation() {
    _cancelAutoAdvance();
    TactileFeedback.press();
    _animController.reset();
    _animController.forward();
  }

  void _clearCanvas() {
    _cancelAutoAdvance();
    TactileFeedback.press();
    setState(() {
      _userStrokes.clear();
      _activeStrokePoints.clear();
      _completedStrokeIndex = 0;
      _isCharacterCompleted = false;
    });
  }

  /// Validates a drawn stroke against the target stroke definition
  /// Optimized with squared distances and dot product to remove expensive sqrt() calculations
  bool _validateStroke(
    List<Offset> rawPoints,
    KanaStroke targetStroke,
    Size canvasSize,
  ) {
    if (rawPoints.length < 2 ||
        canvasSize.width <= 0 ||
        canvasSize.height <= 0) {
      return false;
    }

    final double invW = 1.0 / canvasSize.width;
    final double invH = 1.0 / canvasSize.height;

    // 1. Convert physical touch pixels to normalized 0.0 - 1.0 coordinates
    final Offset userStartNorm = Offset(
      (rawPoints.first.dx * invW).clamp(0.0, 1.0),
      (rawPoints.first.dy * invH).clamp(0.0, 1.0),
    );
    final Offset userEndNorm = Offset(
      (rawPoints.last.dx * invW).clamp(0.0, 1.0),
      (rawPoints.last.dy * invH).clamp(0.0, 1.0),
    );

    // 2. Tolerance radius check for start and end positions using squared distance
    const double tolerance = 0.28;
    const double toleranceSq = tolerance * tolerance;

    final Offset startDelta = userStartNorm - targetStroke.startPoint;
    final double startDistSq =
        startDelta.dx * startDelta.dx + startDelta.dy * startDelta.dy;

    final Offset endDelta = userEndNorm - targetStroke.endPoint;
    final double endDistSq =
        endDelta.dx * endDelta.dx + endDelta.dy * endDelta.dy;

    if (startDistSq > toleranceSq || endDistSq > toleranceSq) {
      return false;
    }

    // 3. Direction vector alignment check (prevents drawing strokes in reverse)
    final Offset targetVec = targetStroke.endPoint - targetStroke.startPoint;
    final Offset userVec = userEndNorm - userStartNorm;

    final double targetDistSq =
        targetVec.dx * targetVec.dx + targetVec.dy * targetVec.dy;
    final double userDistSq = userVec.dx * userVec.dx + userVec.dy * userVec.dy;

    // Only enforce angle check if both strokes have non-negligible length
    if (targetDistSq > 0.0144 && userDistSq > 0.0064) {
      final double dot = targetVec.dx * userVec.dx + targetVec.dy * userVec.dy;
      // Negative dot product indicates the user drew backwards (angle > 90 degrees)
      if (dot < 0.0) {
        return false;
      }
    }

    return true;
  }

  /// Handles touch release: evaluates the stroke, triggers audio/haptics, and auto-advances
  void _onStrokeCompleted(KanaCharacter character, Size canvasSize) {
    if (_activeStrokePoints.isEmpty || _isCharacterCompleted) return;

    // Fallback: if character has no stroke metadata, accept any drawn stroke
    if (character.strokes.isEmpty) {
      setState(() {
        _userStrokes.clear();
        _activeStrokePoints.clear();
        _isCharacterCompleted = true;
      });
      TactileFeedback.success();
      _playCurrentPronunciation();
      _scheduleAutoAdvance();
      return;
    }

    final KanaStroke currentTarget = character.strokes[_completedStrokeIndex];
    final bool isValid = _validateStroke(
      _activeStrokePoints,
      currentTarget,
      canvasSize,
    );

    if (isValid) {
      setState(() {
        _userStrokes.add(null); // Delimit finished stroke for UserStrokePainter
        _activeStrokePoints.clear();
        _completedStrokeIndex++;

        // When character is complete, clear user strokes so only clean font displays
        if (_completedStrokeIndex >= character.strokeCount) {
          _isCharacterCompleted = true;
          _userStrokes.clear(); // Clears user lines to reveal clean glyph
        }
      });
      TactileFeedback.success();

      // Trigger native audio pronunciation and scheduled transition
      if (_isCharacterCompleted) {
        _playCurrentPronunciation();
        _scheduleAutoAdvance();
      }
    } else {
      // Stroke failed validation: trigger error haptic and discard scribble
      TactileFeedback.error();
      setState(() {
        if (_userStrokes.length >= _activeStrokePoints.length) {
          _userStrokes.removeRange(
            _userStrokes.length - _activeStrokePoints.length,
            _userStrokes.length,
          );
        }
        _activeStrokePoints.clear();
      });
    }
  }

  /// Schedules a 750 ms delay before auto-advancing, giving time to view the completed glyph
  void _scheduleAutoAdvance() {
    _cancelAutoAdvance();
    _autoAdvanceTimer = Timer(const Duration(milliseconds: 750), () {
      if (mounted && _isCharacterCompleted) {
        _nextStage();
      }
    });
  }

  void _showCompletionDialog() {
    TactileFeedback.success();
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
              TactileFeedback.press();
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
        return _isCharacterCompleted
            ? 'Great job! Character completed.'
            : 'Trace the character';
      case 3:
        return _isCharacterCompleted
            ? 'Awesome! Drawn from memory.'
            : 'Write from memory';
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
                    onPressed: () {
                      TactileFeedback.press();
                      Navigator.pop(context);
                    },
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
                  const SizedBox(width: 4),
                  // Audio pronunciation replay button
                  IconButton(
                    icon: const Icon(
                      Icons.volume_up_rounded,
                      color: AppColors.textDark,
                      size: 24,
                    ),
                    tooltip: 'Hear Pronunciation',
                    onPressed: () {
                      TactileFeedback.press();
                      _playCurrentPronunciation();
                    },
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
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final canvasSize = Size(
                            constraints.maxWidth,
                            constraints.maxHeight,
                          );

                          return Stack(
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

                              // STAGE 1: Static Stroke With Direction Markers
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

                              // STAGE 2: Guided Tracing (Faint Character Guide)
                              if (_currentStage == 2 && !_isCharacterCompleted)
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: StaticFontPainter(
                                      character: currentChar,
                                      textColor: AppColors.textLight
                                          .withOpacity(0.22),
                                    ),
                                  ),
                                ),

                              // STAGE 3: Memory Mode Peek Hint
                              if (_currentStage == 3 &&
                                  _showExampleInMemoryMode &&
                                  !_isCharacterCompleted)
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: StaticFontPainter(
                                      character: currentChar,
                                      textColor: AppColors.textLight
                                          .withOpacity(0.25),
                                    ),
                                  ),
                                ),

                              // STAGE 2 & STAGE 3: Completed Character Full Calligraphic Display
                              if (_isCharacterCompleted)
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: StaticFontPainter(
                                      character: currentChar,
                                      textColor: AppColors.textDark,
                                    ),
                                  ),
                                ),

                              // STAGE 2 & STAGE 3: Interactive Touch & Live Drawing Layer
                              // Hidden when character is completed so green lines vanish
                              if (_currentStage >= 2 && !_isCharacterCompleted)
                                Positioned.fill(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onPanStart: (details) {
                                      setState(() {
                                        _userStrokes.add(details.localPosition);
                                        _activeStrokePoints.add(
                                          details.localPosition,
                                        );
                                      });
                                    },
                                    onPanUpdate: (details) {
                                      setState(() {
                                        _userStrokes.add(details.localPosition);
                                        _activeStrokePoints.add(
                                          details.localPosition,
                                        );
                                      });
                                    },
                                    onPanEnd: (_) {
                                      _onStrokeCompleted(
                                        currentChar,
                                        canvasSize,
                                      );
                                    },
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
                                    if (_currentStage == 3 &&
                                        !_isCharacterCompleted)
                                      IconButton(
                                        icon: Icon(
                                          _showExampleInMemoryMode
                                              ? Icons.visibility
                                              : Icons.visibility_off,
                                          color: AppColors.textDark,
                                          size: 22,
                                        ),
                                        onPressed: () {
                                          TactileFeedback.toggle();
                                          setState(() {
                                            _showExampleInMemoryMode =
                                                !_showExampleInMemoryMode;
                                          });
                                        },
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
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 4. Bottom Navigation Buttons
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
                  Expanded(
                    child: _buildBottomButton(
                      'Continue >',
                      _nextStage,
                      isHighlighted: _isCharacterCompleted || _currentStage < 2,
                      isPulsing: _isCharacterCompleted,
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

  Widget _buildBottomButton(
    String text,
    VoidCallback onTap, {
    bool isSecondary = false,
    bool isHighlighted = false,
    bool isPulsing = false,
  }) {
    final Color buttonColor = isSecondary
        ? AppColors.cream
        : (isHighlighted ? AppColors.sand : AppColors.taupe);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: isPulsing ? 1.04 : 1.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: buttonColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.textDark,
              width: isPulsing ? 2.5 : 2.0,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.textDark,
                offset: Offset(0, isPulsing ? 4 : 3),
                blurRadius: isPulsing ? 2 : 0,
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
      ),
    );
  }
}
