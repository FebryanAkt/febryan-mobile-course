import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'messaging/push_service.dart';
import 'services/fcm_service.dart';
import 'data/api_client.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'pages/announcement_page.dart';
import 'providers/auth_provider.dart';

import 'routes.dart';

// ---------------------------------------------------------------
// Navigator key digunakan untuk navigasi imperatif dari callback
// FCM yang tidak memiliki BuildContext (push dari luar widget tree).
// ---------------------------------------------------------------
final _rootNavigatorKey = GlobalKey<NavigatorState>();

// ---------------------------------------------------------------
// GoRouter provider — watch authStateProvider agar redirect otomatis
// saat login/logout tanpa perlu navigasi manual dari setiap halaman.
// ---------------------------------------------------------------
final routerProvider = Provider<GoRouter>((ref) {
  final authAsync = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.login,
    // redirect dipanggil setiap kali state berubah
    redirect: (context, state) {
      // Saat auth masih loading, jangan redirect
      if (authAsync.isLoading) return null;

      final isLoggedIn = authAsync.asData?.value ?? false;
      final onLogin = state.matchedLocation == AppRoutes.login;

      if (!isLoggedIn && !onLogin) return AppRoutes.login;
      if (isLoggedIn && onLogin) return AppRoutes.home;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: AppRoutes.announcement,
        builder: (context, state) => AnnouncementPage(
          announcementId: state.pathParameters['id']!,
        ),
      ),
    ],
  );
});

// ---------------------------------------------------------------
// Callback navigasi FCM — dipakai oleh listenForeground &
// handleTerminated. Tidak menerima BuildContext secara langsung;
// menggunakan _rootNavigatorKey untuk mendapat context yang valid.
// ---------------------------------------------------------------
void _openPushRoute(String route) {
  if (route == AppRoutes.root || route.isEmpty) return;

  final ctx = _rootNavigatorKey.currentContext;
  if (ctx == null) return; // Router belum siap, abaikan

  // go() akan me-reset stack sehingga tombol back tidak membawa
  // ke halaman notifikasi sebelumnya — perilaku yang diinginkan.
  ctx.go(route);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Daftarkan background handler SEBELUM runApp()
  registerBackgroundHandler();

  // Inisialisasi channel notifikasi lokal
  await initLocalNotifications();

  runApp(const ProviderScope(child: _AppRoot()));
}

// ---------------------------------------------------------------
// _AppRoot: Consumer agar bisa membaca Riverpod providers
// (termasuk apiClientProvider untuk Dio).
// ---------------------------------------------------------------
class _AppRoot extends ConsumerStatefulWidget {
  const _AppRoot();

  @override
  ConsumerState<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends ConsumerState<_AppRoot> {
  bool _fcmInitialized = false;

  @override
  void initState() {
    super.initState();
    // Jadwalkan inisialisasi FCM token setelah frame pertama agar
    // provider sudah ready dan kita bisa mengakses Dio.
    WidgetsBinding.instance.addPostFrameCallback((_) => _initFcm());
  }

  Future<void> _initFcm() async {
    if (_fcmInitialized) return;
    _fcmInitialized = true;

    final dio = ref.read(apiClientProvider);

    // initFcmToken: request permission + get token + onTokenRefresh
    await FcmService.initFcmToken(
      dio: dio,
      onToken: (token) => FcmService.sendTokenToBackend(dio, token),
    );

    // Daftarkan listener foreground dan handler state terminated.
    // Keduanya harus dipanggil SETELAH router siap (addPostFrameCallback
    // menjamin widget tree sudah di-render minimal satu frame).
    listenForeground(_openPushRoute);
    await handleTerminated(_openPushRoute);
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Campus Notify',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
