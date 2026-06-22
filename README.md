# Reframe

A "before & after" photo **time capsule** for Android. Capture a "before" photo,
seal it behind a countdown you can't bypass, then re-shoot the *same* scene when
the timer opens. Each re-lock adds another shot to a living timeline you export
as a GIF — a face aging, a garden growing, a renovation progressing.

## Why it's different

- **Forced wait** — the before photo is genuinely sealed until the countdown ends.
- **Alignment aids** — re-shoots show the previous frame as a guide (translucent
  "ghost" overlay, or a desaturated trace + rule-of-thirds grid) so your shots
  line up over months.
- **Living timeline** — one capsule = one before + many afters over successive
  unlocks. Not a single before/after pair.
- **Shareable output** — export the whole timeline as an animated GIF.
- **Private** — photos are encrypted at rest (AES-256-GCM, key in Android
  Keystore via `flutter_secure_storage`). Nothing leaves the device except when
  you explicitly share.

## Capture model

1. **New capsule** → take a "before" photo (live camera) → name it + pick a lock
   preset (1 week / 1 month / 3 months / 1 year).
2. Countdown runs. The card shows a blurred thumbnail + time remaining.
3. `unlockAt` passes → status flips to **ready to capture**.
4. Open the camera with the previous frame as an alignment guide; capture an
   **after** photo.
5. Choose: **re-lock** for another period (pick a preset) or **finalize** the
   timeline.
6. Anytime: export a GIF of `[before, after₁, after₂, …]`.

> Known limitation: the lock relies on the device clock, so rolling the clock
> forward can unlock early. v1 trade-off; clock-tamper resistance is future work.

## Build

```bash
flutter build apk --release --split-per-abi --target-platform android-arm64
```

The release build is signed with the Android debug keystore (`~/.android/debug.keystore`).
Signed, named artifact: `Reframe-v0.1.0-arm64.apk`.

## Tech

Flutter 3.44 · `provider` + `sqflite` · `camera` · `cryptography` (AES-GCM) ·
`image` (GIF encode) · `share_plus`. Android-only (minSdk 23).