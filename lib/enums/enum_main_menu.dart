enum EnumMainMenu {
  dashboard,
  pos,
  inventory,
  item,
  stocks,

  pricingDiscount,
  purchaseSupplier,
  purchase,
  supplier,
  reports,
  customer,
  bills,

  system,
  systemUsers, // 1. system
  apiUser, // API User management
  systemSettings, // 2. system
  auditLogs, // 3. system
  brand, // 4. brand management
  branch, // 5. branch management

  expenses,
  account,

  backup,

  settings,
  logout,

  // ===== Reports: Categories =====
  reportGroupSales,
  reportGroupInventory,
  reportGroupPurchase,
  reportGroupProfit,
  reportGroupReturn,
  reportGroupCustomer,
  reportGroupSupplier,
  reportGroupCashier,
  reportGroupFinancial,

// ===== Reports: Sales =====
  reportSalesSummary,
  reportSalesDetail,
  reportItemSales,
  reportCategorySales,
  reportPayment,
  reportHourWiseSales,

// ===== Reports: Inventory =====
  reportCurrentStock,
  reportLowStock,
  reportOutOfStock,
  reportStockMovement,
  reportStockAdjustment,
  reportStockValuation,
  reportExpiry,
  reportNearExpiry,

// ===== Reports: Purchase =====
  reportPurchaseSummary,
  reportPurchaseDetail,
  reportSupplierPurchase,
  reportPendingPurchaseOrders,

// ===== Reports: Profit =====
  reportGrossProfit,
  reportProfitByItem,
  reportProfitByCategory,

// ===== Reports: Return =====
  reportSalesReturn,
  reportPurchaseReturn,

// ===== Reports: Customer =====
  reportCustomerPurchaseHistory,
  reportTopCustomers,
  reportCustomerOutstanding,

// ===== Reports: Supplier =====
  reportSupplierPurchaseHistory,
  reportSupplierOutstanding,

// ===== Reports: Cashier =====
  reportCashierSales,
  reportCashierShift,

// ===== Reports: Financial =====
  reportPaymentCollection,
  reportDailyCashClosing,
  reportTaxGST,
}