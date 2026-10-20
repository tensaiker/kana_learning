import 'package:flutter/material.dart';
import 'screens/learn_screen.dart';
import 'screens/practice_screen.dart';
import 'screens/progress_screen.dart';

void main() {
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

  // Flame and Streak Colors
  static const Color flameOrange = Color(0xFFE06229);
  static const Color flameCardBgActive = Color(0xFFFFD4BE); // State 2
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

  void switchTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeScreen(onNavigateToLearn: () => switchTab(1)),
      const LearnScreen(),
      const PracticeScreen(),
      const ProgressScreen(),
      const Center(
        child: Text(
          'Profile Tab',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
      ),
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
  final VoidCallback? onNavigateToLearn;

  const HomeScreen({super.key, this.onNavigateToLearn});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Streak interaction state: false = State 1 (Frame 157), true = State 2 (Frame 161)
  bool _isStreakActive = false;

  @override
  Widget build(BuildContext context) {
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
                  _buildOverallProgressCard(),
                  const SizedBox(height: 24),
                  _buildContinueLearningCard(),
                  const SizedBox(height: 24),

                  // Interactive Two-State Current Streak (5 Days)
                  _buildInteractiveStreakCard(),
                  const SizedBox(height: 24),

                  _buildQuotesCard(),
                  const SizedBox(height: 30),
                ],
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

  Widget _buildOverallProgressCard() {
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
                const SizedBox(
                  width: 150,
                  height: 150,
                  child: CircularProgressIndicator(
                    value: 0.60,
                    strokeWidth: 22,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.sand),
                  ),
                ),
                const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '60%',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      '230 characters',
                      style: TextStyle(
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
          _buildLinearProgressRow('Hiragana', '40/146', '30%', 0.30),
          const SizedBox(height: 14),
          _buildLinearProgressRow('Katakana', '40/146', '30%', 0.30),
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

  Widget _buildContinueLearningCard() {
    return _buildCardBase(
      headerText: 'Continue Learning',
      headerIcon: Icons.school_outlined,
      child: Column(
        children: [
          _buildContinueRowSubCard(
            title: 'Hiragana - a row',
            characters: 'あ   い   う   え   お',
            progressText: '5/20',
            fraction: 0.25,
            onContinue: widget.onNavigateToLearn,
          ),
          const SizedBox(height: 16),
          _buildContinueRowSubCard(
            title: 'Katakana  - a row',
            characters: '',
            progressText: '5/20',
            fraction: 0.25,
            onContinue: widget.onNavigateToLearn,
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

  // ---------------------------------------------------------------------------
  // INTERACTIVE TWO-STATE STREAK CARD (Frame 157 & Frame 161)
  // Clicking or holding toggles between State 1 (Cream + 3D) and State 2 (Peach + Orange border)
  // ---------------------------------------------------------------------------
  Widget _buildInteractiveStreakCard() {
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
            // State 1: Cream, State 2: Soft Peach
            color: _isStreakActive
                ? AppColors.flameCardBgActive
                : AppColors.cream,
            borderRadius: BorderRadius.circular(16),
            // State 1: Dark Border, State 2: Vibrant Orange Border
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
          child: const Row(
            children: [
              Icon(
                Icons.local_fire_department,
                color: AppColors.flameOrange,
                size: 54,
              ),
              SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '5 days',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
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
