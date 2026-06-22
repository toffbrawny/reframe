import 'package:flutter_test/flutter_test.dart';
import 'package:reframe/models/capsule.dart';

void main() {
  group('Preset', () {
    test('durations match labels', () {
      expect(Preset.week.duration, const Duration(days: 7));
      expect(Preset.month.duration, const Duration(days: 30));
      expect(Preset.quarter.duration, const Duration(days: 90));
      expect(Preset.year.duration, const Duration(days: 365));
    });
  });

  group('Capsule status', () {
    final created = DateTime(2026, 1, 1);
    final before = Frame(
      capsuleId: 1,
      kind: 'before',
      fileName: '1_before_1.enc',
      capturedAt: created,
    );

    test('locked while countdown runs', () {
      final c = Capsule(
        id: 1,
        title: 't',
        createdAt: created,
        unlockAt: created.add(const Duration(days: 7)),
        frames: [before],
      );
      expect(c.statusAt(created.add(const Duration(days: 1))),
          CapsuleStatus.locked);
      expect(c.remainingAt(created.add(const Duration(days: 1)))!.inDays, 6);
    });

    test('ready to capture when unlockAt passes', () {
      final c = Capsule(
        id: 1,
        title: 't',
        createdAt: created,
        unlockAt: created.add(const Duration(days: 7)),
        frames: [before],
      );
      expect(c.statusAt(created.add(const Duration(days: 8))),
          CapsuleStatus.readyToCapture);
    });

    test('awaiting relock after an after-shot with no unlockAt', () {
      final c = Capsule(
        id: 1,
        title: 't',
        createdAt: created,
        unlockAt: null,
        frames: [
          before,
          Frame(
              capsuleId: 1,
              kind: 'after',
              fileName: '1_after_2.enc',
              capturedAt: created.add(const Duration(days: 7))),
        ],
      );
      expect(c.statusAt(created.add(const Duration(days: 8))),
          CapsuleStatus.awaitingRelock);
    });

    test('reference frame is the most recent', () {
      final c = Capsule(
        id: 1,
        title: 't',
        createdAt: created,
        unlockAt: null,
        frames: [
          before,
          Frame(
              capsuleId: 1,
              kind: 'after',
              fileName: '1_after_2.enc',
              capturedAt: created.add(const Duration(days: 7))),
          Frame(
              capsuleId: 1,
              kind: 'after',
              fileName: '1_after_3.enc',
              capturedAt: created.add(const Duration(days: 14))),
        ],
      );
      expect(c.referenceFrame!.capturedAt,
          created.add(const Duration(days: 14)));
    });

    test('finalized status once sealed', () {
      final c = Capsule(
        id: 1,
        title: 't',
        createdAt: created,
        unlockAt: null,
        finalized: true,
        frames: [before],
      );
      expect(c.statusAt(created.add(const Duration(days: 100))),
          CapsuleStatus.finalized);
    });
  });
}