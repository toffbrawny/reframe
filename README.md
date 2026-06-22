<div align="center">

# ⏳ Reframe

### Your Time Capsule for Change.

**Capture today. Reflect tomorrow. Grow forever.**

![Flutter](https://img.shields.io/badge/Flutter-3.44-02569B?logo=flutter&logoColor=white)
![Android](https://img.shields.io/badge/Platform-Android-3DDC84?logo=android&logoColor=white)
![Version](https://img.shields.io/badge/version-0.2.1-blue)
![Storage](https://img.shields.io/badge/storage-AES--256--GCM-9b59b6)
![Cloud](https://img.shields.io/badge/cloud-none-success)

<br/>

<img src="App%20Screenshots/Promo%201.png" width="720" alt="Reframe — Your Time Capsule for Change" />

</div>

---

Reframe turns your phone into a **time machine for the everyday.**

Snap a *before* photo of anything — a sapling you just planted, a clean-shaven
face, an empty room you're about to renovate, the view from your window — then
**seal it behind a countdown you can't talk your way out of.** When the lock
opens, Reframe nudges you to re-shoot the exact same scene. Do it again. And
again. Months later you've built a living timeline of change you'd otherwise
have completely forgotten.

No cloud. No account. No one watching. Just you, your camera, and the slow,
quiet magic of time passing.

---

## ✨ Why you'll love it

- **⏲️ A lock you can't cheat (well, almost)** — pick 1 week, 1 month, 3 months,
  or 1 year. The before photo is genuinely sealed until the countdown ends, so
  the moment arrives when it arrives.
- **🎯 Frame-perfect re-shoots** — line up every shot with a translucent *ghost*
  overlay of the previous frame, or a desaturated *outline* + rule-of-thirds
  grid. Same angle, months apart.
- **🖼️ A gallery, not a graveyard** — browse every frame full-screen, swipe
  through the timeline, pinch to zoom, and export one photo or a whole batch to
  the share sheet in two taps.
- **📊 Smart stats per capsule** — photo count, first and last capture dates,
  total time span, and the average gap between re-shoots. Watch the journey add
  up.
- **🔒 Private by design** — every photo is encrypted on your device with
  AES-256-GCM; the key lives in the Android Keystore. Nothing leaves your phone
  unless you choose to share it.

<div align="center">

<br/>
<img src="App%20Screenshots/Promo%205.png" width="720" alt="How it works — Capture life. Lock time. Reframe forever." />

</div>

---

## 🪴 See the change

A single before/after is nice. A **timeline** is a story. Here's the kind of
transformation Reframe is built to capture:

<div align="center">

| 🪴 A plant grows | 🧔 A beard fills in | 🪟 The seasons turn |
| :---: | :---: | :---: |
| <img src="App%20Screenshots/Promo%206.png" width="260" alt="Before and after of a potted plant growing"/> | <img src="App%20Screenshots/Promo%207.png" width="260" alt="Before and after of a man growing a beard"/> | <img src="App%20Screenshots/Promo%208.png" width="260" alt="The same view from a window in summer and winter"/> |

</div>

Track a garden. Track yourself. Track a renovation, a skyline, a sunrise, a
kid getting taller. If it changes, Reframe will remember it.

---

## 🛠️ How it works

1. **Capture a "before"** — open a new capsule and shoot your starting frame
   with the live camera (tap to focus, pinch to zoom, flash, flip to selfie).
2. **Pick a lock** — 1 week · 1 month · 3 months · 1 year. Name it. Seal it.
3. **Wait** — the countdown runs. Your card shows a blurred thumbnail and the
   time remaining.
4. **Re-shoot when it opens** — Reframe overlays the last frame so your new shot
   lines up perfectly. Capture your first *after*.
5. **Re-lock or finalize** — keep the timeline going for another period, or seal
   it for good.
6. **Browse, view, and export** — open the gallery, swipe through the whole
   timeline, and share one photo or a batch.

<div align="center">

<br/>
<img src="App%20Screenshots/Promo%203.png" width="720" alt="Capture & lock your moments — private, secure, yours forever." />

</div>

---

## 📊 Beautiful timeline. Smart insights.

Every capsule adds up. Reframe keeps track of how far you've come so you don't
have to.

<div align="center">

<br/>
<img src="App%20Screenshots/Promo%202.png" width="720" alt="Track progress over time — beautiful timeline, smart insights." />

</div>

---

## 🔒 Private by design

Your photos. Your device. Your privacy. Reframe has no servers, no accounts,
and no analytics phoning home. Every frame is encrypted at rest with
AES-256-GCM and the key is held in the Android Keystore — so even if someone
gets the file, they get ciphertext.

<div align="center">

<br/>
<img src="App%20Screenshots/Promo%204.png" width="720" alt="Private by design — your photos, your device, your privacy." />

</div>

---

## 📥 Get Reframe

Install the latest stable build on an arm64 Android phone:

- **Gitea** — [Reframe v0.2.1 (arm64 APK)](https://git.toffbrawny.com/toffbrawny/reframe/releases/download/v0.2.1/Reframe-v0.2.1-arm64.apk)
- **GitHub** — [Reframe v0.2.1 (arm64 APK)](https://github.com/toffbrawny/reframe/releases/download/v0.2.1/Reframe-v0.2.1-arm64.apk)

Sideload the APK (allow installs from your browser/file manager). Reframe uses
a single signing key across releases, so installing a new version upgrades the
app in place and keeps all your capsules.

> ⚠️ Reframe is signed with the Android debug keystore (a personal project, no
> Play Store listing). Your phone may warn about the unknown source — that's
> expected.

---

## 🤝 Contribute

Reframe is a small, focused, offline-first project and contributions are
welcome. See **[CONTRIBUTING.md](CONTRIBUTING.md)** for setup, project layout,
conventions, and how to open issues and pull requests.

Known limitations are tracked as issues — the big one being that the time-lock
relies on the device clock, so rolling the clock forward can unlock early. It's
a v1 trade-off for staying fully offline; clock-tamper resistance is future
work. Read it and chip in:
[Gitea #1](https://git.toffbrawny.com/toffbrawny/reframe/issues/1) ·
[GitHub #1](https://github.com/toffbrawny/reframe/issues/1).

---

## 🧱 Built with

Flutter · `provider` · `sqflite` · `camerawesome` (native CameraX) ·
`cryptography` (AES-256-GCM) · `flutter_secure_storage` (Android Keystore) ·
`share_plus` · `package_info_plus`. Android-only (minSdk 23), arm64.

---

<div align="center">

**Capture today. Reflect tomorrow. Grow forever.**

Made with care by **toffbrawny**.

</div>