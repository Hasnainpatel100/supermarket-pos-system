import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../enums/enum_audit_action.dart';
import '../enums/enum_audit_module.dart';
import '../model/model_brand.dart';
import '../service/service_audit_log.dart';
import '../service/service_brand_api.dart';
import '../service/service_storage.dart';

/// Repository coordinating Brand REST API with local cache persistence and audit logging.
class RepoBrand {
  final ServiceBrandApi _api;
  final ServiceStorage _storage;
  static const String storageKeyBrands = 'cached_brands_list_v1';

  RepoBrand({
    required ServiceBrandApi api,
    required ServiceStorage storage,
  })  : _api = api,
        _storage = storage;

  /// Loads cached brands from local storage
  List<ModelBrand> getCachedBrands() {
    final rawJson = _storage.readString(storageKeyBrands);
    if (rawJson == null || rawJson.isEmpty) {
      return [];
    }
    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map((e) => ModelBrand.fromJson(e))
            .toList();
      }
    } catch (e) {
      debugPrint('⚠️ Error reading cached brands: $e');
    }
    return [];
  }

  /// Saves brands list into local storage cache
  Future<void> _saveToCache(List<ModelBrand> brands) async {
    final list = brands.map((b) => b.toMap()).toList();
    final jsonStr = jsonEncode(list);
    await _storage.writeString(storageKeyBrands, jsonStr);
  }

  /// Clears all locally cached brands — next fetchBrands() will get fresh data from server
  Future<void> clearLocalCache() async {
    await _storage.writeString(storageKeyBrands, '[]');
  }

  /// Fetches brands from API, falling back to local cache if offline
  Future<(List<ModelBrand> brands, bool isFromApi, String? errorMessage)> fetchBrands({
    String? appType,
    bool forceRefresh = false,
  }) async {
    final cached = getCachedBrands();

    try {
      final response = await _api.getBrands(appType: appType);
      if (response.success && response.data != null) {
        final apiBrands = response.data!;
        await _saveToCache(apiBrands);
        return (apiBrands, true, null);
      } else {
        return (cached, false, response.message);
      }
    } catch (e) {
      return (cached, false, e.toString());
    }
  }

  /// Creates a new brand via POST /api/brands
  Future<(ModelBrand? brand, bool success, String message)> createBrand(ModelBrand brand) async {
    final response = await _api.createBrand(brand);

    if (response.success && response.data != null) {
      final created = response.data!;
      final currentList = getCachedBrands();
      // Avoid duplicate by id
      currentList.removeWhere((b) => b.id == created.id);
      currentList.insert(0, created);
      await _saveToCache(currentList);

      _logAudit(
        action: AuditAction.create,
        brandId: created.id ?? 'new',
        brandName: created.name.en,
        payload: created.toJsonString(),
        description: 'Brand "${created.name.en}" created via REST API',
      );

      return (created, true, response.message);
    } else {
      // Local fallback creation if network fails
      final fallbackId = 'local_${DateTime.now().millisecondsSinceEpoch}';
      final localBrand = brand.copyWith(id: fallbackId);
      final currentList = getCachedBrands();
      currentList.insert(0, localBrand);
      await _saveToCache(currentList);

      _logAudit(
        action: AuditAction.create,
        brandId: fallbackId,
        brandName: localBrand.name.en,
        payload: localBrand.toJsonString(),
        description: 'Brand "${localBrand.name.en}" saved locally (API offline: ${response.message})',
      );

      return (
        localBrand,
        false,
        '${response.message}. Saved to local cache for offline use.'
      );
    }
  }

  /// Updates an existing brand via PUT /api/brands/:id
  Future<(ModelBrand? brand, bool success, String message)> updateBrand(
    String id,
    ModelBrand brand,
  ) async {
    // If the ID is a local temp ID, create it on server instead of updating
    if (id.startsWith('local_')) {
      final brandForCreate = ModelBrand(
        id: null,
        name: brand.name,
        registration: brand.registration,
        contact: brand.contact,
        appType: brand.appType,
        status: brand.status,
        ownerId: brand.ownerId,
      );
      final (created, success, message) = await createBrand(brandForCreate);
      if (success && created != null) {
        final currentList = getCachedBrands();
        currentList.removeWhere((b) => b.id == id);
        await _saveToCache(currentList);
      }
      return (created, success, success ? 'Brand synced to server successfully' : message);
    }

    final response = await _api.updateBrand(id, brand);

    final updated = (response.success && response.data != null)
        ? response.data!
        : brand.copyWith(id: id);

    final currentList = getCachedBrands();
    final index = currentList.indexWhere((b) => b.id == id);
    if (index >= 0) {
      currentList[index] = updated;
    } else {
      currentList.insert(0, updated);
    }
    await _saveToCache(currentList);

    _logAudit(
      action: AuditAction.update,
      brandId: id,
      brandName: updated.name.en,
      payload: updated.toJsonString(),
      description: 'Brand "${updated.name.en}" ($id) updated',
    );

    return (updated, response.success, response.message);
  }

  /// Deletes a brand via DELETE /api/brands/:id and removes from local cache
  Future<(bool success, String message)> deleteBrand(String id, {String? brandName}) async {
    // If it only exists locally, just remove from cache — never existed on server
    if (id.startsWith('local_')) {
      final currentList = getCachedBrands();
      currentList.removeWhere((b) => b.id == id);
      await _saveToCache(currentList);
      _logAudit(
        action: AuditAction.delete,
        brandId: id,
        brandName: brandName ?? id,
        description: 'Local brand "${brandName ?? id}" removed (was never synced to server)',
      );
      return (true, 'Local brand removed');
    }

    // Call the server DELETE endpoint
    final response = await _api.deleteBrand(id);

    if (response.success) {
      // Server confirmed deletion — remove from cache
      final currentList = getCachedBrands();
      currentList.removeWhere((b) => b.id == id);
      await _saveToCache(currentList);

      _logAudit(
        action: AuditAction.delete,
        brandId: id,
        brandName: brandName ?? id,
        description: 'Brand "${brandName ?? id}" deleted from server and cache',
      );
      return (true, response.message);
    } else {
      // Server deletion failed — keep in cache, return error
      _logAudit(
        action: AuditAction.delete,
        brandId: id,
        brandName: brandName ?? id,
        description: 'Failed to delete brand "${brandName ?? id}" from server: ${response.message}',
      );
      return (false, response.message);
    }
  }



  void _logAudit({
    required AuditAction action,
    required String brandId,
    required String brandName,
    String? payload,
    String? description,
  }) {
    try {
      if (Get.isRegistered<AuditLogService>()) {
        final audit = Get.find<AuditLogService>();
        if (action == AuditAction.create) {
          audit.logCreate(
            module: AuditModule.system,
            entityType: 'Brand',
            entityId: brandId,
            newData: payload,
            description: description,
          );
        } else if (action == AuditAction.update) {
          audit.logUpdate(
            module: AuditModule.system,
            entityType: 'Brand',
            entityId: brandId,
            newData: payload,
            description: description,
          );
        } else if (action == AuditAction.delete) {
          audit.logDelete(
            module: AuditModule.system,
            entityType: 'Brand',
            entityId: brandId,
            description: description,
          );
        }
      }
    } catch (e) {
      debugPrint('⚠️ Audit log error for Brand: $e');
    }
  }
}
