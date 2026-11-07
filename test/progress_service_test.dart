import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kana_learning/services/progress_service.dart';

// Run from the Flutter project folder using:
//   flutter test test/progress_service_test.dart
//
// These tests use an in-memory SharedPreferences store. They do NOT erase
// progress saved by Cozy Kana on an actual Android or iOS device.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ProgressService is a singleton. Reinitializing it with fresh mock
  // preferences before each test avoids depending on another test's state.
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ProgressService.instance.init();
  });

  test('Opening the app does not count as studying', () {
    final progress = ProgressService.instance;

    expect(progress.streakDays, 0);
    expect(progress.activeDaysThisWeek.where((active) => active), isEmpty);
  });

  test('Completing A row unlocks Ka row, but not Sa row', () async {
    final progress = ProgressService.instance;

    expect(
      progress.isRowUnlocked(writingSystem: 'Hiragana', rowTitle: 'A row'),
      isTrue,
    );
    expect(
      progress.isRowUnlocked(writingSystem: 'Hiragana', rowTitle: 'Ka row'),
      isFalse,
    );

    await progress.markRowCompleted(
      writingSystem: 'Hiragana',
      rowTitle: 'A row',
    );

    expect(
      progress.isRowUnlocked(writingSystem: 'Hiragana', rowTitle: 'Ka row'),
      isTrue,
    );
    expect(
      progress.isRowUnlocked(writingSystem: 'Hiragana', rowTitle: 'Sa row'),
      isFalse,
    );
  });

  test('Practice checkpoint does not mark a Learn row completed', () async {
    final progress = ProgressService.instance;

    await progress.saveRowProgress(
      writingSystem: 'Hiragana',
      rowTitle: 'A row',
      currentQuestion: 5,
      totalQuestions: 5,
      markCompleted: false, // Set false for Practice-mode review sessions.
    );

    expect(
      progress.isRowCompleted(writingSystem: 'Hiragana', rowTitle: 'A row'),
      isFalse,
    );
  });

  test('Quiz accuracy uses the actual right and wrong answers', () {
    final progress = ProgressService.instance;

    progress.recordQuizAnswer(correct: true);
    progress.recordQuizAnswer(correct: false);

    expect(progress.quizAnswersCount, 2);
    expect(progress.quizCorrectCount, 1);
    expect(progress.quizAccuracy, closeTo(0.5, 0.0001));
    expect(progress.streakDays, 1); // Studied today.
  });

  test('Writing the same Kana twice counts only once', () {
    final progress = ProgressService.instance;

    progress.markKanaWritten('あ');
    progress.markKanaWritten('あ');
    progress.markKanaWritten('ア');

    expect(progress.isKanaWritten('あ'), isTrue);
    expect(progress.writtenHiraganaCount, 1);
    expect(progress.writtenKatakanaCount, 1);
  });

  test('Mastery counts recognize Hiragana and Katakana separately', () {
    final progress = ProgressService.instance;

    progress.markKanaMastered('あ');
    progress.markKanaMastered('ア');
    progress.markKanaMastered('あ'); // Repeated mastery must not double-count.

    expect(progress.masteredHiraganaCount, 1);
    expect(progress.masteredKatakanaCount, 1);
  });
}
