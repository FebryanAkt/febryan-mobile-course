import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/fcm_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await FcmService.initFcmToken(
    onToken: (token) async {
      await FcmService.sendTokenToBackend(token);
    },
  );

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Notify',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Campus Notify Home'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _fcmToken = 'Mengambil token...';

  @override
  void initState() {
    super.initState();
    _fetchFcmToken();
  }

  Future<void> _fetchFcmToken() async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      // Cetak menggunakan print biasa agar tidak dipotong buffer logcat
      print('================ FCM TOKEN START ================');
      print(token);
      print('================= FCM TOKEN END =================');
      if (mounted) {
        setState(() {
          _fcmToken = token;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _fcmToken = 'Gagal mengambil token (Cek koneksi/Play Services)';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.notifications_active, size: 48, color: Colors.deepPurple),
              const SizedBox(height: 16),
              const Text(
                'FCM Registration Token Anda:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  _fcmToken,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _fcmToken));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Token berhasil disalin ke clipboard!')),
                  );
                },
                icon: const Icon(Icons.copy),
                label: const Text('Salin Token FCM'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}