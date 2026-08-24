import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../model/model_branch.dart';
import '../../util/snackbar_util.dart';

class DialogBranchDetails extends StatelessWidget {
  final ModelBranch branch;
  final VoidCallback? onBranchUpdated;
  final VoidCallback? onBranchDeleted;

  const DialogBranchDetails({
    super.key,
    required this.branch,
    this.onBranchUpdated,
    this.onBranchDeleted,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
      child: Center(
        child: SizedBox(
          width: 680,
          child: Card(
            elevation: 12,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ─── Header ───────────────────────────────────────────────
                _buildHeader(colorScheme),

                // ─── Body ─────────────────────────────────────────────────
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status & service chips
                        _buildBadgesRow(colorScheme),
                        const SizedBox(height: 20),

                        // Brand Reference
                        _sectionTitle('Brand', Icons.branding_watermark_rounded, Colors.indigo.shade400),
                        const SizedBox(height: 8),
                        _infoRow(Icons.storefront_rounded, 'Brand Name', branch.displayBrandName, colorScheme),
                        _infoRow(Icons.fingerprint_rounded, 'Brand ID', branch.brandId, colorScheme, canCopy: true),

                        const SizedBox(height: 16),

                        // Address
                        if (branch.address.full.isNotEmpty || branch.address.city.isNotEmpty) ...[
                          _sectionTitle('Address', Icons.location_on_rounded, Colors.blue.shade400),
                          const SizedBox(height: 8),
                          if (branch.address.full.isNotEmpty)
                            _infoRow(Icons.home_rounded, 'Full Address', branch.address.full, colorScheme),
                          if (branch.address.city.isNotEmpty)
                            _infoRow(Icons.location_city_rounded, 'City', branch.address.city, colorScheme),
                          if (branch.address.state.isNotEmpty)
                            _infoRow(Icons.map_rounded, 'State', branch.address.state, colorScheme),
                          if (branch.address.country.isNotEmpty)
                            _infoRow(Icons.flag_rounded, 'Country', branch.address.country, colorScheme),
                          if (branch.address.zipCode.isNotEmpty)
                            _infoRow(Icons.markunread_mailbox_rounded, 'ZIP Code', branch.address.zipCode, colorScheme),
                          if (branch.address.hasCoordinates)
                            _infoRow(Icons.gps_fixed_rounded, 'Coordinates',
                                '${branch.address.latitude}, ${branch.address.longitude}', colorScheme),
                          if (branch.address.gMapUrl != null && branch.address.gMapUrl!.isNotEmpty)
                            _actionRow(
                              Icons.directions_rounded,
                              'Google Maps',
                              branch.address.gMapUrl!,
                              color: Colors.blue.shade600,
                              onTap: () => _launchUrl(branch.address.gMapUrl!),
                            ),
                          const SizedBox(height: 16),
                        ],

                        // Contact
                        _sectionTitle('Contact', Icons.contact_phone_rounded, Colors.teal.shade400),
                        const SizedBox(height: 8),
                        if (branch.contact.phones.primary.isNotEmpty)
                          _actionRow(
                            Icons.phone_rounded,
                            'Primary Phone',
                            branch.contact.phones.primary,
                            color: Colors.teal.shade600,
                            onTap: () => _launchUrl('tel:${branch.contact.phones.primary}'),
                          ),
                        if (branch.contact.phones.alternate.isNotEmpty)
                          _actionRow(
                            Icons.phone_outlined,
                            'Alternate Phone',
                            branch.contact.phones.alternate,
                            color: Colors.teal.shade400,
                            onTap: () => _launchUrl('tel:${branch.contact.phones.alternate}'),
                          ),
                        if (branch.contact.phones.whatsapp.isNotEmpty)
                          _actionRow(
                            Icons.chat_rounded,
                            'WhatsApp',
                            branch.contact.phones.whatsapp,
                            color: Colors.green.shade600,
                            onTap: () => _launchUrl(
                                'https://wa.me/${branch.contact.phones.whatsapp.replaceAll(RegExp(r'[^\d+]'), '')}'),
                          ),
                        if (branch.contact.email.isNotEmpty)
                          _actionRow(
                            Icons.email_outlined,
                            'Email',
                            branch.contact.email,
                            color: Colors.purple.shade600,
                            onTap: () => _launchUrl('mailto:${branch.contact.email}'),
                          ),

                        const SizedBox(height: 16),

                        // Service Types
                        if (branch.serviceTypes.isNotEmpty) ...[
                          _sectionTitle('Service Types', Icons.room_service_rounded, Colors.orange.shade600),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: branch.serviceTypes.map((type) {
                              return Chip(
                                label: Text(
                                  type.replaceAll('_', ' '),
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                backgroundColor: Colors.deepPurple.shade400,
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Timestamps
                        if (branch.createdAt != null || branch.updatedAt != null) ...[
                          _sectionTitle('Metadata', Icons.schedule_rounded, Colors.grey.shade500),
                          const SizedBox(height: 8),
                          if (branch.createdAt != null)
                            _infoRow(Icons.add_circle_outline, 'Created', branch.createdAt!, colorScheme),
                          if (branch.updatedAt != null)
                            _infoRow(Icons.update_rounded, 'Last Updated', branch.updatedAt!, colorScheme),
                        ],
                      ],
                    ),
                  ),
                ),

                // ─── Footer ───────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    border: Border(top: BorderSide(color: colorScheme.outline.withValues(alpha: 0.1))),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        label: const Text('Copy JSON', style: TextStyle(fontSize: 12)),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: branch.toJsonString(pretty: true)));
                          SnackbarUtil.showSuccess('Branch JSON copied to clipboard');
                        },
                      ),
                      const Spacer(),
                      OutlinedButton(
                        onPressed: () => Get.back(),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 20, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple.shade600, Colors.deepPurple.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.add_business_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  branch.name.en,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        branch.branchCode,
                        style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      branch.appType,
                      style: const TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white70),
            onPressed: () => Get.back(),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesRow(ColorScheme colorScheme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: (branch.isActive ? Colors.green : Colors.red).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: branch.isActive ? Colors.green.shade300 : Colors.red.shade300),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(branch.isActive ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  size: 14, color: branch.isActive ? Colors.green.shade700 : Colors.red.shade700),
              const SizedBox(width: 4),
              Text(
                branch.status,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: branch.isActive ? Colors.green.shade700 : Colors.red.shade700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            branch.appType,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSecondaryContainer,
            ),
          ),
        ),
        if (branch.address.displaySummary.isNotEmpty) ...[
          const SizedBox(width: 8),
          Icon(Icons.location_on_rounded, size: 14, color: Colors.blue.shade400),
          const SizedBox(width: 4),
          Text(
            branch.address.displaySummary,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ],
    );
  }

  Widget _sectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: color)),
        const SizedBox(width: 8),
        Expanded(child: Divider(color: color.withValues(alpha: 0.3))),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value, ColorScheme colorScheme, {bool canCopy = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 14, color: colorScheme.onSurface.withValues(alpha: 0.4)),
          const SizedBox(width: 8),
          SizedBox(
            width: 110,
            child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          if (canCopy)
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              iconSize: 14,
              icon: const Icon(Icons.copy_rounded),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                SnackbarUtil.showSuccess('Copied!');
              },
            ),
        ],
      ),
    );
  }

  Widget _actionRow(IconData icon, String label, String value, {required Color color, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 2),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 8),
            SizedBox(
              width: 110,
              child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
            ),
            Expanded(
              child: Text(
                value,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color, decoration: TextDecoration.underline),
              ),
            ),
            Icon(Icons.open_in_new_rounded, size: 12, color: color.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri);
    } catch (_) {
      SnackbarUtil.showError('Could not open: $url');
    }
  }
}
