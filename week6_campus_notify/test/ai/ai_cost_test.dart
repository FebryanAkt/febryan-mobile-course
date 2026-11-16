import 'package:flutter_test/flutter_test.dart';
import 'package:week6_campus_notify/ai/ai_cost_controller.dart';
import 'ai_service_test.dart';

void main() {
  group('AiResponseCache Unit Tests', () {
    test('Menyimpan dan mengembalikan respons yang di-cache berdasarkan query yang dinormalisasi', () {
      final cache = AiResponseCache();

      cache.put('Jadwal KRS semester genap?', 'Jadwal KRS tanggal 10 Februari.');

      // Query identik
      expect(cache.get('Jadwal KRS semester genap?'), 'Jadwal KRS tanggal 10 Februari.');
      // Query dengan perbedaan huruf besar-kecil dan spasi
      expect(cache.get('jadwal krs semester genap'), 'Jadwal KRS tanggal 10 Februari.');
      expect(cache.cacheHits, 2);
    });

    test('Query yang belum di-cache mengembalikan null', () {
      final cache = AiResponseCache();
      expect(cache.get('Berapa biaya UKT?'), isNull);
      expect(cache.cacheHits, 0);
    });

    test('clear() mengosongkan seluruh cache dan hit counter', () {
      final cache = AiResponseCache();
      cache.put('A', 'Respon A');
      expect(cache.size, 1);

      cache.clear();
      expect(cache.size, 0);
      expect(cache.get('A'), isNull);
    });
  });

  group('AiUsageTracker Unit Tests (Rate Limiting)', () {
    late FakeSecureStorage fakeStorage;

    setUp(() {
      fakeStorage = FakeSecureStorage();
    });

    test('Penggunaan awal bernilai 0 dan dapat melakukan request', () async {
      final tracker = AiUsageTracker(storage: fakeStorage, dailyLimit: 5);

      expect(await tracker.getTodayUsage(), 0);
      expect(await tracker.canMakeRequest(), isTrue);
      expect(await tracker.getRemainingQuota(), 5);
    });

    test('incrementUsage menambah jumlah pemakaian dan mengurangi sisa kuota', () async {
      final tracker = AiUsageTracker(storage: fakeStorage, dailyLimit: 3);

      await tracker.incrementUsage();
      expect(await tracker.getTodayUsage(), 1);
      expect(await tracker.getRemainingQuota(), 2);
      expect(await tracker.canMakeRequest(), isTrue);

      await tracker.incrementUsage();
      await tracker.incrementUsage();
      expect(await tracker.getTodayUsage(), 3);
      expect(await tracker.getRemainingQuota(), 0);
      expect(await tracker.canMakeRequest(), isFalse);
    });

    test('resetUsage mengembalikan kuota ke nilai penuh', () async {
      final tracker = AiUsageTracker(storage: fakeStorage, dailyLimit: 5);
      await tracker.incrementUsage();
      await tracker.incrementUsage();
      expect(await tracker.getTodayUsage(), 2);

      await tracker.resetUsage();
      expect(await tracker.getTodayUsage(), 0);
      expect(await tracker.getRemainingQuota(), 5);
    });
  });
}
