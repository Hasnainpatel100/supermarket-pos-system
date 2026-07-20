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

  reportSalesView,
  reportStockView,
  reportProfitView,
  reportTaxView,
  reportExport,

  // System / Admin
  userCreate,
  userUpdate,
  userDisable,
  roleAssign,
  systemSettingsUpdate,
  dataSyncManual,
  auditLogView,

  //Expenses
  expenses,

  // for app purpose only
  dashboard,
  logout,
}
