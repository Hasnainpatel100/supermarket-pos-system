import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class ServiceVoiceRecorder {
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  String? _currentRecordingPath;

  bool get isRecording => _isRecording;
  String? get currentRecordingPath => _currentRecordingPath;

  Future<bool> hasPermission() async {
    try {
      return await _audioRecorder.hasPermission();
    } catch (e) {
      debugPrint('Mic permission check error: $e');
      return true; // Many desktop OSes grant mic implicitly or query via OS dialog
    }
  }

  Future<String?> start() async {
    try {
      final permitted = await hasPermission();
      if (!permitted) {
        debugPrint('Microphone permission not granted');
        return null;
      }

      final tempDir = await getTemporaryDirectory();
      final fileName = 'voice_order_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final filePath = p.join(tempDir.path, fileName);

      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: filePath,
      );

      _isRecording = true;
      _currentRecordingPath = filePath;
      return filePath;
    } catch (e) {
      debugPrint('Recorder start error: $e');
      _isRecording = false;
      return null;
    }
  }

  Future<String?> stop() async {
    try {
      if (_isRecording) {
        final path = await _audioRecorder.stop();
        _isRecording = false;
        return path ?? _currentRecordingPath;
      }
    } catch (e) {
      debugPrint('Recorder stop error: $e');
    }
    _isRecording = false;
    return _currentRecordingPath;
  }

  Future<void> cancel() async {
    try {
      await _audioRecorder.cancel();
    } catch (e) {
      debugPrint('Recorder cancel error: $e');
    } finally {
      _isRecording = false;
    }
  }

  void dispose() {
    try {
      _audioRecorder.dispose();
    } catch (_) {}
  }
}
