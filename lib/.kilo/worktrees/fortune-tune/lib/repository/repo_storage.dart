import '../service/service_storage.dart';

class RepoStorage {
  late ServiceStorage _storage;

  RepoStorage onInit({required ServiceStorage storage}) {
    _storage = storage;
    return this;
  }

  Future<String> getUser() async {
    return _storage.readString("a") ?? '';
  }

  Future<void> setUser(String value) async {
    await _storage.writeString("a", value);
  }

  Future<void> logout() async {
    await _storage.writeString("a", "");
  }
}
