/// Model item FAQ lokal kampus untuk mode offline dan mekanisme fallback
class LocalFaqItem {
  final String topic;
  final List<String> keywords;
  final String question;
  final String answer;

  const LocalFaqItem({
    required this.topic,
    required this.keywords,
    required this.question,
    required this.answer,
  });
}

/// Hasil pencarian pada basis pengetahuan lokal kampus
class LocalKnowledgeResult {
  final String answer;
  final String topic;
  final bool isExactMatch;
  final double confidenceScore;

  const LocalKnowledgeResult({
    required this.answer,
    required this.topic,
    required this.isExactMatch,
    required this.confidenceScore,
  });
}

/// Basis Pengetahuan Kampus Lokal (Offline Knowledge Base)
/// Digunakan sebagai:
/// 1. Fallback otomatis saat API AI error/down/kuota habis.
/// 2. Mode Offline mandiri saat mahasiswa tidak memiliki akses internet.
/// 3. Validasi saat respons AI dinilai tidak relevan.
class LocalCampusKnowledgeBase {
  static const List<LocalFaqItem> _knowledgeItems = [
    LocalFaqItem(
      topic: 'KRS & Akademik',
      keywords: ['krs', 'kartu rencana studi', 'jadwal krs', 'pengisian krs', 'sks'],
      question: 'Kapan jadwal dan prosedur pengisian KRS?',
      answer:
          '📅 **Jadwal Pengisian KRS:**\n'
          '• Periode KRS Semester Genap dibuka mulai 10 - 20 Februari.\n'
          '• Pengisian dilakukan melalui portal Sistem Informasi Akademik (SIAKAD).\n'
          '• Mahasiswa wajib melakukan konsultasi dengan Dosen Pembimbing Akademik (DPA) sebelum melakukan finalisasi KRS.\n'
          '• Maksimum pengambilan SKS didasarkan pada Indeks Prestasi (IP) semester sebelumnya.',
    ),
    LocalFaqItem(
      topic: 'Beasiswa Kampus',
      keywords: ['beasiswa', 'kip-k', 'kip kuliah', 'beasiswa prestasi', 'bantuan ukt', 'syarat beasiswa'],
      question: 'Apa saja syarat dan jadwal pendaftaran beasiswa kampus?',
      answer:
          '🎓 **Informasi Beasiswa Kampus:**\n'
          '• **Beasiswa Prestasi:** Minimal IPK 3.50, sertifikat lomba minimal tingkat regional/nasional, surat rekomendasi DPA.\n'
          '• **KIP Kuliah:** Terdaftar di DTKS Kemensos, slip penghasilan orang tua < Rp 4.000.000/bulan.\n'
          '• Pendaftaran dibuka tiap awal semester melalui Bagian Kemahasiswaan Gedung Rektorat Lt. 2.',
    ),
    LocalFaqItem(
      topic: 'Skripsi & Tugas Akhir',
      keywords: ['skripsi', 'tugas akhir', 'sidang', 'sempro', 'seminar proposal', 'yudisium'],
      question: 'Bagaimana alur dan syarat pendaftaran sidang skripsi?',
      answer:
          '📚 **Alur Sidang Skripsi & Tugas Akhir:**\n'
          '1. Telah menyelesaikan minimal 138 SKS tanpa nilai E.\n'
          '2. Lolos uji plagiarisme (Turnitin) maksimal similarity 20%.\n'
          '3. Mendapat persetujuan dosen pembimbing 1 dan 2.\n'
          '4. Mendaftar berkas sidang di loket Tata Usaha jurusan selambatnya 2 minggu sebelum periode yudisium.',
    ),
    LocalFaqItem(
      topic: 'Pembayaran UKT & Keuangan',
      keywords: ['ukt', 'spp', 'pembayaran', 'biaya kuliah', 'cicilan', 'keringanan ukt', 'va'],
      question: 'Bagaimana cara pembayaran UKT dan pengajuan cicilan?',
      answer:
          '💳 **Informasi Pembayaran UKT:**\n'
          '• Pembayaran dilakukan melalui nomor Virtual Account (VA) Bank Mitra (BNI, BRI, Mandiri).\n'
          '• Batas akhir pembayaran adalah 1 minggu sebelum jadwal KRS dimulai.\n'
          '• Pengajuan permohonan cicilan atau penurunan UKT diajukan ke Bagian Keuangan dengan melampirkan berkas slip gaji dan keterangan RT/RW.',
    ),
    LocalFaqItem(
      topic: 'Layanan & Fasilitas Kampus',
      keywords: ['perpustakaan', 'tu', 'tata usaha', 'wifi', 'poliklinik', 'gedung', 'legalisir'],
      question: 'Dimana lokasi TU dan jam operasional layanan kampus?',
      answer:
          '🏛️ **Layanan Kampus & Lokasi:**\n'
          '• **Tata Usaha (TU):** Gedung Jurusan Lantai 1 (Senin-Jumat, 08.00 - 15.30 WIB).\n'
          '• **Perpustakaan Pusat:** Gedung Graha Literasi (08.00 - 18.00 WIB).\n'
          '• **Poliklinik Kampus:** Gedung Student Center Lantai 1 (Layanan kesehatan gratis mahasiswa).\n'
          '• **Akses WiFi:** Login menggunakan akun email institusi @student.campus.ac.id.',
    ),
  ];

  /// Mencari jawaban dari basis pengetahuan lokal berdasarkan kecocokan kata kunci
  static LocalKnowledgeResult? findAnswer(String query) {
    final normalized = query.toLowerCase().trim();
    if (normalized.isEmpty) return null;

    LocalFaqItem? bestItem;
    int maxHits = 0;

    for (final item in _knowledgeItems) {
      int hits = 0;
      for (final kw in item.keywords) {
        if (normalized.contains(kw)) {
          hits += kw.contains(' ') ? 3 : 1; // Beri bobot lebih untuk frase多 kata
        }
      }
      if (hits > maxHits) {
        maxHits = hits;
        bestItem = item;
      }
    }

    if (bestItem != null && maxHits > 0) {
      return LocalKnowledgeResult(
        answer: bestItem.answer,
        topic: bestItem.topic,
        isExactMatch: maxHits >= 2,
        confidenceScore: (maxHits / 5).clamp(0.2, 1.0),
      );
    }

    return null;
  }

  /// Menghasilkan pesan fallback default jika query tidak ditemukan di basis pengetahuan
  static String getGeneralOfflineFallback() {
    return '📱 **Mode Offline Kampus Aktif:**\n\n'
        'Layanan AI eksternal sedang tidak dapat dijangkau. Berikut topik informasi yang tersedia di penyimpanan offline:\n'
        '• 📅 Jadwal dan pengisian KRS\n'
        '• 🎓 Informasi dan syarat beasiswa\n'
        '• 📚 Prosedur pendaftaran sidang skripsi\n'
        '• 💳 Pembayaran UKT & cicilan\n'
        '• 🏛️ Jam operasional TU & fasilitas kampus\n\n'
        'Silakan ketik pertanyaan seputar topik di atas atau hubungi Helpdesk Kampus: **helpdesk@campus.ac.id**';
  }
}
