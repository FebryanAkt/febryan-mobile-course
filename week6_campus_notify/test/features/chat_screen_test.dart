import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:week6_campus_notify/ai/ai_service.dart';
import 'package:week6_campus_notify/features/chat_screen.dart';

import '../ai/ai_service_test.dart';

void main() {
  group('ChatNotifier & ChatState Unit Tests', () {
    late FakeSecureStorage fakeStorage;

    setUp(() {
      fakeStorage = FakeSecureStorage()..data['ai_api_key'] = 'mock-key';
    });

    test('Initial state memiliki pesan sambutan AI dan security note', () {
      final mockClient = MockClient((request) async => http.Response('ok', 200));
      final fakeAiService = AiService(storage: fakeStorage, client: mockClient);

      final container = ProviderContainer(
        overrides: [
          aiServiceProvider.overrideWithValue(fakeAiService),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(chatProvider);
      expect(state.messages, isNotEmpty);
      expect(state.messages.first.role, MessageRole.ai);
      expect(state.messages.first.text, contains('Halo! Saya Asisten AI Kampus'));
      expect(state.isLoading, isFalse);
    });

    test('sendMessage menambahkan pesan user dan melakukan streaming AI response',
        () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': 'Pendaftaran beasiswa dibuka bulan depan.'}
                  ]
                }
              }
            ]
          }),
          200,
        );
      });
      final fakeAiService = AiService(storage: fakeStorage, client: mockClient);

      final container = ProviderContainer(
        overrides: [
          aiServiceProvider.overrideWithValue(fakeAiService),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(chatProvider.notifier);
      await notifier.sendMessage('Info beasiswa');

      final finalState = container.read(chatProvider);
      expect(finalState.messages.length, greaterThanOrEqualTo(2));
      expect(finalState.messages.any((m) => m.text == 'Info beasiswa'), isTrue);
      expect(
        finalState.messages.any(
          (m) => m.text.contains('Pendaftaran beasiswa dibuka bulan depan'),
        ),
        isTrue,
      );
      expect(finalState.isLoading, isFalse);
      expect(finalState.isStreaming, isFalse);
    });

    test('sendMessage mendeteksi data sensitif dan mencatat jenisnya', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': 'Data Anda diproses.'}
                  ]
                }
              }
            ]
          }),
          200,
        );
      });
      final fakeAiService = AiService(storage: fakeStorage, client: mockClient);

      final container = ProviderContainer(
        overrides: [
          aiServiceProvider.overrideWithValue(fakeAiService),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(chatProvider.notifier);
      await notifier.sendMessage('Cek NIK saya 3578012345670001');

      final state = container.read(chatProvider);
      expect(state.lastSanitizationNotice, isNotNull);
      expect(state.lastSanitizationNotice, contains('NIK'));
    });

    test('clearChat membersihkan riwayat percakapan', () {
      final mockClient = MockClient((request) async => http.Response('ok', 200));
      final fakeAiService = AiService(storage: fakeStorage, client: mockClient);

      final container = ProviderContainer(
        overrides: [
          aiServiceProvider.overrideWithValue(fakeAiService),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(chatProvider.notifier);
      notifier.clearChat();

      final state = container.read(chatProvider);
      expect(state.messages.length, 1);
      expect(state.messages.first.text, contains('Percakapan telah dibersihkan'));
    });

    test('performOcr menambahkan pesan ekstraksi teks ke dalam chat', () async {
      final dummyBytes = Uint8List.fromList([1, 2, 3]);
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': 'Nama: Budi Santoso\nNIM: 2241720001'}
                  ]
                }
              }
            ]
          }),
          200,
        );
      });
      final fakeAiService = AiService(storage: fakeStorage, client: mockClient);

      final container = ProviderContainer(
        overrides: [
          aiServiceProvider.overrideWithValue(fakeAiService),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(chatProvider.notifier);
      await notifier.performOcr(dummyBytes);

      final state = container.read(chatProvider);
      expect(state.messages.any((m) => m.text.contains('[OCR]')), isTrue);
      expect(
        state.messages.any((m) => m.text.contains('Nama: Budi Santoso')),
        isTrue,
      );
    });

    test('performImageUnderstanding menambahkan deskripsi gambar ke dalam chat',
        () async {
      final dummyBytes = Uint8List.fromList([4, 5, 6]);
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': 'Papan pengumuman berisi jadwal ujian semester.'}
                  ]
                }
              }
            ]
          }),
          200,
        );
      });
      final fakeAiService = AiService(storage: fakeStorage, client: mockClient);

      final container = ProviderContainer(
        overrides: [
          aiServiceProvider.overrideWithValue(fakeAiService),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(chatProvider.notifier);
      await notifier.performImageUnderstanding(
        dummyBytes,
        prompt: 'Jelaskan isi papan pengumuman',
      );

      final state = container.read(chatProvider);
      expect(
        state.messages.any((m) => m.text.contains('[Image Understanding]')),
        isTrue,
      );
      expect(
        state.messages.any((m) => m.text.contains('jadwal ujian semester')),
        isTrue,
      );
    });

    test('performSpeechToText mengonversi audio dan mengirim pertanyaan',
        () async {
      final dummyBytes = Uint8List.fromList([7, 8, 9]);
      var callIndex = 0;
      final mockClient = MockClient((request) async {
        callIndex++;
        if (callIndex == 1) {
          // Response STT
          return http.Response(
            jsonEncode({
              'candidates': [
                {
                  'content': {
                    'parts': [
                      {'text': 'Dimana ruang TU informatika?'}
                    ]
                  }
                }
              ]
            }),
            200,
          );
        } else {
          // Response jawaban AI atas pertanyaan STT
          return http.Response(
            jsonEncode({
              'candidates': [
                {
                  'content': {
                    'parts': [
                      {'text': 'Ruang TU berada di Gedung Sipil lantai 2.'}
                    ]
                  }
                }
              ]
            }),
            200,
          );
        }
      });
      final fakeAiService = AiService(storage: fakeStorage, client: mockClient);

      final container = ProviderContainer(
        overrides: [
          aiServiceProvider.overrideWithValue(fakeAiService),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(chatProvider.notifier);
      await notifier.performSpeechToText(dummyBytes);

      final state = container.read(chatProvider);
      expect(
        state.messages.any((m) => m.text.contains('Dimana ruang TU informatika?')),
        isTrue,
      );
    });

    test('Mode Offline Aktif langsung menjawab dari basis pengetahuan lokal tanpa memanggil API',
        () async {
      int apiCallCount = 0;
      final mockClient = MockClient((request) async {
        apiCallCount++;
        return http.Response('ok', 200);
      });
      final fakeAiService = AiService(storage: fakeStorage, client: mockClient);

      final container = ProviderContainer(
        overrides: [
          aiServiceProvider.overrideWithValue(fakeAiService),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(chatProvider.notifier);
      notifier.toggleOfflineMode();
      expect(container.read(chatProvider).isOfflineMode, isTrue);

      await notifier.sendMessage('Kapan jadwal krs?');

      expect(apiCallCount, 0); // 0 panggilan API!
      final state = container.read(chatProvider);
      expect(state.messages.last.isOffline, isTrue);
      expect(state.messages.last.text, contains('Jadwal Pengisian KRS'));
    });

    test('Error handling memicu fallback dialog dan answerWithOfflineFallback memberikan solusi lokal',
        () async {
      final mockClient = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });
      final fakeAiService = AiService(storage: fakeStorage, client: mockClient);

      final container = ProviderContainer(
        overrides: [
          aiServiceProvider.overrideWithValue(fakeAiService),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(chatProvider.notifier);
      await notifier.sendMessage('Syarat beasiswa');

      final stateError = container.read(chatProvider);
      expect(stateError.triggerFallbackDialog, isTrue);
      expect(stateError.lastFailedPrompt, 'Syarat beasiswa');
      expect(stateError.messages.last.isError, isTrue);

      // Eksekusi aksi fallback offline
      notifier.answerWithOfflineFallback();

      final stateFallback = container.read(chatProvider);
      expect(stateFallback.messages.last.isOffline, isTrue);
      expect(stateFallback.messages.last.text, contains('Informasi Beasiswa Kampus'));
    });

    test('Pertanyaan yang di-cache mengembalikan respons lokal bertanda isCached',
        () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': 'Jawaban pertama dari AI'}
                  ]
                }
              }
            ]
          }),
          200,
        );
      });
      final fakeAiService = AiService(storage: fakeStorage, client: mockClient);

      final container = ProviderContainer(
        overrides: [
          aiServiceProvider.overrideWithValue(fakeAiService),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(chatProvider.notifier);
      await notifier.sendMessage('Info umum');
      expect(container.read(chatProvider).messages.last.text, 'Jawaban pertama dari AI');

      // Kirim pertanyaan yang sama lagi
      await notifier.sendMessage('Info umum');
      final state = container.read(chatProvider);
      expect(state.messages.last.isCached, isTrue);
      expect(state.messages.last.text, 'Jawaban pertama dari AI');
    });
  });

  group('ChatScreen Widget Tests', () {
    late FakeSecureStorage fakeStorage;

    setUp(() {
      fakeStorage = FakeSecureStorage()..data['ai_api_key'] = 'mock-key';
    });

    testWidgets('Merender ChatScreen dengan komponen utama secara lengkap',
        (tester) async {
      final mockClient = MockClient((request) async => http.Response('ok', 200));
      final fakeAiService = AiService(storage: fakeStorage, client: mockClient);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            aiServiceProvider.overrideWithValue(fakeAiService),
          ],
          child: const MaterialApp(
            home: ChatScreen(),
          ),
        ),
      );

      // Verifikasi AppBar
      expect(find.text('Campus AI Chat'), findsOneWidget);
      expect(find.byIcon(Icons.vpn_key_outlined), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);

      // Verifikasi Mode Aman Banner
      expect(
        find.textContaining('Mode Aman Aktif: NIK, nomor telepon & alamat'),
        findsOneWidget,
      );

      // Verifikasi Pesan Awal
      expect(find.textContaining('Halo! Saya Asisten AI Kampus'), findsOneWidget);

      // Verifikasi Input Field & Tombol Kirim & Tombol Multimodal (OCR & Mic)
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.send_rounded), findsOneWidget);
      expect(find.byIcon(Icons.attach_file), findsOneWidget);
      expect(find.byIcon(Icons.mic_none), findsOneWidget);
      expect(find.byIcon(Icons.document_scanner_outlined), findsOneWidget);

      // Verifikasi Quick Suggestions Chips (termasuk fitur multimodal)
      expect(find.text('📅 Jadwal KRS semester genap'), findsOneWidget);
      expect(find.text('📷 Pindai KTM (OCR)'), findsOneWidget);
      expect(find.text('🔍 Analisis Gambar'), findsOneWidget);
    });

    testWidgets('Tapping suggestion chip mengisi teks ke TextField',
        (tester) async {
      final mockClient = MockClient((request) async => http.Response('ok', 200));
      final fakeAiService = AiService(storage: fakeStorage, client: mockClient);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            aiServiceProvider.overrideWithValue(fakeAiService),
          ],
          child: const MaterialApp(
            home: ChatScreen(),
          ),
        ),
      );

      // Tap chip
      await tester.tap(find.text('📅 Jadwal KRS semester genap'));
      await tester.pump();

      // Cek apakah controller terisi
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, '📅 Jadwal KRS semester genap');
    });
  });
}
