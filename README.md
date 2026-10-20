# Daily English

A Flutter mobile app that helps Turkish speakers build an English vocabulary habit with **one carefully explained word a day**.

Instead of long word lists, Daily English focuses on understanding each word deeply: how it is used, what nuance it carries in Turkish, and which mistakes Turkish learners commonly make with it.

## Features

- **Word of the day:** A new word every day from a curated list of 500 words from A2 to C1 level.
- **Detailed word cards:** Each word includes:
  - IPA pronunciation, CEFR level and part of speech
  - A natural example sentence
  - A **common mistake note** written specifically for Turkish learners
  - The Turkish meaning and its **nuance**
- **Text-to-speech:** Listen to the correct pronunciation.
- **Quick quiz:** A short quiz after each word to check understanding.
- **Spaced repetition:** Correct answers double the review interval (up to 30 days); wrong answers bring the word back the next day.
- **Daily streak:** Tracks your current and longest streak and the number of words learned.
- **Daily reminder:** A local notification at a time you choose in Settings.
- **Light and dark mode.**

## Project structure

```
lib/
├── core/          # theme and date utilities
├── data/          # word and progress models, repositories
├── features/      # daily word, quiz, progress and settings screens
├── services/      # notifications, text-to-speech, spaced repetition
└── state/         # app state (progress, streaks)
assets/data/words_seed.json   # word list
```

## Built with

- [Flutter](https://flutter.dev) & Dart
- `flutter_tts` for pronunciation
- `shared_preferences` for saving progress on the device
- `flutter_local_notifications` for daily reminders

## Running the app

```bash
flutter pub get
flutter run
```

## About

Created by Ayşe Büşra Demirdağ — METU Foreign Language Education graduate and English teacher, currently studying AI-Powered Coding at Anadolu University. See also my YDS vocabulary app: [7-Kelime-YDS](https://github.com/busdem/7-Kelime-YDS).
