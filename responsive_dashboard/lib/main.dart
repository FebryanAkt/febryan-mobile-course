import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

void main() => runApp(const DashboardApp());

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

class _AcademicPage extends StatelessWidget {
  const _AcademicPage({required this.isDark, required this.onToggle});
  final bool isDark;
  final ValueChanged<bool> onToggle;

  // Data kartu: [icon, judul, nilai, keterangan]
  static const _cards = [
    [Icons.school, 'IPK', '3.72', 'Kumulatif'],
    [Icons.menu_book, 'SKS Ditempuh', '96', 'dari 144 SKS'],
    [Icons.assignment_turned_in, 'Tugas Selesai', '28 / 32', 'Semester ini'],
    [Icons.event_available, 'Kehadiran', '92 %', 'Rata-rata'],
    [Icons.emoji_events, 'Prestasi', '5', 'Sertifikat diraih'],
    [Icons.calendar_today, 'Minggu Ke-', '02', 'Semester berjalan'],
  ];

  Widget _buildCard(BuildContext context, List<Object> d) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Semantics(
      label: '${d[1]}: ${d[2]}, ${d[3]}',
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
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(d[0] as IconData, color: cs.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(d[1] as String, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                  Text(d[2] as String, style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  Text(d[3] as String, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }

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
              label: 'Profil: Febryan Akhmad, NIM 244107020180, Teknik Informatika, Semester 5',
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
                            fontWeight: FontWeight.bold, color: cs.onPrimaryContainer)),
                          Text('NIM: 244107020180', style: tt.bodyMedium?.copyWith(
                            color: cs.onSecondaryContainer)),
                          Text('Teknik Informatika • Semester 5', style: tt.bodyMedium?.copyWith(
                            color: cs.onSecondaryContainer)),
                        ],
                      ),
                    ),
                  ]),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Kartu responsif: 1 kolom (sempit) / 2 kolom (lebar) ──
            LayoutBuilder(builder: (context, box) {
              final wide = box.maxWidth >= 600;
              if (!wide) {
                return Column(
                  children: [for (final c in _cards) Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildCard(context, c),
                  )],
                );
              }
              return Column(children: [
                for (int i = 0; i < _cards.length; i += 2)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(children: [
                      Expanded(child: _buildCard(context, _cards[i])),
                      const SizedBox(width: 10),
                      Expanded(child: i + 1 < _cards.length
                          ? _buildCard(context, _cards[i + 1])
                          : const SizedBox.shrink()),
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