import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../features/authentication/data/auth_repository.dart';
import '../../repository/repo_storage.dart';
import '../../service/service_brand_context.dart';
import '../../util/app_route.dart';
import '../../widget/dialog_plan_expired_block.dart';
import '../performance/performance_config.dart';

/// Manages plan expiry detection **without** wasteful periodic polling.
///
/// ## Strategy (in priority order)
///
/// 1. **One-shot precision timer** — On login / branch selection, calculate
///    the exact `Duration` until expiry and schedule a single `Timer`.
///    Zero CPU usage while waiting. No load on memory.
///
/// 2. **Lifecycle trigger** — When the user minimizes and re-opens the
///    app (`AppLifecycleState.resumed`), we check expiry immediately
///    because the device clock may have moved past the scheduled timer.
///
/// 3. **Safety-net fallback** — A very low-frequency periodic timer
///    (default: every 30 min) catches edge cases such as system clock
///    adjustments or NTP corrections.
///
/// This replaces the old `Timer.periodic(Duration(minutes: 1))` which
/// woke up 1440 times/day even though the expiry event happens at most
/// **once per subscription period**.
///
/// ## Registration
/// ```dart
/// Get.put<PlanExpiryGuard>(PlanExpiryGuard(), permanent: true);
/// ```
class PlanExpiryGuard extends GetxService with WidgetsBindingObserver {
  Timer? _precisionTimer;
  Timer? _fallbackTimer;
  bool _hasExpired = false;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    scheduleExpiryCheck();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _precisionTimer?.cancel();
    _fallbackTimer?.cancel();
    super.onClose();
  }

  // ── AppLifecycleState ────────────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App came to foreground — clock may have advanced past expiry
      _checkNow();
    }
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Call this whenever the branch/plan changes (login, branch switch).
  void scheduleExpiryCheck() {
    _hasExpired = false;
    _precisionTimer?.cancel();
    _fallbackTimer?.cancel();

    if (!Get.isRegistered<ServiceBrandContext>()) return;
    final brandCtx = Get.find<ServiceBrandContext>();
    final plan = brandCtx.planDetails;
    if (plan == null) return;

    // Already expired — handle immediately
    if (brandCtx.isPlanExpired) {
      _handleExpired();
      return;
    }

    // Schedule precision one-shot timer
    final expiryDate = plan.expiryDate;
    if (expiryDate != null) {
      final remaining = expiryDate.toUtc().difference(DateTime.now().toUtc());
      if (remaining.isNegative) {
        _handleExpired();
        return;
      }
      debugPrint('[PlanExpiryGuard] Precision timer: fires in ${remaining.inMinutes} min');
      _precisionTimer = Timer(remaining, _handleExpired);
    }

    // Start low-frequency fallback (safety net)
    _fallbackTimer = Timer.periodic(
      Duration(minutes: PerfConfig.expiryFallbackCheckMinutes),
      (_) => _checkNow(),
    );
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  void _checkNow() {
    if (_hasExpired) return;
    if (!Get.isRegistered<ServiceBrandContext>()) return;
    final brandCtx = Get.find<ServiceBrandContext>();
    if (brandCtx.planDetails != null && brandCtx.isPlanExpired) {
      _handleExpired();
    }
  }

  Future<void> _handleExpired() async {
    if (_hasExpired) return; // prevent double-fire
    _hasExpired = true;
    _precisionTimer?.cancel();
    _fallbackTimer?.cancel();

    debugPrint('[PlanExpiryGuard] ⚠ Plan expired — logging out');

    if (!Get.isRegistered<ServiceBrandContext>()) return;
    final brandCtx = Get.find<ServiceBrandContext>();
    final branch = brandCtx.selectedBranch;
    final plan = branch?.planDetails;

    // Show blocking dialog
    if (Get.context != null && plan != null) {
      DialogPlanExpiredBlock.show(Get.context!, branch: branch, plan: plan);
    }

    // Logout
    if (Get.isRegistered<AuthRepository>()) {
      await Get.find<AuthRepository>().logout();
    }
    if (Get.isRegistered<RepoStorage>()) {
      await Get.find<RepoStorage>().logout();
    }
    Get.offAllNamed(AppRoute.login);
  }
}
