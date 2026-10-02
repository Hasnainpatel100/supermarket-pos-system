import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../commons/loader.dart';
import '../../../enums/enum_main_menu.dart';
import '../../../features/authentication/data/auth_repository.dart';
import '../../../repository/repo_storage.dart';
import '../../../util/app_route.dart';
import '../controller_home.dart';
import 'account/controller_home_account.dart';

/// Confirmation screen for logging out of the application.
class FragHomeLogout extends StatelessWidget {
  const FragHomeLogout({super.key});

  Future<void> _performLogout() async {
    Loader.showLoader();
    try {
      if (Get.isRegistered<AuthRepository>()) {
        await Get.find<AuthRepository>().logout();
      }

      if (Get.isRegistered<RepoStorage>()) {
        final RepoStorage repoStorage = Get.find();
        await repoStorage.logout();
      }

      if (Get.isRegistered<ControllerHome>()) {
        Get.delete<ControllerHome>(force: true);
      }
      if (Get.isRegistered<ControllerHomeAccount>()) {
        Get.delete<ControllerHomeAccount>(force: true);
      }
    } catch (e) {
      debugPrint('Notice during logout: $e');
    } finally {
      Loader.hideLoader();
      Get.offAllNamed(AppRoute.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ControllerHome controllerHome = Get.find<ControllerHome>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.grey.shade200,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: Color(0xFFEF4444),
                  size: 38,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Confirm Logout',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Are you sure you want to log out of this terminal?',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      controllerHome.selectedMainMenu.value = EnumMainMenu.pos;
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _performLogout,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

