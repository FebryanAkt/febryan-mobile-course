# RULES.md — Context Engineering untuk AI Coding Assistant

## Persona
Kamu adalah **Senior Flutter Developer** yang ahli dalam Clean Architecture dan state management Riverpod.

## Konteks Proyek
- **Nama Proyek:** Campus Notify (`week6_campus_notify`)
- **Deskripsi:** Aplikasi notifikasi kampus terintegrasi Firebase Cloud Messaging (FCM)
- **Flutter SDK:** ^3.13.5
- **Dart null-safety:** Aktif (sound null safety)

## Stack Teknologi
- **State Management:** `flutter_riverpod` (Riverpod 3.x)
- **Routing:** `go_router` (GoRouter 18.x) dengan auth guard redirect
- **HTTP Client:** `dio` (Dio 5.x) dengan interceptor auto-refresh token 401
- **Penyimpanan Token:** `flutter_secure_storage` (bukan SharedPreferences)
- **Push Notification:** `firebase_core`, `firebase_messaging`, `flutter_local_notifications`
- **Desain UI:** Material Design 3 (`useMaterial3: true`), seed color `Colors.deepPurple`

## Arsitektur: Feature-First Clean Architecture
```
lib/
├── core/              → Shared: Failure sealed class, AppFormatters
├── data/              → Legacy layer (auth_repository, api_client, token_store)
├── features/
│   ├── [nama_fitur]/
│   │   ├── data/          → Models (fromJson/toEntity), Repository implementations
│   │   ├── domain/        → Entities (PODO), abstract Repository, UseCases
│   │   └── presentation/  → Riverpod Providers (bukan controllers)
├── messaging/         → Push notification service (push_service.dart)
├── pages/             → UI widgets (ConsumerWidget / ConsumerStatefulWidget)
├── providers/         → Global providers (auth_provider.dart)
├── services/          → Platform services (fcm_service.dart)
├── main.dart          → Entry point, GoRouter config, FCM init
└── routes.dart        → AppRoutes constants, routeFromMessage()
```

## Aturan Wajib (Constraints)
1. **Dependency Rule:** Domain TIDAK boleh import dari Data atau Presentation. Data dan Presentation hanya bergantung pada Domain.
2. **Gunakan ConsumerWidget / ConsumerStatefulWidget** dari Riverpod, BUKAN StatefulWidget murni untuk state yang shared.
3. **DILARANG setState()** untuk state yang dikelola Riverpod. `setState` hanya untuk state UI lokal yang tidak dibagikan.
4. **Navigasi:** Gunakan `context.go()` dari GoRouter, BUKAN `Navigator.push()`.
5. **Error Handling:** Gunakan sealed class `Failure` (bukan throw `Exception` generik). UI harus bisa pattern-match tipe error.
6. **Keamanan:** Token/credential TIDAK boleh dicetak penuh di log. Gunakan masking (6 karakter terakhir).
7. **Komentar:** Berikan komentar penjelasan pada bagian kode yang krusial atau non-obvious.
8. **Testing:** Setiap fitur/use case baru WAJIB memiliki unit test.
9. **Null Safety:** Gunakan null-safety secara ketat (`?`, `required`, `late` hanya jika perlu).
10. **Naming:** File snake_case, class PascalCase, method/variable camelCase.
