## Masalah

`announcementsProvider` membuang tipe `Failure` yang sudah ter-typed (`LocalFailure`, `NetworkFailure`, dll.) dan melempar `Exception` generik:

```dart
throw Exception(result.failure!.message); // tipe Failure hilang
```

UI tidak bisa membedakan jenis error (misal: network error → tampilkan tombol retry vs local error → tampilkan pesan berbeda).

Temuan ini berasal dari **AI Code Review Temuan #2** (lihat `docs/ai-review-vs-keputusan.md`).

## Solusi

Ganti `throw Exception(result.failure!.message)` menjadi `throw result.failure!` agar tipe `Failure` tetap terbawa ke presentation layer.

```dart
// Sebelum
throw Exception(result.failure!.message);

// Sesudah
throw result.failure!; // Pertahankan tipe Failure agar UI bisa pattern-match
```

Perubahan hanya **1 baris** di `lib/features/announcements/presentation/providers/announcement_providers.dart`.

## Cara Uji

```bash
# 1. Static analysis — pastikan tidak ada warning baru
flutter analyze
# Expected: No issues found!

# 2. Jalankan semua test — pastikan tidak ada regresi
flutter test
# Expected: +25: All tests passed!
```

## Hasil Mesin Hijau

```
> flutter analyze
Analyzing week6_campus_notify...
No issues found! (ran in 10.2s)

> flutter test
00:01 +25: All tests passed!
```

## Screenshot

Tidak ada perubahan UI — perbaikan ini di layer provider/logic saja.

## Checklist

- [x] Tidak menambah dependency baru
- [x] `flutter analyze` bersih
- [x] `flutter test` hijau (25/25)
- [x] Tidak melanggar dependency rule (domain tetap bersih)
- [x] Perubahan kecil dan terfokus (1 baris)
