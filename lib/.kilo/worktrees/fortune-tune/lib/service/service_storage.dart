import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class ServiceStorage {
  final Map<String, TypedValue> _cache = {};
  bool _loaded = false;

  Future<ServiceStorage> init() async {
    await _load();
    return this;
  }

  Future<void> writeString(String key, String value) async {
    _cache[key] = TypedValue('string', SimpleCrypto.encrypt(value));
    await _flush();
  }

  Future<void> writeInt(String key, int value) async {
    _cache[key] = TypedValue('int', SimpleCrypto.encrypt(value.toString()));
    await _flush();
  }

  Future<void> writeBool(String key, bool value) async {
    _cache[key] = TypedValue('bool', SimpleCrypto.encrypt(value.toString()));
    await _flush();
  }

  Future<void> writeDouble(String key, double value) async {
    _cache[key] = TypedValue('double', SimpleCrypto.encrypt(value.toString()));
    await _flush();
  }

  String? readString(String key) {
    final tv = _cache[key];
    if (tv == null || tv.type != 'string') return null;
    return SimpleCrypto.decrypt(tv.value);
  }

  int? readInt(String key) {
    final tv = _cache[key];
    if (tv == null || tv.type != 'int') return null;
    return int.tryParse(SimpleCrypto.decrypt(tv.value));
  }

  bool? readBool(String key) {
    final tv = _cache[key];
    if (tv == null || tv.type != 'bool') return null;
    return SimpleCrypto.decrypt(tv.value) == 'true';
  }

  double? readDouble(String key) {
    final tv = _cache[key];
    if (tv == null || tv.type != 'double') return null;
    return double.tryParse(SimpleCrypto.decrypt(tv.value));
  }

  Future<void> delete(String key) async {
    _cache.remove(key);
    await _flush();
  }

  Future<void> clear() async {
    _cache.clear();
    await _flush();
  }

  bool containsKey(String key) => _cache.containsKey(key);

  Future<void> _load() async {
    if (_loaded) return;

    final file = await _file();
    if (!await file.exists()) {
      _loaded = true;
      return;
    }

    final content = await file.readAsString();
    if (content.isNotEmpty) {
      final decoded = jsonDecode(content);
      if (decoded is Map<String, dynamic>) {
        decoded.forEach((key, value) {
          if (value is Map<String, dynamic>) {
            _cache[key] = TypedValue.fromJson(value);
          }
        });
      }
    }

    _loaded = true;
  }

  Future<void> _flush() async {
    final file = await _file();
    final tmp = File('${file.path}.tmp');

    final json = jsonEncode(_cache.map((k, v) => MapEntry(k, v.toJson())));

    await tmp.writeAsString(json, flush: true);

    if (await file.exists()) {
      await file.delete();
    }
    await tmp.rename(file.path);
  }

  Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/.sys_cache_9a3f.dat');
  }
}

class TypedValue {
  final String type; // int, bool, double, string
  final String value; // encrypted string

  TypedValue(this.type, this.value);

  Map<String, dynamic> toJson() => {'t': type, 'v': value};

  factory TypedValue.fromJson(Map<String, dynamic> json) {
    return TypedValue(json['t'] as String, json['v'] as String);
  }
}

class SimpleCrypto {
  static const String _secret = 'wQQknIPJFbbvEqPPJUv32gr0';

  static String encrypt(String plain) {
    final plainBytes = utf8.encode(plain);
    final keyBytes = utf8.encode(_secret);

    final result = List<int>.generate(
      plainBytes.length,
      (i) => plainBytes[i] ^ keyBytes[i % keyBytes.length],
    );

    return base64Encode(result);
  }

  static String decrypt(String cipher) {
    final cipherBytes = base64Decode(cipher);
    final keyBytes = utf8.encode(_secret);

    final result = List<int>.generate(
      cipherBytes.length,
      (i) => cipherBytes[i] ^ keyBytes[i % keyBytes.length],
    );

    return utf8.decode(result);
  }
}
