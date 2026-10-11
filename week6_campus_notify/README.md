# Campus Notify

Flutter mini project for campus announcements, mock login, device token registration, and push notification deep links.

## Features

- Mock email/password login. The GoRouter guard sends unauthenticated users to `/login` and returns authenticated users to `/home`.
- Access and refresh tokens stored with `flutter_secure_storage`.
- Dio attaches the access token, refreshes once after HTTP 401, retries the original request once, and clears the session if refresh fails or the retry is still unauthorized.
- FCM permission, current token and token refresh registration, plus the `pengumuman-kampus` broadcast topic.
- Foreground local notifications and notification taps routed to `/pengumuman/:id` in foreground, background, and terminated states.

## Run

The Android Firebase file is `android/app/google-services.json`; its package name must match `applicationId` in `android/app/build.gradle.kts`.

```powershell
flutter pub get
flutter run --dart-define=API_BASE_URL=https://your-campus-api.example
```

Login is intentionally mocked for this assignment: use any email containing `@` and a password with at least six characters. Replace `AuthRepository` with Firebase Auth or a real auth API before production use.

## Backend contract

Set `API_BASE_URL` to the backend origin. The app registers the FCM device token with:

```http
POST /devices
Authorization: Bearer <access-token>
Content-Type: application/json

{"fcm_token":"<device-token>","platform":"android"}
```

The API must support the app's mock access/refresh behavior or replace `AuthRepository` with real endpoints. Personal notifications must target a device token; topics are for broadcasts only.

## FCM payload example

Send via Firebase Cloud Messaging HTTP v1 (topic `pengumuman-kampus`):

```json
{
  "message": {
    "topic": "pengumuman-kampus",
    "notification": {
      "title": "Jadwal kuliah berubah",
      "body": "Kelas Mobile pindah ke Ruang A2 jam 13.00"
    },
    "data": {
      "route": "/pengumuman/3",
      "id": "3"
    }
  }
}
```

## Tests and evidence

Run automated tests with `flutter test`. The tests cover route parsing and Dio refresh/retry/logout behavior. Manual device results and screenshot evidence are tracked in [`docs/TEST_RESULTS.md`](docs/TEST_RESULTS.md) and [`screenshots/README.md`](screenshots/README.md).

| App state | Action | Expected result |
|---|---|---|
| Foreground | Receive and tap a broadcast notification | Local banner appears; tap opens `/pengumuman/:id` |
| Background | Tap the system notification | App resumes at `/pengumuman/:id` |
| Terminated | Tap the system notification to launch the app | App opens at `/pengumuman/:id` |

Automated tests passed in the implementation environment. The three notification states still need manual confirmation on a connected Android/iOS device; see the test results for the current status.

The AI Challenge prompt, initial draft review, and manual technical corrections are in [`docs/AI_PROMPT.md`](docs/AI_PROMPT.md), [`docs/AI_OUTPUT_INITIAL.md`](docs/AI_OUTPUT_INITIAL.md), and [`docs/MANUAL_FIXES.md`](docs/MANUAL_FIXES.md).
