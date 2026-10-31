# Issue: `announcementsProvider` membuang tipe Failure

## Deskripsi

Di `lib/features/announcements/presentation/providers/announcement_providers.dart` baris 21, `Failure` yang sudah ter-typed dibuang dan diganti `Exception` generik:

```dart
throw Exception(result.failure!.message);
```

## Dampak

- UI (`HomePage`) hanya menerima pesan string dari `Exception`, tidak bisa membedakan jenis error
- Tidak bisa menampilkan aksi berbeda per tipe error (misal: tombol retry untuk `NetworkFailure`)

## Langkah Reproduksi

1. Buka `announcement_providers.dart`
2. Lihat baris 21: `throw Exception(result.failure!.message)`
3. Bandingkan dengan `core/failures.dart` — ada 5 subclass `Failure` yang semuanya diabaikan

## Solusi yang Diharapkan

Ganti menjadi `throw result.failure!` agar tipe asli terbawa ke UI.

## Label

- `bug`
- `good first issue`
