import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../model/model_brand.dart';
import '../../repository/repo_brand.dart';
import '../../util/snackbar_util.dart';
import '../../widget/app_dialog_components.dart';
import 'activity_brand_form.dart';

class DialogBrandDetails extends StatelessWidget {
  final ModelBrand brand;
  final VoidCallback? onBrandUpdated;
  final VoidCallback? onBrandDeleted;

  const DialogBrandDetails({
    super.key,
    required this.brand,
    this.onBrandUpdated,
    this.onBrandDeleted,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isActive = brand.isActive;

    return AppDialog(
      maxWidth: 720,
      maxHeight: 700,
      header: DialogHeader(
        title: brand.name.en,
        icon: Icons.storefront_rounded,
        iconColor: colorScheme.primary,
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (isActive ? Colors.green : Colors.red).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: (isActive ? Colors.green : Colors.red).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isActive ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  size: 14,
                  color: isActive ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  brand.status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isActive ? Colors.green.shade800 : Colors.red.shade800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: DialogBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── Header Info Card ───
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primaryContainer.withValues(alpha: 0.4),
                    colorScheme.surface,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colorScheme.outline.withValues(alpha: 0.12)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: brand.isMarket
                            ? [Colors.teal.shade400, Colors.teal.shade700]
                            : [Colors.deepOrange.shade400, Colors.deepOrange.shade700],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: (brand.isMarket ? Colors.teal : Colors.deepOrange).withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        brand.isMarket
                            ? Icons.shopping_basket_rounded
                            : Icons.restaurant_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          brand.name.en,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                brand.appType,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSecondaryContainer,
                                ),
                              ),
                            ),
                            if (brand.id != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                'ID: ${brand.id}',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ─── Registration Info ───
            FormSection(
              title: 'REGISTRATION & TAX DETAILS',
              icon: Icons.verified_rounded,
              color: Colors.teal.shade700,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                    'GST / VAT Number',
                    brand.registration.gstNo.isNotEmpty ? brand.registration.gstNo : 'N/A',
                    Icons.pin_rounded,
                  ),
                  const Divider(height: 16),
                  _buildDetailRow(
                    'GST / Tax Type',
                    brand.registration.gstType,
                    Icons.account_balance_rounded,
                  ),
                  const Divider(height: 16),
                  _buildDetailRow(
                    'GST Registration Date',
                    brand.registration.gstRegistrationDate.isNotEmpty
                        ? brand.registration.gstRegistrationDate
                        : 'N/A',
                    Icons.calendar_today_rounded,
                  ),
                  if (brand.registration.fssaiNo.isNotEmpty) ...[
                    const Divider(height: 16),
                    _buildDetailRow(
                      'FSSAI License No',
                      brand.registration.fssaiNo,
                      Icons.security_rounded,
                    ),
                  ],
                  if (brand.registration.fssaiExpiryDate.isNotEmpty) ...[
                    const Divider(height: 16),
                    _buildDetailRow(
                      'FSSAI Expiry Date',
                      brand.registration.fssaiExpiryDate,
                      Icons.event_busy_rounded,
                    ),
                  ],
                  if (brand.registration.cin.isNotEmpty) ...[
                    const Divider(height: 16),
                    _buildDetailRow(
                      'CIN',
                      brand.registration.cin,
                      Icons.business_rounded,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ─── Contact Information ───
            FormSection(
              title: 'CONTACT DETAILS',
              icon: Icons.phone_in_talk_rounded,
              color: Colors.blue.shade700,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                    'Primary Phone',
                    brand.contact.phones.primary.isNotEmpty
                        ? brand.contact.phones.primary
                        : 'N/A',
                    Icons.phone_rounded,
                    onTap: brand.contact.phones.primary.isNotEmpty
                        ? () => _launch('tel:${brand.contact.phones.primary}')
                        : null,
                  ),
                  if (brand.contact.phones.alternate.isNotEmpty) ...[
                    const Divider(height: 16),
                    _buildDetailRow(
                      'Alternate Phone',
                      brand.contact.phones.alternate,
                      Icons.phone_callback_rounded,
                      onTap: () => _launch('tel:${brand.contact.phones.alternate}'),
                    ),
                  ],
                  if (brand.contact.phones.whatsapp.isNotEmpty) ...[
                    const Divider(height: 16),
                    _buildDetailRow(
                      'WhatsApp',
                      brand.contact.phones.whatsapp,
                      Icons.chat_bubble_rounded,
                      actionIcon: Icons.open_in_new_rounded,
                      actionTooltip: 'Open in WhatsApp',
                      onTap: () {
                        final clean = brand.contact.phones.whatsapp.replaceAll(RegExp(r'\D'), '');
                        _launch('https://wa.me/$clean');
                      },
                    ),
                  ],
                  if (brand.contact.email.isNotEmpty) ...[
                    const Divider(height: 16),
                    _buildDetailRow(
                      'Email Address',
                      brand.contact.email,
                      Icons.email_rounded,
                      actionIcon: Icons.send_rounded,
                      actionTooltip: 'Send Email',
                      onTap: () => _launch('mailto:${brand.contact.email}'),
                    ),
                  ],
                  if (brand.contact.website.isNotEmpty) ...[
                    const Divider(height: 16),
                    _buildDetailRow(
                      'Website',
                      brand.contact.website,
                      Icons.language_rounded,
                      actionIcon: Icons.open_in_browser_rounded,
                      actionTooltip: 'Visit Website',
                      onTap: () => _launch(brand.contact.website),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ─── JSON Data Inspector ───
            FormSection(
              title: 'API JSON STRUCTURE',
              icon: Icons.code_rounded,
              color: Colors.purple.shade600,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Payload Format',
                        style: TextStyle(
                          color: Colors.cyanAccent,
                          fontFamily: 'monospace',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, color: Colors.white70, size: 16),
                        tooltip: 'Copy JSON',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: brand.toJsonString(pretty: true)));
                          SnackbarUtil.showSuccess('JSON copied to clipboard');
                        },
                      ),
                    ],
                  ),
                  SelectableText(
                    brand.toJsonString(pretty: true),
                    style: const TextStyle(
                      color: Color(0xFFA6E22E),
                      fontFamily: 'monospace',
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      footer: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: colorScheme.outline.withValues(alpha: 0.12))),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SecondaryButton(
              label: 'Close',
              icon: Icons.close_rounded,
              onPressed: () => Get.back(),
            ),
            const SizedBox(width: 12),
            PrimaryButton(
              label: 'Edit Brand',
              icon: Icons.edit_rounded,
              backgroundColor: Colors.blue.shade700,
              onPressed: () async {
                Get.back();
                final result = await Get.dialog(
                  ActivityBrandForm(editingBrand: brand),
                  barrierDismissible: false,
                );
                if (result != null && onBrandUpdated != null) {
                  onBrandUpdated!();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon, {
    VoidCallback? onTap,
    IconData? actionIcon,
    String? actionTooltip,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey.shade600),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: onTap != null ? Colors.blue.shade700 : null,
              ),
            ),
            if (actionIcon != null) ...[
              const SizedBox(width: 6),
              Icon(actionIcon, size: 14, color: Colors.blue.shade700),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _launch(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Could not launch $url: $e');
    }
  }
}
