import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'service_hinglish_transliteration.dart';

/// Gemini 3.5 Transcribe Live Service
/// Connects to Google GenAI Live API over WebSockets for low-latency, real-time speech-to-text.
class ServiceGeminiLiveTranscribe {
  static const String defaultModel = 'gemini-3.5-transcribe-live';
  static const String liveEndpointV1Beta =
      'wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent';
  static const String liveEndpointV1Alpha =
      'wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1alpha.GenerativeService.BidiGenerateContent';

  WebSocket? _webSocket;
  StreamSubscription? _wsSubscription;

  bool _isConnected = false;
  bool _isSessionSetup = false;
  final StringBuffer _finalTranscriptBuffer = StringBuffer();
  String _currentInterimTranscript = '';

  // Callbacks
  void Function(String interimText)? onInterimTranscript;
  void Function(String finalText)? onFinalTranscript;
  void Function(String statusMessage)? onStatusChange;
  void Function(dynamic error)? onError;

  bool get isConnected => _isConnected && _webSocket != null;
  bool get isSessionSetup => _isSessionSetup;
  String get currentInterim => _currentInterimTranscript;
  String get finalTranscript => _finalTranscriptBuffer.toString().trim();

  /// Starts a real-time live transcription session over WebSockets
  Future<bool> startSession({
    required String apiKey,
    String model = defaultModel,
    List<String>? languageCodes,
    String mode = 'SMART',
  }) async {
    await closeSession();
    _finalTranscriptBuffer.clear();
    _currentInterimTranscript = '';

    if (apiKey.trim().isEmpty) {
      onError?.call('Gemini API key is required');
      return false;
    }

    final cleanKey = apiKey.trim();

    // Try v1beta first, fallback to v1alpha
    final endpoints = [
      '$liveEndpointV1Beta?key=$cleanKey',
      '$liveEndpointV1Alpha?key=$cleanKey',
    ];

    for (final url in endpoints) {
      try {
        debugPrint('[Gemini Live] Connecting to WebSocket endpoint...');
        onStatusChange?.call('Connecting to Gemini 3.5 Transcribe Live...');

        _webSocket = await WebSocket.connect(url).timeout(
          const Duration(seconds: 8),
        );
        _isConnected = true;
        _isSessionSetup = false;

        debugPrint('[Gemini Live] WebSocket connection established.');

        final completer = Completer<bool>();

        _wsSubscription = _webSocket!.listen(
          (message) {
            _handleIncomingMessage(message, completer);
          },
          onError: (err) {
            debugPrint('[Gemini Live] WebSocket error: $err');
            _isConnected = false;
            _isSessionSetup = false;
            onError?.call(err);
            if (!completer.isCompleted) completer.complete(false);
          },
          onDone: () {
            debugPrint('[Gemini Live] WebSocket closed by server (code: ${_webSocket?.closeCode}, reason: ${_webSocket?.closeReason})');
            _isConnected = false;
            _isSessionSetup = false;
            if (!completer.isCompleted) completer.complete(false);
          },
        );

        // Send Setup handshake message
        // Formatted identically to Google GenAI SDK LiveConnectConfig:
        final setupPayload = {
          'setup': {
            'model': model.startsWith('models/') ? model : 'models/$model',
            'generationConfig': {
              'responseModalities': ['TEXT'],
            },
            'inputAudioTranscription': {
              'mode': mode,
              'languageCodes': languageCodes ?? [],
            },
          },
        };

        final jsonString = jsonEncode(setupPayload);
        _webSocket!.add(jsonString);
        debugPrint('[Gemini Live] Sent setup configuration for $model');

        // Wait up to 5 seconds for setup confirmation or first response
        final ready = await completer.future.timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            // Even if setupComplete frame was not explicitly sent, proceed if socket is open
            debugPrint('[Gemini Live] Setup confirmation timeout; assuming connected.');
            return _isConnected;
          },
        );

        if (ready) {
          _isSessionSetup = true;
          onStatusChange?.call('Live Transcription connected. Listening...');
          return true;
        }
      } catch (e) {
        debugPrint('[Gemini Live] Connection attempt failed ($url): $e');
        await closeSession();
      }
    }

    onError?.call('Could not connect to Gemini Live Transcription service.');
    return false;
  }

  /// Sends a raw 16-bit PCM 16kHz mono audio chunk to the Gemini Live session
  void sendAudioChunk(Uint8List pcmChunk) {
    if (!_isConnected || _webSocket == null) return;

    try {
      final base64Audio = base64Encode(pcmChunk);
      final payload = {
        'realtimeInput': {
          'mediaChunks': [
            {
              'mimeType': 'audio/pcm;rate=16000',
              'data': base64Audio,
            }
          ],
        },
      };

      _webSocket!.add(jsonEncode(payload));
    } catch (e) {
      debugPrint('[Gemini Live] Error sending audio chunk: $e');
    }
  }

  /// Informs server of audio stream conclusion
  void sendAudioStreamEnd() {
    if (!_isConnected || _webSocket == null) return;
    try {
      final payload = {
        'realtimeInput': {
          'audioStreamEnd': true,
        },
      };
      _webSocket!.add(jsonEncode(payload));
    } catch (e) {
      debugPrint('[Gemini Live] Error sending stream end: $e');
    }
  }

  /// Handles incoming server JSON messages
  void _handleIncomingMessage(dynamic message, Completer<bool> setupCompleter) {
    try {
      String jsonStr;
      if (message is String) {
        jsonStr = message;
      } else if (message is List<int>) {
        jsonStr = utf8.decode(message);
      } else {
        return;
      }

      final data = jsonDecode(jsonStr);
      if (data is! Map<String, dynamic>) return;

      // Check for setup completion
      if (data.containsKey('setupComplete') || data.containsKey('setup_complete')) {
        debugPrint('[Gemini Live] Handshake setup complete.');
        _isSessionSetup = true;
        if (!setupCompleter.isCompleted) setupCompleter.complete(true);
        return;
      }

      // If any server response is received, handshake is implicitly succeeded
      if (!setupCompleter.isCompleted) {
        setupCompleter.complete(true);
      }

      final serverContent = data['serverContent'] ?? data['server_content'];
      if (serverContent is Map<String, dynamic>) {
        // 1. Interim hypothesis (live caption preview while speaking)
        final interim = serverContent['interimInputTranscription'] ??
            serverContent['interim_input_transcription'];
        if (interim is Map<String, dynamic>) {
          final text = (interim['text'] ?? '').toString();
          if (text.isNotEmpty) {
            final hinglishText = HinglishTransliteration.toHinglish(text);
            _currentInterimTranscript = hinglishText;
            onInterimTranscript?.call(hinglishText);
          }
        }

        // 2. Finalized transcript segment
        final finalized = serverContent['inputTranscription'] ??
            serverContent['input_transcription'];
        if (finalized is Map<String, dynamic>) {
          final text = (finalized['text'] ?? '').toString();
          if (text.isNotEmpty) {
            final hinglishText = HinglishTransliteration.toHinglish(text);
            if (_finalTranscriptBuffer.isNotEmpty) {
              _finalTranscriptBuffer.write(' ');
            }
            _finalTranscriptBuffer.write(hinglishText);
            _currentInterimTranscript = '';
            onFinalTranscript?.call(hinglishText);
          }
        }

        // 3. Model Turn text (if model output text)
        final modelTurn = serverContent['modelTurn'] ?? serverContent['model_turn'];
        if (modelTurn is Map<String, dynamic>) {
          final parts = modelTurn['parts'] as List<dynamic>?;
          if (parts != null) {
            for (final part in parts) {
              if (part is Map<String, dynamic> && part['text'] != null) {
                final text = part['text'].toString().trim();
                if (text.isNotEmpty) {
                  final hinglishText = HinglishTransliteration.toHinglish(text);
                  if (_finalTranscriptBuffer.isNotEmpty) {
                    _finalTranscriptBuffer.write(' ');
                  }
                  _finalTranscriptBuffer.write(hinglishText);
                  onFinalTranscript?.call(hinglishText);
                }
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[Gemini Live] Message parse error: $e');
    }
  }

  /// Closes session cleanly and returns complete final transcript
  Future<String> stopSession() async {
    sendAudioStreamEnd();
    // Allow brief grace period for pending transcript frames
    await Future.delayed(const Duration(milliseconds: 300));
    final result = finalTranscript;
    await closeSession();
    return result;
  }

  /// Cancels and closes WebSocket session
  Future<void> closeSession() async {
    _isConnected = false;
    _isSessionSetup = false;
    try {
      await _wsSubscription?.cancel();
    } catch (_) {}
    _wsSubscription = null;

    try {
      await _webSocket?.close();
    } catch (_) {}
    _webSocket = null;
  }

  void dispose() {
    closeSession();
  }
}
