# AI Verification Checklist — Comment Repository Layer

## Prompt yang Digunakan

> Buatkan repository layer Flutter untuk endpoint GET /comments?postId={id}
> dari JSONPlaceholder menggunakan Dio + flutter_riverpod.
> Requirements:
> - Model Comment dengan fromJson aman null (postId, id, name, email, body).
> - CommentRepository dengan method fetchComments(postId) + timeout 10 detik.
> - AsyncNotifierProvider dengan penanganan error otomatis (AsyncError) dan fungsi pesan error ramah pengguna untuk timeout, connection error, 404, dan 500.
> - Satu unit test untuk fromJson dengan field yang hilang.

---

## Checklist Verifikasi

### 1. Apakah UI memanggil Dio secara langsung?
- ✅ **TIDAK.** UI hanya membaca `commentListProvider` (AsyncNotifierProvider).
- Provider memanggil `CommentRepository`, dan repository yang memanggil Dio.
- Alur: `UI → Provider → Repository → Dio → API`
- File: `lib/data/comment_providers.dart` (baris 18, 34-43)

### 2. Apakah fromJson aman null?
- ✅ **YA.** Semua field menggunakan defensive cast:
  - `(json['postId'] as num?)?.toInt() ?? 0` untuk integer
  - `json['name'] as String? ?? ''` untuk string
- Tidak ada cast langsung (`json['id'] as int`) yang bisa crash.
- File: `lib/data/models/comment.dart` (baris 48-56)

### 3. Apakah semua DioExceptionType dipetakan ke pesan pengguna?
- ✅ **YA.** Mapping lengkap di `commentFriendlyErrorMessage()`:
  - `connectionTimeout` / `sendTimeout` / `receiveTimeout` → "Koneksi timeout..."
  - `connectionError` → "Tidak dapat terhubung ke server..."
  - `badResponse 404` → "Komentar tidak ditemukan (404)."
  - `badResponse 500+` → "Server sedang bermasalah..."
  - `badResponse 401/403` → "Akses ditolak..."
  - `default` → "Terjadi kesalahan jaringan..."
  - Non-DioException → "Terjadi kesalahan tak terduga..."
- File: `lib/data/comment_providers.dart` (baris 99-137)

### 4. Apakah baseUrl/timeout terpusat?
- ✅ **YA.** Konfigurasi ada di `lib/data/api_client.dart`:
  - `baseUrl: 'https://jsonplaceholder.typicode.com'`
  - `connectTimeout: Duration(seconds: 10)`
  - `receiveTimeout: Duration(seconds: 10)`
- CommentRepository menerima Dio via constructor injection, tidak membuat Dio sendiri.

### 5. Apakah test menguji kasus field hilang?
- ✅ **YA.** Test mencakup:
  1. Happy path — JSON lengkap
  2. **Field hilang** — JSON kosong `{}` (requirement)
  3. **Field null eksplisit** — semua value `null`
  4. **Sebagian field hilang** — edge case realistis
  5. **Tipe double** — server kirim `2.0` bukan `2`
  6. toJson — round-trip verification

### 6. Hasil `flutter analyze` dan `flutter test`
- ✅ `flutter analyze` → **No issues found!** (ran in 382.3s)
- ✅ `flutter test test/comment_test.dart` → **All 6 tests passed!**

---

## File yang Dibuat

| File | Deskripsi |
|------|-----------|
| `lib/data/models/comment.dart` | Model Comment dengan fromJson/toJson aman null |
| `lib/data/repositories/comment_repository.dart` | Repository dengan fetchComments(postId) |
| `lib/data/comment_providers.dart` | Provider, AsyncNotifier, dan error message |
| `test/comment_test.dart` | Unit test fromJson (6 test case) |
| `docs/ai_verification_checklist.md` | Dokumen ini |

---

## Arsitektur

```
┌─────────────┐     watch      ┌──────────────────┐
│     UI      │ ──────────────→│ commentListProvider│
│ (Consumer   │                │ (AsyncNotifier)   │
│  Widget)    │                └────────┬──────────┘
└─────────────┘                         │ panggil
                                        ▼
                               ┌──────────────────┐
                               │CommentRepository  │
                               │ fetchComments()   │
                               └────────┬──────────┘
                                        │ pakai
                                        ▼
                               ┌──────────────────┐
                               │   Dio (terpusat)  │
                               │ api_client.dart   │
                               └────────┬──────────┘
                                        │ HTTP GET
                                        ▼
                               ┌──────────────────┐
                               │ JSONPlaceholder   │
                               │ /comments?postId= │
                               └──────────────────┘
```
