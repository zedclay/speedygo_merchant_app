import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_merchant_app/features/orders/presentation/prep_time_clock.dart';

void main() {
  group('prep_time_clock', () {
    test('parses postgres-style +01 and formats in Africa/Algiers', () {
      final instant = parsePrepInstant('2026-09-25 04:19:45.801+01');
      expect(instant, isNotNull);
      expect(instant!.isUtc, isTrue);
      // Absolute: 03:19:45.801Z → Algiers wall 04:19
      expect(formatPrepClock(instant), '04:19');
    });

    test('parses ISO with Z and formats Algiers consistently', () {
      final instant = parsePrepInstant('2026-09-25T03:19:45.801Z');
      expect(formatPrepClock(instant!), '04:19');
    });

    test('preview +10 keeps same zone for from and to (no UTC hour leak)', () {
      final preview = prepEstimatePreview(
        estimatedReadyAt: '2026-09-25T04:19:45.801+01:00',
        addMinutes: 10,
      );
      expect(preview.from, '04:19');
      expect(preview.to, '04:29');
    });

    test('preview matches reported defect cases', () {
      expect(
        prepEstimatePreview(
          estimatedReadyAt: '2026-09-25 04:19:45.801+01',
          addMinutes: 10,
        ).to,
        '04:29',
      );
      expect(
        prepEstimatePreview(
          estimatedReadyAt: '2026-09-25T04:24:00.000+01:00',
          addMinutes: 10,
        ).to,
        '04:34',
      );
    });

    test('preview arithmetic crosses midnight in branch timezone', () {
      // 23:50 Algiers = 22:50 UTC
      final preview = prepEstimatePreview(
        estimatedReadyAt: '2026-09-25T22:50:00.000Z',
        addMinutes: 20,
      );
      expect(preview.from, '23:50');
      expect(preview.to, '00:10');
    });

    test('current, original, and proposed use identical formatter', () {
      const currentIso = '2026-09-25T04:19:45.801+01:00';
      const originalIso = '2026-09-25T04:19:45.801+01:00';
      final preview = prepEstimatePreview(
        estimatedReadyAt: currentIso,
        addMinutes: 10,
      );
      expect(formatPrepClockIso(currentIso), preview.from);
      expect(formatPrepClockIso(originalIso), '04:19');
      expect(preview.to, '04:29');
    });

    test('does not invent wall time from device toLocal alone', () {
      // Instant fixed; formatter must ignore ambient device zone by using
      // explicit branch offset (Africa/Algiers).
      final instant = DateTime.utc(2026, 9, 25, 3, 19, 45);
      expect(
        formatPrepClock(instant, branchUtcOffset: kMerchantBranchUtcOffset),
        '04:19',
      );
      expect(
        formatPrepClock(instant, branchUtcOffset: Duration.zero),
        '03:19',
      );
    });
  });
}
