import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../services/fcm_service.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  String _tokenDisplay = 'Mengambil token...';
  bool _subscribed = true; // Diasumsikan subscribe saat login

  // Simulasi riwayat notifikasi (dalam produksi: fetch dari backend / local DB)
  final List<_NotifItem> _history = const [
    _NotifItem(
      title: 'Jadwal UTS Dipercepat',
      body: 'UTS Pemrograman Mobile dimajukan ke 18 Oktober 2026.',
      route: '/pengumuman/1',
      time: '08:00',
    ),
    _NotifItem(
      title: 'Pengumuman Beasiswa',
      body: 'Pendaftaran beasiswa prestasi dibuka hingga 30 Oktober 2026.',
      route: '/pengumuman/2',
      time: 'Kemarin',
    ),
    _NotifItem(
      title: 'Libur Nasional',
      body: 'Kampus libur pada 28 Oktober 2026 (Hari Sumpah Pemuda).',
      route: '/pengumuman/3',
      time: '2 hari lalu',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fetchToken();
  }

  Future<void> _fetchToken() async {
    final token = await FirebaseMessaging.instance.getToken();
    if (mounted) {
      setState(() {
        if (token != null && token.length > 6) {
          // Tampilkan hanya 6 karakter terakhir untuk keamanan
          _tokenDisplay = '...${token.substring(token.length - 6)}';
        } else {
          _tokenDisplay = token ?? 'Gagal mendapatkan token';
        }
      });
    }
  }

  Future<void> _toggleSubscription() async {
    try {
      if (_subscribed) {
        await FcmService.unsubscribeFromTopic('pengumuman-kampus');
      } else {
        await FcmService.subscribeToTopic('pengumuman-kampus');
      }
      if (mounted) {
        setState(() => _subscribed = !_subscribed);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _subscribed
                  ? 'Subscribe ke pengumuman-kampus'
                  : 'Unsubscribe dari pengumuman-kampus',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    await ref.read(authStateProvider.notifier).logout();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Campus Notify'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Keluar',
            onPressed: _logout,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── FCM Token Card ──────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.vpn_key, color: Colors.deepPurple),
                      const SizedBox(width: 8),
                      Text(
                        'FCM Token (6 karakter terakhir)',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _tokenDisplay,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 18),
                        tooltip: 'Salin token penuh',
                        onPressed: () async {
                          final token =
                              await FirebaseMessaging.instance.getToken();
                          if (token != null && context.mounted) {
                            await Clipboard.setData(
                              ClipboardData(text: token),
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Token disalin ke clipboard'),
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Subscription Card ───────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.campaign, color: Colors.deepPurple),
                      const SizedBox(width: 8),
                      Text(
                        'Topik Broadcast',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('pengumuman-kampus'),
                      Switch(
                        value: _subscribed,
                        onChanged: (_) => _toggleSubscription(),
                      ),
                    ],
                  ),
                  Text(
                    _subscribed
                        ? 'Anda menerima notifikasi broadcast kampus'
                        : 'Notifikasi broadcast dinonaktifkan',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Riwayat Notifikasi ──────────────────────────────────
          Text(
            'Riwayat Pengumuman',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ..._history.map(
            (item) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.deepPurple,
                  child: Icon(Icons.notifications, color: Colors.white),
                ),
                title: Text(item.title),
                subtitle: Text(item.body, maxLines: 2, overflow: TextOverflow.ellipsis),
                trailing: Text(
                  item.time,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey),
                ),
                onTap: () => context.go(item.route),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotifItem {
  final String title;
  final String body;
  final String route;
  final String time;

  const _NotifItem({
    required this.title,
    required this.body,
    required this.route,
    required this.time,
  });
}
