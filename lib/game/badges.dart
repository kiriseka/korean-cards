/// Numbers the badges are judged on, gathered by GameService.
class GameStats {
  const GameStats({
    this.wordsLearned = 0,
    this.streak = 0,
    this.bestCombo = 0,
    this.lessonsDone = 0,
    this.perfectLessons = 0,
    this.sentencesBuilt = 0,
    this.challengesPassed = 0,
    this.bestSpeedRound = 0,
    this.customWords = 0,
    this.spokenTotal = 0,
    this.scenesDone = 0,
    this.dailyDays = 0,
    this.phrasesLearned = 0,
    this.completedLessons = const {},
    this.grammarUnits = const {},
    this.hour = 12,
  });

  final int wordsLearned;
  final int streak;
  final int bestCombo;
  final int lessonsDone;
  final int perfectLessons;
  final int sentencesBuilt;
  final int challengesPassed;
  final int bestSpeedRound;
  final int customWords;
  final int spokenTotal;
  final int scenesDone;
  final int dailyDays;
  final int phrasesLearned;
  final Set<String> completedLessons;

  /// Grammar unit id → its lesson ids.
  final Map<String, List<String>> grammarUnits;

  /// Local hour of the activity being judged (for night owl / early bird).
  final int hour;

  bool grammarUnitDone(String unit) {
    final ids = grammarUnits[unit];
    return ids != null && ids.isNotEmpty && ids.every(completedLessons.contains);
  }
}

class GameBadge {
  const GameBadge(this.id, this.emoji, this.title, this.description, this.earned);
  final String id;
  final String emoji;
  final String title;
  final String description;
  final bool Function(GameStats s) earned;
}

final badges = <GameBadge>[
  GameBadge('first_lesson', '🐣', 'First steps', 'Finish your first lesson', (s) => s.lessonsDone >= 1),
  GameBadge('words10', '🌱', '첫 단어', 'Learn 10 words', (s) => s.wordsLearned >= 10),
  GameBadge('words100', '🌿', 'Word collector', 'Learn 100 words', (s) => s.wordsLearned >= 100),
  GameBadge('words500', '🌳', 'Word forest', 'Learn 500 words', (s) => s.wordsLearned >= 500),
  GameBadge('words1000', '🏔️', 'Word mountain', 'Learn 1,000 words', (s) => s.wordsLearned >= 1000),
  GameBadge('streak3', '🔥', 'Warming up', '3-day streak', (s) => s.streak >= 3),
  GameBadge('streak7', '🔥', 'One week!', '7-day streak', (s) => s.streak >= 7),
  GameBadge('streak30', '☄️', 'Unstoppable', '30-day streak', (s) => s.streak >= 30),
  GameBadge('streak100', '🌋', '백일', '100-day streak', (s) => s.streak >= 100),
  GameBadge('combo10', '⚡', 'On fire', '10 right answers in a row', (s) => s.bestCombo >= 10),
  GameBadge('combo25', '🌩️', 'Lightning', '25 right answers in a row', (s) => s.bestCombo >= 25),
  GameBadge('perfect1', '💯', 'Flawless', 'Finish a lesson with no mistakes', (s) => s.perfectLessons >= 1),
  GameBadge('perfect10', '💎', 'Perfectionist', '10 flawless lessons', (s) => s.perfectLessons >= 10),
  GameBadge('particles', '🧲', 'Particle pro', 'Finish every particle lesson', (s) => s.grammarUnitDone('particles')),
  GameBadge('tenses', '⏳', 'Time traveler', 'Finish every tense lesson', (s) => s.grammarUnitDone('tenses')),
  GameBadge('endings', '🔗', 'Chain maker', 'Finish every connecting-ending lesson', (s) => s.grammarUnitDone('endings')),
  GameBadge('sentences50', '🧩', 'Sentence smith', 'Build 50 sentences', (s) => s.sentencesBuilt >= 50),
  GameBadge('challenge1', '🏆', 'Topic master', 'Pass a unit challenge', (s) => s.challengesPassed >= 1),
  GameBadge('challenge5', '🗺️', 'World tour', 'Pass 5 unit challenges', (s) => s.challengesPassed >= 5),
  GameBadge('speed30', '🏎️', 'Speed demon', 'Score 30 in Speed Round', (s) => s.bestSpeedRound >= 30),
  GameBadge('collector', '✏️', 'My own words', 'Add 10 words of your own', (s) => s.customWords >= 10),
  GameBadge('spoken1', '🎤', 'First words', 'Say something in Korean out loud', (s) => s.spokenTotal >= 1),
  GameBadge('spoken100', '📣', 'Chatterbox', 'Say 100 things out loud', (s) => s.spokenTotal >= 100),
  GameBadge('roleplay', '🎭', 'Role-play star', 'Finish a conversation scene', (s) => s.scenesDone >= 1),
  GameBadge('scenes10', '🎬', 'Drama star', 'Finish 10 conversation scenes', (s) => s.scenesDone >= 10),
  GameBadge('phrasebook', '📕', 'Phrasebook', 'Learn all 150 survival phrases', (s) => s.phrasesLearned >= 150),
  GameBadge('daily7', '⏱️', 'Daily habit', "Finish today's session 7 times", (s) => s.dailyDays >= 7),
  GameBadge('daily30', '🗓️', 'Unbreakable habit', "Finish today's session 30 times", (s) => s.dailyDays >= 30),
  GameBadge('night_owl', '🦉', 'Night owl', 'Study after 11 pm', (s) => s.hour >= 23 || s.hour < 4),
  GameBadge('early_bird', '🐦', 'Early bird', 'Study before 7 am', (s) => s.hour >= 4 && s.hour < 7),
];
