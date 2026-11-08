// Cozy Kana — analyzer cleanup.
// Existing public widgets, navigation, learning logic and storage keys are preserved.
import '../../../theme/cozy_palette.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../../../services/progress_service.dart'; // Writing mastery is tracked separately from quizzes.
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

  // Display the result inside this route (instead of opening a dialog on top
  // of the drawing canvas). Does not change handwriting validation or progress.
  bool _isLessonComplete = false;

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
      // Advance to next character or show the full-page result
      if (_currentCharIndex < widget.lessonCharacters.length - 1) {
        setState(() {
          _currentCharIndex++;
          _currentStage = 0;
          _resetWritingState();
          _replayAnimation();
        });
      } else {
        _finishWritingLesson();
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
      if (_currentStage == 3) {
        ProgressService.instance.markKanaWritten(character.kana);
      }
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
        // Only the final memory-writing stage contributes to writing progress.
        if (_currentStage == 3) {
          ProgressService.instance.markKanaWritten(character.kana);
        }
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

  /// Runs only after the last Kana finishes the final (memory) writing stage.
  /// Progress was already recorded by _onStrokeCompleted; do not record it twice.
  void _finishWritingLesson() {
    if (_isLessonComplete) return;
    _cancelAutoAdvance();
    TactileFeedback.success();
    setState(() => _isLessonComplete = true);
  }

  /// Full-page result replaces the old AlertDialog, so the canvas and its
  /// disabled buttons can no longer show through behind the celebration.
  /// The middle section scrolls on compact Android phones and larger text sizes.
  Widget _buildCompletionScreen() {
    final characters = widget.lessonCharacters;
    final total = characters.length;

    return Scaffold(
      backgroundColor: AppColors.beige,
      body: SafeArea(
        child: Column(
          children: [
            // Keep the same stationery header style as the writing activity.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
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
                  Icon(
                    Icons.draw_outlined,
                    color: AppColors.textDark,
                    size: 25,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Writing Complete',
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w800,
                        fontSize: 21,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: CozyPalette.lightSageShade,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: CozyPalette.outline,
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            Icons.check_circle_outline_rounded,
                            color: CozyPalette.basicGreen,
                            size: 42,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Lesson Complete!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You finished every writing stage for this lesson. '
                        'Keep practicing to make each character feel natural!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          color: AppColors.textLight,
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Display session completion, not a made-up handwriting
                      // accuracy score or a change to quiz mastery.
                      Row(
                        children: [
                          Expanded(
                            child: _buildWritingResultStat(
                              '$total/$total',
                              'Kana practiced',
                              Icons.edit_note_rounded,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildWritingResultStat(
                              '4',
                              'Writing stages',
                              Icons.layers_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Characters practiced',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Wrap keeps 5+ Kana legible on narrow phones.
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (final character in characters)
                            Container(
                              constraints: const BoxConstraints(minWidth: 54),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: CozyPalette.lightSageShade,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: CozyPalette.outline,
                                  width: 1.2,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    character.kana,
                                    style: TextStyle(
                                      fontSize: 25,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  Text(
                                    character.romaji,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // The action stays visible while the result details scroll.
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  onPressed: () {
                    TactileFeedback.press();
                    Navigator.of(context).pop(); // One route pop (no dialog).
                  },
                  icon: const Icon(Icons.menu_book_outlined),
                  label: const Text('Back to Lessons'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.taupe,
                    foregroundColor: AppColors.textDark,
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: CozyPalette.outline, width: 1.6),
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

  Widget _buildWritingResultStat(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.beige,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CozyPalette.outline, width: 1.2),
      ),
      child: Column(
        children: [
          Icon(icon, size: 23, color: AppColors.textLight),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: AppColors.textLight),
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
    CozyPalette.watch(
      context,
    ); // Repaint on light/dark or system theme changes.
    if (widget.lessonCharacters.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.beige,
        body: Center(
          child: Text(
            'No characters provided.',
            style: TextStyle(color: AppColors.textDark),
          ),
        ),
      );
    }

    // Switch to the complete result route without changing the handwriting
    // state machine, recorded progress, or animation/timer handling.
    if (_isLessonComplete) return _buildCompletionScreen();

    final currentChar = widget.lessonCharacters[_currentCharIndex];

    return Scaffold(
      backgroundColor: AppColors.beige,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Bar
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
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    currentChar.romaji,
                    style: TextStyle(fontSize: 20, color: AppColors.textDark),
                  ),
                  const SizedBox(width: 4),
                  // Audio pronunciation replay button
                  IconButton(
                    icon: Icon(
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
                    style: TextStyle(
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
                              color: CozyPalette.outline,
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
                    style: TextStyle(
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
                      border: Border.all(color: CozyPalette.outline, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: CozyPalette.shadow,
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
                                      textColor: AppColors.textLight.withValues(
                                        alpha: 0.22,
                                      ),
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
                                      textColor: AppColors.textLight.withValues(
                                        alpha: 0.25,
                                      ),
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
              color: CozyPalette.outline,
              width: isPulsing ? 2.5 : 2.0,
            ),
            boxShadow: [
              BoxShadow(
                color: CozyPalette.shadow,
                offset: Offset(0, isPulsing ? 4 : 3),
                blurRadius: isPulsing ? 2 : 0,
              ),
            ],
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
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
