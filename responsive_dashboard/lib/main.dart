import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Breakpoint responsif: di bawah nilai ini → 1 kolom, di atasnya → 2 kolom.
const kWideBreakpoint = 700.0;

void main() => runApp(const DashboardApp());

// ──────────────────────────────────────────────────────────────
// Root – mengelola state tema terang/gelap
// ──────────────────────────────────────────────────────────────
class DashboardApp extends StatefulWidget {
  const DashboardApp({super.key});
  @override
  State<DashboardApp> createState() => _DashboardAppState();
}

class _DashboardAppState extends State<DashboardApp> {
  bool isDark = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.indigo,
      ),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: _AcademicPage(
        isDark: isDark,
        onToggle: (v) => setState(() => isDark = v),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Halaman utama Academic Overview
// ──────────────────────────────────────────────────────────────
class _AcademicPage extends StatelessWidget {
  const _AcademicPage({required this.isDark, required this.onToggle});
  final bool isDark;
  final ValueChanged<bool> onToggle;

  static const _cards = [
    (icon: Icons.school, title: 'IPK', value: '3.72', subtitle: 'Kumulatif'),
    (icon: Icons.menu_book, title: 'SKS Ditempuh', value: '96', subtitle: 'dari 144 SKS'),
    (icon: Icons.assignment_turned_in, title: 'Tugas Selesai', value: '28 / 32', subtitle: 'Semester ini'),
    (icon: Icons.event_available, title: 'Kehadiran', value: '92 %', subtitle: 'Rata-rata'),
    (icon: Icons.emoji_events, title: 'Prestasi', value: '5', subtitle: 'Sertifikat diraih'),
    (icon: Icons.calendar_today, title: 'Minggu Ke-', value: '02', subtitle: 'Semester berjalan'),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Semantics(header: true, child: const Text('Academic Overview')),
        actions: [
          Semantics(
            label: 'Pengaturan mode gelap',
            toggled: isDark,
            child: Row(children: [
              Icon(isDark ? Icons.dark_mode : Icons.light_mode,
                  semanticLabel: isDark ? 'Mode gelap' : 'Mode terang'),
              const SizedBox(width: 4),
              CupertinoSwitch(value: isDark, onChanged: onToggle),
              const SizedBox(width: 12),
            ]),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── Header profil ──
            Semantics(
              label: 'Profil: Febryan Akhmad, NIM 244107020180, '
                  'Teknik Informatika, Semester 5',
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [cs.primaryContainer, cs.secondaryContainer],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(20),
                child: ExcludeSemantics(
                  child: Row(children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundColor: cs.primary,
                      child: Text('FA', style: tt.titleLarge?.copyWith(
                          color: cs.onPrimary, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Febryan Akhmad', style: tt.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: cs.onPrimaryContainer)),
                          Text('NIM: 244107020180', style: tt.bodyMedium
                              ?.copyWith(color: cs.onSecondaryContainer)),
                          Text('Teknik Informatika • Semester 5',
                              style: tt.bodyMedium?.copyWith(
                                  color: cs.onSecondaryContainer)),
                        ],
                      ),
                    ),
                  ]),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Kartu responsif ──
            LayoutBuilder(builder: (context, box) {
              final wide = box.maxWidth >= kWideBreakpoint;

              if (!wide) {
                return Column(
                  children: [
                    for (final c in _cards)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: InfoCard(
                          icon: c.icon,
                          title: c.title,
                          value: c.value,
                          subtitle: c.subtitle,
                        ),
                      ),
                  ],
                );
              }

              return Column(children: [
                for (int i = 0; i < _cards.length; i += 2)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(children: [
                      Expanded(child: InfoCard(
                        icon: _cards[i].icon,
                        title: _cards[i].title,
                        value: _cards[i].value,
                        subtitle: _cards[i].subtitle,
                      )),
                      const SizedBox(width: 10),
                      Expanded(
                        child: i + 1 < _cards.length
                            ? InfoCard(
                                icon: _cards[i + 1].icon,
                                title: _cards[i + 1].title,
                                value: _cards[i + 1].value,
                                subtitle: _cards[i + 1].subtitle,
                              )
                            : const SizedBox.shrink(),
                      ),
                    ]),
                  ),
              ]);
            }),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Widget reusable – kartu informasi akademik
// Semua warna dan ukuran teks diambil dari Theme.of(context).
// ──────────────────────────────────────────────────────────────
class InfoCard extends StatelessWidget {
  const InfoCard({
    required this.icon,
    required this.title,
    required this.value,
    this.subtitle,
    super.key,
  });

  final IconData icon;
  final String title;
  final String value;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Semantics(
      label: subtitle != null
          ? '$title: $value, $subtitle'
          : '$title: $value',
      readOnly: true,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
        ),
        padding: const EdgeInsets.all(16),
        child: ExcludeSemantics(
          child: Row(children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: cs.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: tt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant)),
                  Text(value, style: tt.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold)),
                  if (subtitle != null)
                    Text(subtitle!, style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant)),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}