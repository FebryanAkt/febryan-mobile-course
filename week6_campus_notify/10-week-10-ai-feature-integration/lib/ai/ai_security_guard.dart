/// Helper keamanan untuk memastikan data pribadi dan sensitif mahasiswa/pengguna
/// TIDAK pernah dikirim ke AI API pihak ketiga (sesuai Catatan Keamanan Praktikum).
///
/// Data yang disanitasi:
/// - NIK (16 digit angka)
/// - Nomor Telepon / HP (format Indonesia: 08xx, +62xx, 62xx)
/// - Alamat fisik / detail lokasi sensitif (Jl., RT/RW, dsb.)
/// - Alamat Email pribadi
class AiSecurityGuard {
  // Regex untuk NIK (16 digit angka berturut-turut)
  static final RegExp _nikRegex = RegExp(r'\b\d{16}\b');

  // Regex untuk nomor telepon Indonesia (+62 / 62 / 08...)
  static final RegExp _phoneRegex =
      RegExp(r'(\+62|62|08)[0-9]{8,11}\b');

  // Regex untuk email pribadi
  static final RegExp _emailRegex =
      RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b');

  // Regex untuk deteksi alamat sensitif (Jl./Jalan/RT/RW/Komplek)
  static final RegExp _addressRegex = RegExp(
    r'(?:(?:jl\.|jalan|kompleks?|perum(?:ahan)?|blok|gang|gg\.)\s+[a-zA-Z0-9\s.,]+(?:no\.?\s*\d+)?|rt\s*\d+\s*/\s*rw\s*\d+)',
    caseSensitive: false,
  );

  /// Memeriksa apakah teks mengandung data sensitif
  static bool hasSensitiveData(String text) {
    return _nikRegex.hasMatch(text) ||
        _phoneRegex.hasMatch(text) ||
        _emailRegex.hasMatch(text) ||
        _addressRegex.hasMatch(text);
  }

  /// Melakukan sanitasi/anonimisasi teks sebelum dikirim ke AI API.
  /// Menghasilkan [SanitizationResult] yang berisi teks bersih dan daftar data yang terdeteksi.
  static SanitizationResult sanitize(String text) {
    String sanitized = text;
    final List<String> detectedTypes = [];

    if (_nikRegex.hasMatch(sanitized)) {
      detectedTypes.add('NIK');
      sanitized = sanitized.replaceAllMapped(_nikRegex, (match) {
        final nik = match.group(0)!;
        return '[NIK_ANONIM_${nik.substring(nik.length - 4)}]';
      });
    }

    if (_phoneRegex.hasMatch(sanitized)) {
      detectedTypes.add('Nomor Telepon');
      sanitized = sanitized.replaceAllMapped(_phoneRegex, (match) {
        return '[NO_TELP_ANONIM]';
      });
    }

    if (_emailRegex.hasMatch(sanitized)) {
      detectedTypes.add('Email');
      sanitized = sanitized.replaceAllMapped(_emailRegex, (match) {
        return '[EMAIL_ANONIM]';
      });
    }

    if (_addressRegex.hasMatch(sanitized)) {
      detectedTypes.add('Alamat');
      sanitized = sanitized.replaceAllMapped(_addressRegex, (match) {
        return '[ALAMAT_ANONIM]';
      });
    }

    return SanitizationResult(
      originalText: text,
      sanitizedText: sanitized,
      detectedTypes: detectedTypes,
    );
  }
}

class SanitizationResult {
  final String originalText;
  final String sanitizedText;
  final List<String> detectedTypes;

  const SanitizationResult({
    required this.originalText,
    required this.sanitizedText,
    required this.detectedTypes,
  });

  bool get containsSensitiveData => detectedTypes.isNotEmpty;
}
