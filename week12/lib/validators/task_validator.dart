/// Logika Validasi Judul dan Deskripsi Tugas (Domain Validator Murni)
class TaskValidator {
  static const int minTitleLength = 3;
  static const int maxTitleLength = 60;
  static const int maxDescriptionLength = 200;

  /// Memeriksa apakah judul tugas valid setelah spasi diabaikan
  static bool isValidTaskTitle(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return false;
    if (trimmed.length < minTitleLength) return false;
    if (trimmed.length > maxTitleLength) return false;
    return true;
  }

  /// Menghasilkan pesan error validasi yang ramah pengguna
  static String? validateTaskTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Judul tugas tidak boleh kosong';
    }
    final trimmed = value.trim();
    if (trimmed.length < minTitleLength) {
      return 'Judul tugas minimal $minTitleLength karakter';
    }
    if (trimmed.length > maxTitleLength) {
      return 'Judul tugas maksimal $maxTitleLength karakter';
    }
    return null;
  }

  /// Validasi deskripsi opsional (maksimal 200 karakter)
  static String? validateDescription(String? value) {
    if (value == null || value.isEmpty) return null;
    if (value.trim().length > maxDescriptionLength) {
      return 'Deskripsi maksimal $maxDescriptionLength karakter';
    }
    return null;
  }
}
