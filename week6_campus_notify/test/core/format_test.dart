import 'package:flutter_test/flutter_test.dart';
import 'package:week6_campus_notify/core/format.dart';

void main() {
  group('AppFormatters.parseRoute', () {
    test('normalizes missing leading slash', () {
      expect(
        AppFormatters.parseRoute({'route': 'pengumuman/3'}),
        '/pengumuman/3',
      );
    });

    test('preserves existing leading slash', () {
      expect(
        AppFormatters.parseRoute({'route': '/pengumuman/3'}),
        '/pengumuman/3',
      );
    });

    test('falls back to / on empty or missing route', () {
      expect(AppFormatters.parseRoute({}), '/');
      expect(AppFormatters.parseRoute({'route': ''}), '/');
    });
  });

  group('AppFormatters.extractId', () {
    test('extracts direct id key when present', () {
      expect(
        AppFormatters.extractId({'id': '42', 'route': '/pengumuman/1'}),
        '42',
      );
    });

    test('extracts last path segment when id is missing', () {
      expect(AppFormatters.extractId({'route': '/pengumuman/7'}), '7');
    });
  });

  group('AppFormatters.formatRelativeTime', () {
    final now = DateTime(2026, 10, 11, 14, 0, 0);

    test('returns "Baru saja" for seconds difference', () {
      final dt = now.subtract(const Duration(seconds: 30));
      expect(AppFormatters.formatRelativeTime(dt, now: now), 'Baru saja');
    });

    test('returns minutes ago', () {
      final dt = now.subtract(const Duration(minutes: 15));
      expect(AppFormatters.formatRelativeTime(dt, now: now), '15 menit lalu');
    });

    test('returns hours ago', () {
      final dt = now.subtract(const Duration(hours: 3));
      expect(AppFormatters.formatRelativeTime(dt, now: now), '3 jam lalu');
    });

    test('returns "Kemarin" for 1 day diff', () {
      final dt = now.subtract(const Duration(days: 1));
      expect(AppFormatters.formatRelativeTime(dt, now: now), 'Kemarin');
    });

    test('returns days ago for < 7 days', () {
      final dt = now.subtract(const Duration(days: 4));
      expect(AppFormatters.formatRelativeTime(dt, now: now), '4 hari lalu');
    });
  });
}
