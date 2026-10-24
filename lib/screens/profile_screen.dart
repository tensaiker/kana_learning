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
  static const Color lightSage = Color(0xFFE4EFE7);
  static const Color skyBlue = Color(0xFFA5C4E5);
  static const Color lightSkyBlue = Color(0xFFEBF0F5);
  static const Color greenButton = Color(0xFF6EAA78);
  static const Color dangerRed = Color(0xFFD88A82);
  static const Color flameOrange = Color(0xFFE06229);
  static const Color flameBadgeBg = Color(0xFFFFD2BA);
  static const Color devPurple = Color(0xFFB8A5C6); // Developer accent tint
}

/// Profile & Settings Screen with Integrated Developer & Debug Tools.
///
/// Features & Guidance:
/// 1. Learner Profile & Badges: Displays username, avatar, and live streak / mastery stats.
/// 2. Audio & Speech Settings: Configures TTS rate, volume, and tactile stationery sound/vibrations.
/// 3. Developer / Debug Tools Card:
///    - **Unlock All Rows Live Toggle**: Instantly toggles [ProgressService.unlockAllRows] across
///      the entire app so you can preview all rows without completing lessons.
///    - **Lock to 'A row' Only**: Resets all row question checkpoints and completion flags back to
///      the initial state (only 'A row' unlocked) while preserving your streak, username, and avatar.
///    - **Simulate Flashcard Ratings**: Injects sample SRS ratings ('Easy', 'Good', 'Hard', 'Again')
///      into SharedPreferences so you can test the new stacked Practice Quiz difficulty UI immediately.
///    - **Clear Flashcard Ratings**: Removes all `kana_difficulty_*` ratings without affecting lesson progress.
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
  static const List<IconData> _avatarIcons = [
    Icons.person,
    Icons.pets,
    Icons.local_florist,
    Icons.auto_stories,
    Icons.coffee,
  ];

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

  /// Loads profile settings and mirrors shared keys for seamless HomeScreen synchronization.
  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      // Synchronize with both profile-specific keys and general user keys read by HomeScreen
      _userName =
          _prefs.getString('profile_username') ??
          _prefs.getString('user_name') ??
          'Kerby';
      _selectedAvatarIndex = _prefs.getInt('profile_avatar_idx') ?? 0;
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

  /// Saves a preference with dual-key synchronization when updating identity data.
  Future<void> _savePreference(String key, dynamic value) async {
    if (value is String) {
      await _prefs.setString(key, value);
      if (key == 'profile_username') {
        // Dual-write so HomeScreen picks up the exact same key immediately
        await _prefs.setString('user_name', value);
      }
    } else if (value is int) {
      await _prefs.setInt(key, value);
      if (key == 'profile_avatar_idx') {
        // Map index to name string for screens reading string-based avatar keys
        await _prefs.setString('user_avatar', 'avatar_$value');
      }
    } else if (value is double) {
      await _prefs.setDouble(key, value);
    } else if (value is bool) {
      await _prefs.setBool(key, value);
    }
  }

  void _testPronunciation() async {
    TactileFeedback.press();
    await _flutterTts.stop();
    await _flutterTts.setSpeechRate(_speechRate);
    await _flutterTts.setVolume(_speechVolume);
    await _flutterTts.speak("こんにちは！");
  }

  void _showEditNameDialog() {
    TactileFeedback.press();
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
            onPressed: () {
              TactileFeedback.toggle();
              Navigator.pop(context);
            },
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textLight),
            ),
          ),
          GestureDetector(
            onTap: () {
              TactileFeedback.press();
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
    TactileFeedback.press();
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

  // ===========================================================================
  // SOUND & TTS MODAL SHEET (Audio + Tactile & Haptics)
  // ===========================================================================
  void _showSoundSettingsModal() {
    TactileFeedback.press();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.taupe,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Icon(
                        Icons.volume_up_outlined,
                        color: AppColors.textDark,
                        size: 24,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Sound & Audio Settings',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // SUBSECTION 1: AUDIO & PRONUNCIATION (TTS)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.beige.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.textDark, width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Audio & Pronunciation (TTS)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Speech Speed',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                            Text(
                              '${_speechRate.toStringAsFixed(2)}x',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
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
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 9,
                            ),
                            trackHeight: 5,
                          ),
                          child: Slider(
                            value: _speechRate,
                            min: 0.25,
                            max: 1.0,
                            divisions: 15,
                            onChanged: (val) {
                              setModalState(() => _speechRate = val);
                              setState(() => _speechRate = val);
                              _savePreference('settings_speech_rate', val);
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Speech Volume',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                            Text(
                              '${(_speechVolume * 100).toInt()}%',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
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
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 9,
                            ),
                            trackHeight: 5,
                          ),
                          child: Slider(
                            value: _speechVolume,
                            min: 0.0,
                            max: 1.0,
                            divisions: 10,
                            onChanged: (val) {
                              setModalState(() => _speechVolume = val);
                              setState(() => _speechVolume = val);
                              _savePreference('settings_speech_volume', val);
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        Center(
                          child: GestureDetector(
                            onTap: _testPronunciation,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.sand,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.textDark,
                                  width: 1.5,
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.volume_up,
                                    color: AppColors.textDark,
                                    size: 18,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Test Voice: こんにちは',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
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
                  ),

                  const SizedBox(height: 18),

                  // SUBSECTION 2: TACTILE AND HAPTICS
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.beige.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.textDark, width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tactile & Haptics',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildToggleRow(
                          label: 'Sound Effects (Clicks)',
                          value: _soundFxEnabled,
                          onChanged: (val) {
                            TactileFeedback.toggle();
                            setModalState(() => _soundFxEnabled = val);
                            setState(() => _soundFxEnabled = val);
                            _savePreference('settings_sound_fx', val);
                            TactileFeedback.soundEnabled = val;
                          },
                        ),
                        const Divider(
                          color: AppColors.textDark,
                          height: 24,
                          thickness: 1,
                        ),
                        _buildToggleRow(
                          label: 'Haptic Feedback (Vibrations)',
                          value: _hapticsEnabled,
                          onChanged: (val) {
                            TactileFeedback.toggle();
                            setModalState(() => _hapticsEnabled = val);
                            setState(() => _hapticsEnabled = val);
                            _savePreference('settings_haptics', val);
                            TactileFeedback.hapticsEnabled = val;
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // DATA MANAGEMENT MODAL (Reset Progress)
  // ===========================================================================
  void _showDataManagementModal() {
    TactileFeedback.press();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.taupe,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.dangerRed,
                  size: 24,
                ),
                SizedBox(width: 8),
                Text(
                  'Data Management',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildActionButton(
              label: 'Reset Mastered Kana',
              color: AppColors.taupe,
              onTap: () {
                Navigator.pop(context);
                _showResetConfirmDialog(resetAll: false);
              },
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              label: 'Reset All Data & Streaks',
              color: AppColors.dangerRed,
              isDestructive: true,
              onTap: () {
                Navigator.pop(context);
                _showResetConfirmDialog(resetAll: true);
              },
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
            onPressed: () {
              TactileFeedback.toggle();
              Navigator.pop(context);
            },
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
                // Clear user profile overrides while retaining essential keys if needed
                await ProgressService.instance.resetAllProgress();
                _loadSettings();
              } else {
                await ProgressService.instance.resetMasteredKana();
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

  // ===========================================================================
  // DEVELOPER & DEBUG ACTIONS
  // ===========================================================================

  /// Resets row question checkpoints and completion flags back to initial state
  /// (enforces 'A row' as the only unlocked row). Preserves study streak and profile.
  Future<void> _resetRowCheckpointsOnly() async {
    TactileFeedback.press();
    await ProgressService.instance.resetRowCheckpoints();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.cream,
          content: const Text(
            "Row locks reset! Only 'A row' is unlocked.",
            style: TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: AppColors.textDark, width: 1.5),
          ),
        ),
      );
    }
  }

  /// Injects simulated SRS ratings across Hiragana and Katakana characters
  /// so all 5 Quiz difficulty buckets (Easy, Good, Hard, Again, All) have testable data.
  Future<void> _simulateFlashcardRatings() async {
    TactileFeedback.success();

    final Map<String, String> mockRatings = {
      // Easy (10 characters)
      'あ': 'Easy', 'い': 'Easy', 'う': 'Easy', 'え': 'Easy', 'お': 'Easy',
      'ア': 'Easy', 'イ': 'Easy', 'ウ': 'Easy', 'エ': 'Easy', 'オ': 'Easy',
      // Good (6 characters)
      'か': 'Good', 'き': 'Good', 'く': 'Good',
      'カ': 'Good', 'キ': 'Good', 'ク': 'Good',
      // Hard (4 characters)
      'さ': 'Hard', 'し': 'Hard',
      'サ': 'Hard', 'シ': 'Hard',
      // Again (3 characters)
      'た': 'Again',
      'タ': 'Again', 'チ': 'Again',
    };

    final writes = <Future<bool>>[];
    for (final entry in mockRatings.entries) {
      writes.add(_prefs.setString('kana_difficulty_${entry.key}', entry.value));
    }
    await Future.wait(writes);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.cream,
          content: const Text(
            'Simulated SRS ratings generated! (Easy: 10, Good: 6, Hard: 4, Again: 3)',
            style: TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: AppColors.textDark, width: 1.5),
          ),
        ),
      );
    }
  }

  /// Erases all stored flashcard difficulty ratings (`kana_difficulty_*`)
  Future<void> _clearFlashcardRatings() async {
    TactileFeedback.press();
    final keys = _prefs
        .getKeys()
        .where((k) => k.startsWith('kana_difficulty_'))
        .toList();

    if (keys.isNotEmpty) {
      await Future.wait(keys.map((k) => _prefs.remove(k)));
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.cream,
          content: const Text(
            'All flashcard difficulty ratings cleared.',
            style: TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: AppColors.textDark, width: 1.5),
          ),
        ),
      );
    }
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
                      // 1. Learner Profile Card with 3 Badges (Streak, Hiragana, Katakana)
                      _buildProfileCard(ps),
                      const SizedBox(height: 24),

                      // 2. Preferences Card (Notification, Sound -> TTS & Haptics, Appearance)
                      _buildPreferencesCard(),
                      const SizedBox(height: 24),

                      // 3. App Card (About the app -> Features, Reset Progress -> Data Management)
                      _buildAppCard(),
                      const SizedBox(height: 24),

                      // 4. Developer / Debug Tools Card (Live Unlocks & Rating Testing)
                      _buildDeveloperCard(ps),
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
            'Profile',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          Icon(Icons.person_outline, color: AppColors.textDark, size: 28),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. USER PROFILE SUMMARY CARD (WITH 3 STAT BADGES)
  // ===========================================================================
  Widget _buildProfileCard(ProgressService ps) {
    return _buildCardBase(
      headerText: 'Learner Profile',
      headerIcon: Icons.badge_outlined,
      trailingAction: GestureDetector(
        onTap: _showEditNameDialog,
        child: const Icon(
          Icons.edit_outlined,
          color: AppColors.textDark,
          size: 20,
        ),
      ),
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
                      'Japanese Kana Learner',
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

          // 3 Stat Badges side by side (Streak, Hiragana Masters, Katakana Masters)
          Row(
            children: [
              Expanded(
                child: _buildStatBadge(
                  icon: Icons.local_fire_department,
                  iconColor: AppColors.flameOrange,
                  title: '${ps.streakDays}',
                  subtitle: 'Streak',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatBadge(
                  icon: Icons.check_circle_outline,
                  iconColor: AppColors.greenButton,
                  title: '${ps.masteredHiraganaCount}/104',
                  subtitle: 'Hiragana',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatBadge(
                  icon: Icons.check_circle_outline,
                  iconColor: AppColors.skyBlue,
                  title: '${ps.masteredKatakanaCount}/104',
                  subtitle: 'Katakana',
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
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.beige.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.textDark, width: 1.5),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textLight,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 3. PREFERENCES CARD
  // ===========================================================================
  Widget _buildPreferencesCard() {
    return _buildCardBase(
      headerText: 'Preferences',
      headerIcon: Icons.tune_rounded,
      child: Column(
        children: [
          _buildSettingsNavigationTile(
            icon: Icons.notifications_none_rounded,
            title: 'Notification',
            subtitle: 'Manage your notifications',
            onTap: () {
              TactileFeedback.press();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Daily study reminders are scheduled.'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          const Divider(color: AppColors.textDark, height: 20, thickness: 1),
          _buildSettingsNavigationTile(
            icon: Icons.volume_up_outlined,
            title: 'Sound',
            subtitle: 'Adjust audio & tactile settings',
            onTap: _showSoundSettingsModal,
          ),
          const Divider(color: AppColors.textDark, height: 20, thickness: 1),
          _buildSettingsNavigationTile(
            icon: Icons.palette_outlined,
            title: 'Appearance',
            subtitle: 'Customize your app theme',
            onTap: () {
              TactileFeedback.press();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cozy stationery pastel palette is active.'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 4. APP CARD
  // ===========================================================================
  Widget _buildAppCard() {
    return _buildCardBase(
      headerText: 'App',
      headerIcon: Icons.info_outline_rounded,
      child: Column(
        children: [
          _buildSettingsNavigationTile(
            icon: Icons.info_outline,
            title: 'About the app',
            subtitle: 'Version 1.0.0',
            onTap: () {
              TactileFeedback.press();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AboutApplicationScreen(),
                ),
              );
            },
          ),
          const Divider(color: AppColors.textDark, height: 20, thickness: 1),
          _buildSettingsNavigationTile(
            icon: Icons.refresh_rounded,
            title: 'Reset Progress',
            subtitle: 'Clear your data and start over',
            onTap: _showDataManagementModal,
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 5. DEVELOPER / DEBUG TOOLS CARD
  // ===========================================================================
  Widget _buildDeveloperCard(ProgressService ps) {
    return _buildCardBase(
      headerText: 'Developer & Debug Tools',
      headerIcon: Icons.bug_report_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Live Unlock All Rows Toggle
          _buildToggleRow(
            label: 'Unlock All Rows (Dev Override)',
            value: ps.unlockAllRows,
            onChanged: (val) {
              TactileFeedback.toggle();
              ps.setUnlockAllRows(val);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.cream,
                  content: Text(
                    val
                        ? 'All rows unlocked across the app.'
                        : 'Row progression locks re-enforced.',
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  duration: const Duration(seconds: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(
                      color: AppColors.textDark,
                      width: 1.5,
                    ),
                  ),
                ),
              );
            },
          ),
          const Divider(color: AppColors.textDark, height: 22, thickness: 1),

          // 2. Lock to 'A row' Only
          _buildSettingsNavigationTile(
            icon: Icons.lock_reset_rounded,
            title: "Lock to 'A row' Only",
            subtitle: 'Reset row progression without losing streak',
            onTap: _resetRowCheckpointsOnly,
          ),
          const Divider(color: AppColors.textDark, height: 22, thickness: 1),

          // 3. Simulate Flashcard SRS Ratings
          _buildSettingsNavigationTile(
            icon: Icons.auto_fix_high_rounded,
            title: 'Simulate Flashcard Ratings',
            subtitle: 'Populate Easy, Good, Hard, Again quiz buckets',
            onTap: _simulateFlashcardRatings,
          ),
          const Divider(color: AppColors.textDark, height: 22, thickness: 1),

          // 4. Clear Flashcard Ratings
          _buildSettingsNavigationTile(
            icon: Icons.layers_clear_outlined,
            title: 'Clear Flashcard Ratings',
            subtitle: 'Reset SRS difficulty ratings back to 0',
            onTap: _clearFlashcardRatings,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsNavigationTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.beige.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.textDark, width: 1.2),
            ),
            child: Icon(icon, color: AppColors.textDark, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
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
                    fontSize: 11,
                    color: AppColors.textLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textDark, size: 22),
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
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
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
    Widget? trailingAction,
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
                const Spacer(),
                if (trailingAction != null) trailingAction,
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
// ABOUT APPLICATION SCREEN (FEATURES PANEL & CREDITS)
// =============================================================================
class AboutApplicationScreen extends StatelessWidget {
  const AboutApplicationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.beige,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
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
                      Icons.arrow_back_ios_new,
                      color: AppColors.textDark,
                      size: 22,
                    ),
                    onPressed: () {
                      TactileFeedback.toggle();
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'About',
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                children: [
                  // 1. Application Information
                  _buildAboutCard(
                    headerText: 'Application Information',
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            color: AppColors.sage,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.textDark,
                              width: 2,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'かな',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Kana Application',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'A cozy, tactile Japanese Kana learning companion crafted with spaced repetition, native audio pronunciation, and interactive stroke tracing.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textLight,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 2. Features Panel
                  _buildAboutCard(
                    headerText: 'Features',
                    headerIcon: Icons.menu_book_rounded,
                    child: Column(
                      children: [
                        _buildFeaturePill(
                          kanaChar: 'あ',
                          title: 'Hiragana Lessons',
                          description:
                              'Master all 46 basic characters, dakuon, and compound yoon.',
                          bgColor: AppColors.lightSage,
                        ),
                        const SizedBox(height: 10),
                        _buildFeaturePill(
                          kanaChar: 'ア',
                          title: 'Katakana Lessons',
                          description:
                              'Build your reading confidence for loanwords and foreign terms.',
                          bgColor: const Color(0xFFF3E7F7),
                        ),
                        const SizedBox(height: 10),
                        _buildFeaturePill(
                          icon: Icons.edit_note_rounded,
                          title: 'Interactive Stroke Writing',
                          description:
                              'Follow stroke animations and trace Kana on canvas with real-time accuracy.',
                          bgColor: AppColors.lightSkyBlue,
                        ),
                        const SizedBox(height: 10),
                        _buildFeaturePill(
                          icon: Icons.extension_outlined,
                          title: 'Word Builder',
                          description:
                              'Assemble real JLPT vocabulary from syllable tiles with instant TTS feedback.',
                          bgColor: const Color(0xFFFFF0D4),
                        ),
                        const SizedBox(height: 10),
                        _buildFeaturePill(
                          icon: Icons.style_outlined,
                          title: 'Flashcard SRS',
                          description:
                              'Reinforce recognition with customizable spaced-repetition difficulty ratings.',
                          bgColor: AppColors.beige.withOpacity(0.6),
                        ),
                        const SizedBox(height: 10),
                        _buildFeaturePill(
                          icon: Icons.menu_book_rounded,
                          title: 'Vocabulary Library',
                          description:
                              'Offline dictionary with live search, English meanings, and audio replay.',
                          bgColor: AppColors.cream,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 3. Credits
                  _buildAboutCard(
                    headerText: 'Credits',
                    headerIcon: Icons.code_rounded,
                    child: const Column(
                      children: [
                        _CreditRow(label: 'Developer', value: 'Kerby Cruz'),
                        SizedBox(height: 10),
                        _CreditRow(label: 'UI/UX Design', value: 'Kerby Cruz'),
                        SizedBox(height: 10),
                        _CreditRow(
                          label: 'Software Used',
                          value:
                              '• Flutter / Dart — app development\n• VS Code — code editor\n• Figma — UI/UX design',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutCard({
    required String headerText,
    IconData? headerIcon,
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
                if (headerIcon != null) ...[
                  Icon(headerIcon, color: AppColors.textDark, size: 18),
                  const SizedBox(width: 8),
                ],
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
          Padding(padding: const EdgeInsets.all(16.0), child: child),
        ],
      ),
    );
  }

  Widget _buildFeaturePill({
    String? kanaChar,
    IconData? icon,
    required String title,
    required String description,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.textDark, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.textDark, width: 1.2),
            ),
            alignment: Alignment.center,
            child: kanaChar != null
                ? Text(
                    kanaChar,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  )
                : Icon(icon, color: AppColors.textDark, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
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
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textLight,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CreditRow extends StatelessWidget {
  final String label;
  final String value;

  const _CreditRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textLight,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
