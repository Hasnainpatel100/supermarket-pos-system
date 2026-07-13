import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'controller_login.dart';

class ActivityLogin extends GetView<ControllerLogin> {
  const ActivityLogin({super.key});

  @override
  Widget build(BuildContext context) {
    ControllerLogin controller = Get.put(ControllerLogin());
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── Branded Header ──
                  _buildHeader(colorScheme, isDark),
                  const SizedBox(height: 40),

                  // ── Login Card ──
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Section title
                          Text(
                            'Sign In',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Enter your credentials to continue',
                            style:
                                Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                          ),
                          const SizedBox(height: 28),

                          // ── Username / Email Field ──
                          Text(
                            'Username',
                            style:
                                Theme.of(context).textTheme.labelLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: controller.emailController,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              hintText: 'Enter your username',
                              hintStyle: TextStyle(
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.35),
                              ),
                              prefixIcon: Icon(
                                Icons.person_outline_rounded,
                                color: colorScheme.primary,
                                size: 20,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: colorScheme.outline
                                      .withValues(alpha: 0.2),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: colorScheme.outline
                                      .withValues(alpha: 0.2),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: colorScheme.primary,
                                  width: 1.5,
                                ),
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : colorScheme.surfaceContainerLowest,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // ── Password Field ──
                          Text(
                            'Password',
                            style:
                                Theme.of(context).textTheme.labelLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                          ),
                          const SizedBox(height: 8),
                          Obx(
                            () => TextField(
                              controller: controller.passwordController,
                              obscureText: controller.isPasswordHidden.value,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => controller.login(),
                              decoration: InputDecoration(
                                hintText: 'Enter your password',
                                hintStyle: TextStyle(
                                  color: colorScheme.onSurface
                                      .withValues(alpha: 0.35),
                                ),
                                prefixIcon: Icon(
                                  Icons.lock_outline_rounded,
                                  color: colorScheme.primary,
                                  size: 20,
                                ),
                                suffixIcon: IconButton(
                                  icon: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 200),
                                    child: Icon(
                                      controller.isPasswordHidden.value
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      key: ValueKey(
                                          controller.isPasswordHidden.value),
                                      color: colorScheme.onSurface
                                          .withValues(alpha: 0.5),
                                      size: 20,
                                    ),
                                  ),
                                  onPressed:
                                      controller.togglePasswordVisibility,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: colorScheme.outline
                                        .withValues(alpha: 0.2),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: colorScheme.outline
                                        .withValues(alpha: 0.2),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: colorScheme.primary,
                                    width: 1.5,
                                  ),
                                ),
                                filled: true,
                                fillColor: isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : colorScheme.surfaceContainerLowest,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),

                          // ── Login Button ──
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: FilledButton.icon(
                              onPressed: controller.login,
                              icon: const Icon(Icons.login_rounded, size: 20),
                              label: const Text(
                                'Sign In',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: FilledButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Footer ──
                  Text(
                    'Supermarket POS v1.0.0',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme, bool isDark) {
    return Column(
      children: [
        // Logo container
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primary,
                colorScheme.primary.withValues(alpha: 0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.storefront_rounded,
            color: Colors.white,
            size: 40,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Inventory POS',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Point of Sale System',
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}
