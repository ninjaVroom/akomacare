# AkomaCare

Samuel Vroom

A Flutter prototype for reading cardiovascular guidelines, keeping notes and working through short learning activities.

## Case study

The reader needed to hold a place in a long guideline without making someone start again at the top. Sections have stable keys. Bookmarks, notes and the last-read position use those keys, and the app saves them on the device with the profile.

The main screens cover guideline browsing, saved sections, calculators and games. Text size can be changed in the reader. The supplied stroke-referral content has its own flowchart and assessment table; sections without supplied text remain labelled placeholders.

The learning screens include a sliding puzzle and a word finder. Scoring is stored with the profile. Existing tests check calculator outputs, puzzle movement, word placement and one-time scoring. Widget checks cover navigation back to Home, sign-out and form errors.

This is an interface and interaction prototype. Accounts use mock sign-in and local storage. The included clinical content is incomplete, and the calculators have not been independently validated for patient care. No patient records or clinical backend are connected.

## Run locally

Install Flutter with Dart compatible with `pubspec.yaml`.

```sh
flutter pub get
flutter run -d chrome
flutter test
```

The demo sign-in values are defined in `lib/data.dart`. Use the onboarding and sign-in screens, open a guideline, save a section, add a note and return to it from Saved.

## Source

`lib/data.dart` defines the supplied content and calculator models. `lib/state.dart` handles profiles and local persistence. `lib/screens/` contains the reader, authentication and learning screens. Font notices remain alongside the bundled fonts.

## Prototype

Figma prototype link pending.
