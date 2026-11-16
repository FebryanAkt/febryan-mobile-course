import 'package:flutter_test/flutter_test.dart';
import 'package:week6_campus_notify/ai/local_campus_kb.dart';

void main() {
  group('LocalCampusKnowledgeBase Unit Tests (Offline Fallback)', () {
    test('Mencocokkan kata kunci KRS dan mengembalikan jadwal KRS', () {
      final result = LocalCampusKnowledgeBase.findAnswer('Kapan jadwal pengisian krs online?');

      expect(result, isNotNull);
      expect(result!.topic, 'KRS & Akademik');
      expect(result.answer, contains('Jadwal Pengisian KRS'));
      expect(result.answer, contains('SIAKAD'));
    });

    test('Mencocokkan kata kunci Beasiswa dan mengembalikan info beasiswa', () {
      final result = LocalCampusKnowledgeBase.findAnswer('Syarat beasiswa prestasi dan kip kuliah apa saja?');

      expect(result, isNotNull);
      expect(result!.topic, 'Beasiswa Kampus');
      expect(result.answer, contains('Beasiswa Prestasi'));
      expect(result.answer, contains('KIP Kuliah'));
    });

    test('Mencocokkan kata kunci Skripsi dan mengembalikan syarat sidang', () {
      final result = LocalCampusKnowledgeBase.findAnswer('Berapa syarat skripsi dan turnitin?');

      expect(result, isNotNull);
      expect(result!.topic, 'Skripsi & Tugas Akhir');
      expect(result.answer, contains('Turnitin'));
    });

    test('Mencocokkan kata kunci UKT dan pengajuan cicilan', () {
      final result = LocalCampusKnowledgeBase.findAnswer('Cara pembayaran ukt va bank?');

      expect(result, isNotNull);
      expect(result!.topic, 'Pembayaran UKT & Keuangan');
      expect(result.answer, contains('Virtual Account'));
    });

    test('Pertanyaan yang tidak cocok mengembalikan null dan fallback umum', () {
      final result = LocalCampusKnowledgeBase.findAnswer('Siapa pemenang piala dunia 2022?');
      expect(result, isNull);

      final fallback = LocalCampusKnowledgeBase.getGeneralOfflineFallback();
      expect(fallback, contains('Mode Offline Kampus Aktif'));
      expect(fallback, contains('helpdesk@campus.ac.id'));
    });
  });
}
