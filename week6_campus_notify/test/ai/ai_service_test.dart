import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:week6_campus_notify/ai/ai_service.dart';

class FakeSecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> data = {};

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return data[key];
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) {
      data[key] = value;
    } else {
      data.remove(key);
    }
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    data.remove(key);
  }
}

void main() {
  group('AiService Unit Tests', () {
    late FakeSecureStorage fakeStorage;

    setUp(() {
      fakeStorage = FakeSecureStorage();
    });

    test('ask() melempar exception saat API key belum tersedia', () async {
      final client = MockClient((request) async => http.Response('ok', 200));
      final service = AiService(storage: fakeStorage, client: client);

      expect(
        () => service.ask('Halo apa kabar?'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('API key tidak tersedia'),
          ),
        ),
      );
    });

    test('ask() berhasil memanggil Gemini API dan mengembalikan teks balasan',
        () async {
      fakeStorage.data['ai_api_key'] = 'valid-test-gemini-key';

      final mockClient = MockClient((request) async {
        expect(request.url.queryParameters['key'], 'valid-test-gemini-key');
        expect(request.headers['Content-Type'], contains('application/json'));

        final body = jsonDecode(request.body);
        expect(body['contents'][0]['parts'][0]['text'], 'Jadwal KRS kapan?');

        final responseJson = {
          'candidates': [
            {
              'content': {
                'parts': [
                  {'text': 'Jadwal KRS dimulai tanggal 10 Februari 2026.'}
                ]
              }
            }
          ]
        };

        return http.Response(jsonEncode(responseJson), 200);
      });

      final service = AiService(storage: fakeStorage, client: mockClient);
      final answer = await service.ask('Jadwal KRS kapan?');

      expect(answer, 'Jadwal KRS dimulai tanggal 10 Februari 2026.');
    });

    test('ask() melempar exception saat API mengembalikan status error (bukan 200)',
        () async {
      fakeStorage.data['ai_api_key'] = 'expired-key';

      final mockClient = MockClient((request) async {
        return http.Response('Unauthorized - Invalid API Key', 401);
      });

      final service = AiService(storage: fakeStorage, client: mockClient);

      expect(
        () => service.ask('Halo'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Gagal memanggil AI API: 401'),
          ),
        ),
      );
    });

    test('ask() otomatis menyaring data NIK pengguna sebelum dikirim ke API',
        () async {
      fakeStorage.data['ai_api_key'] = 'valid-key';
      String? sentPayloadText;

      final mockClient = MockClient((request) async {
        final body = jsonDecode(request.body);
        sentPayloadText = body['contents'][0]['parts'][0]['text'];

        return http.Response(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': 'Data Anda aman.'}
                  ]
                }
              }
            ]
          }),
          200,
        );
      });

      final service = AiService(storage: fakeStorage, client: mockClient);
      await service.ask('Cek NIK saya 3201019908880002');

      expect(sentPayloadText, isNotNull);
      expect(sentPayloadText, contains('[NIK_ANONIM_0002]'));
      expect(sentPayloadText!.contains('3201019908880002'), isFalse);
    });

    test('saveApiKey, getApiKey, dan deleteApiKey mengelola storage dengan benar',
        () async {
      final service = AiService(storage: fakeStorage);

      expect(await service.getApiKey(), isNull);

      await service.saveApiKey('my-secret-gemini-key');
      expect(await service.getApiKey(), 'my-secret-gemini-key');
      expect(fakeStorage.data['ai_api_key'], 'my-secret-gemini-key');

      await service.deleteApiKey();
      expect(await service.getApiKey(), isNull);
    });

    test('askStream() mengalirkan potongan teks balasan', () async {
      fakeStorage.data['ai_api_key'] = 'valid-key';

      // Simulasikan fallback ask() streaming
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': 'Halo selamat datang di kampus'}
                  ]
                }
              }
            ]
          }),
          200,
        );
      });

      final service = AiService(storage: fakeStorage, client: mockClient);
      final stream = service.askStream('Halo');

      final chunks = await stream.toList();
      expect(chunks, isNotEmpty);
      final fullText = chunks.join('');
      expect(fullText, 'Halo selamat datang di kampus');
    });

    test('recognizeText() mengekstrak teks gambar melalui multimodal API (OCR)',
        () async {
      fakeStorage.data['ai_api_key'] = 'valid-key';
      final dummyBytes = Uint8List.fromList([1, 2, 3, 4, 5]);

      final mockClient = MockClient((request) async {
        final body = jsonDecode(request.body);
        final parts = body['contents'][0]['parts'] as List;

        expect(parts[0]['text'], contains('OCR'));
        expect(parts[1]['inline_data']['mime_type'], 'image/jpeg');
        expect(parts[1]['inline_data']['data'], base64Encode(dummyBytes));

        return http.Response(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': 'KARTU TANDA MAHASISWA\nNIM: 2241720000'}
                  ]
                }
              }
            ]
          }),
          200,
        );
      });

      final service = AiService(storage: fakeStorage, client: mockClient);
      final result = await service.recognizeText(dummyBytes);

      expect(result, contains('KARTU TANDA MAHASISWA'));
      expect(result, contains('2241720000'));
    });

    test('speechToText() mengonversi rekaman audio menjadi teks', () async {
      fakeStorage.data['ai_api_key'] = 'valid-key';
      final dummyAudioBytes = Uint8List.fromList([10, 20, 30, 40]);

      final mockClient = MockClient((request) async {
        final body = jsonDecode(request.body);
        final parts = body['contents'][0]['parts'] as List;

        expect(parts[0]['text'], contains('Transkripsikan'));
        expect(parts[1]['inline_data']['mime_type'], 'audio/m4a');
        expect(parts[1]['inline_data']['data'], base64Encode(dummyAudioBytes));

        return http.Response(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': 'Kapan batas akhir pengisian KRS?'}
                  ]
                }
              }
            ]
          }),
          200,
        );
      });

      final service = AiService(storage: fakeStorage, client: mockClient);
      final text = await service.speechToText(dummyAudioBytes);

      expect(text, 'Kapan batas akhir pengisian KRS?');
    });

    test('understandImage() menghasilkan deskripsi visual konten gambar',
        () async {
      fakeStorage.data['ai_api_key'] = 'valid-key';
      final dummyBytes = Uint8List.fromList([100, 101, 102]);

      final mockClient = MockClient((request) async {
        final body = jsonDecode(request.body);
        final parts = body['contents'][0]['parts'] as List;

        expect(parts[0]['text'], contains('Deskripsikan gedung perpustakaan'));
        expect(parts[1]['inline_data']['data'], base64Encode(dummyBytes));

        return http.Response(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {
                      'text':
                          'Gambar memperlihatkan gedung perpustakaan pusat berlantai tiga.'
                    }
                  ]
                }
              }
            ]
          }),
          200,
        );
      });

      final service = AiService(storage: fakeStorage, client: mockClient);
      final desc = await service.understandImage(
        dummyBytes,
        prompt: 'Deskripsikan gedung perpustakaan ini',
      );

      expect(desc, contains('gedung perpustakaan pusat'));
    });
  });
}
