import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../../../service/service_storage.dart';
import '../models/model_voice_invoice.dart';
import '../models/model_voice_item.dart';

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
Supported languages: Hindi, Hinglish, Marathi, English.

Rules:
1. Understand colloquial language:
   - Hindi/Hinglish: "2 kilo cheeni, 1 packet doodh, Satyam ke naam se"
   - Marathi: "Ramesh chya navane 2 kilo sakhar, ek puda tel, don dolo 650 dya"
   - English: "New invoice Alex, two coffees at 100 each, one sandwich at 150, cash"
2. Weights & Units:
   - "aadha kilo" / "ardha kilo" = 0.5 kg
   - "pav kilo" = 0.25 kg
   - "dedh kilo" = 1.5 kg
   - "dhai kilo" = 2.5 kg
   - "dabba", "packet", "puda", "batti", "strip", "bottle", "piece", "packet", "litre", "kg", "g", "ml"
3. Price & Tax:
   - If speaker says price (e.g., "100 rupaye wala", "at 50 each"), extract as price.
   - If speaker says tax (e.g. "5 percent GST", "12% tax"), extract tax_rate.
4. Output STRICT JSON format only without markdown blocks:
{
  "transcript": "exact transcription of what the speaker said in original language or script",
  "customer_name": "string or null",
  "customer_phone": "string or null",
  "payment_mode": "Cash" | "UPI" | "Card" | "Credit" | "Other",
  "notes": "string or null",
  "items": [
    {
      "item_name": "cleaned common product name in English or standard name",
      "spoken_name": "exact word spoken e.g. sakhar, cheeni, doodh",
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
      final invoice = await _parseTranscriptWithGroq(transcript, groqKey, language: language);
      invoice.transcript = transcript;
      return invoice;
    } else if (geminiKey.isNotEmpty) {
      return _parseWithGemini(audioFilePath, geminiKey, language: language);
    } else if (groqKey.isNotEmpty) {
      final transcript = await _transcribeWithGroq(audioFilePath, groqKey, language: language);
      try {
        final invoice = await _parseTranscriptWithGroq(transcript, groqKey, language: language);
        invoice.transcript = transcript;
        return invoice;
      } catch (e) {
        debugPrint('Groq LLaMA parse failed, falling back to local NLP: $e');
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
      return (json['text'] ?? '').toString();
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
    'llama-3.1-8b-instant',
    'llama-3.3-70b-versatile',
    'llama-3.1-70b-versatile',
    'llama3-70b-8192',
    'llama3-8b-8192',
    'mixtral-8x7b-32768',
    'gemma2-9b-it',
  ];

  /// Groq Cloud: Multi-model resilient JSON parsing
  Future<ModelVoiceInvoice> _parseTranscriptWithGroq(
    String transcript,
    String groqKey, {
    String language = 'hi',
  }) async {
    final uri = Uri.parse('https://api.groq.com/openai/v1/chat/completions');

    final modelsToTry = <String>[];
    if (_cachedWorkingGroqModel != null && _cachedWorkingGroqModel!.isNotEmpty) {
      modelsToTry.add(_cachedWorkingGroqModel!);
    }
    for (final m in _candidateGroqModels) {
      if (!modelsToTry.contains(m)) {
        modelsToTry.add(m);
      }
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
          'response_format': {'type': 'json_object'},
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
          throw Exception('Empty response from Groq LLaMA ($model)');
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
            e.toString().contains('access')) {
          continue;
        }
        rethrow;
      }
    }

    throw Exception('All Groq models failed: $lastErrorMsg');
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

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey',
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
          return ModelVoiceInvoice.fromJson(invoiceMap);
        }
      }
      throw Exception('Empty response from Gemini AI');
    } else {
      final body = response.body;
      debugPrint('Gemini Audio API error: ${response.statusCode} - $body');
      try {
        final errJson = jsonDecode(body);
        final msg = errJson['error']?['message'] ?? body;
        throw Exception('Gemini API (${response.statusCode}): $msg');
      } catch (e) {
        if (e is Exception && e.toString().contains('Gemini API')) rethrow;
        throw Exception('Gemini API Error (${response.statusCode})');
      }
    }
  }

  /// Parses text query via Groq, Gemini, or fallback NLP
  Future<ModelVoiceInvoice> parseTextWithFallback(String transcript, {String language = 'hi'}) async {
    if (transcript.trim().isEmpty) {
      return ModelVoiceInvoice(items: []);
    }

    final provider = activeProvider;
    final groqKey = savedGroqKey;
    final geminiKey = savedGeminiKey;

    if (provider == 'groq' && groqKey.isNotEmpty) {
      try {
        final inv = await _parseTranscriptWithGroq(transcript, groqKey, language: language);
        inv.transcript = transcript;
        return inv;
      } catch (e) {
        debugPrint('Groq text parsing error: $e');
      }
    } else if (geminiKey.isNotEmpty) {
      try {
        return await _parseTextWithGemini(transcript, geminiKey, language: language);
      } catch (e) {
        debugPrint('Gemini text parsing error: $e');
      }
    }

    // Smart Local Offline Regex Parser
    return _localNlpFallback(transcript, language);
  }

  Future<ModelVoiceInvoice> _parseTextWithGemini(String transcript, String apiKey, {String language = 'hi'}) async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey',
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
          return ModelVoiceInvoice.fromJson(invoiceMap);
        }
      }
    }
    throw Exception('Gemini text recognition failed (${response.statusCode})');
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
    final lower = text.toLowerCase();
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
    final hindiCustMatch = RegExp(r'([a-zA-Z\u0900-\u097F]+)\s*(?:ke\s*naam\s*se|ka\s*bill|ke\s*liye)', caseSensitive: false).firstMatch(text);
    final marathiCustMatch = RegExp(r'([a-zA-Z\u0900-\u097F]+)\s*(?:chya\s*navane|chya\s*navani|che\s*bill)', caseSensitive: false).firstMatch(text);
    final engCustMatch = RegExp(r'(?:customer|client|for|name\s*is)\s+([a-zA-Z]+)', caseSensitive: false).firstMatch(text);

    if (hindiCustMatch != null) {
      customerName = hindiCustMatch.group(1);
    } else if (marathiCustMatch != null) {
      customerName = marathiCustMatch.group(1);
    } else if (engCustMatch != null) {
      customerName = engCustMatch.group(1);
    }

    // 3. Customer Phone (10 digits)
    final phoneMatch = RegExp(r'\b[6-9]\d{9}\b').firstMatch(text);
    if (phoneMatch != null) {
      customerPhone = phoneMatch.group(0);
    }

    // 4. Extract Items & Quantities
    final items = <ModelVoiceItem>[];

    final itemVocab = [
      {'key': 'Sugar', 'matches': ['sugar', 'sakhar', 'cheeni', 'chini', 'साखर', 'चीनी'], 'unit': 'kg', 'price': 45.0, 'tax': 5.0},
      {'key': 'Milk', 'matches': ['milk', 'doodh', 'dudh', 'दूध', 'दुध'], 'unit': 'packet', 'price': 32.0, 'tax': 0.0},
      {'key': 'Cooking Oil', 'matches': ['oil', 'tel', 'tail', 'तेल'], 'unit': 'litre', 'price': 140.0, 'tax': 5.0},
      {'key': 'Rice', 'matches': ['rice', 'chawal', 'tandul', 'चावल', 'तांदूळ'], 'unit': 'kg', 'price': 60.0, 'tax': 5.0},
      {'key': 'Wheat Flour (Atta)', 'matches': ['atta', 'gehu', 'gahu', 'flour', 'आटा', 'गहू'], 'unit': 'kg', 'price': 40.0, 'tax': 5.0},
      {'key': 'Tea (Chai)', 'matches': ['tea', 'chai', 'chaha', 'patti', 'चाय', 'चहा'], 'unit': 'packet', 'price': 110.0, 'tax': 5.0},
      {'key': 'Coffee', 'matches': ['coffee', 'कॉफी'], 'unit': 'piece', 'price': 100.0, 'tax': 18.0},
      {'key': 'Bread', 'matches': ['bread', 'ब्रेड'], 'unit': 'packet', 'price': 40.0, 'tax': 0.0},
      {'key': 'Sandwich', 'matches': ['sandwich', 'सैंडविच'], 'unit': 'piece', 'price': 150.0, 'tax': 5.0},
      {'key': 'Soap', 'matches': ['soap', 'sabun', 'saban', 'साबण', 'साबुन'], 'unit': 'piece', 'price': 35.0, 'tax': 18.0},
      {'key': 'Salt', 'matches': ['salt', 'namak', 'meeth', 'मीठ', 'नमक'], 'unit': 'packet', 'price': 25.0, 'tax': 0.0},
      {'key': 'Paracetamol 650', 'matches': ['paracetamol', 'dolo', 'dolo 650', 'dolo650', 'paracitamol'], 'unit': 'strip', 'price': 30.0, 'tax': 12.0},
    ];

    for (final v in itemVocab) {
      final nameMatches = v['matches'] as List<String>;
      for (final matchWord in nameMatches) {
        if (lower.contains(matchWord.toLowerCase())) {
          double qty = 1.0;
          String unit = v['unit'] as String;

          if (lower.contains('aadha kilo') || lower.contains('ardha kilo') || lower.contains('आधा किलो')) {
            qty = 0.5;
            unit = 'kg';
          } else if (lower.contains('pav kilo') || lower.contains('पाव किलो')) {
            qty = 0.25;
            unit = 'kg';
          } else if (lower.contains('dedh kilo') || lower.contains('दीड किलो')) {
            qty = 1.5;
            unit = 'kg';
          } else {
            final qtyRegex = RegExp(r'(\d+(?:\.\d+)?)\s*(?:kilo|kg|packet|pack|ltr|litre|piece|pcs|strip|किलो|पैकेट|लिटर)?\s*' + RegExp.escape(matchWord), caseSensitive: false);
            final m = qtyRegex.firstMatch(text);
            if (m != null && m.group(1) != null) {
              qty = double.tryParse(m.group(1)!) ?? 1.0;
            } else {
              if (lower.contains('do $matchWord') || lower.contains('don $matchWord') || lower.contains('two $matchWord') || lower.contains('२ $matchWord') || lower.contains('2 $matchWord')) {
                qty = 2.0;
              } else if (lower.contains('teen $matchWord') || lower.contains('three $matchWord') || lower.contains('3 $matchWord')) {
                qty = 3.0;
              } else if (lower.contains('char $matchWord') || lower.contains('four $matchWord') || lower.contains('4 $matchWord')) {
                qty = 4.0;
              } else if (lower.contains('paanch $matchWord') || lower.contains('five $matchWord') || lower.contains('5 $matchWord')) {
                qty = 5.0;
              }
            }
          }

          double price = v['price'] as double;
          final priceRegex = RegExp(RegExp.escape(matchWord) + r'(?:\s+at|\s+wale|\s+wali)?\s+(\d+(?:\.\d+)?)\s*(?:rs|rupees|rupaye|रुपये)?', caseSensitive: false);
          final pm = priceRegex.firstMatch(text);
          if (pm != null && pm.group(1) != null) {
            price = double.tryParse(pm.group(1)!) ?? price;
          }

          items.add(ModelVoiceItem(
            itemName: v['key'] as String,
            spokenName: matchWord,
            quantity: qty,
            unit: unit,
            price: price,
            mrp: price,
            taxRate: v['tax'] as double,
          ));
          break;
        }
      }
    }

    if (items.isEmpty && text.trim().isNotEmpty) {
      items.add(ModelVoiceItem(
        itemName: text.length > 25 ? '${text.substring(0, 25)}...' : text,
        spokenName: text,
        quantity: 1.0,
        unit: 'pcs',
        price: 100.0,
        taxRate: 5.0,
      ));
    }

    final invoice = ModelVoiceInvoice(
      transcript: text,
      customerName: customerName,
      customerPhone: customerPhone,
      paymentMode: paymentMode,
      items: items,
    );
    invoice.recalculate();
    return invoice;
  }
}
