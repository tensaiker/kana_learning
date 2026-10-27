import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import 'screens/learn_screen.dart';
import 'screens/practice_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/profile_screen.dart'; // Imports the Profile & Settings tab
import 'services/progress_service.dart';
import 'services/vocabulary_service.dart'; // Imports offline JSON vocabulary database service
import 'utils/tactile_feedback.dart'; // Imports tactile sound & haptic utility

void main() async {
  // Ensure Flutter engine bindings are initialized before calling SharedPreferences[cite: 13]
  WidgetsFlutterBinding.ensureInitialized();

  // Loads saved tactile click sound effects and vibration preferences into memory at startup[cite: 13]
  await TactileFeedback.init();

  // Initializes user progress, streaks, and row checkpoints[cite: 13]
  await ProgressService.instance.init();

  // Preloads offline vocabulary JSON on app startup[cite: 13]
  await VocabularyService.instance.init();

  runApp(const KanaLearningApp());
}

// --- COLOR PALETTE ---
class AppColors {
  static const Color cream = Color(0xFFFDF8F3);
  static const Color beige = Color(0xFFEADFD1);
  static const Color sand = Color(0xFFDCC6A8);
  static const Color taupe = Color(0xFFC6B8A5);
  static const Color textDark = Color(0xFF5D534A);
  static const Color textLight = Color(0xFF8B8076);

  static const Color sage = Color(0xFFB7C9B2);
  static const Color greenButton = Color(0xFF6EAA78);

  static const Color flameOrange = Color(0xFFE06229);
  static const Color flameCardBgActive = Color(0xFFFFD4BE);
}

/// Helper model defining sequential rows, titles, and characters for the Recent Learning panel[cite: 13]
class _RowInfo {
  final String
  key; // Matches rowTitle in ProgressService (e.g. 'A row', 'Ka row')[cite: 13]
  final String displayName;
  final String hiraganaChars;
  final String katakanaChars;

  const _RowInfo({
    required this.key,
    required this.displayName,
    required this.hiraganaChars,
    required this.katakanaChars,
  });
}

class KanaLearningApp extends StatelessWidget {
  const KanaLearningApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kana Learning',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.beige,
        primaryColor: AppColors.taupe,
        fontFamily: 'Nunito',
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: AppColors.textDark),
          bodyMedium: TextStyle(color: AppColors.textDark),
        ),
      ),
      home: const MainNavigator(),
    );
  }
}

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => MainNavigatorState();
}

class MainNavigatorState extends State<MainNavigator> {
  int _currentIndex = 0;
  // Key to trigger instant profile re-sync on HomeScreen when switching back to tab 0[cite: 13]
  final GlobalKey<_HomeScreenState> _homeKey = GlobalKey<_HomeScreenState>();

  /// Switches the active tab. When targeting Learn (tab 1), it sets
  /// the active writing system (Hiragana vs Katakana) in ProgressService[cite: 13].
  void switchTab(int index, {bool isHiragana = true}) {
    if (index == 1) {
      ProgressService.instance.setLearnScript(isHiragana: isHiragana);
    }
    setState(() => _currentIndex = index);

    // Synchronize username & avatar whenever navigating to Home[cite: 13]
    if (index == 0) {
      _homeKey.currentState?.syncProfileData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeScreen(
        key: _homeKey,
        onNavigateToLearn: ({required bool isHiragana}) =>
            switchTab(1, isHiragana: isHiragana),
        onNavigateToProfile: () => switchTab(4),
      ),
      const LearnScreen(),
      const PracticeScreen(),
      const ProgressScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.cream,
          border: Border(
            top: BorderSide(color: AppColors.textDark, width: 1.5),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => switchTab(index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.cream,
          selectedItemColor: AppColors.textDark,
          unselectedItemColor: AppColors.textLight,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_outlined),
              activeIcon: Icon(Icons.menu_book),
              label: 'Learn',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.edit_note_outlined),
              activeIcon: Icon(Icons.edit_note),
              label: 'Practice',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart),
              label: 'Progress',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

/// Home Dashboard Screen with live reactivity bound to [ProgressService].
///
/// Features & Guidelines:
/// 1. Reactivity via ListenableBuilder:
///    The entire dashboard listens to [ProgressService.instance]. Any completed row,
///    mastered kana, streak increment, or dev reset immediately triggers a frame update.
/// 2. Live Widgets:
///    - Overall Progress Donut Chart & Character Counter[cite: 13]
///    - Hiragana & Katakana Mastery Ratio Bars[cite: 13]
///    - Recent Learning Active Row Cards & Progress Bars[cite: 13]
///    - Streak Flame Badge & Weekly Dot Calendar (with current day highlight)[cite: 13]
class HomeScreen extends StatefulWidget {
  final void Function({required bool isHiragana})? onNavigateToLearn;
  final VoidCallback? onNavigateToProfile;

  const HomeScreen({
    super.key,
    this.onNavigateToLearn,
    this.onNavigateToProfile,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  bool _isStreakManualGlow = false;

  // Profile fields synchronized with Profile tab storage[cite: 13]
  String _userName = 'Kerby';
  int _selectedAvatarIndex = 0;

  static const List<IconData> _avatarIcons = [
    Icons.person,
    Icons.pets,
    Icons.local_florist,
    Icons.auto_stories,
    Icons.coffee,
  ];

  static const List<_RowInfo> _basicRowProgression = [
    _RowInfo(
      key: 'A row',
      displayName: 'a row',
      hiraganaChars: 'あ   い   う   え   お',
      katakanaChars: 'ア   イ   ウ   エ   オ',
    ),
    _RowInfo(
      key: 'Ka row',
      displayName: 'ka row',
      hiraganaChars: 'か   き   く   け   こ',
      katakanaChars: 'カ   キ   ク   ケ   コ',
    ),
    _RowInfo(
      key: 'Sa row',
      displayName: 'sa row',
      hiraganaChars: 'さ   し   す   せ   そ',
      katakanaChars: 'サ   シ   ス   セ   ソ',
    ),
    _RowInfo(
      key: 'Ta row',
      displayName: 'ta row',
      hiraganaChars: 'た   ち   つ   て   と',
      katakanaChars: 'タ   チ   ツ   テ   ト',
    ),
    _RowInfo(
      key: 'Na row',
      displayName: 'na row',
      hiraganaChars: 'な   に   ぬ   ね   の',
      katakanaChars: 'ナ   ニ   ヌ   ネ   ノ',
    ),
    _RowInfo(
      key: 'Ha row',
      displayName: 'ha row',
      hiraganaChars: 'は   ひ   ふ   へ   ほ',
      katakanaChars: 'ハ   ヒ   フ   ヘ   ホ',
    ),
    _RowInfo(
      key: 'Ma row',
      displayName: 'ma row',
      hiraganaChars: 'ま   み   む   め   も',
      katakanaChars: 'マ   ミ   ム   メ   モ',
    ),
    _RowInfo(
      key: 'Ya row',
      displayName: 'ya row',
      hiraganaChars: 'や   ゆ   よ',
      katakanaChars: 'ヤ   ユ   ヨ',
    ),
    _RowInfo(
      key: 'Ra row',
      displayName: 'ra row',
      hiraganaChars: 'ら   り   る   れ   ろ',
      katakanaChars: 'ラ   リ   ル   レ   ロ',
    ),
    _RowInfo(
      key: 'Wa / N row',
      displayName: 'wa / n row',
      hiraganaChars: 'わ   を   ん',
      katakanaChars: 'ワ   ヲ   ン',
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    syncProfileData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      syncProfileData();
    }
  }

  /// Synchronizes user display name and avatar badge from SharedPreferences[cite: 13].
  Future<void> syncProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _userName =
          prefs.getString('profile_username') ??
          prefs.getString('user_name') ??
          'Kerby';
      _selectedAvatarIndex = prefs.getInt('profile_avatar_idx') ?? 0;
    });
  }

  /// Finds the currently active (first incomplete) row for the writing system.
  /// If all rows are completed, defaults to the final row with full 20/20 progress[cite: 13].
  _RowInfo _getActiveRow(ProgressService ps, String writingSystem) {
    for (final row in _basicRowProgression) {
      final isCompleted = ps.isRowCompleted(
        writingSystem: writingSystem,
        rowTitle: row.key,
      );
      if (!isCompleted) {
        return row;
      }
    }
    return _basicRowProgression.last;
  }

  @override
  Widget build(BuildContext context) {
    // ListenableBuilder wraps the dashboard content to react to any ProgressService state updates
    return Scaffold(
      backgroundColor: AppColors.beige,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: ProgressService.instance,
          builder: (context, _) {
            final ps = ProgressService.instance;
            return Column(
              children: [
                _buildTopHeader(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 20,
                    ),
                    children: [
                      // 1. Overall Progress Graph & Ratio Bars
                      _buildOverallProgressCard(ps),
                      const SizedBox(height: 24),

                      // 2. Recent Learning Active Row Cards
                      _buildRecentLearningCard(ps),
                      const SizedBox(height: 24),

                      // 3. Reactive Streak Card & Weekly Dot Calendar
                      _buildInteractiveStreakCard(ps),
                      const SizedBox(height: 24),

                      // 4. Quotes Card
                      _buildQuotesCard(),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ===========================================================================
  // TOP BAR: SYNCHRONIZED NAME & AVATAR
  // ===========================================================================
  Widget _buildTopHeader() {
    final avatarIcon =
        (_selectedAvatarIndex >= 0 &&
            _selectedAvatarIndex < _avatarIcons.length)
        ? _avatarIcons[_selectedAvatarIndex]
        : Icons.person;

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
          Expanded(
            child: Text(
              'こんにちは, $_userName!',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: () {
              TactileFeedback.press();
              widget.onNavigateToProfile?.call();
            },
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.sage,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.textDark, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.textDark,
                    offset: Offset(0, 3),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Icon(avatarIcon, color: AppColors.textDark, size: 30),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 1. OVERALL PROGRESS GRAPH & REACTIVE METRICS
  // ===========================================================================
  Widget _buildOverallProgressCard(ProgressService ps) {
    const int totalKana = 208; // 104 Hiragana + 104 Katakana[cite: 13]
    final double overallPercent = (ps.totalMastered / totalKana).clamp(
      0.0,
      1.0,
    );
    final double hiraganaPercent = (ps.masteredHiraganaCount / 104).clamp(
      0.0,
      1.0,
    );
    final double katakanaPercent = (ps.masteredKatakanaCount / 104).clamp(
      0.0,
      1.0,
    );

    return _buildCardBase(
      headerText: 'Overall progress',
      headerIcon: Icons.access_time_rounded,
      child: Column(
        children: [
          const SizedBox(height: 10),

          // Custom-drawn circular progress ring with dark borders and sand fill[cite: 13]
          SizedBox(
            width: 154,
            height: 154,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(154, 154),
                  painter: _StationeryDonutPainter(
                    progress: overallPercent,
                    fillColor: AppColors.sand,
                    trackColor: AppColors.textDark,
                    borderColor: AppColors.textDark,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(overallPercent * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${ps.totalMastered} characters',
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
          ),

          const SizedBox(height: 28),

          // Hiragana breakdown bar
          _buildLinearProgressRow(
            'Hiragana',
            '${ps.masteredHiraganaCount}/104',
            '${(hiraganaPercent * 100).toInt()}%',
            hiraganaPercent,
          ),
          const SizedBox(height: 16),

          // Katakana breakdown bar
          _buildLinearProgressRow(
            'Katakana',
            '${ps.masteredKatakanaCount}/104',
            '${(katakanaPercent * 100).toInt()}%',
            katakanaPercent,
          ),
        ],
      ),
    );
  }

  Widget _buildLinearProgressRow(
    String label,
    String fractionText,
    String percentageText,
    double fraction,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  fractionText,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
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
        const SizedBox(height: 6),
        Container(
          height: 12,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.beige,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.textDark, width: 1.5),
          ),
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: fraction.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.textDark,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 2. RECENT LEARNING SECTION (REACTIVE ROW PROGRESSION)
  // ===========================================================================
  Widget _buildRecentLearningCard(ProgressService ps) {
    final hRow = _getActiveRow(ps, 'Hiragana');
    final kRow = _getActiveRow(ps, 'Katakana');

    final bool isHCompleted = ps.isRowCompleted(
      writingSystem: 'Hiragana',
      rowTitle: hRow.key,
    );
    final bool isKCompleted = ps.isRowCompleted(
      writingSystem: 'Katakana',
      rowTitle: kRow.key,
    );

    final hProg = ps.getRowProgress(
      writingSystem: 'Hiragana',
      rowTitle: hRow.key,
    );
    final kProg = ps.getRowProgress(
      writingSystem: 'Katakana',
      rowTitle: kRow.key,
    );

    // Accurately reflects row checkpoint from 0 to total questions
    final int hTotal = hProg.total > 0 ? hProg.total : 20;
    final int hCurrent = isHCompleted ? hTotal : hProg.current;
    final double hFraction = (hCurrent / hTotal).clamp(0.0, 1.0);

    final int kTotal = kProg.total > 0 ? kProg.total : 20;
    final int kCurrent = isKCompleted ? kTotal : kProg.current;
    final double kFraction = (kCurrent / kTotal).clamp(0.0, 1.0);

    return _buildCardBase(
      headerText: 'Recent Learning',
      headerIcon: Icons.school_outlined,
      child: Column(
        children: [
          // Hiragana Recent Card
          _buildRecentRowSubCard(
            title: 'Hiragana - ${hRow.displayName}',
            characters: hRow.hiraganaChars,
            progressText: '$hCurrent/$hTotal',
            fraction: hFraction,
            onContinue: () {
              TactileFeedback.press();
              widget.onNavigateToLearn?.call(isHiragana: true);
            },
          ),
          const SizedBox(height: 16),

          // Katakana Recent Card
          _buildRecentRowSubCard(
            title: 'Katakana - ${kRow.displayName}',
            characters: kRow.katakanaChars,
            progressText: '$kCurrent/$kTotal',
            fraction: kFraction,
            onContinue: () {
              TactileFeedback.press();
              widget.onNavigateToLearn?.call(isHiragana: false);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecentRowSubCard({
    required String title,
    required String characters,
    required String progressText,
    required double fraction,
    VoidCallback? onContinue,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          if (characters.isNotEmpty) ...[
            const SizedBox(height: 8),
            Center(
              child: Text(
                characters,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                  color: AppColors.textDark,
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                progressText,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            height: 10,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.beige,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: AppColors.textDark, width: 1.2),
            ),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: fraction,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.textDark,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: GestureDetector(
              onTap: onContinue,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 36,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.greenButton,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.textDark, width: 1.8),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.textDark,
                      offset: Offset(0, 3),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.play_arrow, color: AppColors.textDark, size: 18),
                    SizedBox(width: 4),
                    Text(
                      'Continue',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 3. REACTIVE STREAK CARD & WEEKLY CALENDAR DOTS
  // ===========================================================================
  Widget _buildInteractiveStreakCard(ProgressService ps) {
    const days = ['Mon', 'Tue', 'Wed', 'Thur', 'Fri', 'Sat', 'Sun'];

    // Automatically activates flame glow when user has an active streak of 1+ days
    final bool isFlameActive = ps.streakDays > 0 || _isStreakManualGlow;
    final int todayIndex = DateTime.now().weekday - 1; // 0 for Mon, 6 for Sun

    return _buildCardBase(
      headerText: 'Current Streak',
      headerIcon: Icons.calendar_month_outlined,
      child: GestureDetector(
        onTap: () {
          TactileFeedback.press();
          setState(() => _isStreakManualGlow = !_isStreakManualGlow);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: isFlameActive
                ? AppColors.flameCardBgActive
                : AppColors.cream,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isFlameActive ? AppColors.flameOrange : AppColors.textDark,
              width: isFlameActive ? 2.2 : 1.8,
            ),
            boxShadow: [
              BoxShadow(
                color: isFlameActive
                    ? AppColors.flameOrange.withOpacity(0.35)
                    : AppColors.textDark,
                offset: Offset(0, isFlameActive ? 2.0 : 4.0),
                blurRadius: 0,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.local_fire_department_rounded,
                    color: isFlameActive
                        ? AppColors.flameOrange
                        : AppColors.taupe,
                    size: 54,
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${ps.streakDays} ${ps.streakDays == 1 ? "day" : "days"}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isFlameActive
                            ? 'Keep the flame burning!'
                            : 'Study today to start your streak!',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Weekly calendar dots showing real-time study activity
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(7, (index) {
                  final isActive = ps.activeDaysThisWeek[index];
                  final isToday = (index == todayIndex);

                  return Column(
                    children: [
                      Text(
                        days[index],
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isToday
                              ? FontWeight.w900
                              : FontWeight.bold,
                          color: isToday
                              ? AppColors.flameOrange
                              : AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.greenButton
                              : AppColors.beige,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isToday
                                ? AppColors.flameOrange
                                : AppColors.textDark,
                            width: isToday ? 2.0 : 1.5,
                          ),
                        ),
                        child: isActive
                            ? const Icon(
                                Icons.check,
                                size: 12,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ],
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 4. QUOTES CARD
  // ===========================================================================
  Widget _buildQuotesCard() {
    return _buildCardBase(
      headerText: 'Quotes',
      headerIcon: Icons.format_quote_rounded,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Proverbs 16: 9',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '“The heart of man plans his way, but the LORD establishes his steps.”',
            style: TextStyle(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: AppColors.textDark,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // REUSABLE BASE CARD CONTAINER
  // ===========================================================================
  Widget _buildCardBase({
    required String headerText,
    required IconData headerIcon,
    required Widget child,
  }) {
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
                Icon(headerIcon, color: AppColors.textDark, size: 18),
                const SizedBox(width: 8),
                Text(
                  headerText,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(20.0), child: child),
        ],
      ),
    );
  }
}

// =============================================================================
// CUSTOM PAINTER: STATIONERY DONUT GRAPH WITH CRISP OUTLINES
// =============================================================================
class _StationeryDonutPainter extends CustomPainter {
  final double progress;
  final Color fillColor;
  final Color trackColor;
  final Color borderColor;

  _StationeryDonutPainter({
    required this.progress,
    required this.fillColor,
    required this.trackColor,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const double strokeWidth = 20.0;
    final double radius = (size.width - strokeWidth) / 2;

    // 1. Draw track arc (dark brown)[cite: 13]
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..isAntiAlias = true;
    canvas.drawCircle(center, radius, trackPaint);

    // 2. Draw progress arc (sand)[cite: 13]
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = fillColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..isAntiAlias = true;

      const double startAngle = -math.pi / 2; // Starts from top
      final double sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );
    }

    // 3. Draw outer and inner outline borders[cite: 13]
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..isAntiAlias = true;

    final double outerRadius = radius + (strokeWidth / 2);
    final double innerRadius = radius - (strokeWidth / 2);

    canvas.drawCircle(center, outerRadius, borderPaint);
    canvas.drawCircle(center, innerRadius, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _StationeryDonutPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.borderColor != borderColor;
  }
}
