import 'package:flutter/material.dart';
import 'screens/learn_screen.dart'; // Imports your interactive Learn tab[cite: 22, 26]
import 'screens/practice_screen.dart'; // Imports the new Practice tab[cite: 26]

void main() {
  runApp(const KanaLearningApp());
}

// --- COLOR PALETTE ---
class AppColors {
  static const Color cream = Color(0xFFFDF8F3);
  static const Color beige = Color(0xFFEADFD1);
  static const Color sand = Color(0xFFDCC6A8);
  static const Color sage = Color(0xFFB7C9B2);
  static const Color blush = Color(0xFFE7C9D1);
  static const Color taupe = Color(0xFFC6B8A5);

  static const Color textDark = Color(0xFF5D534A);
  static const Color textLight = Color(0xFF8B8076);
}

// --- MAIN APP WIDGET ---
class KanaLearningApp extends StatelessWidget {
  const KanaLearningApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kana Learning',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Set to AppColors.beige so the white/cream cards pop against the background[cite: 26]
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

// --- MAIN NAVIGATION SHELL ---
class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _currentIndex = 0;

  // The 5 primary tabs of the application[cite: 24, 25, 26]
  final List<Widget> _screens = const [
    HomeScreen(),
    LearnScreen(),
    PracticeScreen(), // Connected to your Kana Practice & Flashcard screen[cite: 24, 25]
    Center(
      child: Text(
        'Progress Tab',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textDark,
        ),
      ),
    ),
    Center(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack preserves the scroll position and state of each tab when switching[cite: 26]
      body: IndexedStack(index: _currentIndex, children: _screens),
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
            // Tab 0: Home[cite: 24, 26]
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            // Tab 1: Learn[cite: 24, 26]
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_outlined),
              activeIcon: Icon(Icons.menu_book),
              label: 'Learn',
            ),
            // Tab 2: Practice (Flashcards, Word Builder, Quiz)[cite: 24, 25, 26]
            BottomNavigationBarItem(
              icon: Icon(Icons.edit_note_outlined),
              activeIcon: Icon(Icons.edit_note),
              label: 'Practice',
            ),
            // Tab 3: Progress[cite: 24, 26]
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart),
              label: 'Progress',
            ),
            // Tab 4: Profile[cite: 24, 26]
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

// --- HOME TAB SCREEN (DASHBOARD) ---
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.beige, // Background matching the palette[cite: 26]
      child: ListView(
        padding: EdgeInsets
            .zero, // Allows the top header to touch status bar[cite: 26]
        children: [
          _buildTopHeader(),
          const SizedBox(height: 24),

          // Overall Progress Section[cite: 26]
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildProgressCard(),
          ),
          const SizedBox(height: 24),

          // Engagement Streak Section[cite: 26]
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildStreakCard(),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  /// Builds the rounded top header with the user's greeting and avatar[cite: 26].
  Widget _buildTopHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
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
          // User Avatar with dark border[cite: 26]
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.sage,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.textDark, width: 2),
            ),
            child: const Icon(
              Icons.person,
              color: AppColors.textDark,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the Overall Progress card containing circular chart and linear progress bars[cite: 26].
  Widget _buildProgressCard() {
    return _buildCardBase(
      headerText: 'Overall progress',
      headerIcon: Icons.pie_chart_outline,
      child: Column(
        children: [
          const SizedBox(height: 16),

          // 1. Circular Progress Indicator[cite: 26]
          Stack(
            alignment: Alignment.center,
            children: [
              // Dark outer track border[cite: 26]
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.textDark,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.textDark, width: 2),
                ),
              ),
              // Inner cutout to form a clean donut chart[cite: 26]
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.textDark, width: 2),
                ),
              ),
              // Progress slice[cite: 26]
              const SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: 0.20,
                  strokeWidth: 16,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.sand),
                ),
              ),
              const Text(
                '0%',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // 2. Linear Progress Bars for Hiragana & Katakana[cite: 26]
          _buildLinearProgress('Hiragana', '0/145'),
          const SizedBox(height: 16),
          _buildLinearProgress('Katakana', '0/145'),
        ],
      ),
    );
  }

  /// Helper to build linear progress rows[cite: 26].
  Widget _buildLinearProgress(String label, String progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: AppColors.textDark,
              ),
            ),
            Text(
              progress,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 16,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.beige,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.textDark, width: 1.5),
          ),
        ),
      ],
    );
  }

  /// Builds the Engagement Streak card with 7-day indicators[cite: 26].
  Widget _buildStreakCard() {
    final days = ['Mon', 'Tue', 'Wed', 'Thur', 'Fri', 'Sat', 'Sun'];

    return _buildCardBase(
      headerText: 'Engagement Streak',
      headerIcon: Icons.calendar_today,
      headerTrailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFFC099), // Soft pastel orange badge[cite: 26]
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.textDark, width: 1.5),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.local_fire_department,
              color: Colors.deepOrange,
              size: 16,
            ),
            SizedBox(width: 4),
            Text(
              '7 Days!',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: days.map((day) {
            return Column(
              children: [
                Text(
                  day,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.sage,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.textDark, width: 1.5),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Reusable wrapper that creates the two-tone pastel card layout with hard shadow[cite: 26].
  Widget _buildCardBase({
    required String headerText,
    required IconData headerIcon,
    Widget? headerTrailing,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.textDark, width: 2),
        boxShadow: const [
          BoxShadow(
            color: AppColors.textDark,
            offset: Offset(0, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          // Card Header Bar[cite: 26]
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.sand,
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
              border: Border(
                bottom: BorderSide(color: AppColors.textDark, width: 2),
              ),
            ),
            child: Row(
              children: [
                Icon(headerIcon, color: AppColors.textDark, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    headerText,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                if (headerTrailing != null) headerTrailing,
              ],
            ),
          ),
          // Card Body Content[cite: 26]
          Padding(padding: const EdgeInsets.all(20.0), child: child),
        ],
      ),
    );
  }
}
