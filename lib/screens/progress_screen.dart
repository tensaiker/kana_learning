import '../theme/cozy_palette.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../features/writing/data/vocabulary_data.dart';
import '../services/progress_service.dart';

// Cozy Kana's existing stationery palette, scoped to this file.
// A private name prevents accidental collisions with other screens' AppColors.
class _ProgressColors {
  static Color get cream => CozyPalette.cream;
  static Color get beige => CozyPalette.beige;
  static Color get sand => CozyPalette.sand;
  static Color get taupe => CozyPalette.taupe;
  static Color get textDark => CozyPalette.textDark;
  static Color get textLight => CozyPalette.textLight;
  static Color get basicGreen => CozyPalette.basicGreen;
  static Color get dakuonBlue => CozyPalette.dakuonBlue;
  static Color get yoonBrown => CozyPalette.yoonBrown;
  static Color get flameOrange => CozyPalette.flameOrangeProgress;
  static Color get flameBadgeBg => CozyPalette.flameBadgeBg;
  static Color get activeDay => CozyPalette.activeDay;
}

/// The Progress tab uses only metrics already saved by ProgressService.
/// No additional database, plugin, or service modification is required.
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  // Independent view filter: changing it does not change the Learn tab's script.
  bool _isHiragana = true;

  @override
  Widget build(BuildContext context) {
    CozyPalette.watch(
      context,
    ); // Repaint on light/dark or system theme changes.
    return ListenableBuilder(
      listenable: ProgressService.instance,
      builder: (context, _) {
        final progress = ProgressService.instance;
        final script = _isHiragana ? 'Hiragana' : 'Katakana';

        // IMPORTANT: Count the actual mastered characters in each category.
        // Do not distribute the total count into Basic -> Dakuon -> Yoon;
        // users can master these in any order through Practice activities.
        final stats = _KanaCategoryStats.calculate(progress, _isHiragana);

        return Scaffold(
          backgroundColor: _ProgressColors.beige,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                    children: [
                      _buildOverviewCard(script, stats),
                      const SizedBox(height: 18),
                      _buildLearningJourney(progress, script),
                      const SizedBox(height: 18),
                      _buildPracticeCard(progress),
                      const SizedBox(height: 18),
                      _buildSkillCard(progress),
                      const SizedBox(height: 18),
                      _buildStreakCard(progress),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Header and script switcher
  // ---------------------------------------------------------------------------
  // Match Learn and Practice: 24px sides, 20px top/bottom, 24px title,
  // 38px toggle pill. SafeArea above already handles the phone status bar.
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      decoration: BoxDecoration(
        color: _ProgressColors.sand,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        border: Border(
          bottom: BorderSide(color: CozyPalette.outline, width: 2),
        ),
      ),
      child: Row(
        children: [
          // Expanded prevents the title from colliding with the script pill.
          Expanded(
            child: Text(
              'Kana Progress',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _ProgressColors.textDark,
              ),
            ),
          ),
          const SizedBox(width: 12),
          _buildScriptSwitch(),
        ],
      ),
    );
  }

  /// Uses the same stationery pill dimensions and styling as Kana Learn.
  /// This remains an independent Progress filter, not the Learn tab's setting.
  Widget _buildScriptSwitch() {
    return Container(
      height: 38,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: _ProgressColors.sand,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CozyPalette.outline, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildScriptButton('あ', true, 'Show Hiragana progress'),
          _buildScriptButton('ア', false, 'Show Katakana progress'),
        ],
      ),
    );
  }

  Widget _buildScriptButton(String symbol, bool hiragana, String label) {
    final selected = _isHiragana == hiragana;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: () {
          // Preserve the original independent Progress tab filter.
          if (_isHiragana != hiragana) {
            setState(() => _isHiragana = hiragana);
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? _ProgressColors.taupe : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? _ProgressColors.textDark : Colors.transparent,
              width: 2,
            ),
          ),
          child: Text(
            symbol,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _ProgressColors.textDark,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Reusable stationery card
  // ---------------------------------------------------------------------------
  Widget _buildCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _ProgressColors.cream,
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
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: _ProgressColors.sand,
              border: Border(
                bottom: BorderSide(color: CozyPalette.outline, width: 2),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 19, color: _ProgressColors.textDark),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _ProgressColors.textDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(18), child: child),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Correctly calculated overall and category mastery
  // ---------------------------------------------------------------------------
  Widget _buildOverviewCard(String script, _KanaCategoryStats stats) {
    return _buildCard(
      title: 'Overview Progress',
      icon: Icons.donut_large_outlined,
      child: Column(
        children: [
          const SizedBox(height: 4),
          SizedBox(
            width: 168,
            height: 168,
            child: CustomPaint(
              painter: _KanaDonutPainter(stats),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(stats.fraction * 100).round()}%',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: _ProgressColors.textDark,
                      ),
                    ),
                    Text(
                      '${stats.learned}/${stats.total} mastered',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _ProgressColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '$script mastery',
              style: TextStyle(
                color: _ProgressColors.textDark,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 15),
          _buildCategoryRow(
            label: 'Basic',
            category: stats.basic,
            color: _ProgressColors.basicGreen,
          ),
          const SizedBox(height: 15),
          _buildCategoryRow(
            label: 'Dakuon',
            category: stats.dakuon,
            color: _ProgressColors.dakuonBlue,
          ),
          const SizedBox(height: 15),
          _buildCategoryRow(
            label: 'Yoon',
            category: stats.yoon,
            color: _ProgressColors.yoonBrown,
          ),
          const SizedBox(height: 12),
          Text(
            'Kana mastery is recorded from correct quiz answers. '
            'Handwriting is tracked separately. Yoon counts full combinations such as きゃ.',
            style: TextStyle(fontSize: 11, color: _ProgressColors.textLight),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRow({
    required String label,
    required _CategoryCount category,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: _ProgressColors.textDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '${category.learned}/${category.total}  •  '
              '${(category.fraction * 100).round()}%',
              style: TextStyle(
                color: _ProgressColors.textDark,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Container(
          height: 13,
          decoration: BoxDecoration(
            color: _ProgressColors.beige,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: CozyPalette.outline, width: 1),
          ),
          clipBehavior: Clip.antiAlias,
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: category.fraction,
              heightFactor: 1,
              child: ColoredBox(color: color),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Lesson checkpoints already recorded by ProgressService
  // ---------------------------------------------------------------------------
  Widget _buildLearningJourney(ProgressService ps, String script) {
    // Developer unlock mode is not real lesson completion.
    if (ps.unlockAllRows) {
      return _buildCard(
        title: 'Learning Journey',
        icon: Icons.menu_book_outlined,
        child: Text(
          'All rows are unlocked in Developer settings. Turn that option off '
          'to see meaningful lesson-completion counts.',
          style: TextStyle(color: _ProgressColors.textLight, fontSize: 13),
        ),
      );
    }

    int completedCount(List<String> rows) => rows
        .where((row) => ps.isRowCompleted(writingSystem: script, rowTitle: row))
        .length;

    final basicDone = completedCount(ProgressService.basicRowOrder);
    final dakuonDone = completedCount(ProgressService.dakuonRowTitles);
    final yoonDone = completedCount(ProgressService.yoonRowTitles);
    final done = basicDone + dakuonDone + yoonDone;
    final allRows = [
      ...ProgressService.basicRowOrder,
      ...ProgressService.dakuonRowTitles,
      ...ProgressService.yoonRowTitles,
    ];
    final next = allRows.where(
      (row) => !ps.isRowCompleted(writingSystem: script, rowTitle: row),
    );
    final nextRow = next.isEmpty ? null : next.first;

    return _buildCard(
      title: 'Learning Journey',
      icon: Icons.menu_book_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Lesson rows completed',
                  style: TextStyle(
                    color: _ProgressColors.textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '$done/${allRows.length}',
                style: TextStyle(
                  color: _ProgressColors.textDark,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          _buildJourneyRow(
            'Basic rows',
            basicDone,
            ProgressService.basicRowOrder.length,
          ),
          const SizedBox(height: 8),
          _buildJourneyRow(
            'Dakuon rows',
            dakuonDone,
            ProgressService.dakuonRowTitles.length,
          ),
          const SizedBox(height: 8),
          _buildJourneyRow(
            'Yoon rows',
            yoonDone,
            ProgressService.yoonRowTitles.length,
          ),
          Divider(height: 24, color: _ProgressColors.beige),
          Text(
            nextRow == null
                ? 'All $script lesson rows completed!'
                : 'Next checkpoint: $nextRow',
            style: TextStyle(
              color: _ProgressColors.textDark,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (nextRow != null)
            Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'Go to the Learn tab to continue.',
                style: TextStyle(
                  fontSize: 12,
                  color: _ProgressColors.textLight,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildJourneyRow(String title, int done, int total) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(fontSize: 12, color: _ProgressColors.textDark),
          ),
        ),
        Text(
          '$done/$total',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: _ProgressColors.textDark,
          ),
        ),
        const SizedBox(width: 10),
        Icon(
          done == total ? Icons.check_circle : Icons.circle_outlined,
          color: done == total
              ? _ProgressColors.basicGreen
              : _ProgressColors.taupe,
          size: 17,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Real saved practice statistics. No fabricated accuracy or study time.
  // ---------------------------------------------------------------------------
  Widget _buildPracticeCard(ProgressService ps) {
    return _buildCard(
      title: 'Practice Summary',
      icon: Icons.style_outlined,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMetric(
                  icon: Icons.layers_outlined,
                  value: '${ps.flashcardsReviewedCount}',
                  label: 'Cards reviewed',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetric(
                  icon: Icons.translate,
                  value: '${ps.totalMasteredWords}',
                  label: 'Unique words learned',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Successful Word Builder answers: ${ps.wordsCompletedCount}',
            style: TextStyle(fontSize: 12, color: _ProgressColors.textLight),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 110),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
      decoration: BoxDecoration(
        color: _ProgressColors.beige,
        border: Border.all(color: CozyPalette.outline, width: 1.2),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: _ProgressColors.textDark),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
              color: _ProgressColors.textDark,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: _ProgressColors.textLight),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Independent skill history: no fabricated accuracy or writing metrics.
  // ---------------------------------------------------------------------------
  Widget _buildSkillCard(ProgressService ps) {
    final written = _isHiragana
        ? ps.writtenHiraganaCount
        : ps.writtenKatakanaCount;
    final accuracy = ps.quizAnswersCount == 0
        ? 'Not measured yet'
        : '${(ps.quizAccuracy * 100).round()}% (${ps.quizCorrectCount}/${ps.quizAnswersCount})';
    return _buildCard(
      title: 'Skill Progress',
      icon: Icons.auto_graph_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Written from memory: $written / 104 Kana',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _ProgressColors.textDark,
            ),
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: (written / 104).clamp(0.0, 1.0),
            backgroundColor: _ProgressColors.beige,
            color: _ProgressColors.basicGreen,
            minHeight: 9,
            borderRadius: BorderRadius.circular(6),
          ),
          const SizedBox(height: 16),
          Text(
            'Quiz accuracy: $accuracy',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _ProgressColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Writing counts unique Kana completed in memory mode. '
            'Accuracy measures answers recorded after this update.',
            style: TextStyle(fontSize: 11, color: _ProgressColors.textLight),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Read-only activity calendar. No cosmetic tap toggle or fake activity.
  // Study days are recorded by actual practice activities, not app launches.
  // ---------------------------------------------------------------------------
  Widget _buildStreakCard(ProgressService ps) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final activeDays = ps.activeDaysThisWeek;
    return _buildCard(
      title: 'Study Streak',
      icon: Icons.calendar_month_outlined,
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.local_fire_department,
                color: _ProgressColors.flameOrange,
                size: 24,
              ),
              const SizedBox(width: 6),
              Text(
                '${ps.streakDays} ${ps.streakDays == 1 ? 'day' : 'days'}',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: _ProgressColors.textDark,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _ProgressColors.flameBadgeBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _ProgressColors.flameOrange),
                ),
                child: Text(
                  'This week',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _ProgressColors.flameOrange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(7, (index) {
              final active = index < activeDays.length && activeDays[index];
              return Expanded(
                child: Column(
                  children: [
                    Text(
                      days[index],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _ProgressColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: active
                            ? _ProgressColors.activeDay
                            : _ProgressColors.beige,
                        border: Border.all(
                          color: CozyPalette.outline,
                          width: 1.4,
                        ),
                      ),
                      child: active
                          ? Icon(
                              Icons.check,
                              size: 13,
                              color: _ProgressColors.cream,
                            )
                          : null,
                    ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'A day is checked after a quiz answer, flashcard review, '
              'Word Builder answer, or completed Kana writing.',
              style: TextStyle(fontSize: 11, color: _ProgressColors.textLight),
            ),
          ),
        ],
      ),
    );
  }
}

// Simple immutable model used only for screen calculations.
class _CategoryCount {
  final int learned;
  final int total;

  const _CategoryCount(this.learned, this.total);

  double get fraction => total == 0 ? 0.0 : (learned / total).clamp(0.0, 1.0);
}

class _KanaCategoryStats {
  final _CategoryCount basic;
  final _CategoryCount dakuon;
  final _CategoryCount yoon;

  const _KanaCategoryStats(this.basic, this.dakuon, this.yoon);

  int get learned => basic.learned + dakuon.learned + yoon.learned;
  int get total => basic.total + dakuon.total + yoon.total;
  double get fraction => total == 0 ? 0.0 : learned / total;

  /// Uses the app's canonical kana-to-row map as the single source of truth.
  /// Its 104 entries per script include 33 two-character Yoon combinations.
  static _KanaCategoryStats calculate(ProgressService ps, bool isHiragana) {
    int basicTotal = 0, dakuonTotal = 0, yoonTotal = 0;
    int basicLearned = 0, dakuonLearned = 0, yoonLearned = 0;

    for (final entry in kanaToRowTitleMap.entries) {
      final firstCodePoint = entry.key.runes.first;
      final isEntryHiragana =
          firstCodePoint >= 0x3040 && firstCodePoint <= 0x309F;
      final isEntryKatakana =
          firstCodePoint >= 0x30A0 && firstCodePoint <= 0x30FF;
      if (isHiragana ? !isEntryHiragana : !isEntryKatakana) continue;

      final mastered = ps.isKanaMastered(entry.key);
      if (ProgressService.basicRowOrder.contains(entry.value)) {
        basicTotal++;
        if (mastered) basicLearned++;
      } else if (ProgressService.dakuonRowTitles.contains(entry.value)) {
        dakuonTotal++;
        if (mastered) dakuonLearned++;
      } else if (ProgressService.yoonRowTitles.contains(entry.value)) {
        yoonTotal++;
        if (mastered) yoonLearned++;
      }
    }

    return _KanaCategoryStats(
      _CategoryCount(basicLearned, basicTotal),
      _CategoryCount(dakuonLearned, dakuonTotal),
      _CategoryCount(yoonLearned, yoonTotal),
    );
  }
}

/// Three colored arcs, each weighted by the category's share of all kana.
/// The space between arcs separates Basic, Dakuon and Yoon visually.
class _KanaDonutPainter extends CustomPainter {
  final _KanaCategoryStats stats;

  const _KanaDonutPainter(this.stats);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 13;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const strokeWidth = 18.0;
    final background = Paint()
      ..color = _ProgressColors.beige
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, background);

    if (stats.total == 0) return;
    const gapRadians = 0.055;
    var start = -math.pi / 2;
    final parts = [
      (stats.basic, _ProgressColors.basicGreen),
      (stats.dakuon, _ProgressColors.dakuonBlue),
      (stats.yoon, _ProgressColors.yoonBrown),
    ];

    for (final part in parts) {
      final portion = 2 * math.pi * part.$1.total / stats.total;
      final paintedSweep = math.max(
        0.0,
        portion * part.$1.fraction - gapRadians,
      );
      if (paintedSweep > 0) {
        final paint = Paint()
          ..color = part.$2
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;
        canvas.drawArc(
          rect,
          start + gapRadians / 2,
          paintedSweep,
          false,
          paint,
        );
      }
      start += portion;
    }
  }

  @override
  bool shouldRepaint(covariant _KanaDonutPainter oldDelegate) {
    return oldDelegate.stats.basic.learned != stats.basic.learned ||
        oldDelegate.stats.dakuon.learned != stats.dakuon.learned ||
        oldDelegate.stats.yoon.learned != stats.yoon.learned;
  }
}
