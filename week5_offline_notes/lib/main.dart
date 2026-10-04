import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'pages/notes_page.dart';
import 'pages/note_detail_page.dart';
import 'pages/settings_page.dart';
import 'data/prefs.dart';

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const NotesPage(),
    ),
    GoRoute(
      path: '/note/:id',
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
        return NoteDetailPage(id: id);
      },
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsPage(),
    ),
  ],
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = PrefsRepository();
  await prefs.markOpenedNow();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkMode = ref.watch(darkModeProvider);
    return MaterialApp.router(
      title: 'Offline Notes',
      routerConfig: router,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: darkMode.when(
        data: (dark) => dark ? ThemeMode.dark : ThemeMode.light,
        loading: () => ThemeMode.light,
        error: (_, _) => ThemeMode.light,
      ),
    );
  }
}
