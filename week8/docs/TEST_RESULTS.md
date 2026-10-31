# Test Results

## Automated tests

Command: `flutter test --no-pub`

| Test | Result |
|---|---|
| Parses FCM route payloads, normalizes a missing leading slash, and falls back to `/` | PASS |
| Refreshes once after 401, retries with the new access token, and succeeds | PASS |
| Clears stored tokens and calls the logout callback when refresh fails | PASS |

Run result: **3 tests passed**.

## Manual notification matrix

Payload for each scenario:

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

| App state | Manual action | Expected result | Device verification |
|---|---|---|---|
| Foreground | Send the payload while the app is open, then tap the local banner | Banner shows title/body; tap opens `/pengumuman/3` | Pending: no Android device was attached during implementation |
| Background | Send the payload, background the app, then tap the system notification | App resumes at `/pengumuman/3` | Pending: no Android device was attached during implementation |
| Terminated | Force-stop the app, send the payload, then tap the system notification | App opens at `/pengumuman/3` | Pending: no Android device was attached during implementation |

Capture real-device evidence in `screenshots/` after completing these steps. Do not use a real FCM token in screenshots; the home screen only shows its last six characters.
