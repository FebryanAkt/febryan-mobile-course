import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/announcements/presentation/widgets/announcement_list.dart';
import '../features/announcements/presentation/widgets/announcement_search_bar.dart';
import '../providers/auth_provider.dart';
import '../routes.dart';
import '../services/fcm_service.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  String _tokenDisplay = 'Mengambil token...';
  bool _subscribed = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchToken();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchToken() async {
    final token = await FirebaseMessaging.instance.getToken();
    if (!mounted) return;
    setState(() {
      _tokenDisplay = (token != null && token.length > 6)
          ? '...${token.substring(token.length - 6)}'
          : (token ?? 'Gagal mendapatkan token');
    });
  }

  Future<void> _toggleSubscription() async {
    try {
      if (_subscribed) {
        await FcmService.unsubscribeFromTopic('Pengumuman Kampus');
      } else {
        await FcmService.subscribeToTopic('Pengumuman Kampus');
      }
      if (!mounted) return;
      setState(() => _subscribed = !_subscribed);
      _showSnackBar(
        _subscribed
            ? 'Subscribe ke pengumuman-kampus'
            : 'Unsubscribe dari pengumuman-kampus',
      );
    } catch (e) {
      if (mounted) _showSnackBar('Error: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }

  Future<void> _logout() async {
    await ref.read(authStateProvider.notifier).logout();
    if (mounted) context.go(AppRoutes.login);
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
          _TokenCard(tokenDisplay: _tokenDisplay),
          const SizedBox(height: 12),
          _SubscriptionCard(
            subscribed: _subscribed,
            onToggle: _toggleSubscription,
          ),
          const SizedBox(height: 16),
          AnnouncementSearchBar(controller: _searchController),
          const SizedBox(height: 16),
          Text(
            'Riwayat Pengumuman',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const AnnouncementList(),
        ],
      ),
    );
  }
}

class _TokenCard extends StatelessWidget {
  const _TokenCard({required this.tokenDisplay});
  final String tokenDisplay;

  @override
  Widget build(BuildContext context) {
    return Card(
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
                    tokenDisplay,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  tooltip: 'Salin token penuh',
                  onPressed: () => _copyToken(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copyToken(BuildContext context) async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null && context.mounted) {
      await Clipboard.setData(ClipboardData(text: token));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Token disalin ke clipboard')),
        );
      }
    }
  }
}

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({required this.subscribed, required this.onToggle});

  final bool subscribed;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Card(
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
                Switch(value: subscribed, onChanged: (_) => onToggle()),
              ],
            ),
            Text(
              subscribed
                  ? 'Anda menerima notifikasi broadcast kampus'
                  : 'Notifikasi broadcast dinonaktifkan',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
