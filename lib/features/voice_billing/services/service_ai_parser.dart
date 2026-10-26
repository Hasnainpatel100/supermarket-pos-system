import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../../../service/service_storage.dart';
import '../models/model_voice_invoice.dart';
import '../models/model_voice_item.dart';
import 'service_gemini_live.dart';
import 'service_hinglish_transliteration.dart';

class ServiceAiParser {
  final ServiceStorage _storage = Get.find<ServiceStorage>();

  static const String keyStorageProvider = 'voice_ai_provider';
  static const String keyStorageGroqKey = 'groq_api_key';
  static const String keyStorageGeminiKey = 'gemini_api_key';

  String get savedGroqKey => _storage.readString(keyStorageGroqKey)?.trim() ?? '';
  String get savedGeminiKey => _storage.readString(keyStorageGeminiKey)?.trim() ?? '';

  String get activeProvider {
    final p = _storage.readString(keyStorageProvider)?.trim();
    if (p == 'groq' || p == 'gemini') return p!;
    if (savedGroqKey.isNotEmpty) return 'groq';
    return 'gemini';
  }

  bool get hasValidApiKey {
    if (activeProvider == 'groq') {
      return savedGroqKey.isNotEmpty;
    }
    return savedGeminiKey.isNotEmpty;
  }

  Future<void> saveSettings({
    required String provider,
    String? groqKey,
    String? geminiKey,
  }) async {
    await _storage.writeString(keyStorageProvider, provider);
    if (groqKey != null) {
      await _storage.writeString(keyStorageGroqKey, groqKey.trim());
    }
    if (geminiKey != null) {
      await _storage.writeString(keyStorageGeminiKey, geminiKey.trim());
    }
  }

  /// System prompt designed for Indian Retail & Pharmacy voice billing
  static const String _systemPrompt = '''
You are an intelligent Voice Billing AI Assistant for an Indian Supermarket & Pharmacy POS.
Extract customer details, items, quantities, weights, units, prices, taxes, and payment mode from the speech audio or text.
Supported languages: Hinglish, English, Marathi.

CRITICAL TRANSCRIBE IN HINGLISH ONLY RULE:
1. You MUST transcribe and output everything in ROMANIZED HINGLISH ONLY (Latin script / English letters).
2. NEVER output Devanagari script (NO हिंदी / देवनागरी वर्णमाला under any circumstances).
3. If the user speaks Hindi words, transcribe them phonetically into natural Hinglish.
   Example: User says "बासमती चावल 1 किलो 100 रुपये"
   -> "transcript": "basmati chawal 1 kilo 100rs"
   -> "item_name": "basmati chawal"
   -> "spoken_name": "basmati chawal"
   -> "quantity": 1.0, "unit": "kg", "price": 100.0

Rules:
1. Understand colloquial language in Hinglish:
   - "basmati chawal 1 kilo 100rs"
   - "2 packet maggi 24rs, 1 packet doodh 30rs"
   - "2 kilo cheeni, 1 packet doodh, Satyam ke naam se"
   - "Ramesh chya navane 2 kilo sakhar, ek puda tel"
   - "New invoice Alex, two coffees at 100 each, cash"
2. Weights & Units:
   - "aadha kilo" = 0.5 kg
   - "pav kilo" = 0.25 kg
   - "dedh kilo" = 1.5 kg
   - "dhai kilo" = 2.5 kg
   - "dabba", "packet", "puda", "batti", "strip", "bottle", "piece", "packet", "litre", "kg", "g", "ml"
3. Price & Tax:
   - If speaker says price (e.g., "100rs", "100 rupaye wala", "at 50 each"), extract as price.
   - If speaker says tax (e.g. "5 percent GST", "12% tax"), extract tax_rate.
4. Output STRICT JSON format only without markdown blocks:
{
  "transcript": "transcription in Romanized Hinglish (Latin alphabet only, e.g. 'basmati chawal 1 kilo 100rs')",
  "customer_name": "string or null",
  "customer_phone": "string or null",
  "payment_mode": "Cash" | "UPI" | "Card" | "Credit" | "Other",
  "notes": "string or null",
  "items": [
    {
      "item_name": "cleaned common product name in English or Hinglish (e.g. basmati chawal, maggi, sugar)",
      "spoken_name": "exact word spoken in Roman script e.g. basmati chawal, sakhar, cheeni, doodh",
      "quantity": 1.0,
      "unit": "kg" | "g" | "litre" | "ml" | "packet" | "piece" | "strip" | "box",
      "price": number or 0,
      "tax_rate": number or 0,
      "discount": number or 0
    }
  ]
}
''';

  /// Parses voice audio file via Groq Whisper or Gemini Multimodal
  Future<ModelVoiceInvoice> parseAudioFile(String audioFilePath, {String language = 'hi'}) async {
    final file = File(audioFilePath);
    if (!await file.exists()) {
      throw StateError('Audio file was not recorded successfully');
    }

    final provider = activeProvider;
    final groqKey = savedGroqKey;
    final geminiKey = savedGeminiKey;

    if (provider == 'groq' && groqKey.isNotEmpty) {
      final transcript = await _transcribeWithGroq(audioFilePath, groqKey, language: language);
      if (transcript.trim().isEmpty) {
        throw StateError('No speech was detected in the audio recording. Please speak clearly.');
      }
      try {
        final invoice = await _parseTranscriptWithGroq(transcript, groqKey, language: language);
        invoice.transcript = transcript;
        return invoice;
      } catch (e) {
        debugPrint('Groq LLM parsing failed ($e). Extracting order items with local NLP: "$transcript"');
        final invoice = _localNlpFallback(transcript, language);
        invoice.transcript = transcript;
        return invoice;
      }
    } else if (geminiKey.isNotEmpty) {
      try {
        return await _parseWithGemini(audioFilePath, geminiKey, language: language);
      } catch (e) {
        debugPrint('Gemini audio parse error: $e');
        if (groqKey.isNotEmpty) {
          try {
            debugPrint('Attempting backup audio transcription via Groq Whisper...');
            final transcript = await _transcribeWithGroq(audioFilePath, groqKey, language: language);
            final invoice = _localNlpFallback(transcript, language);
            invoice.transcript = transcript;
            return invoice;
          } catch (_) {}
        }
        rethrow;
      }
    } else if (groqKey.isNotEmpty) {
      final transcript = await _transcribeWithGroq(audioFilePath, groqKey, language: language);
      try {
        final invoice = await _parseTranscriptWithGroq(transcript, groqKey, language: language);
        invoice.transcript = transcript;
        return invoice;
      } catch (e) {
        debugPrint('Groq parse failed, falling back to local NLP: $e');
        final invoice = _localNlpFallback(transcript, language);
        invoice.transcript = transcript;
        return invoice;
      }
    } else {
      throw StateError('API_KEY_MISSING');
    }
  }

  /// Groq Cloud: Whisper Speech-to-Text
  Future<String> _transcribeWithGroq(String audioFilePath, String groqKey, {String language = 'hi'}) async {
    final uri = Uri.parse('https://api.groq.com/openai/v1/audio/transcriptions');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $groqKey';
    request.fields['model'] = 'whisper-large-v3-turbo';
    request.fields['response_format'] = 'json';
    request.fields['temperature'] = '0.0';
    request.fields['prompt'] = 'Transcribe in Romanized Hinglish script (Latin alphabet only, no Devanagari script). Example: "basmati chawal 1 kilo 100rs", "2 packet maggi 24rs", "ek kilo cheeni 45rs", "10 packet crunchies 10rs", "ramesh customer cash"';

    final ext = audioFilePath.split('.').last.toLowerCase();
    final contentType = ext == 'wav' ? MediaType('audio', 'wav') : MediaType('audio', 'm4a');

    request.files.add(await http.MultipartFile.fromPath(
      'file',
      audioFilePath,
      contentType: contentType,
    ));

    final streamed = await request.send().timeout(const Duration(seconds: 18));
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final rawText = (json['text'] ?? '').toString();
      return HinglishTransliteration.toHinglish(rawText);
    } else {
      final body = response.body;
      debugPrint('Groq Whisper error: ${response.statusCode} - $body');
      try {
        final errJson = jsonDecode(body);
        final msg = errJson['error']?['message'] ?? body;
        throw Exception('Groq Whisper (${response.statusCode}): $msg');
      } catch (e) {
        if (e is Exception && e.toString().contains('Groq Whisper')) rethrow;
        throw Exception('Groq Whisper Error (${response.statusCode})');
      }
    }
  }

  static String? _cachedWorkingGroqModel;

  static const List<String> _candidateGroqModels = [
    'openai/gpt-oss-120b',
    'openai/gpt-oss-20b',
    'qwen/qwen3.8-27b',
    'qwen/qwen3.6-27b',
    'llama-3.3-70b-versatile',
    'llama-3.1-8b-instant',
    'llama-3.1-70b-versatile',
  ];

  Future<List<String>> _discoverActiveGroqModels(String groqKey) async {
    try {
      final res = await http.get(
        Uri.parse('https://api.groq.com/openai/v1/models'),
        headers: {'Authorization': 'Bearer $groqKey'},
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = (data['data'] as List<dynamic>?)
            ?.map((m) => m['id']?.toString() ?? '')
            .where((id) => !id.contains('whisper') && !id.contains('guard') && id.isNotEmpty)
            .toList() ?? [];
        if (list.isNotEmpty) {
          debugPrint('Discovered ${list.length} active models from Groq: $list');
          return list;
        }
      }
    } catch (_) {}
    return [];
  }

  /// Groq Cloud: Multi-model resilient JSON parsing with live catalog discovery
  Future<ModelVoiceInvoice> _parseTranscriptWithGroq(
    String transcript,
    String groqKey, {
    String language = 'hi',
  }) async {
    final uri = Uri.parse('https://api.groq.com/openai/v1/chat/completions');

    final liveModels = await _discoverActiveGroqModels(groqKey);

    final modelsToTry = <String>[];
    if (_cachedWorkingGroqModel != null && _cachedWorkingGroqModel!.isNotEmpty) {
      modelsToTry.add(_cachedWorkingGroqModel!);
    }
    for (final m in liveModels) {
      if (!modelsToTry.contains(m)) modelsToTry.add(m);
    }
    for (final m in _candidateGroqModels) {
      if (!modelsToTry.contains(m)) modelsToTry.add(m);
    }

    String lastErrorMsg = '';

    for (final model in modelsToTry) {
      try {
        final requestBody = {
          'model': model,
          'messages': [
            {
              'role': 'system',
              'content': '$_systemPrompt\nLanguage: $language. Return strict JSON matching schema with transcript field.'
            },
            {
              'role': 'user',
              'content': 'Customer voice order: "$transcript"'
            }
          ],
          'temperature': 0.1,
        };

        final response = await http.post(
          uri,
          headers: {
            'Authorization': 'Bearer $groqKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(requestBody),
        ).timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final choices = data['choices'] as List<dynamic>?;
          if (choices != null && choices.isNotEmpty) {
            final content = choices[0]['message']?['content']?.toString() ?? '{}';
            final clean = _cleanJsonString(content);
            final map = jsonDecode(clean) as Map<String, dynamic>;
            map['transcript'] ??= transcript;
            _cachedWorkingGroqModel = model;
            return ModelVoiceInvoice.fromJson(map);
          }
        } else if (response.statusCode == 404 || response.statusCode == 400 || response.statusCode == 403) {
          final body = response.body;
          debugPrint('Groq model $model returned ${response.statusCode}: $body, trying next candidate model...');
          lastErrorMsg = 'Groq ($model ${response.statusCode}): $body';
          continue;
        } else {
          final body = response.body;
          throw Exception('Groq API Error (${response.statusCode}): $body');
        }
      } catch (e) {
        debugPrint('Groq model $model attempt error: $e');
        lastErrorMsg = e.toString();
        if (e.toString().contains('404') ||
            e.toString().contains('does not exist') ||
            e.toString().contains('access') ||
            e.toString().contains('decommissioned')) {
          continue;
        }
        rethrow;
      }
    }

    throw Exception('All Groq models failed: $lastErrorMsg');
  }

  static String? _cachedWorkingGeminiModel;

  static const List<String> _geminiCandidateModels = [
    'gemini-2.5-flash',
    'gemini-2.0-flash',
    'gemini-1.5-flash',
    'gemini-1.5-flash-latest',
    'gemini-1.5-flash-8b',
    'gemini-1.5-pro',
  ];

  Future<List<String>> _discoverActiveGeminiModels(String apiKey) async {
    try {
      final res = await http.get(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey'),
      ).timeout(const Duration(seconds: 3));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = (data['models'] as List<dynamic>?)
            ?.map((m) => m['name']?.toString().replaceFirst('models/', '') ?? '')
            .where((id) => (id.contains('flash') || id.contains('pro')) && !id.contains('live') && !id.contains('embedding') && id.isNotEmpty)
            .toList() ?? [];
        if (list.isNotEmpty) {
          debugPrint('Discovered ${list.length} active Gemini models: $list');
          return list;
        }
      }
    } catch (_) {}
    return [];
  }

  /// Tests Gemini Live WebSocket connection directly
  Future<bool> testGeminiLiveSession(String apiKey) async {
    final live = ServiceGeminiLiveTranscribe();
    try {
      final success = await live.startSession(
        apiKey: apiKey,
        model: 'gemini-3.5-transcribe-live',
        languageCodes: ['hi', 'en'],
      );
      await live.closeSession();
      return success;
    } catch (e) {
      debugPrint('Gemini live test error: $e');
      await live.closeSession();
      return false;
    }
  }

  /// Google Gemini Multimodal Audio Parsing
  Future<ModelVoiceInvoice> _parseWithGemini(String audioFilePath, String apiKey, {String language = 'hi'}) async {
    final bytes = await File(audioFilePath).readAsBytes();
    if (bytes.length < 500) {
      throw StateError('Audio recording was too short or empty. Please speak again.');
    }
    final base64Audio = base64Encode(bytes);

    String mimeType = 'audio/wav';
    final lower = audioFilePath.toLowerCase();
    if (lower.endsWith('.wav')) {
      mimeType = 'audio/wav';
    } else if (lower.endsWith('.mp3')) {
      mimeType = 'audio/mp3';
    } else if (lower.endsWith('.aac')) {
      mimeType = 'audio/aac';
    } else if (lower.endsWith('.m4a')) {
      mimeType = 'audio/mp4';
    }

    final modelsToTry = <String>[];
    if (_cachedWorkingGeminiModel != null && _cachedWorkingGeminiModel!.isNotEmpty) {
      modelsToTry.add(_cachedWorkingGeminiModel!);
    }
    for (final m in _geminiCandidateModels) {
      if (!modelsToTry.contains(m)) modelsToTry.add(m);
    }

    String lastErrorMsg = '';

    for (final model in modelsToTry) {
      try {
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
        );

        final requestBody = {
          'contents': [
            {
              'parts': [
                {'text': '$_systemPrompt\nThe speaker is speaking in $language.'},
                {
                  'inlineData': {
                    'mimeType': mimeType,
                    'data': base64Audio,
                  }
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.1,
            'responseMimeType': 'application/json',
          }
        };

        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestBody),
        ).timeout(const Duration(seconds: 18));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final candidates = data['candidates'] as List<dynamic>?;
          if (candidates != null && candidates.isNotEmpty) {
            final content = candidates[0]['content'];
            final parts = content['parts'] as List<dynamic>?;
            if (parts != null && parts.isNotEmpty) {
              final rawJson = parts[0]['text'].toString();
              final cleanJson = _cleanJsonString(rawJson);
              final invoiceMap = jsonDecode(cleanJson) as Map<String, dynamic>;
              _cachedWorkingGeminiModel = model;
              return ModelVoiceInvoice.fromJson(invoiceMap);
            }
          }
          throw Exception('Empty response from Gemini ($model)');
        } else {
          final body = response.body;
          debugPrint('Gemini model $model returned ${response.statusCode}: $body, trying next candidate...');
          lastErrorMsg = 'Gemini ($model ${response.statusCode}): $body';
          continue;
        }
      } catch (e) {
        debugPrint('Gemini model $model error: $e');
        lastErrorMsg = e.toString();
        continue;
      }
    }

    throw Exception('All Gemini models failed: $lastErrorMsg');
  }

  /// Parses text query via Groq, Gemini, or fallback NLP
  Future<ModelVoiceInvoice> parseTextWithFallback(String transcript, {String language = 'hinglish'}) async {
    final hinglishTranscript = HinglishTransliteration.toHinglish(transcript);
    if (hinglishTranscript.trim().isEmpty) {
      return ModelVoiceInvoice(items: []);
    }

    final provider = activeProvider;
    final groqKey = savedGroqKey;
    final geminiKey = savedGeminiKey;

    if (provider == 'groq' && groqKey.isNotEmpty) {
      try {
        final inv = await _parseTranscriptWithGroq(hinglishTranscript, groqKey, language: language);
        inv.transcript = hinglishTranscript;
        return inv;
      } catch (e) {
        debugPrint('Groq text parsing error: $e');
      }
    } else if (geminiKey.isNotEmpty) {
      try {
        final inv = await _parseTextWithGemini(hinglishTranscript, geminiKey, language: language);
        inv.transcript = hinglishTranscript;
        return inv;
      } catch (e) {
        debugPrint('Gemini text parsing error: $e');
      }
    }

    // Smart Local Offline Regex Parser
    final inv = _localNlpFallback(hinglishTranscript, language);
    inv.transcript = hinglishTranscript;
    return inv;
  }

  Future<ModelVoiceInvoice> _parseTextWithGemini(String transcript, String apiKey, {String language = 'hi'}) async {
    final liveModels = await _discoverActiveGeminiModels(apiKey);

    final modelsToTry = <String>[];
    if (_cachedWorkingGeminiModel != null && _cachedWorkingGeminiModel!.isNotEmpty) {
      modelsToTry.add(_cachedWorkingGeminiModel!);
    }
    for (final m in liveModels) {
      if (!modelsToTry.contains(m)) modelsToTry.add(m);
    }
    for (final m in _geminiCandidateModels) {
      if (!modelsToTry.contains(m)) modelsToTry.add(m);
    }

    String lastErrorMsg = '';

    for (final model in modelsToTry) {
      try {
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
        );

        final requestBody = {
          'contents': [
            {
              'parts': [
                {'text': '$_systemPrompt\nLanguage: $language\nUser spoken input: "$transcript"'}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.1,
            'responseMimeType': 'application/json',
          }
        };

        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestBody),
        ).timeout(const Duration(seconds: 12));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final candidates = data['candidates'] as List<dynamic>?;
          if (candidates != null && candidates.isNotEmpty) {
            final content = candidates[0]['content'];
            final parts = content['parts'] as List<dynamic>?;
            if (parts != null && parts.isNotEmpty) {
              final rawJson = parts[0]['text'].toString();
              final cleanJson = _cleanJsonString(rawJson);
              final invoiceMap = jsonDecode(cleanJson) as Map<String, dynamic>;
              invoiceMap['transcript'] ??= transcript;
              _cachedWorkingGeminiModel = model;
              return ModelVoiceInvoice.fromJson(invoiceMap);
            }
          }
        } else {
          debugPrint('Gemini text model $model returned ${response.statusCode}, trying next candidate...');
          lastErrorMsg = 'Gemini ($model ${response.statusCode})';
          continue;
        }
      } catch (e) {
        lastErrorMsg = e.toString();
        continue;
      }
    }

    throw Exception('Gemini text recognition failed: $lastErrorMsg');
  }

  /// Cleans markdown ```json blocks from model response
  String _cleanJsonString(String raw) {
    var s = raw.trim();
    if (s.startsWith('```json')) {
      s = s.substring(7);
    } else if (s.startsWith('```')) {
      s = s.substring(3);
    }
    if (s.endsWith('```')) {
      s = s.substring(0, s.length - 3);
    }
    return s.trim();
  }

  /// Smart local rule-based entity extractor (Works 100% offline without API key)
  ModelVoiceInvoice _localNlpFallback(String text, String language) {
    // 0. Transliterate all Hindi/Devanagari text to natural Roman Hinglish
    final normalizedText = HinglishTransliteration.toHinglish(text);

    final lower = normalizedText.toLowerCase();
    String? customerName;
    String? customerPhone;
    String paymentMode = 'Cash';

    // 1. Payment mode detection
    if (lower.contains('upi') || lower.contains('gpay') || lower.contains('phonepe') || lower.contains('paytm') || lower.contains('online')) {
      paymentMode = 'UPI';
    } else if (lower.contains('card') || lower.contains('debit') || lower.contains('credit card')) {
      paymentMode = 'Card';
    } else if (lower.contains('udhar') || lower.contains('khata') || lower.contains('credit')) {
      paymentMode = 'Credit';
    }

    // 2. Customer Name detection
    final hindiCustMatch = RegExp(r'([a-zA-Z\u0900-\u097F]+)\s*(?:ke\s*naam\s*se|ka\s*bill|ke\s*liye)', caseSensitive: false).firstMatch(normalizedText);
    final marathiCustMatch = RegExp(r'([a-zA-Z\u0900-\u097F]+)\s*(?:chya\s*navane|chya\s*navani|che\s*bill)', caseSensitive: false).firstMatch(normalizedText);
    final engCustMatch = RegExp(r'(?:customer|client|for|name\s*is)\s+([a-zA-Z]+)', caseSensitive: false).firstMatch(normalizedText);

    if (hindiCustMatch != null) {
      customerName = hindiCustMatch.group(1);
    } else if (marathiCustMatch != null) {
      customerName = marathiCustMatch.group(1);
    } else if (engCustMatch != null) {
      customerName = engCustMatch.group(1);
    }

    // 3. Customer Phone (10 digits)
    final phoneMatch = RegExp(r'\b[6-9]\d{9}\b').firstMatch(normalizedText);
    if (phoneMatch != null) {
      customerPhone = phoneMatch.group(0);
    }

    // 4. Extract Items & Quantities
    final items = <ModelVoiceItem>[];

    // Split speech into clauses (separated by '।', ';', '\n', or 'and' / 'aur')
    final clauses = normalizedText
        .split(RegExp(r'[।;\n]|\s+aur\s+|\s+and\s+', caseSensitive: false))
        .map((c) => c.trim())
        .where((c) => c.isNotEmpty)
        .toList();

    for (final clause in clauses) {
      // Dynamic pattern for: "<Item Name>, <Qty> <Unit>, <Price> रुपये"
      // e.g. "बासमती चावल, 1 किलो, 100 रुपये किलो"
      // e.g. "क्रंचीस, 10 पैकेट, 1 पैकेट 10 रुपये"
      double qty = 1.0;
      String unit = 'packet';
      double price = 0.0;

      // Extract price
      final priceMatch = RegExp(r'(\d+(?:\.\d+)?)\s*(?:रुपये|रुपए|rupaye|rupees|rs|रु|₹)', caseSensitive: false).firstMatch(clause);
      if (priceMatch != null) {
        price = double.tryParse(priceMatch.group(1)!) ?? 0.0;
      }

      // Extract quantity and unit
      final qtyUnitMatch = RegExp(r'(\d+(?:\.\d+)?)\s*(किलो|kg|पैकेट|packet|लीटर|litre|लीटर|ग्राम|gm|g|पीस|piece|pcs|strip|box|पैक)', caseSensitive: false).firstMatch(clause);
      if (qtyUnitMatch != null) {
        qty = double.tryParse(qtyUnitMatch.group(1)!) ?? 1.0;
        final rawUnit = qtyUnitMatch.group(2)!.toLowerCase();
        if (rawUnit.contains('किलो') || rawUnit.contains('kg')) {
          unit = 'kg';
        } else if (rawUnit.contains('लीटर') || rawUnit.contains('litre')) {
          unit = 'litre';
        } else if (rawUnit.contains('ग्राम') || rawUnit.contains('gm') || rawUnit == 'g') {
          unit = 'g';
        } else if (rawUnit.contains('पैकेट') || rawUnit.contains('packet') || rawUnit.contains('पैक')) {
          unit = 'packet';
        } else if (rawUnit.contains('पीस') || rawUnit.contains('piece') || rawUnit.contains('pcs')) {
          unit = 'piece';
        } else if (rawUnit.contains('strip')) {
          unit = 'strip';
        }
      } else {
        if (clause.contains('aadha kilo') || clause.contains('आधा किलो')) {
          qty = 0.5;
          unit = 'kg';
        } else if (clause.contains('pav kilo') || clause.contains('पाव किलो')) {
          qty = 0.25;
          unit = 'kg';
        }
      }

      // Extract Item Name by removing quantity, unit, price, and commas from clause
      var cleanItem = clause
          .replaceAll(RegExp(r'\d+(?:\.\d+)?\s*(?:रुपये|रुपए|rupaye|rupees|rs|रु|₹|\/|-)?(?:\s*(?:किलो|kg|पैकेट|packet|piece))?', caseSensitive: false), '')
          .replaceAll(RegExp(r'\d+(?:\.\d+)?\s*(?:किलो|kg|पैकेट|packet|लीटर|litre|लीटर|ग्राम|gm|g|पीस|piece|pcs|strip|box|पैक)', caseSensitive: false), '')
          .replaceAll(RegExp(r'[,\.\-]', caseSensitive: false), ' ')
          .trim();

      // Clean up extra spaces
      cleanItem = cleanItem.replaceAll(RegExp(r'\s+'), ' ').trim();

      if (cleanItem.isNotEmpty && cleanItem.length >= 2 && !cleanItem.contains('total') && !cleanItem.contains('bill')) {
        items.add(ModelVoiceItem(
          itemName: cleanItem,
          spokenName: cleanItem,
          quantity: qty,
          unit: unit,
          price: price,
          mrp: price > 0 ? price : 0.0,
          taxRate: 0.0,
        ));
      }
    }

    // Fallback if clause splitting didn't produce items
    if (items.isEmpty && normalizedText.trim().isNotEmpty) {
      items.add(ModelVoiceItem(
        itemName: normalizedText.length > 25 ? '${normalizedText.substring(0, 25)}...' : normalizedText,
        spokenName: normalizedText,
        quantity: 1.0,
        unit: 'packet',
        price: 0.0,
        taxRate: 0.0,
      ));
    }

    final invoice = ModelVoiceInvoice(
      transcript: normalizedText,
      customerName: customerName,
      customerPhone: customerPhone,
      paymentMode: paymentMode,
      items: items,
    );
    invoice.recalculate();
    return invoice;
  }
}
