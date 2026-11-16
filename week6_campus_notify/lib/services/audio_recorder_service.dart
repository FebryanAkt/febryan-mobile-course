import 'dart:io' as io;
import 'package:record/record.dart';

/// Service untuk menangani rekaman suara mikrofon menggunakan package `record`.
class AudioRecorderService {
  final AudioRecorder _recorder;
  bool _isRecording = false;
  String? _currentPath;

  AudioRecorderService({AudioRecorder? recorder})
      : _recorder = recorder ?? AudioRecorder();

  bool get isRecording => _isRecording;
  String? get currentPath => _currentPath;

  /// Memulai proses perekaman audio jika izin mikrofon diberikan
  Future<bool> startRecording() async {
    try {
      if (await _recorder.hasPermission()) {
        final tempDir = io.Directory.systemTemp;
        final path =
            '${tempDir.path}/rec_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _recorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: path,
        );
        _isRecording = true;
        _currentPath = path;
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// Menghentikan rekaman dan mengembalikan path file audio yang tersimpan
  Future<String?> stopRecording() async {
    try {
      if (_isRecording) {
        final path = await _recorder.stop();
        _isRecording = false;
        return path ?? _currentPath;
      }
    } catch (_) {}
    _isRecording = false;
    return null;
  }

  /// Membatalkan rekaman yang sedang berjalan dan menghapus file sementara
  Future<void> cancelRecording() async {
    try {
      if (_isRecording) {
        await _recorder.stop();
        _isRecording = false;
      }
      if (_currentPath != null) {
        final file = io.File(_currentPath!);
        if (await file.exists()) {
          await file.delete();
        }
        _currentPath = null;
      }
    } catch (_) {}
  }

  void dispose() {
    _recorder.dispose();
  }
}
