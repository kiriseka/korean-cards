# Korean Cards

A personal, offline, gamified Korean app for Android focused on talking with people: speaking practice with speech recognition, conversation role-play, survival phrases, topic and grammar lessons, word games and Anki-style flashcards (FSRS), built on 2,492 beginner (초급) words from the National Institute of Korean Language's Basic Korean Dictionary, with Korean pronunciation through the phone's text-to-speech.

## Using it

- **Today's session (오늘의 15분)**: one button on Home, three short steps sized to 10/15/20 minutes — due flashcards, speak & listen (shadowing, natural replies, dictation, a phrase from English), then something new (the next conversation scene, topic lesson or grammar point). +25 XP for finishing.
- **Speaking**: lessons, scenes and the Echo game use the phone's speech recognition (Google, works offline with the Korean speech pack). You see which syllables were heard right; two tries; "Can't talk now" skips without penalty.
- **Home**: daily XP goal ring, streak 🔥 (with streak freezes 🧊), three daily quests, *Continue* buttons for your next topic and grammar lesson, flashcard review, word of the day.
- **Learn → Topics**: 8 survival-phrase units first (150 phrases: politeness, not understanding, café, shopping, getting around, meeting people, reactions, help — practised by saying them), then 20 topics (Food, Family, Weather, Transport…) plus *My words*. Each is a path of 8-word lessons: meet the words, then ~14 mixed exercises (meaning, listening, matching pairs, syllable building, typing), then stars. Lessons inside a topic unlock in order; finish them all to unlock the 🏆 unit challenge (3 hearts). Learned words go into your flashcards automatically.
- **Learn → Talk**: 24 everyday conversation scenes (introductions, café, taxi, pharmacy, weekend plans…). Listen, understand, shadow your lines, then role-play: the app speaks the other person and checks what you say.
- **Learn → Grammar**: 37 lessons in 5 units — sentence basics (word order, 이에요, 있어요, speech levels), particles (은/는, 이/가, 을/를, 도, 에, 에서, 의, 하고, (으)로, 부터/까지, 한테, 만), tenses (present, past, future, -고 있어요, formal, negation, irregular verbs), connecting & describing endings (-고, -지만, -아서, -(으)니까, -(으)면, -는, -(으)ㄴ, -(으)ㄹ) and everyday patterns (-고 싶어요, -(으)세요, -아/어 주세요, can, must, shall we). Each lesson has swipeable explanation cards with formulas and tap-to-hear examples, then sentence building, fill-in-the-blank and conjugation drills generated from real words.
- **Practice**:
  - 💪 **Grammar Gym** — particles (은/는, 이/가, 을/를, 도, 에, 에서, (으)로) and verb tenses (present, past, future, -고 있어요, negative, formal, "which tense fits 어제/내일/지금?") drilled in generated sentences with English, each skill scheduled like a flashcard with a mastery meter.
  - 🔢 **Numbers & money** — Sino vs native numbers, prices, time, age, months (유월, 시월) and counters (개, 명, 잔, 권, 장, 마리).
  - 🩹 **Fix my mistakes** (anything missed this week, until you get it right twice) and 😵‍💫 **Tricky words** (forgotten 4+ times).
  - 🎮 Arcade: Speed Round, Match Madness, Listening Challenge (now with "pick the natural reply"), Sentence Builder, Spelling Bee, Echo (repeat sentences against the clock) — with your learned words, a topic, or your own words. Personal bests are kept.
- **Words**: search and filter all words; 📖 **offline dictionary** (53,000 KRDict entries, conjugated forms work: 들었어요 → 듣다); add your own words with dictionary autofill, and edit them.
- **Share to the app**: share text from any app, or select Korean text → *Look up in Korean Cards* — every word is looked up and can be added in one tap.
- **Home-screen widget**: streak, cards due, today's steps and the word of the day.
- **Level 2 (중급)**: 8,669 intermediate words as Level 2 lessons in each topic (after its beginner lessons); new flashcards include them after 1,500 beginner words or when switched on.
- **Me**: level and title (새싹 → 한국어 왕), XP, 23 badges, detailed stats, ⚙ settings (daily goal, sounds, vibration, typing exercises, flashcards, reminder, theme, backup).

The study day rolls over at 4am.

## Builds

Built APKs are kept per version in `releases/` (git-ignored):

- `releases/v1.0.0/` — the first build (flashcards only; reports version 0.1.0).
- `releases/v1.1.0/` — topics, grammar, games, gamification.
- `releases/v1.2.0/` — speaking, conversations, phrases, Today's session.
- `releases/v1.3.0/korean-cards-1.3.0-arm64.apk` — this version: Grammar Gym, numbers, smart review, intermediate words, dictionary, share-to-look-up, widget, new icon. Installs over any earlier APK and keeps your progress.

## Phone setup

1. **Korean voice**: Settings → System → Languages → Text-to-speech output → Google (Speech Recognition & Synthesis) → Install voice data → 한국어. Without it the app works silently and shows a banner.
2. **Install the app** — either:
   - USB: enable Developer options (tap *Build number* 7 times) → USB debugging, plug in, then `flutter run --release` (or `flutter install` after a build).
   - Or run `flutter build apk --release --split-per-abi`, copy `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` (~21 MB, right for almost every modern phone) to the phone and open it (allow "Install unknown apps" for your file manager).

## Development

Toolchain on this PC: Flutter at `C:\src\flutter` (on the user PATH), Android SDK at `C:\Android\Sdk`, JDK from Android Studio (`flutter config --jdk-dir`).

```bash
flutter pub get
dart run build_runner build      # after changing lib/data/db.dart
flutter test
flutter run                      # phone connected over USB
flutter build apk --release
```

Layout: `lib/data` (drift database, word import, migrations), `lib/srs` (FSRS), `lib/learn` (curriculum, exercise generator, lesson runner), `lib/grammar` (Hangul helpers, conjugator, grammar content model), `lib/game` (XP, levels, streak, quests, badges, sounds), `lib/games` (exercise widgets), `lib/features/*` (screens), `lib/services` (TTS, reminder, backup).

Content:

- `assets/data/phrases.json` / `dialogues.json` — hand-written survival phrases (ids are permanent) and conversation scenes. Checked by `test/talk_test.dart`.
- `assets/data/grammar.json` — the hand-written grammar course (first option in a question is the right one; the app shuffles). `test/content_test.dart` checks it.
- `assets/data/sentence_frames.json` — hand-written sentence building blocks for the Grammar Gym (`lib/grammar/sentence_gen.dart`). Checked by `test/sentence_gen_test.dart`.
- `assets/data/dictionary.json.gz` — built by `python tools/build_dictionary.py` from the KRDict dump.
- `assets/icon/*.png` — drawn by `python tools/make_icon.py`; then `dart run flutter_launcher_icons` and `dart run flutter_native_splash:create`.
- `assets/sounds/*.wav` — generated by `python tools/make_sounds.py`.
- Database schema changes: bump `schemaVersion`, run `dart run drift_dev make-migrations`, write the step in `lib/data/db.dart`, and fill in `test/drift/default/migration_test.dart`.

### Rebuilding the word list

`assets/data/words.json` is generated by `tools/build_words.py` from the official KRDict download (krdict.korean.go.kr → 사전 내려받기 → JSON). Unzip it into the project root (the folder is git-ignored) and run:

```bash
python tools/build_words.py --levels 초급,중급   # what the app ships
python tools/build_dictionary.py
```

It also writes `assets/data/curriculum.json` (topic units) and stores each verb's KRDict conjugation forms, which the conjugator uses to get irregular verbs right. On next launch the app imports changed words; progress, stars and notes are kept.

### Release signing

Release builds are signed with `C:\Users\Pongo\korean-cards-signing\korean-cards.keystore` via `android/key.properties` (both kept out of git). It is the key every installed version has used, so updates install in place. **Back that folder up** (cloud drive / USB): without it, a new build can't update the installed app.

## Data & credits

- Words, meanings, examples: 한국어기초사전 (Basic Korean Dictionary), National Institute of Korean Language — CC BY-SA 2.0 KR.
- Learning order: OpenSubtitles word frequencies from hermitdave/FrequencyWords — CC BY-SA 4.0.
- Scheduling: [FSRS](https://github.com/open-spaced-repetition/dart-fsrs).
