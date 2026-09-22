import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../model/model_api_user.dart';
import '../service/service_api_user.dart';
import '../service/service_storage.dart';

/// Repository coordinating API User REST API with local cache persistence.
class RepoApiUser {
  final ServiceApiUser _api;
  final ServiceStorage _storage;
  static const String storageKeyApiUsers = 'cached_api_users_list_v1';

  RepoApiUser({
    required ServiceApiUser api,
    required ServiceStorage storage,
  })  : _api = api,
        _storage = storage;

  /// Loads cached API users from local storage
  List<ModelApiUser> getCachedUsers() {
    final rawJson = _storage.readString(storageKeyApiUsers);
    if (rawJson == null || rawJson.isEmpty) {
      return [];
    }
    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map((e) => ModelApiUser.fromJson(e))
            .toList();
      }
    } catch (e) {
      debugPrint('⚠️ Error reading cached API users: $e');
    }
    return [];
  }

  /// Saves API users list into local storage cache
  Future<void> _saveToCache(List<ModelApiUser> users) async {
    final list = users.map((u) => u.toJson()).toList();
    final jsonStr = jsonEncode(list);
    await _storage.writeString(storageKeyApiUsers, jsonStr);
  }

  /// Fetches API users from server, falling back to local cache if offline
  Future<(List<ModelApiUser> users, bool isFromApi, String? errorMessage)> fetchUsers({
    String? brandId,
    bool forceRefresh = false,
  }) async {
    final cached = getCachedUsers();

    try {
      final response = await _api.getApiUsers(brandId: brandId);
      if (response.success && response.data != null) {
        final apiList = response.data!;
        // Merge API list with any cached ones that haven't synced yet
        final Map<String, ModelApiUser> mergedMap = {};
        for (var user in apiList) {
          if (user.id != null) {
            mergedMap[user.id!] = user;
          } else if (user.username.isNotEmpty) {
            mergedMap[user.username] = user;
          }
        }
        for (var user in cached) {
          final key = user.id ?? user.username;
          if (key.isNotEmpty && !mergedMap.containsKey(key)) {
            mergedMap[key] = user;
          }
        }
        final result = mergedMap.values.toList();
        await _saveToCache(result);
        return (result, true, null);
      } else {
        return (cached, false, response.message);
      }
    } catch (e) {
      debugPrint('⚠️ Network fetch error for API Users: $e');
      return (cached, false, e.toString());
    }
  }

  /// Creates a new API user via REST API and updates local cache
  Future<ApiUserResponse<ModelApiUser>> createUser(ModelApiUser user) async {
    final response = await _api.createApiUser(user);

    if (response.success && response.data != null) {
      final created = response.data!;
      final currentList = getCachedUsers();
      currentList.insert(0, created);
      await _saveToCache(currentList);
      return response;
    } else {
      // Do not save locally with temporary ID — save directly to server
      return response;
    }
  }

  /// Updates an existing API user
  Future<ApiUserResponse<ModelApiUser>> updateUser(String id, ModelApiUser user) async {
    final response = await _api.updateApiUser(id, user);

    final currentList = getCachedUsers();
    final index = currentList.indexWhere((u) => u.id == id || u.username == user.username);

    final updated = response.success && response.data != null ? response.data! : user.copyWith(id: id);

    if (index != -1) {
      currentList[index] = updated;
    } else {
      currentList.add(updated);
    }
    await _saveToCache(currentList);

    return response;
  }

  /// Deletes an API user
  Future<ApiUserResponse<bool>> deleteUser(String id) async {
    final response = await _api.deleteApiUser(id);

    final currentList = getCachedUsers();
    currentList.removeWhere((u) => u.id == id);
    await _saveToCache(currentList);

    return response;
  }
}
