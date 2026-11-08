// Cozy Kana — Profile & Settings screen.
//
// Learner-facing version: Developer & Debug Tools have been removed.
// All other profile, audio, haptic, About, and reset workflows are preserved.
import '../theme/cozy_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/progress_service.dart';
import '../services/appearance_service.dart';
import '../services/notification_service.dart';
import '../utils/tactile_feedback.dart';
import 'welcome_screen.dart'; // Routes to Welcome onboarding after full data reset

// --- COLOR PALETTE (Cozy Pastel Stationery Theme) ---
class AppColors {
  static Color get cream => CozyPalette.cream;
  static Color get beige => CozyPalette.beige;
  static Color get sand => CozyPalette.sand;
  static Color get taupe => CozyPalette.taupe;
  static Color get textDark => CozyPalette.textDark;
  static Color get textLight => CozyPalette.textLight;

  static Color get sage => CozyPalette.sage;
  static Color get lightSage => CozyPalette.lightSageShade;
  static Color get skyBlue => CozyPalette.skyBlue;
  static Color get lightSkyBlue => CozyPalette.lightSkyBlue;
  static Color get greenButton => CozyPalette.greenButton;
  static Color get dangerRed => CozyPalette.dangerRed;
  static Color get flameOrange => CozyPalette.flameOrange;
  static Color get flameBadgeBg => CozyPalette.flameBadgeBg;
}

/// Profile & Settings screen for learners.
///
/// Features & Guidelines:
/// 1. Learner Profile & Badges:
///    - Synchronizes username and avatar indices with SharedPreferences and HomeScreen.
/// 2. Audio & Haptics Preferences:
///    - Manages TTS rate, volume, and tactile sound effects / haptic vibrations.
/// 3. Data Management & Destructive Resets:
///    - Reset Kana Progress: Resets mastered characters while preserving streaks and profile.
///    - Reset All Data & Streaks: Wipes SharedPreferences entirely (including onboarding flags)
///      and returns the user to [WelcomeScreen].
/// 4. Developer tools:
///    - Removed from this screen in all build modes.
///    - A previously saved "unlock all rows" override is turned off on load.
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

  // Optional daily reminder. Scheduling is handled by NotificationService;
  // these SharedPreferences keys only describe the user's chosen settings.
  bool _dailyReminderEnabled = false;
  int _reminderHour = 19;
  int _reminderMinute = 0;

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

    // IMPORTANT FOR RELEASE:
    // Earlier development versions could save an "Unlock All Rows" override.
    // Since this screen no longer exposes developer controls, disable that
    // override without erasing genuine quiz results or completed lesson rows.
    // ProgressService notifies Learn/Practice of the updated lock status.
    final progress = ProgressService.instance;
    if (progress.unlockAllRows) {
      await progress.setUnlockAllRows(false);
    }

    if (!mounted) return;

    setState(() {
      _userName =
          _prefs.getString('profile_username') ??
          _prefs.getString('user_name') ??
          'Kerby';
      _selectedAvatarIndex = _prefs.getInt('profile_avatar_idx') ?? 0;
      _speechRate = _prefs.getDouble('settings_speech_rate') ?? 0.5;
      _speechVolume = _prefs.getDouble('settings_speech_volume') ?? 1.0;
      _soundFxEnabled = _prefs.getBool('settings_sound_fx') ?? true;
      _hapticsEnabled = _prefs.getBool('settings_haptics') ?? true;
      _dailyReminderEnabled =
          _prefs.getBool('settings_daily_reminder') ?? false;
      _reminderHour = _prefs.getInt('settings_reminder_hour') ?? 19;
      _reminderMinute = _prefs.getInt('settings_reminder_minute') ?? 0;

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
        await _prefs.setString('user_name', value);
      }
    } else if (value is int) {
      await _prefs.setInt(key, value);
      if (key == 'profile_avatar_idx') {
        await _prefs.setString('user_avatar', 'avatar_$value');
      }
    } else if (value is double) {
      await _prefs.setDouble(key, value);
    } else if (value is bool) {
      await _prefs.setBool(key, value);
    }
  }

  Future<void> _testPronunciation() async {
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
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.cream,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: CozyPalette.outline, width: 2),
        ),
        title: Text(
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
          style: TextStyle(
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
              borderSide: BorderSide(color: CozyPalette.outline, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: CozyPalette.outline, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              TactileFeedback.toggle();
              Navigator.pop(dialogCtx);
            },
            child: Text('Cancel', style: TextStyle(color: AppColors.textLight)),
          ),
          GestureDetector(
            onTap: () {
              TactileFeedback.press();
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                setState(() => _userName = newName);
                _savePreference('profile_username', newName);
              }
              Navigator.pop(dialogCtx);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.taupe,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: CozyPalette.outline, width: 1.5),
              ),
              child: Text(
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
      builder: (bottomSheetCtx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
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
                    Navigator.pop(bottomSheetCtx);
                  },
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.sand : AppColors.beige,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: CozyPalette.outline,
                        width: isSelected ? 2.5 : 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: CozyPalette.shadow,
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
                  Row(
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
                      color: AppColors.beige.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: CozyPalette.outline,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
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
                            Text(
                              'Speech Speed',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                            Text(
                              '${_speechRate.toStringAsFixed(2)}x',
                              style: TextStyle(
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
                            overlayColor: AppColors.sand.withValues(alpha: 0.3),
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
                            Text(
                              'Speech Volume',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                            Text(
                              '${(_speechVolume * 100).toInt()}%',
                              style: TextStyle(
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
                            overlayColor: AppColors.sand.withValues(alpha: 0.3),
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
                                  color: CozyPalette.outline,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
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
                      color: AppColors.beige.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: CozyPalette.outline,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
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
                        Divider(
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
  // APPEARANCE SETTINGS — persisted by AppearanceService
  // ===========================================================================
  void _showAppearanceSettingsModal() {
    TactileFeedback.press();
    showModalBottomSheet<void>(
      context: context,
      // The surface below rebuilds as soon as the learner switches theme.
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => ListenableBuilder(
        listenable: AppearanceService.instance,
        builder: (context, _) => Container(
          decoration: BoxDecoration(
            color: AppColors.cream,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
              child: ListenableBuilder(
                listenable: AppearanceService.instance,
                builder: (context, _) {
                  final selected = AppearanceService.instance.mode;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.palette_outlined,
                            color: AppColors.textDark,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Appearance',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: AppColors.textDark,
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Choose the look that feels most comfortable for studying.',
                        style: TextStyle(
                          color: AppColors.textLight,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildAppearanceChoice(
                        label: 'Cozy Light',
                        subtitle: 'Warm cream and beige (recommended)',
                        icon: Icons.wb_sunny_outlined,
                        mode: ThemeMode.light,
                        selected: selected == ThemeMode.light,
                      ),
                      const SizedBox(height: 10),
                      _buildAppearanceChoice(
                        label: 'Cozy Dark',
                        subtitle: 'Warm cocoa cards with soft cream lettering',
                        icon: Icons.dark_mode_outlined,
                        mode: ThemeMode.dark,
                        selected: selected == ThemeMode.dark,
                      ),
                      const SizedBox(height: 10),
                      _buildAppearanceChoice(
                        label: 'Follow System',
                        subtitle: 'Match the device appearance setting',
                        icon: Icons.settings_brightness_outlined,
                        mode: ThemeMode.system,
                        selected: selected == ThemeMode.system,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Your choice is saved automatically and applies to all learning screens.',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ), // Themed Container surface.
      ), // AppearanceService listener updates sheet background.
    );
  }

  Widget _buildAppearanceChoice({
    required String label,
    required String subtitle,
    required IconData icon,
    required ThemeMode mode,
    required bool selected,
  }) {
    return InkWell(
      onTap: () async {
        TactileFeedback.toggle();
        await AppearanceService.instance.setMode(mode);
        if (mounted) setState(() {});
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.sand : AppColors.beige,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: CozyPalette.outline,
            width: selected ? 2.2 : 1.2,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textDark, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: AppColors.textLight, fontSize: 11),
                  ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: AppColors.textDark,
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // NOTIFICATION SETTINGS — actual opt-in, device-local daily reminders
  // ===========================================================================
  void _showNotificationSettingsModal() {
    TactileFeedback.press();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cream,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, updateSheet) => SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.notifications_active_outlined,
                      color: AppColors.textDark,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Study Reminders',
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'A small reminder each day to keep practicing Japanese Kana.',
                  style: TextStyle(color: AppColors.textLight, fontSize: 12),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.beige,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: CozyPalette.outline, width: 1.5),
                  ),
                  child: SwitchListTile.adaptive(
                    // Flutter 3.31+: replace deprecated activeColor with thumb styling.
                    activeThumbColor: AppColors.greenButton,
                    title: Text(
                      'Daily Reminder',
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      'Off by default. Enable when you want.',
                      style: TextStyle(
                        color: AppColors.textLight,
                        fontSize: 11,
                      ),
                    ),
                    value: _dailyReminderEnabled,
                    onChanged: (enabled) async {
                      await _saveReminderSetting(
                        enabled: enabled,
                        time: TimeOfDay(
                          hour: _reminderHour,
                          minute: _reminderMinute,
                        ),
                      );
                      if (sheetContext.mounted) updateSheet(() {});
                    },
                  ),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: _dailyReminderEnabled
                      ? () async {
                          final chosen = await showTimePicker(
                            context: sheetContext,
                            initialTime: TimeOfDay(
                              hour: _reminderHour,
                              minute: _reminderMinute,
                            ),
                          );
                          if (chosen == null) return;
                          await _saveReminderSetting(
                            enabled: true,
                            time: chosen,
                          );
                          if (sheetContext.mounted) updateSheet(() {});
                        }
                      : null,
                  icon: const Icon(Icons.schedule_outlined),
                  label: Text(
                    'Reminder time: ${TimeOfDay(hour: _reminderHour, minute: _reminderMinute).format(sheetContext)}',
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Android may deliver non-urgent reminders a little later to save battery.',
                  style: TextStyle(color: AppColors.textLight, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Persist only after scheduling/cancellation succeeds. Denied permissions
  /// must not leave the switch displaying a misleading "enabled" state.
  Future<void> _saveReminderSetting({
    required bool enabled,
    required TimeOfDay time,
  }) async {
    try {
      if (enabled) {
        final scheduled = await NotificationService.instance.scheduleDaily(
          hour: time.hour,
          minute: time.minute,
        );
        if (!scheduled) {
          // Always use a block for conditional statements (Flutter lint).
          if (mounted) {
            _showSettingsMessage(
              'Notification permission is required to enable reminders.',
            );
          }
          return;
        }
      } else {
        await NotificationService.instance.cancelReminder();
      }
      await _prefs.setBool('settings_daily_reminder', enabled);
      await _prefs.setInt('settings_reminder_hour', time.hour);
      await _prefs.setInt('settings_reminder_minute', time.minute);
      if (!mounted) return;
      setState(() {
        _dailyReminderEnabled = enabled;
        _reminderHour = time.hour;
        _reminderMinute = time.minute;
      });
      _showSettingsMessage(
        enabled
            ? 'Daily study reminder scheduled.'
            : 'Daily study reminder turned off.',
      );
    } catch (e) {
      // Report an actual scheduling error without altering other settings.
      if (mounted) {
        _showSettingsMessage(
          'Could not update reminders. Check notification setup and permissions.',
        );
      }
    }
  }

  void _showSettingsMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
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
      builder: (bottomSheetCtx) => Container(
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
            Row(
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
              label: 'Reset Mastered Kana Only',
              color: AppColors.taupe,
              onTap: () {
                Navigator.pop(bottomSheetCtx);
                _showResetConfirmDialog(resetAll: false);
              },
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              label: 'Reset All Data & Streaks',
              color: AppColors.dangerRed,
              isDestructive: true,
              onTap: () {
                Navigator.pop(bottomSheetCtx);
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
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.cream,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: CozyPalette.outline, width: 2),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: AppColors.dangerRed,
              size: 28,
            ),
            const SizedBox(width: 8),
            Text(
              resetAll ? 'Reset All Data?' : 'Reset Kana Progress?',
              style: TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          resetAll
              ? 'This will erase all progress, streak history, profile name, and return to the Welcome onboarding screen. This cannot be undone.'
              : 'This will reset your mastered characters count. Your study streak and profile will be preserved.',
          style: TextStyle(color: AppColors.textDark, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () {
              TactileFeedback.toggle();
              Navigator.pop(dialogCtx);
            },
            child: Text('Cancel', style: TextStyle(color: AppColors.textDark)),
          ),
          GestureDetector(
            onTap: () async {
              TactileFeedback.press();
              Navigator.pop(dialogCtx);

              if (resetAll) {
                // Cancel a previously scheduled reminder before clearing its setting.
                // A notification should never survive a full account reset.
                try {
                  await NotificationService.instance.cancelReminder();
                } catch (_) {
                  // Reset must remain possible even if notifications are unavailable.
                }
                // Completely erase SharedPreferences (including onboarding flags).
                await _prefs.clear();
                AppearanceService.instance.reset();

                // Re-initialize in-memory service models
                await ProgressService.instance.init();

                if (!mounted) return;

                // Route directly to WelcomeScreen, removing all navigation stacks
                Navigator.pushAndRemoveUntil(
                  context,
                  PageRouteBuilder(
                    transitionDuration: const Duration(milliseconds: 400),
                    pageBuilder: (_, _, _) => const WelcomeScreen(),
                    transitionsBuilder: (_, animation, _, child) =>
                        FadeTransition(opacity: animation, child: child),
                  ),
                  (route) => false,
                );
              } else {
                // Reset mastered kana counts only
                await ProgressService.instance.resetMasteredKana();
                await _loadSettings();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.cream,
                      content: Text(
                        'Mastered kana reset.',
                        style: TextStyle(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: CozyPalette.outline,
                          width: 1.5,
                        ),
                      ),
                    ),
                  );
                }
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.dangerRed,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: CozyPalette.outline, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: CozyPalette.shadow,
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
    CozyPalette.watch(
      context,
    ); // Repaint on light/dark or system theme changes.
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.beige,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.textDark),
        ),
      );
    }

    return Scaffold(
      // Matches the themed canvas used on every tab.
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

                      // Small bottom margin keeps the last card above the
                      // persistent bottom navigation bar.
                      const SizedBox(height: 24),
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
      decoration: BoxDecoration(
        color: AppColors.sand,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        border: Border(
          bottom: BorderSide(color: CozyPalette.outline, width: 2),
        ),
      ),
      child: Row(
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
        child: Icon(Icons.edit_outlined, color: AppColors.textDark, size: 20),
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
                        border: Border.all(
                          color: CozyPalette.outline,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: CozyPalette.shadow,
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
                            color: CozyPalette.outline,
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
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
                            style: TextStyle(
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
                          child: Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
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
        color: AppColors.beige.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CozyPalette.outline, width: 1.5),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            subtitle,
            style: TextStyle(
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
            title: 'Notifications',
            subtitle: _dailyReminderEnabled
                ? 'Daily reminder is enabled'
                : 'Set a gentle daily practice reminder',
            onTap: _showNotificationSettingsModal,
          ),
          Divider(color: AppColors.textDark, height: 20, thickness: 1),
          _buildSettingsNavigationTile(
            icon: Icons.volume_up_outlined,
            title: 'Sound',
            subtitle: 'Adjust audio & tactile settings',
            onTap: _showSoundSettingsModal,
          ),
          Divider(color: AppColors.textDark, height: 20, thickness: 1),
          _buildSettingsNavigationTile(
            icon: Icons.palette_outlined,
            title: 'Appearance',
            subtitle: 'Cozy Light, Cozy Dark, or Follow System',
            onTap: _showAppearanceSettingsModal,
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
          Divider(color: AppColors.textDark, height: 20, thickness: 1),
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
              color: AppColors.beige.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: CozyPalette.outline, width: 1.2),
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
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: AppColors.textDark, size: 22),
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
            style: TextStyle(
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
              border: Border.all(color: CozyPalette.outline, width: 1.8),
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
                  border: Border.all(color: CozyPalette.outline, width: 1.2),
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
          border: Border.all(color: CozyPalette.outline, width: 1.8),
          boxShadow: [
            BoxShadow(
              color: CozyPalette.shadow,
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
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.sand,
              border: Border(
                bottom: BorderSide(color: CozyPalette.outline, width: 2),
              ),
            ),
            child: Row(
              children: [
                Icon(headerIcon, color: AppColors.textDark, size: 18),
                const SizedBox(width: 8),
                Text(
                  headerText,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.textDark,
                  ),
                ),
                const Spacer(),
                // Add the widget only when it is non-null (Dart 3.8+).
                ?trailingAction,
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
    CozyPalette.watch(
      context,
    ); // Repaint on light/dark or system theme changes.
    return Scaffold(
      // Matches the themed canvas used on every tab.
      backgroundColor: AppColors.beige,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
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
                  Text(
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
                  // 1. Current branding — use the same app icon already
                  // declared in pubspec.yaml for launcher generation.
                  _buildAboutCard(
                    headerText: 'Application Information',
                    headerIcon: Icons.info_outline_rounded,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.asset(
                            'assets/image/cozy_kana_launcher_legacy.png',
                            width: 76,
                            height: 76,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const SizedBox(
                                  width: 76,
                                  height: 76,
                                  child: Icon(
                                    Icons.menu_book_rounded,
                                    size: 44,
                                  ),
                                ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Cozy Kana',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textDark,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Your cozy Japanese learning companion',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textLight,
                                ),
                              ),
                              SizedBox(height: 9),
                              Text(
                                'Learn Hiragana and Katakana with guided lessons, '
                                'handwriting, quizzes, flashcards, and categorized '
                                'vocabulary. Track your progress at your own pace.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textLight,
                                  height: 1.4,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Version 1.0.0',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textDark,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 2. Feature descriptions match the current app.
                  _buildAboutCard(
                    headerText: 'Features',
                    headerIcon: Icons.menu_book_rounded,
                    child: Column(
                      children: [
                        _buildFeaturePill(
                          kanaChar: 'あ',
                          title: 'Hiragana Lessons',
                          description:
                              'Learn basic Kana, voiced sounds, and combination characters.',
                          bgColor: AppColors.lightSage,
                        ),
                        const SizedBox(height: 10),
                        _buildFeaturePill(
                          kanaChar: 'ア',
                          title: 'Katakana Lessons',
                          description:
                              'Practice reading Katakana, including loanwords and foreign names.',
                          bgColor: CozyPalette.lavender,
                        ),
                        const SizedBox(height: 10),
                        _buildFeaturePill(
                          icon: Icons.draw_outlined,
                          title: 'Interactive Handwriting',
                          description:
                              'Trace strokes and practice writing characters from memory.',
                          bgColor: AppColors.lightSkyBlue,
                        ),
                        const SizedBox(height: 10),
                        _buildFeaturePill(
                          icon: Icons.style_outlined,
                          title: 'Flashcard Learning',
                          description:
                              'Review characters and rate your recognition difficulty.',
                          bgColor: AppColors.beige,
                        ),
                        const SizedBox(height: 10),
                        _buildFeaturePill(
                          icon: Icons.quiz_outlined,
                          title: 'Kana Quizzes',
                          description:
                              'Test Kana recognition, reading, and listening.',
                          bgColor: AppColors.lightSage,
                        ),
                        const SizedBox(height: 10),
                        _buildFeaturePill(
                          icon: Icons.extension_outlined,
                          title: 'Word Builder',
                          description:
                              'Build Japanese words using tiles, categories, and flexible practice modes.',
                          bgColor: CozyPalette.paleGold,
                        ),
                        const SizedBox(height: 10),
                        _buildFeaturePill(
                          icon: Icons.local_library_outlined,
                          title: 'Vocabulary Library',
                          description:
                              'Explore categorized offline vocabulary with search, meanings, and audio.',
                          bgColor: AppColors.beige,
                        ),
                        const SizedBox(height: 10),
                        _buildFeaturePill(
                          icon: Icons.insights_outlined,
                          title: 'Progress & Study Streaks',
                          description:
                              'Follow your writing, learning progress, and daily study activity.',
                          bgColor: AppColors.lightSkyBlue,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 3. Credits — icon-led rows fit even on narrower phones.
                  _buildAboutCard(
                    headerText: 'Credits',
                    headerIcon: Icons.code_rounded,
                    child: Column(
                      children: [
                        _CreditRow(
                          icon: Icons.code_rounded,
                          label: 'Developer',
                          value: 'Kerby Cruz',
                        ),
                        Divider(height: 22, color: AppColors.beige),
                        _CreditRow(
                          icon: Icons.palette_outlined,
                          label: 'UI/UX Design',
                          value: 'Kerby Cruz',
                        ),
                        Divider(height: 22, color: AppColors.beige),
                        _CreditRow(
                          icon: Icons.computer_rounded,
                          label: 'Software Used',
                          value:
                              'Flutter & Dart — app development\n'
                              'VS Code — code editor\n'
                              'Figma — UI/UX design',
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
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.sand,
              border: Border(
                bottom: BorderSide(color: CozyPalette.outline, width: 2),
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
                  style: TextStyle(
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
        border: Border.all(color: CozyPalette.outline, width: 1.5),
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
              border: Border.all(color: CozyPalette.outline, width: 1.2),
            ),
            alignment: Alignment.center,
            child: kanaChar != null
                ? Text(
                    kanaChar,
                    style: TextStyle(
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
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
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
  final IconData icon;
  final String label;
  final String value;

  const _CreditRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    CozyPalette.watch(
      context,
    ); // Repaint on light/dark or system theme changes.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.beige,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: CozyPalette.outline, width: 1.2),
          ),
          child: Icon(icon, color: AppColors.textDark, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: AppColors.textLight,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
