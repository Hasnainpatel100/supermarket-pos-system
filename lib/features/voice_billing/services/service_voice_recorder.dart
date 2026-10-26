import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class ServiceVoiceRecorder {
  AudioRecorder? _audioRecorder;
  AudioRecorder get _recorder => _audioRecorder ??= AudioRecorder();
  bool _isRecording = false;
  bool _isStreaming = false;
  String? _currentRecordingPath;

  StreamSubscription<Uint8List>? _streamSub;
  final BytesBuilder _pcmBuffer = BytesBuilder();

  bool get isRecording => _isRecording;
  bool get isStreaming => _isStreaming;
  String? get currentRecordingPath => _currentRecordingPath;

  Future<bool> hasPermission() async {
    try {
      return await _recorder.hasPermission();
    } catch (e) {
      debugPrint('Mic permission check error: $e');
      return true; // Desktop OSes grant mic implicitly or query via OS dialog
    }
  }

  /// Starts standard file recording
  Future<String?> start() async {
    try {
      final permitted = await hasPermission();
      if (!permitted) {
        debugPrint('Microphone permission not granted');
        return null;
      }

      final tempDir = await getTemporaryDirectory();
      final fileName = 'voice_order_${DateTime.now().millisecondsSinceEpoch}.wav';
      final filePath = p.join(tempDir.path, fileName);

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
        ),
        path: filePath,
      );

      _isRecording = true;
      _isStreaming = false;
      _currentRecordingPath = filePath;
      return filePath;
    } catch (e) {
      debugPrint('Recorder start error: $e');
      _isRecording = false;
      _isStreaming = false;
      return null;
    }
  }

  /// Starts streaming 16-bit PCM 16kHz mono audio chunks in real time
  Future<bool> startStreaming({
    required void Function(Uint8List chunk) onChunk,
  }) async {
    try {
      final permitted = await hasPermission();
      if (!permitted) {
        debugPrint('Microphone permission not granted');
        return false;
      }

      final tempDir = await getTemporaryDirectory();
      final fileName = 'voice_order_${DateTime.now().millisecondsSinceEpoch}.wav';
      _currentRecordingPath = p.join(tempDir.path, fileName);

      _pcmBuffer.clear();

      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
        ),
      );

      _isRecording = true;
      _isStreaming = true;

      _streamSub = stream.listen(
        (chunk) {
          _pcmBuffer.add(chunk);
          onChunk(chunk);
        },
        onError: (e) {
          debugPrint('Audio stream error: $e');
        },
      );

      return true;
    } catch (e) {
      debugPrint('Recorder startStreaming error: $e');
      _isRecording = false;
      _isStreaming = false;
      return false;
    }
  }

  /// Stops recording or streaming and returns the saved WAV file path
  Future<String?> stop() async {
    try {
      if (_isStreaming) {
        await _streamSub?.cancel();
        _streamSub = null;
        await _recorder.stop();
        _isRecording = false;
        _isStreaming = false;

        // Save accumulated PCM buffer into WAV file for backup/fallback
        final pcmBytes = _pcmBuffer.toBytes();
        if (pcmBytes.isNotEmpty && _currentRecordingPath != null) {
          final wavBytes = pcmToWav(pcmBytes);
          final file = File(_currentRecordingPath!);
          await file.writeAsBytes(wavBytes, flush: true);
          return _currentRecordingPath;
        }
        return _currentRecordingPath;
      }

      if (_isRecording) {
        final path = await _recorder.stop();
        _isRecording = false;
        _isStreaming = false;
        return path ?? _currentRecordingPath;
      }
    } catch (e) {
      debugPrint('Recorder stop error: $e');
    }
    _isRecording = false;
    _isStreaming = false;
    return _currentRecordingPath;
  }

  Future<void> cancel() async {
    try {
      await _streamSub?.cancel();
      _streamSub = null;
      await _recorder.cancel();
    } catch (e) {
      debugPrint('Recorder cancel error: $e');
    } finally {
      _isRecording = false;
      _isStreaming = false;
      _pcmBuffer.clear();
    }
  }

  void dispose() {
    try {
      _streamSub?.cancel();
      _streamSub = null;
      _audioRecorder?.dispose();
    } catch (_) {}
    _audioRecorder = null;
  }

  /// Converts raw 16-bit PCM bytes to a standard WAV audio format
  static Uint8List pcmToWav(
    Uint8List pcmData, {
    int sampleRate = 16000,
    int channels = 1,
    int bitsPerSample = 16,
  }) {
    final byteRate = sampleRate * channels * (bitsPerSample ~/ 8);
    final blockAlign = channels * (bitsPerSample ~/ 8);
    final totalDataLen = pcmData.length;
    final totalAudioLen = totalDataLen + 36;

    final header = ByteData(44);
    // RIFF
    header.setUint8(0, 0x52);
    header.setUint8(1, 0x49);
    header.setUint8(2, 0x46);
    header.setUint8(3, 0x46);
    header.setUint32(4, totalAudioLen, Endian.little);
    // WAVE
    header.setUint8(8, 0x57);
    header.setUint8(9, 0x41);
    header.setUint8(10, 0x56);
    header.setUint8(11, 0x45);
    // fmt
    header.setUint8(12, 0x66);
    header.setUint8(13, 0x6D);
    header.setUint8(14, 0x74);
    header.setUint8(15, 0x20);
    header.setUint32(16, 16, Endian.little);
    header.setUint16(20, 1, Endian.little); // PCM
    header.setUint16(22, channels, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, blockAlign, Endian.little);
    header.setUint16(34, bitsPerSample, Endian.little);
    // data
    header.setUint8(36, 0x64);
    header.setUint8(37, 0x61);
    header.setUint8(38, 0x74);
    header.setUint8(39, 0x61);
    header.setUint32(40, totalDataLen, Endian.little);

    final builder = BytesBuilder();
    builder.add(header.buffer.asUint8List());
    builder.add(pcmData);
    return builder.toBytes();
  }
}
