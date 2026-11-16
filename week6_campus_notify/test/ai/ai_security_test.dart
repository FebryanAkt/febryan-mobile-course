import 'package:flutter_test/flutter_test.dart';
import 'package:week6_campus_notify/ai/ai_security_guard.dart';

void main() {
  group('AiSecurityGuard Unit Tests', () {
    test('Teks biasa tanpa data sensitif tidak diubah', () {
      const input = 'Kapan batas akhir pengisian KRS semester genap?';
      final result = AiSecurityGuard.sanitize(input);

      expect(result.containsSensitiveData, isFalse);
      expect(result.sanitizedText, equals(input));
      expect(result.detectedTypes, isEmpty);
    });

    test('Menyaring dan menganonimkan NIK (16 digit angka)', () {
      const input =
          'Halo tolong cek status mahasiswa dengan NIK 3578012345670001 apakah aktif?';
      final result = AiSecurityGuard.sanitize(input);

      expect(result.containsSensitiveData, isTrue);
      expect(result.detectedTypes, contains('NIK'));
      expect(result.sanitizedText, contains('[NIK_ANONIM_0001]'));
      expect(result.sanitizedText.contains('3578012345670001'), isFalse);
    });

    test('Menyaring dan menganonimkan nomor telepon Indonesia (+62/08)', () {
      const input =
          'Hubungi saya di nomor 08123456789 atau +628987654321 jika berkas siap.';
      final result = AiSecurityGuard.sanitize(input);

      expect(result.containsSensitiveData, isTrue);
      expect(result.detectedTypes, contains('Nomor Telepon'));
      expect(result.sanitizedText, contains('[NO_TELP_ANONIM]'));
      expect(result.sanitizedText.contains('08123456789'), isFalse);
      expect(result.sanitizedText.contains('+628987654321'), isFalse);
    });

    test('Menyaring dan menganonimkan alamat email pribadi', () {
      const input =
          'Kirimkan silabus perkuliahan ke mhs.pribadi@gmail.com terima kasih.';
      final result = AiSecurityGuard.sanitize(input);

      expect(result.containsSensitiveData, isTrue);
      expect(result.detectedTypes, contains('Email'));
      expect(result.sanitizedText, contains('[EMAIL_ANONIM]'));
      expect(result.sanitizedText.contains('mhs.pribadi@gmail.com'), isFalse);
    });

    test('Menyaring dan menganonimkan detail alamat fisik', () {
      const input =
          'Saya tinggal di Jl. Sudirman No. 45 RT 02 / RW 05 dekat kampus.';
      final result = AiSecurityGuard.sanitize(input);

      expect(result.containsSensitiveData, isTrue);
      expect(result.detectedTypes, contains('Alamat'));
      expect(result.sanitizedText.contains('Jl. Sudirman'), isFalse);
    });

    test('Menyaring kombinasi beberapa data sensitif sekaligus', () {
      const input =
          'Data saya: NIK 3201019908880002, No Telp 085712349999, Jl. Merdeka No 10.';
      final result = AiSecurityGuard.sanitize(input);

      expect(result.containsSensitiveData, isTrue);
      expect(result.detectedTypes.length, greaterThanOrEqualTo(2));
      expect(result.sanitizedText, contains('[NIK_ANONIM_0002]'));
      expect(result.sanitizedText, contains('[NO_TELP_ANONIM]'));
      expect(result.sanitizedText.contains('3201019908880002'), isFalse);
      expect(result.sanitizedText.contains('085712349999'), isFalse);
    });

    test('hasSensitiveData mendeteksi data sensitif secara akurat', () {
      expect(AiSecurityGuard.hasSensitiveData('Apa kabar?'), isFalse);
      expect(
        AiSecurityGuard.hasSensitiveData('NIK saya 1234567890123456'),
        isTrue,
      );
      expect(AiSecurityGuard.hasSensitiveData('WA ke 08123456789'), isTrue);
    });
  });
}
