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
import 'controller_home.dart';
import 'fragment/dashboard/frag_home_dashboard.dart';
import 'fragment/frag_home_logout.dart';
import 'fragment/report/frag_home_report.dart';
import 'fragment/report/frag_sales_report.dart';
import 'fragment/report/frag_inventory_report.dart';
import 'fragment/report/controller_inventory_report.dart';
import 'fragment/report/frag_purchase_report.dart';
import 'fragment/report/controller_purchase_report.dart';
import 'fragment/report/frag_profit_report.dart';
import 'fragment/report/controller_profit_report.dart';
import 'fragment/report/frag_return_report.dart';
import 'fragment/report/controller_return_report.dart';
import 'fragment/report/frag_supplier_report.dart';
import 'fragment/report/controller_supplier_report.dart';
import 'fragment/report/frag_cashier_report.dart';
import 'fragment/report/controller_cashier_report.dart';
import 'fragment/report/frag_financial_report.dart';
import 'fragment/report/controller_financial_report.dart';
import 'fragment/setting/frag_home_settings.dart';
import 'fragment/setting/controller_home_settings.dart';
import 'fragment/users/frag_home_users.dart';

class ActivityHome extends StatelessWidget {
  const ActivityHome({super.key});

  @override
  Widget build(BuildContext context) {
    ControllerHome controller = Get.put(ControllerHome(), permanent: true);
    // Register Settings controller globally so bill details can always display store info
    if (!Get.isRegistered<ControllerHomeSettings>()) {
      Get.put(ControllerHomeSettings(), permanent: true);
    }
    return Scaffold(
      body: Row(
        children: [
          Obx(() {
            EntityUser? user = controller.rxUser.value;
            if (user == null) {
              return SizedBox();
            }
            return SizedBox(
              width: controller.isDrawerCollapsed.value ? 70 : 200,
              child: RepoDrawer.drawerList(user),
            );
          }),

          Expanded(
            child: Obx(() {
              // return Center(
              //   child: Text(controller.selectedMainMenu.value.toString()),
              // );
              if (controller.selectedMainMenu.value == EnumMainMenu.dashboard) {
                return FragHomeDashboard();
              }
              if (controller.selectedMainMenu.value == EnumMainMenu.pos) {
                return FragmentHomePos();
              }
              if (controller.selectedMainMenu.value == EnumMainMenu.item) {
                return FragmentHomeItem();
              }
              if (controller.selectedMainMenu.value == EnumMainMenu.stocks) {
                return FragmentHomeStock();
              }
              if (controller.selectedMainMenu.value == EnumMainMenu.customer) {
                return FragmentHomeCustomer();
              }
              if (controller.selectedMainMenu.value == EnumMainMenu.reports) {
                return const FragSalesReport();
              }
              if(controller.selectedMainMenu.value == EnumMainMenu.purchase){
                return FragmentHomePurchase();
              }
              if(controller.selectedMainMenu.value == EnumMainMenu.supplier){
                return FragmentHomeSupplier();
              }
              if (controller.selectedMainMenu.value ==
                  EnumMainMenu.systemUsers) {
                return FragHomeUsers(entityUser: controller.rxUser.value);
              }
              if (controller.selectedMainMenu.value == EnumMainMenu.settings) {
                return FragHomeSettings();
              }
              if (controller.selectedMainMenu.value == EnumMainMenu.logout) {
                return FragHomeLogout();
              }
              if(controller.selectedMainMenu.value == EnumMainMenu.expenses){
                return FragmentHomeExpenses();
              }

              // ── Sales Reports (single entry under Reports → Sales Reports) ──
              if (controller.selectedMainMenu.value == EnumMainMenu.reportGroupSales) {
                return const FragSalesReport();
              }

              // ── Inventory Reports (single entry under Reports → Inventory Reports) ──
              if (controller.selectedMainMenu.value == EnumMainMenu.reportGroupInventory) {
                return const FragInventoryReport();
              }
              if (controller.selectedMainMenu.value == EnumMainMenu.reportCurrentStock) {
                return const FragInventoryReport(initialReportType: InventoryReportType.currentStock);
              }
              if (controller.selectedMainMenu.value == EnumMainMenu.reportLowStock) {
                return const FragInventoryReport(initialReportType: InventoryReportType.lowStock);
              }
              if (controller.selectedMainMenu.value == EnumMainMenu.reportOutOfStock) {
                return const FragInventoryReport(initialReportType: InventoryReportType.outOfStock);
              }
              if (controller.selectedMainMenu.value == EnumMainMenu.reportStockMovement) {
                return const FragInventoryReport(initialReportType: InventoryReportType.stockMovement);
              }
              if (controller.selectedMainMenu.value == EnumMainMenu.reportStockAdjustment) {
                return const FragInventoryReport(initialReportType: InventoryReportType.stockAdjustment);
              }
              if (controller.selectedMainMenu.value == EnumMainMenu.reportStockValuation) {
                return const FragInventoryReport(initialReportType: InventoryReportType.stockValuation);
              }
              if (controller.selectedMainMenu.value == EnumMainMenu.reportExpiry) {
                return const FragInventoryReport(initialReportType: InventoryReportType.expiry);
              }
              if (controller.selectedMainMenu.value == EnumMainMenu.reportNearExpiry) {
                return const FragInventoryReport(initialReportType: InventoryReportType.nearExpiry);
              }

              // ── Purchase Reports (single entry under Reports → Purchase Reports) ──
              if (controller.selectedMainMenu.value == EnumMainMenu.reportGroupPurchase) {
                return const FragPurchaseReport();
              }
              if (controller.selectedMainMenu.value == EnumMainMenu.reportPurchaseSummary) {
                return const FragPurchaseReport(initialReportType: PurchaseReportType.purchaseSummary);
              }
              if (controller.selectedMainMenu.value == EnumMainMenu.reportPurchaseDetail) {
                return const FragPurchaseReport(initialReportType: PurchaseReportType.purchaseDetail);
              }
              if (controller.selectedMainMenu.value == EnumMainMenu.reportSupplierPurchase) {
                return const FragPurchaseReport(initialReportType: PurchaseReportType.supplierPurchase);
              }
              if (controller.selectedMainMenu.value == EnumMainMenu.reportPendingPurchaseOrders) {
                return const FragPurchaseReport(initialReportType: PurchaseReportType.pendingPurchaseOrders);
              }
              if (controller.selectedMainMenu.value == EnumMainMenu.reportGroupReturn) {
                return const FragReturnReport();
              }
              if (controller.selectedMainMenu.value == EnumMainMenu.reportSalesReturn) {
                return const FragReturnReport(initialReportType: ReturnReportType.salesReturn);
              }
              if (controller.selectedMainMenu.value == EnumMainMenu.reportPurchaseReturn) {
                return const FragReturnReport(initialReportType: ReturnReportType.purchaseReturn);
              }

              // ── Profit Reports (single entry under Reports → Profit Reports) ──
              if (controller.selectedMainMenu.value == EnumMainMenu.reportGroupProfit) {
                return const FragProfitReport();
              }
              if (controller.selectedMainMenu.value == EnumMainMenu.reportGrossProfit) {
                return const FragProfitReport(initialReportType: ProfitReportType.profitSummary);
              }
              if (controller.selectedMainMenu.value == EnumMainMenu.reportProfitByItem) {
                return const FragProfitReport(initialReportType: ProfitReportType.itemProfit);
              }
              if (controller.selectedMainMenu.value == EnumMainMenu.reportProfitByCategory) {
                return const FragProfitReport(initialReportType: ProfitReportType.categoryProfit);
              }

              // ── Supplier Reports (single entry under Reports → Supplier Reports) ──
              if (controller.selectedMainMenu.value == EnumMainMenu.reportGroupSupplier) {
                return const FragSupplierReport();
              }
              if (controller.selectedMainMenu.value == EnumMainMenu.reportSupplierPurchaseHistory) {
                return const FragSupplierReport(initialReportType: SupplierReportType.purchaseHistory);
              }
              if (controller.selectedMainMenu.value == EnumMainMenu.reportSupplierOutstanding) {
                return const FragSupplierReport(initialReportType: SupplierReportType.outstanding);
              }

              // ── Cashier Reports (single entry under Reports → Cashier Reports) ──
              if (controller.selectedMainMenu.value == EnumMainMenu.reportGroupCashier) {
                return const FragCashierReport();
              }
              if (controller.selectedMainMenu.value == EnumMainMenu.reportCashierSales) {
                return const FragCashierReport(initialReportType: CashierReportType.cashierSales);
              }
              if (controller.selectedMainMenu.value == EnumMainMenu.reportCashierShift) {
                return const FragCashierReport(initialReportType: CashierReportType.cashierShift);
              }

              // ── Financial Reports (single entry under Reports → Financial Reports) ──
              if (controller.selectedMainMenu.value == EnumMainMenu.reportGroupFinancial) {
                return const FragFinancialReport();
              }
              if (controller.selectedMainMenu.value == EnumMainMenu.reportPaymentCollection) {
                return const FragFinancialReport(initialReportType: FinancialReportType.paymentCollection);
              }
              if (controller.selectedMainMenu.value == EnumMainMenu.reportDailyCashClosing) {
                return const FragFinancialReport(initialReportType: FinancialReportType.dailyCashClosing);
              }
              if (controller.selectedMainMenu.value == EnumMainMenu.reportTaxGST) {
                return const FragFinancialReport(initialReportType: FinancialReportType.taxGST);
              }

              return FragComingSoon();
            }),
          ),
        ],
      ),
    );
  }
}
