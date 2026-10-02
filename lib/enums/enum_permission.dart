enum EnumPermission {
  // POS / Billing
  posBillCreate,
  posBillHold,
  posBillResume,
  posBillCancel,
  posBillVoid,
  posBillReturnSameDay,
  posPaymentCollect,
  posBillReprint,

  // Inventory
  itemCreate,
  itemUpdate,
  itemView,
  stockIn,
  stockOut,
  stockAdjust,
  stockCount,
  stockView,
  expiryManage,

  // Pricing & Discount
  priceView,
  priceUpdate,
  discountApply,
  discountOverride,

  // Purchase & Supplier
  purchaseCreate,
  purchaseReceive,
  supplierManage,

  //customer
  customerCreate,
  customerEdit,
  customerDelete,


  // Reports
  // Report category permissions (gate an entire report category + its pages)
  // Reports
  reportSalesView,
  reportStockView,
  reportPurchaseView,
  reportProfitView,
  reportReturnView,
  reportCustomerView,
  reportSupplierView,
  reportCashierView,
  reportFinancialView,
  reportExport,

  // System / Admin
  userCreate,
  userUpdate,
  userDisable,
  roleAssign,
  apiUserManage,
  systemSettingsUpdate,
  dataSyncManual,
  auditLogView,
  brandManage,
  brandCreate,
  brandView,
  branchManage,
  branchCreate,
  branchView,

  //Expenses
  expenses,

  // Account & Cash Drawer
  account,

  // Backup & Recovery
  backupRestore,

  // for app purpose only
  dashboard,
  logout,

  /// Gates Brand/Branch management & API User screens.
  /// Only the software vendor's own admin accounts receive this permission.
  /// Client users (store managers, cashiers) never get it and never see those menus.
  superVendorAccess,
}
