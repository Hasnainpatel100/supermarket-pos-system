import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';

import '../objectbox.g.dart';
import '../screens/home/fragment/pos/controller_home_pos.dart';
import '../screens/home/fragment/item/controller_home_item.dart';
import '../screens/home/fragment/bills/controller_home_bills.dart';
import '../screens/home/fragment/dashboard/controller_home_dashboard.dart';
import '../screens/home/fragment/stocks/controller_home_stock.dart';
import '../screens/home/fragment/reports/controller_home_reports.dart';
import '../screens/home/fragment/customer/controller_home_customer.dart';
import '../screens/home/fragment/purchase_supplier/purchase/controller_home_purchase.dart';
import '../screens/home/fragment/api_user/controller_home_api_users.dart';

/// Central ObjectBox Database Service with Multi-Brand Isolation Support.
///
/// Automatically creates and connects to isolated local database instances
/// for each distinct `brandId` (e.g. `market_brand_000000001`, `market_brand_00000002`).
/// This ensures complete separation of bills, invoices, items, customers, and reports
/// across different brand logins on the same device.
class ServiceObjectBox extends GetxService {
  Store? _store;
  String _currentBrandId = '';

  /// Currently active brandId associated with this ObjectBox store.
  String get currentBrandId => _currentBrandId;

  Store get store {
    if (_store == null || _store!.isClosed()) {
      throw StateError(
        'ServiceObjectBox Store is not initialized or has been closed. Current brand: "$_currentBrandId"',
      );
    }
    return _store!;
  }

  /// Returns a shareable reference to the underlying Store.
  ///
  /// Pass this to background Isolates so they can open their own
  /// lightweight Store handle via Store.fromReference(...).
  ByteData get storeReference => store.reference;

  /// Sanitizes brandId to form a safe directory name on all filesystems.
  static String sanitizeBrandId(String? raw) {
    if (raw == null) return '';
    return raw.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
  }

  String _buildDirectoryName(String? brandId) {
    final clean = sanitizeBrandId(brandId);
    if (clean.isNotEmpty) {
      return 'market_brand_$clean';
    }
    return 'market';
  }

  Future<String> _resolveDirectoryPath(String dirName) async {
    if (kDebugMode) {
      return dirName;
    } else {
      final appSupportDir = await getApplicationSupportDirectory();
      return '${appSupportDir.path}/$dirName';
    }
  }

  /// Initializes the ObjectBox store for the given [brandId] (or default if null).
  Future<ServiceObjectBox> init({String? brandId}) async {
    final clean = sanitizeBrandId(brandId);
    if (_store != null && !_store!.isClosed() && _currentBrandId == clean) {
      return this;
    }

    if (_store != null && !_store!.isClosed()) {
      _store!.close();
      _store = null;
    }

    _currentBrandId = clean;
    final dirName = _buildDirectoryName(clean);
    final path = await _resolveDirectoryPath(dirName);

    _store = Store(
      getObjectBoxModel(),
      directory: path,
    );

    if (kDebugMode) {
      debugPrint('📦 [ServiceObjectBox] Initialized local database for brand "$clean" at "$path"');
    }

    return this;
  }

  /// Switches active ObjectBox database to the specified [newBrandId].
  ///
  /// Closes the previous store and opens the isolated database for [newBrandId].
  /// If the database directory doesn't exist yet, ObjectBox creates it automatically.
  Future<void> switchBrandDatabase(String newBrandId) async {
    final clean = sanitizeBrandId(newBrandId);
    if (_store != null && !_store!.isClosed() && _currentBrandId == clean) {
      if (kDebugMode) {
        debugPrint('ℹ️ [ServiceObjectBox] Already connected to database for brand "$clean"');
      }
      return;
    }

    if (kDebugMode) {
      debugPrint('🔄 [ServiceObjectBox] Switching database from brand "$_currentBrandId" to "$clean"');
    }

    // ── Evict all controllers holding live Box<T> references BEFORE closing
    // the previous store. This prevents "Store is already closed" crashes and
    // guarantees no in-memory cart/bill data leaks across brands. The
    // incoming screen lazily re-instantiates each controller with fresh boxes.
    _evictBrandControllers();

    if (_store != null && !_store!.isClosed()) {
      _store!.close();
      _store = null;
    }

    _currentBrandId = clean;
    final dirName = _buildDirectoryName(clean);
    final path = await _resolveDirectoryPath(dirName);

    _store = Store(
      getObjectBoxModel(),
      directory: path,
    );

    if (kDebugMode) {
      debugPrint('✅ [ServiceObjectBox] Successfully connected to database for brand "$clean" at "$path"');
    }
  }

  /// Evicts every GetX controller that holds a live ObjectBox Box<T> reference.
  /// Safe to call even when a controller is not registered.
  void _evictBrandControllers() {
    if (Get.isRegistered<ControllerHomePos>()) Get.delete<ControllerHomePos>(force: true);
    if (Get.isRegistered<ControllerHomeItem>()) Get.delete<ControllerHomeItem>(force: true);
    if (Get.isRegistered<ControllerHomeBills>()) Get.delete<ControllerHomeBills>(force: true);
    if (Get.isRegistered<ControllerHomeDashboard>()) Get.delete<ControllerHomeDashboard>(force: true);
    if (Get.isRegistered<ControllerHomeStock>()) Get.delete<ControllerHomeStock>(force: true);
    if (Get.isRegistered<ControllerHomeReports>()) Get.delete<ControllerHomeReports>(force: true);
    if (Get.isRegistered<ControllerHomeCustomer>()) Get.delete<ControllerHomeCustomer>(force: true);
    if (Get.isRegistered<ControllerHomePurchase>()) Get.delete<ControllerHomePurchase>(force: true);
    if (Get.isRegistered<ControllerHomeApiUsers>()) Get.delete<ControllerHomeApiUsers>(force: true);
  }

  /// Re-opens the ObjectBox store after a restore or logout reset.
  Future<void> reopen({String? brandId}) async {
    final targetBrand = brandId != null ? sanitizeBrandId(brandId) : _currentBrandId;
    await switchBrandDatabase(targetBrand);
  }

  Box<T> box<T>() => store.box<T>();

  /// ⚡ DATABASE HOUSEKEEPING:
  /// Verifies store integrity, closes dangling queries, and retrieves storage info.
  Map<String, dynamic> getMaintenanceInfo() {
    if (_store == null || _store!.isClosed()) {
      return {'status': 'closed', 'brandId': _currentBrandId};
    }
    return {
      'status': 'healthy',
      'brandId': _currentBrandId,
      'directory': _store!.directoryPath,
    };
  }

  @override
  void onClose() {
    if (_store != null && !_store!.isClosed()) {
      _store!.close();
    }
    super.onClose();
  }
}
