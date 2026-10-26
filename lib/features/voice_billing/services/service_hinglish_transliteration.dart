/// High-Performance Devanagari to Roman Hinglish Transliteration Engine
/// Converts spoken Hindi/Devanagari text into natural Romanized Hinglish
/// e.g. "बासमती चावल, 1 किलो, 100 रुपये" -> "basmati chawal 1 kilo 100rs"
class HinglishTransliteration {
  // Common grocery, POS, supermarket, number, and conversational vocabulary
  static const Map<String, String> _wordDictionary = {
    // Grains, Rice, Flours & Pulses
    'बासमती': 'basmati',
    'चावल': 'chawal',
    'चांवल': 'chawal',
    'भात': 'bhaat',
    'आटा': 'aata',
    'गेहूं': 'gehu',
    'मैदा': 'maida',
    'सूजी': 'sooji',
    'रवा': 'rawa',
    'बेसन': 'besan',
    'पोहा': 'poha',
    'दाल': 'dal',
    'दालें': 'daalein',
    'मूंग': 'moong',
    'चना': 'chana',
    'चने': 'chane',
    'छोले': 'chhole',
    'राजमा': 'rajma',
    'उड़द': 'urad',
    'तुअर': 'toor',
    'अरहर': 'toor',
    'मसूर': 'masoor',

    // Sugar, Salt, Spices & Oils
    'चीनी': 'cheeni',
    'शक्कर': 'sakhar',
    'गुड़': 'gud',
    'नमक': 'namak',
    'तेल': 'tel',
    'सरसों': 'sarson',
    'रिफाइंड': 'refined',
    'घी': 'ghee',
    'हल्दी': 'haldi',
    'मिर्च': 'mirch',
    'मिर्ची': 'mirchi',
    'धनिया': 'dhaniya',
    'जीरा': 'jeera',
    'राई': 'rai',
    'सौंफ': 'saunf',
    'लौंग': 'laung',
    'इलायची': 'elaichi',
    'कालीमिर्च': 'kali mirch',
    'हींग': 'heeng',
    'मसाला': 'masala',
    'गरम': 'garam',

    // Dairy & Bakery
    'दूध': 'doodh',
    'दही': 'dahi',
    'मक्खन': 'makhan',
    'पनीर': 'paneer',
    'छाछ': 'chhaachh',
    'लस्सी': 'lassi',
    'ब्रेड': 'bread',
    'पाव': 'paav',
    'अंडा': 'anda',
    'अंडे': 'ande',
    'टोस्ट': 'toast',
    'रस': 'rusk',

    // Snacks, Beverages & Packaged Goods
    'चाय': 'chai',
    'चायपत्ती': 'chai patti',
    'कॉफी': 'coffee',
    'बिस्कुट': 'biscuit',
    'बिस्किट': 'biscuit',
    'कुकीज': 'cookies',
    'क्रंचीस': 'crunchies',
    'क्रंची': 'crunchies',
    'नमकीन': 'namkeen',
    'भुजिया': 'bhujia',
    'चिप्स': 'chips',
    'कुरकुरे': 'kurkure',
    'मैगी': 'maggi',
    'नूडल्स': 'noodles',
    'पास्ता': 'pasta',
    'सॉस': 'sauce',
    'केचप': 'ketchup',
    'अचार': 'achaar',
    'पापड़': 'papad',
    'पानी': 'paani',
    'बोतल': 'bottle',
    'जूस': 'juice',
    'कोल्ड्रिंक': 'cold drink',
    'शरबत': 'sharbat',

    // Dry Fruits & Nuts
    'काजू': 'kaju',
    'बादाम': 'badam',
    'किशमिश': 'kishmish',
    'पिस्ता': 'pista',
    'अखरोट': 'akhrot',
    'मखाना': 'makhana',
    'मूंगफली': 'moongfali',

    // Personal & Home Care
    'साबुन': 'sabun',
    'सोप': 'soap',
    'सर्फ': 'surf',
    'डिटर्जेंट': 'detergent',
    'शैम्पू': 'shampoo',
    'तेलशीशी': 'hair oil',
    'कोलगेट': 'colgate',
    'टूथपेस्ट': 'toothpaste',
    'ब्रश': 'brush',
    'फिनाइल': 'phenyl',
    'माचिस': 'machis',
    'अगरबत्ती': 'agarbatti',
    'मोमबत्ती': 'mombatti',

    // Vegetables & Fruits
    'आलू': 'aaloo',
    'बटाटा': 'batata',
    'प्याज': 'pyaaz',
    'कांदा': 'kanda',
    'टमाटर': 'tamatar',
    'लहसुन': 'lahsun',
    'अदरक': 'adrak',
    'हरी': 'hari',
    'नींबू': 'nimbu',
    'केला': 'kela',
    'सेब': 'seb',

    // Units & Measures
    'किलो': 'kilo',
    'किलोग्राम': 'kg',
    'ग्राम': 'gm',
    'लीटर': 'litre',
    'मिलीलीटर': 'ml',
    'पैकेट': 'packet',
    'पैक': 'packet',
    'पीस': 'piece',
    'नग': 'piece',
    'दर्जन': 'dozen',
    'डिब्बा': 'box',
    'डब्बा': 'box',
    'बोरी': 'sack',
    'कट्टा': 'bag',
    'स्ट्रिप': 'strip',
    'पेटी': 'box',

    // Currency & Payment
    'रुपये': 'rs',
    'रुपए': 'rs',
    'रुपया': 'rs',
    'रु': 'rs',
    'रू': 'rs',
    'पैसा': 'paisa',
    'पैसे': 'paise',
    'नकद': 'cash',
    'कैश': 'cash',
    'उधार': 'udhar',
    'खाता': 'khata',
    'बाकी': 'baaki',
    'जमा': 'jama',
    'कार्ड': 'card',
    'ऑनलाइन': 'online',
    'गूगलपे': 'google pay',
    'फोनपे': 'phonepe',
    'पेटीएम': 'paytm',

    // Spoken Numbers & Quantities
    'आधा': 'aadha',
    'डेढ़': 'dedh',
    'ढाई': 'dhai',
    'सवा': 'sawa',
    'पौने': 'paune',
    'एक': '1',
    'दो': '2',
    'तीन': '3',
    'चार': '4',
    'पांच': '5',
    'पाँच': '5',
    'छह': '6',
    'सात': '7',
    'आठ': '8',
    'नौ': '9',
    'दस': '10',
    'ग्यारह': '11',
    'बारह': '12',
    'तेरह': '13',
    'चौदह': '14',
    'पंद्रह': '15',
    'सोलह': '16',
    'सत्रह': '17',
    'अठारह': '18',
    'उन्नीस': '19',
    'बीस': '20',
    'पच्चीस': '25',
    'तीस': '30',
    'पैंतीस': '35',
    'चालीस': '40',
    'पैंतालीस': '45',
    'पचास': '50',
    'साठ': '60',
    'सत्तर': '70',
    'अस्सी': '80',
    'नब्बे': '90',
    'सौ': '100',
    'हजार': '1000',

    // Connectors & POS phrases
    'और': 'aur',
    'का': 'ka',
    'की': 'ki',
    'के': 'ke',
    'को': 'ko',
    'में': 'mein',
    'पर': 'par',
    'से': 'se',
    'नाम': 'naam',
    'ग्राहक': 'customer',
    'बिल': 'bill',
    'कुल': 'total',
    'देना': 'dena',
    'लेना': 'lena',
    'लगाओ': 'lagao',
    'डालो': 'daalo',
    'करो': 'karo',
    'दीजिए': 'dijiye',
    'चाहिए': 'chahiye',
    'वाला': 'wala',
    'वाली': 'wali',
    'वाले': 'wale',
  };

  // Phonetic Devanagari character mappings
  static const Map<String, String> _vowels = {
    'अ': 'a',
    'आ': 'aa',
    'इ': 'i',
    'ई': 'ee',
    'उ': 'u',
    'ऊ': 'oo',
    'ऋ': 'ri',
    'ए': 'e',
    'ऐ': 'ai',
    'ओ': 'o',
    'औ': 'au',
    'अं': 'an',
    'अः': 'ah',
  };

  static const Map<String, String> _matras = {
    'ा': 'a',
    'ि': 'i',
    'ी': 'i',
    'ु': 'u',
    'ू': 'u',
    'ृ': 'ri',
    'े': 'e',
    'ै': 'ai',
    'ो': 'o',
    'ौ': 'au',
    'ं': 'n',
    'ँ': 'n',
    'ः': 'h',
  };

  static const Map<String, String> _consonants = {
    'क': 'k',
    'ख': 'kh',
    'ग': 'g',
    'घ': 'gh',
    'ङ': 'ng',
    'च': 'ch',
    'छ': 'chh',
    'ज': 'j',
    'झ': 'jh',
    'ञ': 'ny',
    'ट': 't',
    'ठ': 'th',
    'ड': 'd',
    'ढ': 'dh',
    'ण': 'n',
    'त': 't',
    'थ': 'th',
    'द': 'd',
    'ध': 'dh',
    'न': 'n',
    'प': 'p',
    'फ': 'f',
    'ब': 'b',
    'भ': 'bh',
    'म': 'm',
    'य': 'y',
    'र': 'r',
    'ल': 'l',
    'व': 'v',
    'श': 'sh',
    'ष': 'sh',
    'स': 's',
    'ह': 'h',
    'क्ष': 'ksh',
    'त्र': 'tr',
    'ज्ञ': 'gya',
    'श्र': 'shr',
    'ड़': 'd',
    'ढ़': 'dh',
    'फ़': 'f',
    'ज़': 'z',
    'ख़': 'kh',
    'ग़': 'gh',
    'क़': 'q',
  };

  /// Main entry point: converts any text containing Hindi/Devanagari into natural Roman Hinglish
  static String toHinglish(String input) {
    if (input.trim().isEmpty) return input;

    // 1. Normalize Devanagari numerals ०-९ to 0-9
    var text = input;
    const devDigits = '०१२३४५६७८९';
    for (var i = 0; i < 10; i++) {
      text = text.replaceAll(devDigits[i], '$i');
    }

    // 2. Normalize symbols & punctuations
    text = text.replaceAll('₹', ' rs ');
    text = text.replaceAll('।', ' , ');

    // 3. Process tokens (words and punctuation)
    final tokens = _tokenize(text);
    final resultWords = <String>[];

    for (final token in tokens) {
      if (_isDevanagari(token)) {
        // Check dictionary lookup first
        final cleanToken = _stripPunctuation(token);
        if (_wordDictionary.containsKey(cleanToken)) {
          final mapped = _wordDictionary[cleanToken]!;
          resultWords.add(token.replaceAll(cleanToken, mapped));
        } else {
          // Fallback to phonetic transliteration
          resultWords.add(_transliterateDevanagariWord(token));
        }
      } else {
        resultWords.add(token);
      }
    }

    var output = resultWords.join(' ');

    // 4. Clean up formatting and standard POS patterns (e.g. "100 rs" or "100 rupaye" -> "100rs")
    output = _normalizeHinglishFormatting(output);

    return output;
  }

  static bool _isDevanagari(String s) {
    for (final rune in s.runes) {
      if (rune >= 0x0900 && rune <= 0x097F) return true;
    }
    return false;
  }

  static String _stripPunctuation(String s) {
    return s.replaceAll(RegExp(r'[,.\-;:!?()\[\]]'), '').trim();
  }

  static List<String> _tokenize(String s) {
    return s.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
  }

  /// Phonetic transliteration for words not found in the dictionary
  static String _transliterateDevanagariWord(String word) {
    final sb = StringBuffer();
    final runes = word.runes.toList();
    final len = runes.length;

    for (var i = 0; i < len; i++) {
      final ch = String.fromCharCode(runes[i]);

      // Check for standalone vowels
      if (_vowels.containsKey(ch)) {
        sb.write(_vowels[ch]);
        continue;
      }

      // Check for consonants
      if (_consonants.containsKey(ch)) {
        final roman = _consonants[ch]!;
        sb.write(roman);

        // Lookahead for virama (halant), matra, or end of word
        if (i + 1 < len) {
          final nextCh = String.fromCharCode(runes[i + 1]);
          if (nextCh == '्') {
            // Halant suppresses inherent 'a', skip halant
            i++;
            continue;
          } else if (_matras.containsKey(nextCh)) {
            // Matra replaces inherent 'a'
            sb.write(_matras[nextCh]);
            i++;
            continue;
          } else if (_isDevanagari(nextCh) && _consonants.containsKey(nextCh)) {
            // Consonant followed by consonant -> inherent 'a'
            sb.write('a');
          }
        } else {
          // End of word in modern Hindi/Hinglish: schwa is deleted (no trailing 'a')
          // e.g. "चावल" -> "chawal" not "chawala", "दुकान" -> "dukan"
        }
        continue;
      }

      // Standalone matra or punctuation
      if (_matras.containsKey(ch)) {
        sb.write(_matras[ch]);
        continue;
      }

      // Any non-Devanagari character (Latin letters, punctuation, digits)
      sb.write(ch);
    }

    return sb.toString();
  }

  /// Standardizes spacing, price representations, and common POS phrases
  /// e.g. "100 rs" -> "100rs", "1 kilo", "10 packet"
  static String _normalizeHinglishFormatting(String text) {
    var s = text;

    // Normalize spacing around commas and periods
    s = s.replaceAll(RegExp(r'\s*,\s*'), ', ');
    s = s.replaceAll(RegExp(r'\s*\.\s*'), '. ');

    // Normalize price representations e.g. "100 rs", "100 rupees", "100 rupaye" -> "100rs"
    s = s.replaceAllMapped(
      RegExp(r'(\d+(?:\.\d+)?)\s*(?:rs|rupaye|rupees|rupe|rupya)\b', caseSensitive: false),
      (m) => '${m.group(1)}rs',
    );

    // Normalize quantity units e.g. "1 kg" -> "1 kilo"
    s = s.replaceAllMapped(
      RegExp(r'(\d+(?:\.\d+)?)\s*kg\b', caseSensitive: false),
      (m) => '${m.group(1)} kilo',
    );
    s = s.replaceAllMapped(
      RegExp(r'(\d+(?:\.\d+)?)\s*pkt\b', caseSensitive: false),
      (m) => '${m.group(1)} packet',
    );

    // Clean up multiple spaces
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();

    return s;
  }
}
