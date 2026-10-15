# Flutter Project Instructions

## Project
This is a Flutter mobile application written in Dart.

## Development rules

- Use Flutter and Dart best practices.
- Prefer Material 3 unless explicitly instructed otherwise.
- Write clean, maintainable, modular code.
- Use null safety.
- Avoid unnecessary dependencies.
- Before adding a package, explain why it is needed.
- Do not modify Android configuration unless necessary.
- Do not change Flutter SDK configuration.
- Do not change Android SDK configuration unless explicitly requested.
- Keep Android-specific configuration compatible with the current Flutter project.
- Test changes with Flutter analysis and the Android emulator.

## Before making changes

1. Inspect the existing project structure.
2. Inspect relevant files.
3. Understand the current implementation.
4. Make the smallest appropriate changes.
5. Do not overwrite working functionality unnecessarily.

## After making changes

Run:

flutter analyze

If appropriate, run:

flutter test

For Android testing:

flutter run -d emulator-5554

## UI

Create responsive mobile-first interfaces.

Prefer:
- SafeArea
- MediaQuery
- LayoutBuilder
- reusable widgets
- proper spacing
- accessible touch targets
- Material 3 components

Avoid:
- unnecessarily hardcoded dimensions
- giant single-file widgets
- duplicated UI code
- excessive dependencies.

## Code quality

Use meaningful names.

Keep widgets reasonably small.

Separate:
- UI
- models
- services
- state
- utilities

when the project becomes sufficiently complex.