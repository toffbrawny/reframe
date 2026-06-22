# Contributing to Reframe

Thanks for your interest in Reframe — a Flutter Android app that turns your
camera roll into a time capsule: capture a "before" photo, seal it behind a
countdown, and re-shoot the same scene when the lock opens to build a timeline
of change over time.

This document explains how to set up the project, the conventions to follow,
and how to propose changes or report problems.

## Prerequisites

- **Flutter** SDK (the project targets Flutter 3.44.x; see `pubspec.yaml` for
  the exact Dart SDK constraint).
- **Android SDK** with a recent build-tools + platform.
- An **arm64 Android device or emulator** for running the app.

## Getting the code

```bash
git clone <repo-url> reframe
cd reframe
flutter pub get
```

## Running and testing

```bash
flutter run                  # run on a connected device/emulator
flutter analyze              # must be clean before opening a PR
flutter test                 # model/logic unit tests
```

To build an installable APK:

```bash
flutter build apk --release --split-per-abi --target-platform android-arm64
```

The debug build (`flutter build apk --debug ...`) includes extra tools that are
gated behind `kDebugMode` (short lock presets, a fast-forward unlock button);
they are not compiled into release builds.

## Project layout

```
lib/
  models/        Capsule, Frame, Preset, DebugPreset — the data model
  data/          db.dart (sqflite), photo_vault.dart (AES-256-GCM encryption),
                 capsule_repository.dart (SQLite + encrypted files)
  state/         capsule_provider.dart (ChangeNotifier + broadcast clock stream)
  capture/       capture_screen.dart (camerawesome) + alignment_overlay.dart
  screens/       home, new_capsule, capsule_detail, gallery, help_about
  util/          date_format, photo_exporter, delete_capsule_dialog helpers
```

A few things to know before changing things:

- **Photos are encrypted at rest.** All crypto goes through `PhotoVault` —
  keep it as the single swap point. Never write plaintext captured photos to a
  persistent location; exports decrypt to the system temp dir and clean up.
- **The countdown clock** is a broadcast stream shared by the home and detail
  screens. Keep it broadcast so multiple screens can listen.
- **Debug-only features** must stay behind `kDebugMode` so release builds
  never include them.
- **Keep `flutter analyze` clean and `flutter test` green.**

## Commit conventions

- Write clear, imperative commit messages (e.g. "Add tap-to-focus on the
  capture screen").
- Keep commits focused; one logical change per commit.
- Sign commits with your own identity. Do **not** add AI/assistant
  attribution footers (no "Generated with …" / "Co-Authored-By: …" lines) to
  commits, tags, PRs, or release notes.

## Reporting issues

Open an issue on Gitea or GitHub and include:

- What you expected, and what actually happened.
- Steps to reproduce.
- App version (see Help & About in the app), Android version, and device.
- For capture/camera issues, the device model helps a lot.

Known limitations are tracked as issues (for example, the time-lock trusting
the device clock — see the "Known limitation" issue).

## Pull requests

1. Create a branch off `main` for your change.
2. Make sure `flutter analyze` is clean and `flutter test` passes.
3. Open a PR describing what changed and why. If it fixes an issue, reference
   the issue number.
4. Be ready to iterate on review feedback.

## Scope notes

Reframe is intentionally small and focused: camera-only capture, fixed lock
presets, on-device encrypted storage, no cloud, no account. Proposals that fit
that philosophy are much more likely to be accepted.