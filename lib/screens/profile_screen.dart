import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/progress_service.dart';
import '../utils/tactile_feedback.dart';

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
  static const Color dangerRed = Color(0xFFD88A82);
  static const Color flameOrange = Color(0xFFE06229);
  static const Color flameBadgeBg = Color(0xFFFFD2BA);
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FlutterTts _flutterTts = FlutterTts();
  late SharedPreferences _prefs;
  bool _isLoading = true;

  // Profile preferences
  String _userName = 'Kerby';
  int _selectedAvatarIndex = 0;
  final List<IconData> _avatarIcons = [
    Icons.person,
    Icons.pets,
    Icons.local_florist,
    Icons.auto_stories,
    Icons.coffee,
  ];

  // Study goal preferences
  int _dailyGoalMinutes = 10;
  final List<int> _goalOptions = [5, 10, 15, 20];

  // Speech engine settings
  double _speechRate = 0.5;
  double _speechVolume = 1.0;

  // Tactile feedback settings
  bool _soundFxEnabled = true;
  bool _hapticsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = _prefs.getString('profile_username') ?? 'Kerby';
      _selectedAvatarIndex = _prefs.getInt('profile_avatar_idx') ?? 0;
      _dailyGoalMinutes = _prefs.getInt('settings_daily_goal') ?? 10;
      _speechRate = _prefs.getDouble('settings_speech_rate') ?? 0.5;
      _speechVolume = _prefs.getDouble('settings_speech_volume') ?? 1.0;
      _soundFxEnabled = _prefs.getBool('settings_sound_fx') ?? true;
      _hapticsEnabled = _prefs.getBool('settings_haptics') ?? true;

      // Sync with global tactile utility
      TactileFeedback.soundEnabled = _soundFxEnabled;
      TactileFeedback.hapticsEnabled = _hapticsEnabled;

      _isLoading = false;
    });

    await _flutterTts.setLanguage("ja-JP");
    await _flutterTts.setSpeechRate(_speechRate);
    await _flutterTts.setVolume(_speechVolume);
  }

  Future<void> _savePreference(String key, dynamic value) async {
    if (value is String) await _prefs.setString(key, value);
    if (value is int) await _prefs.setInt(key, value);
    if (value is double) await _prefs.setDouble(key, value);
    if (value is bool) await _prefs.setBool(key, value);
  }

  void _testPronunciation() async {
    TactileFeedback.press();
    await _flutterTts.stop();
    await _flutterTts.setSpeechRate(_speechRate);
    await _flutterTts.setVolume(_speechVolume);
    await _flutterTts.speak("こんにちは！");
  }

  void _showEditNameDialog() {
    final controller = TextEditingController(text: _userName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cream,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.textDark, width: 2),
        ),
        title: const Text(
          'Edit Your Name',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          cursorColor: AppColors.textDark,
          style: const TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.beige,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.textDark,
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.textDark, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textLight),
            ),
          ),
          GestureDetector(
            onTap: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                setState(() => _userName = newName);
                _savePreference('profile_username', newName);
              }
              Navigator.pop(context);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.taupe,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.textDark, width: 1.5),
              ),
              child: const Text(
                'Save',
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

  void _showAvatarPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Avatar Badge',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_avatarIcons.length, (idx) {
                final isSelected = _selectedAvatarIndex == idx;
                return GestureDetector(
                  onTap: () {
                    TactileFeedback.press();
                    setState(() => _selectedAvatarIndex = idx);
                    _savePreference('profile_avatar_idx', idx);
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.sand : AppColors.beige,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.textDark,
                        width: isSelected ? 2.5 : 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.textDark,
                          offset: Offset(0, isSelected ? 1 : 3),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Icon(
                      _avatarIcons[idx],
                      color: AppColors.textDark,
                      size: 28,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showResetConfirmDialog({required bool resetAll}) {
    TactileFeedback.error();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cream,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.textDark, width: 2),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.dangerRed,
              size: 28,
            ),
            const SizedBox(width: 8),
            Text(
              resetAll ? 'Reset All Data?' : 'Reset Kana Progress?',
              style: const TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          resetAll
              ? 'This will erase all mastered characters, row checkpoints, and your study streak. This cannot be undone.'
              : 'This will reset your mastered characters count. Your study streak will be preserved.',
          style: const TextStyle(color: AppColors.textDark, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textDark),
            ),
          ),
          GestureDetector(
            onTap: () async {
              TactileFeedback.press();
              Navigator.pop(context);
              if (resetAll) {
                final allKeys = _prefs.getKeys();
                for (var key in allKeys) {
                  await _prefs.remove(key);
                }
                await ProgressService.instance.init();
                _loadSettings();
              } else {
                await _prefs.remove('masteredKana');
                await ProgressService.instance.init();
              }

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.cream,
                    content: Text(
                      resetAll
                          ? 'All progress has been reset.'
                          : 'Mastered kana reset.',
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(
                        color: AppColors.textDark,
                        width: 1.5,
                      ),
                    ),
                  ),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.dangerRed,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.textDark, width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.textDark,
                    offset: Offset(0, 3),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: const Text(
                'Confirm Reset',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.beige,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.textDark),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.beige,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopHeader(),
            Expanded(
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
                      // 1. Profile User Badge Card
                      _buildProfileCard(ps),
                      const SizedBox(height: 24),

                      // 2. Daily Study Goals Card
                      _buildDailyGoalsCard(),
                      const SizedBox(height: 24),

                      // 3. Audio & Speech Settings Card
                      _buildAudioSettingsCard(),
                      const SizedBox(height: 24),

                      // 4. Tactile & Haptic Feedback Toggles Card
                      _buildTactileSettingsCard(),
                      const SizedBox(height: 24),

                      // 5. Danger Zone / Data Management Card
                      _buildDangerZoneCard(),
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

  // ===========================================================================
  // 1. TOP HEADER BAR
  // ===========================================================================
  Widget _buildTopHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      decoration: const BoxDecoration(
        color: AppColors.sand,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        border: Border(bottom: BorderSide(color: AppColors.textDark, width: 2)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Profile & Settings',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          Icon(Icons.settings_outlined, color: AppColors.textDark, size: 28),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. USER PROFILE SUMMARY CARD
  // ===========================================================================
  Widget _buildProfileCard(ProgressService ps) {
    return _buildCardBase(
      headerText: 'Learner Profile',
      headerIcon: Icons.badge_outlined,
      child: Column(
        children: [
          Row(
            children: [
              // Avatar with Edit Badge
              GestureDetector(
                onTap: _showAvatarPicker,
                child: Stack(
                  children: [
                    Container(
                      width: 68,
                      height: 68,
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
                      child: Icon(
                        _avatarIcons[_selectedAvatarIndex],
                        color: AppColors.textDark,
                        size: 38,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.sand,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.textDark,
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.edit,
                          size: 14,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _userName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: _showEditNameDialog,
                          child: const Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Japanese Kana Explorer',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Quick Stats Bar
          Row(
            children: [
              Expanded(
                child: _buildStatBadge(
                  icon: Icons.local_fire_department,
                  iconColor: AppColors.flameOrange,
                  title: '${ps.streakDays} Days',
                  subtitle: 'Streak',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatBadge(
                  icon: Icons.check_circle_outline,
                  iconColor: AppColors.greenButton,
                  title: '${ps.totalMastered} Kana',
                  subtitle: 'Mastered',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.beige.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.textDark, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 3. DAILY STUDY GOAL CARD
  // ===========================================================================
  Widget _buildDailyGoalsCard() {
    return _buildCardBase(
      headerText: 'Daily Study Goal',
      headerIcon: Icons.timer_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Target practice time each day:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: _goalOptions.map((minutes) {
              final isSelected = _dailyGoalMinutes == minutes;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: GestureDetector(
                    onTap: () {
                      TactileFeedback.press();
                      setState(() => _dailyGoalMinutes = minutes);
                      _savePreference('settings_daily_goal', minutes);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.sand : AppColors.beige,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.textDark,
                          width: isSelected ? 2.2 : 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.textDark,
                            offset: Offset(0, isSelected ? 1 : 3),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${minutes}m',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isSelected
                              ? FontWeight.w900
                              : FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 4. AUDIO & PRONUNCIATION SETTINGS CARD
  // ===========================================================================
  Widget _buildAudioSettingsCard() {
    return _buildCardBase(
      headerText: 'Audio & Pronunciation (TTS)',
      headerIcon: Icons.volume_up_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Speech Rate Slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Speech Speed',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                '${(_speechRate).toStringAsFixed(2)}x',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.taupe,
              inactiveTrackColor: AppColors.beige,
              thumbColor: AppColors.sand,
              overlayColor: AppColors.sand.withOpacity(0.3),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              trackHeight: 6,
            ),
            child: Slider(
              value: _speechRate,
              min: 0.25,
              max: 1.0,
              divisions: 15,
              onChanged: (val) {
                setState(() => _speechRate = val);
                _savePreference('settings_speech_rate', val);
              },
            ),
          ),
          const SizedBox(height: 10),

          // Speech Volume Slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Speech Volume',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                '${(_speechVolume * 100).toInt()}%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.taupe,
              inactiveTrackColor: AppColors.beige,
              thumbColor: AppColors.sand,
              overlayColor: AppColors.sand.withOpacity(0.3),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              trackHeight: 6,
            ),
            child: Slider(
              value: _speechVolume,
              min: 0.0,
              max: 1.0,
              divisions: 10,
              onChanged: (val) {
                setState(() => _speechVolume = val);
                _savePreference('settings_speech_volume', val);
              },
            ),
          ),
          const SizedBox(height: 14),

          // Pronunciation Test Button
          Center(
            child: GestureDetector(
              onTap: _testPronunciation,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.taupe,
                  borderRadius: BorderRadius.circular(12),
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
                    Icon(
                      Icons.play_circle_outline,
                      color: AppColors.textDark,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Test Voice: こんにちは',
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
  // 5. TACTILE & FEEDBACK SETTINGS CARD
  // ===========================================================================
  Widget _buildTactileSettingsCard() {
    return _buildCardBase(
      headerText: 'Tactile & Haptics',
      headerIcon: Icons.vibration_outlined,
      child: Column(
        children: [
          _buildToggleRow(
            label: 'Sound Effects (Clicks)',
            value: _soundFxEnabled,
            onChanged: (val) {
              TactileFeedback.toggle();
              setState(() => _soundFxEnabled = val);
              _savePreference('settings_sound_fx', val);
              TactileFeedback.soundEnabled = val;
            },
          ),
          const Divider(color: AppColors.textDark, height: 24, thickness: 1),
          _buildToggleRow(
            label: 'Haptic Feedback (Vibrations)',
            value: _hapticsEnabled,
            onChanged: (val) {
              TactileFeedback.toggle();
              setState(() => _hapticsEnabled = val);
              _savePreference('settings_haptics', val);
              TactileFeedback.hapticsEnabled = val;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        GestureDetector(
          onTap: () => onChanged(!value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 48,
            height: 28,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: value ? AppColors.greenButton : AppColors.beige,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.textDark, width: 1.8),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 180),
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.textDark, width: 1.2),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 6. DANGER ZONE / DATA RESET CARD
  // ===========================================================================
  Widget _buildDangerZoneCard() {
    return _buildCardBase(
      headerText: 'Data Management',
      headerIcon: Icons.delete_outline_rounded,
      child: Column(
        children: [
          _buildActionButton(
            label: 'Reset Mastered Kana',
            color: AppColors.taupe,
            onTap: () => _showResetConfirmDialog(resetAll: false),
          ),
          const SizedBox(height: 14),
          _buildActionButton(
            label: 'Reset All Data & Streaks',
            color: AppColors.dangerRed,
            isDestructive: true,
            onTap: () => _showResetConfirmDialog(resetAll: true),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required Color color,
    bool isDestructive = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.textDark, width: 1.8),
          boxShadow: const [
            BoxShadow(
              color: AppColors.textDark,
              offset: Offset(0, 3),
              blurRadius: 0,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isDestructive ? Colors.white : AppColors.textDark,
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // BASE REUSABLE CARD CONTAINER
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
