import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'pages/todo_page.dart';
import 'pages/stats_page.dart';

// ──────────────────────────────────────────────────────────────────
// GoRouter configuration dengan StatefulShellRoute.
//
// StatefulShellRoute mempertahankan state masing-masing tab/branch
// saat berpindah halaman via NavigationBar, sehingga:
// - State ToDo tidak hilang saat berpindah ke Stats dan kembali.
// - Setiap branch punya navigator sendiri (independent stack).
//
// Rute:
//   /       → TodoPage (daftar tugas)
//   /stats  → StatsPage (halaman statistik async)
// ──────────────────────────────────────────────────────────────────

// Key navigator untuk setiap branch — diperlukan oleh GoRouter
// agar setiap tab punya navigation stack terpisah.
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _todoBranchKey = GlobalKey<NavigatorState>();
final _statsBranchKey = GlobalKey<NavigatorState>();

final GoRouter router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    // ── StatefulShellRoute ──
    // Membungkus semua branch dengan satu scaffold yang memiliki
    // NavigationBar di bawah. Setiap branch mempertahankan state-nya.
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        // Shell UI: Scaffold dengan body = halaman aktif + NavigationBar
        return Scaffold(
          body: navigationShell, // Menampilkan halaman branch aktif
          bottomNavigationBar: NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: (index) {
              // goBranch: pindah ke branch lain tanpa menghapus state
              navigationShell.goBranch(
                index,
                // Jika tap pada tab yang sudah aktif, kembali ke root branch
                initialLocation: index == navigationShell.currentIndex,
              );
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.checklist),
                selectedIcon: Icon(Icons.checklist_outlined),
                label: 'ToDo',
              ),
              NavigationDestination(
                icon: Icon(Icons.bar_chart_outlined),
                selectedIcon: Icon(Icons.bar_chart),
                label: 'Statistik',
              ),
            ],
          ),
        );
      },
      branches: [
        // ── Branch 1: ToDo ──
        StatefulShellBranch(
          navigatorKey: _todoBranchKey,
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const TodoPage(),
            ),
          ],
        ),
        // ── Branch 2: Statistik ──
        StatefulShellBranch(
          navigatorKey: _statsBranchKey,
          routes: [
            GoRoute(
              path: '/stats',
              builder: (context, state) => const StatsPage(),
            ),
          ],
        ),
      ],
    ),
  ],
);
