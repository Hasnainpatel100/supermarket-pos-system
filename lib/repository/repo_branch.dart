import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../enums/enum_audit_action.dart';
import '../enums/enum_audit_module.dart';
import '../model/model_branch.dart';
import '../service/service_audit_log.dart';
import '../service/service_branch_api.dart';
import '../service/service_storage.dart';

/// Repository coordinating Branch REST API with local cache and audit logging.
class RepoBranch {
  final ServiceBranchApi _api;
  final ServiceStorage _storage;
  static const String _cacheKey = 'cached_branches_list_v1';

  RepoBranch({required ServiceBranchApi api, required ServiceStorage storage})
      : _api = api,
        _storage = storage;

  // ── Cache helpers ─────────────────────────────────────────────────────────

  List<ModelBranch> getCachedBranches() {
    final rawJson = _storage.readString(_cacheKey);
    if (rawJson == null || rawJson.isEmpty) return [];
    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is List) {
        return decoded.whereType<Map<String, dynamic>>().map((e) => ModelBranch.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('⚠️ Error reading cached branches: $e');
    }
    return [];
  }

  Future<void> _saveToCache(List<ModelBranch> branches) async {
    final list = branches.map((b) => b.toMap()).toList();
    await _storage.writeString(_cacheKey, jsonEncode(list));
  }

  // ── Fetch ─────────────────────────────────────────────────────────────────

  /// Fetches all branches, falling back to local cache on network failure.
  Future<(List<ModelBranch> branches, bool isFromApi, String? errorMessage)> fetchBranches({
    bool forceRefresh = false,
  }) async {
    final cached = getCachedBranches();
    try {
      final response = await _api.getBranches();
      if (response.success && response.data != null) {
        await _saveToCache(response.data!);
        return (response.data!, true, null);
      }
      return (cached, false, response.message);
    } catch (e) {
      return (cached, false, e.toString());
    }
  }

  /// Fetches branches belonging to a specific brand.
  Future<(List<ModelBranch> branches, bool isFromApi, String? errorMessage)> fetchBranchesByBrand(
    String brandId,
  ) async {
    // Filter cached list as an immediate fallback
    final cached = getCachedBranches().where((b) => b.brandId == brandId).toList();
    try {
      final response = await _api.getBranchesByBrand(brandId);
      if (response.success && response.data != null) {
        // Merge into cache: keep branches from other brands + replace this brand's branches
        final all = getCachedBranches().where((b) => b.brandId != brandId).toList();
        all.addAll(response.data!);
        await _saveToCache(all);
        return (response.data!, true, null);
      }
      return (cached, false, response.message);
    } catch (e) {
      return (cached, false, e.toString());
    }
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────

  Future<(ModelBranch? branch, bool success, String message)> createBranch(ModelBranch branch) async {
    // Guard against non-24 hex character brandId which causes BSON assertion failure on server
    if (!RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(branch.brandId)) {
      return (
        null,
        false,
        'Cannot sync branch: Selected Brand does not have a valid server ID (must be a 24-character hex string). Please select a server-synced brand.'
      );
    }

    final response = await _api.createBranch(branch);

    if (response.success && response.data != null) {
      final created = response.data!;
      final all = getCachedBranches();
      all.removeWhere((b) => b.id == created.id);
      all.insert(0, created);
      await _saveToCache(all);
      _logAudit(
        action: AuditAction.create,
        branchId: created.id ?? 'new',
        branchName: created.name.en,
        payload: created.toJsonString(),
        description: 'Branch "${created.name.en}" [${created.branchCode}] created',
      );
      return (created, true, response.message);
    }

    // Offline fallback
    final fallbackId = 'local_${DateTime.now().millisecondsSinceEpoch}';
    final local = branch.copyWith(id: fallbackId);
    final all = getCachedBranches();
    all.insert(0, local);
    await _saveToCache(all);
    _logAudit(
      action: AuditAction.create,
      branchId: fallbackId,
      branchName: local.name.en,
      payload: local.toJsonString(),
      description: 'Branch "${local.name.en}" saved locally (API offline: ${response.message})',
    );
    return (local, false, '${response.message}. Saved locally for offline use.');
  }

  Future<(ModelBranch? branch, bool success, String message)> updateBranch(
    String id,
    ModelBranch branch,
  ) async {
    // If the ID is a local temp ID or not a valid 24-char hex MongoDB ID, create it on the server instead
    final isValidMongoId = RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(id);
    if (!isValidMongoId || id.startsWith('local_')) {
      // Rebuild the branch explicitly with id: null to strip local/dummy ID
      final branchForCreate = ModelBranch(
        id: null,
        brandId: branch.brandId,
        brandName: branch.brandName,
        branchCode: branch.branchCode,
        name: branch.name,
        address: branch.address,
        contact: branch.contact,
        serviceTypes: branch.serviceTypes,
        appType: branch.appType,
        status: branch.status,
        settings: branch.settings,
        remoteId: branch.remoteId,
      );
      final (created, success, message) = await createBranch(branchForCreate);
      if (success && created != null) {
        // Remove the old local entry and replace with the synced one
        final all = getCachedBranches();
        all.removeWhere((b) => b.id == id);
        all.removeWhere((b) => b.id == created.id);
        all.insert(0, created);
        await _saveToCache(all);
      }
      return (created, success, success ? 'Branch synced to server successfully' : message);
    }

    final response = await _api.updateBranch(id, branch);
    final updated = (response.success && response.data != null) ? response.data! : branch.copyWith(id: id);

    final all = getCachedBranches();
    final index = all.indexWhere((b) => b.id == id);
    if (index >= 0) {
      all[index] = updated;
    } else {
      all.insert(0, updated);
    }
    await _saveToCache(all);

    _logAudit(
      action: AuditAction.update,
      branchId: id,
      branchName: updated.name.en,
      payload: updated.toJsonString(),
      description: 'Branch "${updated.name.en}" ($id) updated',
    );
    return (updated, response.success, response.message);
  }

  /// Clears the local branches cache.
  Future<void> clearLocalCache() async {
    await _storage.writeString(_cacheKey, '[]');
  }

  Future<(bool success, String message)> deleteBranch(
    String id, {
    String? branchName,
    String? branchCode,
  }) async {
    // If the ID is empty, starts with 'local_', or was never saved with a server ID
    if (id.isEmpty || id.startsWith('local_')) {
      final all = getCachedBranches();
      all.removeWhere((b) =>
          (id.isNotEmpty && b.id == id) ||
          (branchCode != null && branchCode.isNotEmpty && b.branchCode == branchCode) ||
          (branchName != null && branchName.isNotEmpty && b.name.en == branchName));
      await _saveToCache(all);
      _logAudit(
        action: AuditAction.delete,
        branchId: id.isEmpty ? 'local' : id,
        branchName: branchName ?? id,
        description: 'Local branch "${branchName ?? id}" removed (was never synced)',
      );
      return (true, 'Local branch removed successfully');
    }

    final response = await _api.deleteBranch(id);
    final all = getCachedBranches();
    all.removeWhere((b) =>
        b.id == id ||
        (branchCode != null && branchCode.isNotEmpty && b.branchCode == branchCode));
    await _saveToCache(all);

    _logAudit(
      action: AuditAction.delete,
      branchId: id,
      branchName: branchName ?? id,
      description: 'Branch "${branchName ?? id}" deleted',
    );
    return (response.success, response.message);
  }

  /// Assigns a plan to a branch via PUT /api/branches/:id/plan
  Future<(ModelBranch? branch, bool success, String message)> assignPlanToBranch(
    String id,
    Map<String, dynamic> planPayload,
  ) async {
    final response = await _api.assignPlanToBranch(id, planPayload);
    if (response.success && response.data != null) {
      final updated = response.data!;
      final all = getCachedBranches();
      final index = all.indexWhere((b) => b.id == id);
      if (index >= 0) {
        all[index] = updated;
        await _saveToCache(all);
      }
      return (updated, true, response.message);
    }
    return (null, false, response.message);
  }

  /// Fetches branch plan history via GET /api/branches/:id/plan-history
  Future<(List<dynamic> history, bool success, String message)> getBranchPlanHistory(String id) async {
    final response = await _api.getBranchPlanHistory(id);
    if (response.success && response.data != null) {
      return (response.data!, true, response.message);
    }
    return ([], false, response.message);
  }

  // ── Audit ─────────────────────────────────────────────────────────────────

  void _logAudit({
    required AuditAction action,
    required String branchId,
    required String branchName,
    String? payload,
    String? description,
  }) {
    try {
      if (Get.isRegistered<AuditLogService>()) {
        final audit = Get.find<AuditLogService>();
        if (action == AuditAction.create) {
          audit.logCreate(
            module: AuditModule.branch,
            entityType: 'Branch',
            entityId: branchId,
            newData: payload,
            description: description,
          );
        } else if (action == AuditAction.update) {
          audit.logUpdate(
            module: AuditModule.branch,
            entityType: 'Branch',
            entityId: branchId,
            newData: payload,
            description: description,
          );
        } else if (action == AuditAction.delete) {
          audit.logDelete(
            module: AuditModule.branch,
            entityType: 'Branch',
            entityId: branchId,
            description: description,
          );
        }
      }
    } catch (e) {
      debugPrint('⚠️ Audit log error for Branch: $e');
    }
  }
}
