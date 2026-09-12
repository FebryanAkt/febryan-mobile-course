import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router.dart';

// ──────────────────────────────────────────────────────────────────
// Entry point aplikasi.
//
// ProviderScope HARUS membungkus root widget agar semua provider
// Riverpod dapat diakses dari mana saja di widget tree.
// State ToDo bertahan saat berpindah halaman karena ProviderScope
// berada di level paling atas (di atas router).
// ──────────────────────────────────────────────────────────────────
void main() => runApp(const ProviderScope(child: MyApp()));

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp.router(
        title: 'Week 3 - ToDo',
        theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
        // Menggunakan GoRouter untuk navigasi deklaratif
        routerConfig: router,
      );
}