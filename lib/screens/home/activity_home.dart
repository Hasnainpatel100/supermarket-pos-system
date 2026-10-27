import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:super_market/screens/home/fragment/customer/fragment_home_customer.dart';
import 'package:super_market/screens/home/fragment/expenses/fragment_home_expenses.dart';
import 'package:super_market/screens/home/fragment/item/fragment_home_item.dart';
import 'package:super_market/screens/home/fragment/pos/fragment_home_pos.dart';
import 'package:super_market/screens/home/fragment/purchase_supplier/purchase/frag_home_purchase.dart';
import 'package:super_market/screens/home/fragment/purchase_supplier/supplier/frag_home_supplier.dart';
import 'package:super_market/screens/home/fragment/stocks/fragment_home_stock.dart';
import '../../commons/frag_coming_soon.dart';
import '../../enums/enum_main_menu.dart';
import '../../model/entity_user.dart';
import '../../repository/repo_drawer.dart';
import '../../service/service_locale.dart';
import 'controller_home.dart';
import 'fragment/dashboard/frag_home_dashboard.dart';
import 'fragment/frag_home_logout.dart';
import 'fragment/bills/frag_sales_report.dart';
import 'fragment/bills/frag_inventory_report.dart';
import 'fragment/bills/controller_inventory_report.dart';
import 'fragment/bills/frag_purchase_report.dart';
import 'fragment/bills/controller_purchase_report.dart';
import 'fragment/bills/frag_profit_report.dart';
import 'fragment/bills/controller_profit_report.dart';
import 'fragment/bills/frag_return_report.dart';
import 'fragment/bills/controller_return_report.dart';
import 'fragment/bills/frag_supplier_report.dart';
import 'fragment/bills/controller_supplier_report.dart';
import 'fragment/bills/frag_cashier_report.dart';
import 'fragment/bills/controller_cashier_report.dart';
import 'fragment/bills/frag_financial_report.dart';
import 'fragment/bills/controller_financial_report.dart';
import 'fragment/setting/frag_home_settings.dart';
import 'fragment/setting/controller_home_settings.dart';
import 'fragment/system/frag_home_backup.dart';
import 'fragment/system/frag_audit_logs.dart';
import 'fragment/account/fragment_home_account.dart';
import '../sales/invoice/frag_sales_invoices.dart';
import '../sales/quotation/frag_quotations.dart';
import '../sales/returns/frag_sales_returns.dart';
import '../../features/voice_billing/activity_voice_billing.dart';
import '../../features/voice_billing/activity_voice_sales_history.dart';

class ActivityHome extends StatelessWidget {
  const ActivityHome({super.key});

  @override
  Widget build(BuildContext context) {
    ControllerHome controller = Get.isRegistered<ControllerHome>()
        ? Get.find<ControllerHome>()
        : Get.put(ControllerHome());
    final localeService = Get.find<ServiceLocale>();

    // Never allow home screen to remain stuck on logout menu
    if (controller.selectedMainMenu.value == EnumMainMenu.logout) {
      controller.selectedMainMenu.value = EnumMainMenu.account;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        controller.checkAndPromptDayShift(context);
        controller.checkDeviceLimit(context);
      }
    });

    // Register Settings controller globally so bill details can always display store info
    if (!Get.isRegistered<ControllerHomeSettings>()) {
      Get.put(ControllerHomeSettings(), permanent: true);
    }
    return Scaffold(
      body: Row(
        children: [
          Obx(() {
            final _ = localeService.rxLocale.value;
            EntityUser? user = controller.rxUser.value;
            if (user == null) {
              return SizedBox();
            }
            final isCollapsed = controller.isDrawerCollapsed.value;
            final drawerWidth = isCollapsed ? 70.0 : 200.0;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: drawerWidth,
              child: ClipRect(
                child: OverflowBox(
                  alignment: Alignment.topLeft,
                  minWidth: drawerWidth,
                  maxWidth: drawerWidth,
                  child: SizedBox(
                    width: drawerWidth,
                    child: RepoDrawer.drawerList(user),
                  ),
                ),
              ),
            );
          }),

          Expanded(
            child: Obx(() {
              if (controller.hasNoPermissions) {
                return _buildNoPermissionsFragment(context);
              }
              final activeLocale = localeService.rxLocale.value.toString();
              final selectedMenu = controller.selectedMainMenu.value;
              return KeyedSubtree(
                key: ValueKey('${selectedMenu.name}_$activeLocale'),
                child: _buildFragment(selectedMenu, controller.rxUser.value, context),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildNoPermissionsFragment(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shield_outlined,
                size: 56,
                color: Colors.amber,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Access Denied',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your account does not have any active permissions assigned. Please contact your store administrator to assign your role.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                  ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () {
                final ctrl = Get.find<ControllerHome>();
                ctrl.selectedMainMenu.value = EnumMainMenu.logout;
              },
              icon: const Icon(Icons.logout),
              label: Text('logout'.tr),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFragment(EnumMainMenu menu, EntityUser? user, BuildContext context) {
    final ControllerHome controller = Get.find<ControllerHome>();
    if (!controller.canAccessMenu(menu)) {
      return _buildNoPermissionsFragment(context);
    }
    if (menu == EnumMainMenu.dashboard) {
      return FragHomeDashboard();
    }
    if (menu == EnumMainMenu.pos) {
      return FragmentHomePos();
    }
    if (menu == EnumMainMenu.voiceBilling || menu == EnumMainMenu.voiceBillingGroup) {
      return const ActivityVoiceBilling();
    }
    if (menu == EnumMainMenu.voiceSalesHistory) {
      return const ActivityVoiceSalesHistory();
    }
    if (menu == EnumMainMenu.item) {
      return FragmentHomeItem();
    }
    if (menu == EnumMainMenu.stocks) {
      return FragmentHomeStock();
    }
    if (menu == EnumMainMenu.customer) {
      return FragmentHomeCustomer();
    }
    if (menu == EnumMainMenu.salesInvoices || menu == EnumMainMenu.salesGroup) {
      return const FragSalesInvoices();
    }
    if (menu == EnumMainMenu.quotationEstimate) {
      return const FragQuotations();
    }
    if (menu == EnumMainMenu.salesReturn) {
      return const FragSalesReturns();
    }
    if (menu == EnumMainMenu.reports) {
      return const FragSalesReport();
    }
    if (menu == EnumMainMenu.purchase) {
      return FragmentHomePurchase();
    }
    if (menu == EnumMainMenu.supplier) {
      return FragmentHomeSupplier();
    }
    if (menu == EnumMainMenu.settings) {
      return FragHomeSettings();
    }
    if (menu == EnumMainMenu.logout) {
      return FragHomeLogout();
    }
    if (menu == EnumMainMenu.expenses) {
      return FragmentHomeExpenses();
    }
    if (menu == EnumMainMenu.account) {
      return const FragmentHomeAccount();
    }
    if (menu == EnumMainMenu.backup) {
      return const FragHomeBackup();
    }
    if (menu == EnumMainMenu.auditLogs) {
      return const FragAuditLogs();
    }
    if (menu == EnumMainMenu.reportGroupSales) {
      return const FragSalesReport();
    }
    if (menu == EnumMainMenu.reportGroupInventory) {
      return const FragInventoryReport();
    }
    if (menu == EnumMainMenu.reportCurrentStock) {
      return const FragInventoryReport(initialReportType: InventoryReportType.currentStock);
    }
    if (menu == EnumMainMenu.reportLowStock) {
      return const FragInventoryReport(initialReportType: InventoryReportType.lowStock);
    }
    if (menu == EnumMainMenu.reportOutOfStock) {
      return const FragInventoryReport(initialReportType: InventoryReportType.outOfStock);
    }
    if (menu == EnumMainMenu.reportStockMovement) {
      return const FragInventoryReport(initialReportType: InventoryReportType.stockMovement);
    }
    if (menu == EnumMainMenu.reportStockAdjustment) {
      return const FragInventoryReport(initialReportType: InventoryReportType.stockAdjustment);
    }
    if (menu == EnumMainMenu.reportStockValuation) {
      return const FragInventoryReport(initialReportType: InventoryReportType.stockValuation);
    }
    if (menu == EnumMainMenu.reportExpiry) {
      return const FragInventoryReport(initialReportType: InventoryReportType.expiry);
    }
    if (menu == EnumMainMenu.reportNearExpiry) {
      return const FragInventoryReport(initialReportType: InventoryReportType.nearExpiry);
    }
    if (menu == EnumMainMenu.reportGroupPurchase) {
      return const FragPurchaseReport();
    }
    if (menu == EnumMainMenu.reportPurchaseSummary) {
      return const FragPurchaseReport(initialReportType: PurchaseReportType.purchaseSummary);
    }
    if (menu == EnumMainMenu.reportPurchaseDetail) {
      return const FragPurchaseReport(initialReportType: PurchaseReportType.purchaseDetail);
    }
    if (menu == EnumMainMenu.reportSupplierPurchase) {
      return const FragPurchaseReport(initialReportType: PurchaseReportType.supplierPurchase);
    }
    if (menu == EnumMainMenu.reportPendingPurchaseOrders) {
      return const FragPurchaseReport(initialReportType: PurchaseReportType.pendingPurchaseOrders);
    }
    if (menu == EnumMainMenu.reportGroupReturn) {
      return const FragReturnReport();
    }
    if (menu == EnumMainMenu.reportSalesReturn) {
      return const FragReturnReport(initialReportType: ReturnReportType.salesReturn);
    }
    if (menu == EnumMainMenu.reportPurchaseReturn) {
      return const FragReturnReport(initialReportType: ReturnReportType.purchaseReturn);
    }
    if (menu == EnumMainMenu.reportGroupProfit) {
      return const FragProfitReport();
    }
    if (menu == EnumMainMenu.reportGrossProfit) {
      return const FragProfitReport(initialReportType: ProfitReportType.profitSummary);
    }
    if (menu == EnumMainMenu.reportProfitByItem) {
      return const FragProfitReport(initialReportType: ProfitReportType.itemProfit);
    }
    if (menu == EnumMainMenu.reportProfitByCategory) {
      return const FragProfitReport(initialReportType: ProfitReportType.categoryProfit);
    }
    if (menu == EnumMainMenu.reportGroupSupplier) {
      return const FragSupplierReport();
    }
    if (menu == EnumMainMenu.reportSupplierPurchaseHistory) {
      return const FragSupplierReport(initialReportType: SupplierReportType.purchaseHistory);
    }
    if (menu == EnumMainMenu.reportSupplierOutstanding) {
      return const FragSupplierReport(initialReportType: SupplierReportType.outstanding);
    }
    if (menu == EnumMainMenu.reportGroupCashier) {
      return const FragCashierReport();
    }
    if (menu == EnumMainMenu.reportCashierSales) {
      return const FragCashierReport(initialReportType: CashierReportType.cashierSales);
    }
    if (menu == EnumMainMenu.reportCashierShift) {
      return const FragCashierReport(initialReportType: CashierReportType.cashierShift);
    }
    if (menu == EnumMainMenu.reportGroupFinancial) {
      return const FragFinancialReport();
    }
    if (menu == EnumMainMenu.reportPaymentCollection) {
      return const FragFinancialReport(initialReportType: FinancialReportType.paymentCollection);
    }
    if (menu == EnumMainMenu.reportDailyCashClosing) {
      return const FragFinancialReport(initialReportType: FinancialReportType.dailyCashClosing);
    }
    if (menu == EnumMainMenu.reportTaxGST) {
      return const FragFinancialReport(initialReportType: FinancialReportType.taxGST);
    }

    return FragComingSoon();
  }
}
