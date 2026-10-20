import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../services/progress_service.dart'; // Imports the local persistence service[cite: 34]

// --- COLOR PALETTE ---
class AppColors {
  static const Color cream = Color(0xFFFDF8F3);
  static const Color beige = Color(0xFFEADFD1);
  static const Color sand = Color(0xFFDCC6A8);
  static const Color taupe = Color(0xFFC6B8A5);
  static const Color textDark = Color(0xFF5D534A);
  static const Color textLight = Color(0xFF8B8076);

  // Category Progress Bar Colors[cite: 34]
  static const Color basicGreen = Color(0xFF526E5A);
  static const Color dakuonBlue = Color(0xFF7BA2C7);
  static const Color yoonBrown = Color(0xFFA67C52);

  // Streak & Badge Colors[cite: 34]
  static const Color flameOrange = Color(0xFFE06D39);
  static const Color flameBadgeBg = Color(0xFFFFD2BA);
  static const Color streakActiveGreen = Color(0xFF8FA98F);
  static const Color streakActiveOrange = Color(0xFFFFD4BE);
}

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  // Master script toggle: true = Hiragana (あ), false = Katakana (ア)[cite: 34]
  bool _isHiragana = true;

  // Streak card interaction state: false = State 1 (Cream + 3D), true = State 2 (Peach + Orange border)[cite: 34]
  bool _isStreakActive = false;

  @override
  Widget build(BuildContext context) {
    final systemName = _isHiragana ? 'Hiragana' : 'Katakana';

    // ListenableBuilder ensures real-time UI updates whenever progress is saved[cite: 34]
    return ListenableBuilder(
      listenable: ProgressService.instance,
      builder: (context, _) {
        final ps = ProgressService.instance;

        // Total standard characters per script: 46 basic, 25 dakuon, 33 yoon (104 total)[cite: 34]
        const int basicTotal = 46;
        const int dakuonTotal = 25;
        const int yoonTotal = 33;
        const int totalCharacters =
            basicTotal + dakuonTotal + yoonTotal; // 104[cite: 34]

        // Fetch live count of mastered characters for active writing system[cite: 34]
        final int totalLearned = _isHiragana
            ? ps.masteredHiraganaCount
            : ps.masteredKatakanaCount;

        // Distribute learned kana across categories (Basic -> Dakuon -> Yoon)[cite: 34]
        final int basicCurrent = math.min(totalLearned, basicTotal);
        final int dakuonCurrent = math.min(
          math.max(0, totalLearned - basicTotal),
          dakuonTotal,
        );
        final int yoonCurrent = math.max(
          0,
          totalLearned - basicTotal - dakuonTotal,
        );

        final double overallPercent = (totalLearned / totalCharacters).clamp(
          0.0,
          1.0,
        );

        return Scaffold(
          backgroundColor: AppColors.beige,
          body: SafeArea(
            child: Column(
              children: [
                _buildTopHeader(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 20,
                    ),
                    children: [
                      // 1. Overview Progress with dynamic donut chart and category bars[cite: 34]
                      _buildOverviewCard(
                        systemName: systemName,
                        overallPercent: overallPercent,
                        basicCurrent: basicCurrent,
                        basicTotal: basicTotal,
                        dakuonCurrent: dakuonCurrent,
                        dakuonTotal: dakuonTotal,
                        yoonCurrent: yoonCurrent,
                        yoonTotal: yoonTotal,
                      ),
                      const SizedBox(height: 24),

                      // 2. Interactive Two-State Current Streak Card connected to calendar data[cite: 34]
                      _buildStreakCard(ps),
                      const SizedBox(height: 20),
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

  // ===========================================================================
  // TOP HEADER & TOGGLE SWITCH
  // ===========================================================================
  Widget _buildTopHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      decoration: const BoxDecoration(
        color: AppColors.sand,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        border: Border(bottom: BorderSide(color: AppColors.textDark, width: 2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Kana Progress',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          _buildPillToggle(),
        ],
      ),
    );
  }

  Widget _buildPillToggle() {
    return Container(
      height: 38,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.sand,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.textDark, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => setState(() => _isHiragana = true),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _isHiragana ? AppColors.taupe : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isHiragana ? AppColors.textDark : Colors.transparent,
                  width: 2,
                ),
              ),
              child: const Text(
                'あ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _isHiragana = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: !_isHiragana ? AppColors.taupe : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: !_isHiragana ? AppColors.textDark : Colors.transparent,
                  width: 2,
                ),
              ),
              child: const Text(
                'ア',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // OVERVIEW PROGRESS CARD (DONUT CHART & BREAKDOWN BARS)
  // ===========================================================================
  Widget _buildOverviewCard({
    required String systemName,
    required double overallPercent,
    required int basicCurrent,
    required int basicTotal,
    required int dakuonCurrent,
    required int dakuonTotal,
    required int yoonCurrent,
    required int yoonTotal,
  }) {
    final double basicProgress = basicTotal > 0
        ? (basicCurrent / basicTotal)
        : 0.0;
    final double dakuonProgress = dakuonTotal > 0
        ? (dakuonCurrent / dakuonTotal)
        : 0.0;
    final double yoonProgress = yoonTotal > 0 ? (yoonCurrent / yoonTotal) : 0.0;

    return Container(
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
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: const BoxDecoration(
              color: AppColors.sand,
              border: Border(
                bottom: BorderSide(color: AppColors.textDark, width: 2),
              ),
            ),
            child: const Text(
              'Overview Progress',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(
                      Icons.filter_alt_outlined,
                      color: AppColors.textDark,
                      size: 28,
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Filter options coming soon!'),
                        ),
                      );
                    },
                  ),
                ),
                // Custom Donut Progress Chart[cite: 34]
                SizedBox(
                  width: 170,
                  height: 170,
                  child: CustomPaint(
                    painter: _ProgressDonutPainter(
                      basicProgress: basicProgress,
                      dakuonProgress: dakuonProgress,
                      yoonProgress: yoonProgress,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${(overallPercent * 100).toInt()}%',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          const Text(
                            'mastered',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textLight,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                // Detailed Breakdown Box[cite: 34]
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.cream,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.textDark, width: 1.8),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.textDark,
                        offset: Offset(0, 3),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$systemName progress',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildLinearStatRow(
                        label: 'Basic $systemName',
                        countText: '$basicCurrent/$basicTotal cards',
                        percentageText: '${(basicProgress * 100).toInt()}%',
                        fraction: basicProgress,
                        activeColor: AppColors.basicGreen,
                      ),
                      const SizedBox(height: 14),
                      _buildLinearStatRow(
                        label: 'Dakuon',
                        countText: '$dakuonCurrent/$dakuonTotal cards',
                        percentageText: '${(dakuonProgress * 100).toInt()}%',
                        fraction: dakuonProgress,
                        activeColor: AppColors.dakuonBlue,
                      ),
                      const SizedBox(height: 14),
                      _buildLinearStatRow(
                        label: 'Yoon',
                        countText: '$yoonCurrent/$yoonTotal cards',
                        percentageText: '${(yoonProgress * 100).toInt()}%',
                        fraction: yoonProgress,
                        activeColor: AppColors.yoonBrown,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinearStatRow({
    required String label,
    required String countText,
    required String percentageText,
    required double fraction,
    required Color activeColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            Row(
              children: [
                Text(
                  countText,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  percentageText,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 12,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.beige,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.textDark, width: 1.2),
          ),
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: fraction.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: activeColor,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // INTERACTIVE TWO-STATE CURRENT STREAK CARD[cite: 34]
  // ===========================================================================
  Widget _buildStreakCard(ProgressService ps) {
    final days = ['Mon', 'Tue', 'Wed', 'Thur', 'Fri', 'Sat', 'Sun'];

    return Container(
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
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header Bar with dynamic streak badge[cite: 34]
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.sand,
              border: Border(
                bottom: BorderSide(color: AppColors.textDark, width: 2),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_month_outlined,
                  color: AppColors.textDark,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Current Streak',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.flameBadgeBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.flameOrange,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.local_fire_department,
                        color: AppColors.flameOrange,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${ps.streakDays} Days!',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: AppColors.flameOrange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Clickable / Holdable Weekday Dots Panel with two visual states[cite: 34]
          Padding(
            padding: const EdgeInsets.all(20),
            child: GestureDetector(
              onTap: () => setState(() => _isStreakActive = !_isStreakActive),
              onLongPress: () =>
                  setState(() => _isStreakActive = !_isStreakActive),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 10,
                ),
                decoration: BoxDecoration(
                  // State 1: Cream (#FDF8F3), State 2: Soft Peach (#FFD4BE)[cite: 34]
                  color: _isStreakActive
                      ? AppColors.streakActiveOrange
                      : AppColors.cream,
                  borderRadius: BorderRadius.circular(16),
                  // State 1: Dark Brown Border, State 2: Vibrant Orange Border[cite: 34]
                  border: Border.all(
                    color: _isStreakActive
                        ? AppColors.flameOrange
                        : AppColors.textDark,
                    width: _isStreakActive ? 2.2 : 1.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _isStreakActive
                          ? AppColors.flameOrange.withOpacity(0.3)
                          : AppColors.textDark,
                      offset: Offset(0, _isStreakActive ? 1.5 : 3.0),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(7, (index) {
                    final bool isActive = ps.activeDaysThisWeek[index];
                    return Column(
                      children: [
                        Text(
                          days[index],
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.streakActiveGreen
                                : AppColors.beige,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.textDark,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// CUSTOM DONUT PAINTER[cite: 34]
// =============================================================================
class _ProgressDonutPainter extends CustomPainter {
  final double basicProgress;
  final double dakuonProgress;
  final double yoonProgress;

  _ProgressDonutPainter({
    required this.basicProgress,
    required this.dakuonProgress,
    required this.yoonProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    const strokeWidth = 22.0;

    // Outer background track ring[cite: 34]
    final bgPaint = Paint()
      ..color = const Color(0xFFD8D2C8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, bgPaint);

    // Active arc progress segment[cite: 34]
    final activePaint = Paint()
      ..color = AppColors.yoonBrown
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle =
        ((basicProgress * 46 + dakuonProgress * 25 + yoonProgress * 33) / 104) *
        2 *
        math.pi;

    if (sweepAngle > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweepAngle,
        false,
        activePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ProgressDonutPainter oldDelegate) {
    return oldDelegate.basicProgress != basicProgress ||
        oldDelegate.dakuonProgress != dakuonProgress ||
        oldDelegate.yoonProgress != yoonProgress;
  }
}
