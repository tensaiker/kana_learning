import 'package:flutter/material.dart';
import 'screens/learn_screen.dart';
import 'screens/practice_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/profile_screen.dart'; // Imports the Profile & Settings tab[cite: 11]
import 'services/progress_service.dart';
import 'services/vocabulary_service.dart'; // Imports offline JSON vocabulary database service[cite: 11]
import 'utils/tactile_feedback.dart'; // Imports tactile sound & haptic utility

void main() async {
  // Ensure Flutter engine bindings are initialized before calling SharedPreferences[cite: 11]
  WidgetsFlutterBinding.ensureInitialized();

  // Loads saved tactile click sound effects and vibration preferences into memory at startup
  await TactileFeedback.init();

  // Initializes user progress, streaks, and row checkpoints[cite: 11]
  await ProgressService.instance.init();

  // Preloads offline vocabulary JSON on app startup[cite: 11]
  await VocabularyService.instance.init();

  runApp(const KanaLearningApp());
}

// --- COLOR PALETTE ---[cite: 11]
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

/// Helper model defining sequential rows, titles, and characters for the Continue panel[cite: 11]
class _RowInfo {
  final String
  key; // Matches rowTitle in ProgressService (e.g. 'A row', 'Ka row')[cite: 11]
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

  /// Switches the active tab. When targeting Learn (tab 1), it sets
  /// the active writing system (Hiragana vs Katakana) in ProgressService.[cite: 11]
  void switchTab(int index, {bool isHiragana = true}) {
    if (index == 1) {
      ProgressService.instance.setLearnScript(isHiragana: isHiragana);
    }
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeScreen(
        onNavigateToLearn: ({required bool isHiragana}) =>
            switchTab(1, isHiragana: isHiragana),
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
          onTap: (index) => setState(() => _currentIndex = index),
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

class HomeScreen extends StatefulWidget {
  // Accepts a script parameter to navigate directly to Hiragana or Katakana in LearnScreen[cite: 11]
  final void Function({required bool isHiragana})? onNavigateToLearn;

  const HomeScreen({super.key, this.onNavigateToLearn});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isStreakActive = false;

  // The 10 sequential Basic Kana rows with their respective characters[cite: 11]
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

  /// Finds the first incomplete row for the given writing system.[cite: 11]
  /// If the current row is completed (20/20), it automatically advances to the next row (e.g. A row -> Ka row).[cite: 11]
  _RowInfo _getActiveRow(ProgressService ps, String writingSystem) {
    for (final row in _basicRowProgression) {
      final isCompleted = ps.isRowCompleted(
        writingSystem: writingSystem,
        rowTitle: row.key,
      );
      final prog = ps.getRowProgress(
        writingSystem: writingSystem,
        rowTitle: row.key,
      );

      // If not yet completed and questions remain, this is the active row to continue[cite: 11]
      if (!isCompleted && prog.current < prog.total) {
        return row;
      }
    }
    // If all rows are 100% completed, display the final row[cite: 11]
    return _basicRowProgression.last;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.beige,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopHeader(),
            Expanded(
              // ListenableBuilder dynamically rebuilds Home on progress and streak updates[cite: 11]
              child: ListenableBuilder(
                listenable: ProgressService.instance,
                builder: (context, _) {
                  final ps = ProgressService.instance;
                  return ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 20,
                    ),
                    children: [
                      _buildOverallProgressCard(ps),
                      const SizedBox(height: 24),
                      // Passes ProgressService to dynamically update active row & checkpoints[cite: 11]
                      _buildContinueLearningCard(ps),
                      const SizedBox(height: 24),
                      _buildInteractiveStreakCard(ps),
                      const SizedBox(height: 24),
                      _buildQuotesCard(),
                      const SizedBox(height: 30),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

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
            'こんにちは, Kerby!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.sage,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.textDark, width: 2),
            ),
            child: const Icon(
              Icons.person,
              color: AppColors.textDark,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallProgressCard(ProgressService ps) {
    // 104 standard Kana per system (46 basic + 25 dakuon + 33 yoon)[cite: 11]
    const int totalKana = 208; // 104 Hiragana + 104 Katakana[cite: 11]
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
      headerIcon: Icons.pie_chart_outline,
      child: Column(
        children: [
          const SizedBox(height: 10),
          SizedBox(
            width: 150,
            height: 150,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: AppColors.textDark,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.textDark, width: 2),
                  ),
                ),
                Container(
                  width: 106,
                  height: 106,
                  decoration: BoxDecoration(
                    color: AppColors.cream,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.textDark, width: 2),
                  ),
                ),
                SizedBox(
                  width: 150,
                  height: 150,
                  child: CircularProgressIndicator(
                    value: overallPercent,
                    strokeWidth: 22,
                    backgroundColor: Colors.transparent,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.sand,
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(overallPercent * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
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
          _buildLinearProgressRow(
            'Hiragana',
            '${ps.masteredHiraganaCount}/104',
            '${(hiraganaPercent * 100).toInt()}%',
            hiraganaPercent,
          ),
          const SizedBox(height: 14),
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
                const SizedBox(width: 8),
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
            border: Border.all(color: AppColors.textDark, width: 1.2),
          ),
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: fraction.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.textDark,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Displays the continue cards reading real stored progress checkpoints.[cite: 11]
  /// Automatically advances to the next row (e.g. Ka row) once the previous row is completed.[cite: 11]
  Widget _buildContinueLearningCard(ProgressService ps) {
    // 1. Dynamically determine active rows for Hiragana and Katakana[cite: 11]
    final hRow = _getActiveRow(ps, 'Hiragana');
    final kRow = _getActiveRow(ps, 'Katakana');

    // 2. Read saved checkpoints for each active row[cite: 11]
    final hProg = ps.getRowProgress(
      writingSystem: 'Hiragana',
      rowTitle: hRow.key,
    );
    final kProg = ps.getRowProgress(
      writingSystem: 'Katakana',
      rowTitle: kRow.key,
    );

    final double hFraction = hProg.total > 0
        ? (hProg.current / hProg.total).clamp(0.0, 1.0)
        : 0.0;
    final double kFraction = kProg.total > 0
        ? (kProg.current / kProg.total).clamp(0.0, 1.0)
        : 0.0;

    return _buildCardBase(
      headerText: 'Continue Learning',
      headerIcon: Icons.school_outlined,
      child: Column(
        children: [
          // Hiragana Active Row Subcard[cite: 11]
          _buildContinueRowSubCard(
            title: 'Hiragana - ${hRow.displayName}',
            characters: hRow.hiraganaChars,
            progressText: '${hProg.current}/${hProg.total}',
            fraction: hFraction,
            onContinue: () => widget.onNavigateToLearn?.call(isHiragana: true),
          ),
          const SizedBox(height: 16),

          // Katakana Active Row Subcard (Displays characters and advances automatically)[cite: 11]
          _buildContinueRowSubCard(
            title: 'Katakana - ${kRow.displayName}',
            characters: kRow.katakanaChars,
            progressText: '${kProg.current}/${kProg.total}',
            fraction: kFraction,
            onContinue: () => widget.onNavigateToLearn?.call(isHiragana: false),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueRowSubCard({
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

  Widget _buildInteractiveStreakCard(ProgressService ps) {
    final days = ['Mon', 'Tue', 'Wed', 'Thur', 'Fri', 'Sat', 'Sun'];

    return _buildCardBase(
      headerText: 'Current Streak',
      headerIcon: Icons.calendar_month_outlined,
      child: GestureDetector(
        onTap: () => setState(() => _isStreakActive = !_isStreakActive),
        onLongPress: () => setState(() => _isStreakActive = !_isStreakActive),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: _isStreakActive
                ? AppColors.flameCardBgActive
                : AppColors.cream,
            borderRadius: BorderRadius.circular(16),
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
                offset: Offset(0, _isStreakActive ? 1.5 : 4.0),
                blurRadius: 0,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.local_fire_department,
                    color: AppColors.flameOrange,
                    size: 54,
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Formatted as "day/s" to match design specs
                      Text(
                        '${ps.streakDays} day/s',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'keep it up!',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Daily dots driven by shared_preferences calendar data[cite: 11]
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(7, (index) {
                  final isActive = ps.activeDaysThisWeek[index];
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
                      const SizedBox(height: 8),
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.greenButton
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
            ],
          ),
        ),
      ),
    );
  }

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
