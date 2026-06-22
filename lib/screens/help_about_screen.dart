/// Help + About screen for Reframe. Reached from the home app bar.
library;

import 'package:flutter/material.dart';

class HelpAboutScreen extends StatelessWidget {
  const HelpAboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Help & About')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _IntroCard(theme: theme),
          const SizedBox(height: 16),
          _SectionCard(
            icon: Icons.timeline,
            title: 'How it works',
            theme: theme,
            body: const [
              '1. Start a capsule with a "before" photo of a scene — a beard, a '
                  'room renovation, a plant, the view from a window.',
              '2. Pick a lock duration (1 week, 1 month, 3 months, or 1 year). '
                  'The photo is sealed behind a countdown.',
              '3. When the lock opens, Reframe reminds you to re-shoot the same '
                  'scene. Each re-shoot becomes an "after" frame.',
              '4. Re-lock for another period and repeat. Over time your capsule '
                  'builds a timeline of the same subject.',
            ],
          ),
          const SizedBox(height: 16),
          _SectionCard(
            icon: Icons.center_focus_strong,
            title: 'Lining up your shots',
            theme: theme,
            body: const [
              'When re-shooting, the previous frame is shown over the live '
                  'camera so you can match the framing by eye.',
              '• Ghost — a translucent overlay of the last photo.',
              '• Outline — a desaturated trace plus a rule-of-thirds grid.',
              '• Off — no overlay.',
              'Adjust the ghost opacity with the slider, and tap the preview to '
                  'focus, pinch to zoom.',
            ],
          ),
          const SizedBox(height: 16),
          _SectionCard(
            icon: Icons.insights,
            title: 'Stats, browsing & export',
            theme: theme,
            body: const [
              'Each capsule shows a stats card: number of photos, first and last '
                  'capture dates, total time span, and the average gap between '
                  're-shots.',
              'Tap any photo on the timeline to view it full-screen. Swipe '
                  'between frames and pinch to zoom.',
              'Use Browse photos to open the gallery grid. Tap Select to pick '
                  'one or more frames and export them via the system share sheet.',
            ],
          ),
          const SizedBox(height: 16),
          _SectionCard(
            icon: Icons.lock,
            title: 'Privacy',
            theme: theme,
            body: const [
              'Every photo is encrypted on your device with AES-256-GCM; the key '
                  'is held in the Android Keystore.',
              'Photos never leave your device unless you explicitly export them. '
                  'There is no cloud sync and no account.',
            ],
          ),
          const SizedBox(height: 16),
          _AboutCard(theme: theme),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard({required this.theme});
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lock_clock, size: 40, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Reframe',
                          style: theme.textTheme.headlineSmall),
                      const Text('Capture a moment. Seal it. Re-shoot it later.',
                          style: TextStyle(color: Colors.white54)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.theme,
    required this.body,
  });

  final IconData icon;
  final String title;
  final ThemeData theme;
  final List<String> body;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(title, style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 10),
            for (final line in body) ...[
              Text(line, style: const TextStyle(height: 1.4)),
              const SizedBox(height: 6),
            ],
          ],
        ),
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard({required this.theme});
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('About', style: theme.textTheme.titleMedium),
            const SizedBox(height: 10),
            const _Row(label: 'App', value: 'Reframe'),
            const _Row(label: 'Version', value: '0.2.0'),
            const _Row(label: 'Built for', value: 'Android'),
            const SizedBox(height: 10),
            const Text(
              'A time capsule for your camera roll. Made by toffbrawny.',
              style: TextStyle(color: Colors.white54, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white60)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}