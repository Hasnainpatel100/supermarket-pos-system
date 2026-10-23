/// Centralized catalog of all RBAC permissions managed by the backend.
/// Using string constants ensures type-safety, IDE autocomplete, and prevents typos.
class AppPermissions {
  // ──────────────────────────────────────────────────────────────────────────
  // Core POS Application Permissions (72 Permissions)
  // ──────────────────────────────────────────────────────────────────────────

  // ── 1. Orders & Point of Sale (POS) (8) ───────────────────────────────────
  static const String orderCreate = 'ORDER_CREATE';
  static const String orderRead = 'ORDER_READ';
  static const String orderUpdate = 'ORDER_UPDATE';
  static const String orderDelete = 'ORDER_DELETE';
  static const String orderList = 'ORDER_LIST';
  static const String orderCancel = 'ORDER_CANCEL';
  static const String orderRefund = 'ORDER_REFUND';
  static const String orderReprint = 'ORDER_REPRINT';

  // ── 2. Payments & Cash Register (7) ───────────────────────────────────────
  static const String paymentProcess = 'PAYMENT_PROCESS';
  static const String refundProcess = 'REFUND_PROCESS';
  static const String paymentView = 'PAYMENT_VIEW';
  static const String paymentRefund = 'PAYMENT_REFUND';
  static const String paymentViewReports = 'PAYMENT_VIEW_REPORTS';
  static const String paymentCancel = 'PAYMENT_CANCEL';
  static const String drawerOpenManual = 'DRAWER_OPEN_MANUAL';

  // ── 3. Inventory, Catalog & Scanning (9) ──────────────────────────────────
  static const String inventoryCreate = 'INVENTORY_CREATE';
  static const String inventoryRead = 'INVENTORY_READ';
  static const String inventoryUpdate = 'INVENTORY_UPDATE';
  static const String inventoryDelete = 'INVENTORY_DELETE';
  static const String barcodeScan = 'BARCODE_SCAN';
  static const String weightBasedPricing = 'WEIGHT_BASED_PRICING';
  static const String bulkItemImport = 'BULK_ITEM_IMPORT';
  static const String stockAdjust = 'STOCK_ADJUST';
  static const String expiryManage = 'EXPIRY_MANAGE';

  // ── 4. Pricing & POS Security (3) ─────────────────────────────────────────
  static const String discountApply = 'DISCOUNT_APPLY';
  static const String discountOverride = 'DISCOUNT_OVERRIDE';
  static const String priceOverride = 'PRICE_OVERRIDE';

  // ── 5. Customers (5) ──────────────────────────────────────────────────────
  static const String customerCreate = 'CUSTOMER_CREATE';
  static const String createCustomer = 'CREATE_CUSTOMER';
  static const String customerRead = 'CUSTOMER_READ';
  static const String customerUpdate = 'CUSTOMER_UPDATE';
  static const String customerDelete = 'CUSTOMER_DELETE';
  static const String customerList = 'CUSTOMER_LIST';

  // ── 6. Suppliers (5) ──────────────────────────────────────────────────────
  static const String supplierCreate = 'SUPPLIER_CREATE';
  static const String supplierRead = 'SUPPLIER_READ';
  static const String supplierUpdate = 'SUPPLIER_UPDATE';
  static const String supplierDelete = 'SUPPLIER_DELETE';
  static const String supplierList = 'SUPPLIER_LIST';

  // ── 7. Purchases (6) ──────────────────────────────────────────────────────
  static const String purchaseCreate = 'PURCHASE_CREATE';
  static const String purchaseRead = 'PURCHASE_READ';
  static const String purchaseUpdate = 'PURCHASE_UPDATE';
  static const String purchaseDelete = 'PURCHASE_DELETE';
  static const String purchaseList = 'PURCHASE_LIST';
  static const String purchaseReceive = 'PURCHASE_RECEIVE';

  // ── 8. Expenses (5) ───────────────────────────────────────────────────────
  static const String expenseCreate = 'EXPENSE_CREATE';
  static const String expenseRead = 'EXPENSE_READ';
  static const String expenseUpdate = 'EXPENSE_UPDATE';
  static const String expenseDelete = 'EXPENSE_DELETE';
  static const String expenseApprove = 'EXPENSE_APPROVE';

  // ── 9. Accounts & Cash Movements (5) ──────────────────────────────────────
  static const String accountCreate = 'ACCOUNT_CREATE';
  static const String accountRead = 'ACCOUNT_READ';
  static const String accountUpdate = 'ACCOUNT_UPDATE';
  static const String accountDelete = 'ACCOUNT_DELETE';
  static const String accountManage = 'ACCOUNT_MANAGE';

  // ── 10. Taxes (6) ─────────────────────────────────────────────────────────
  static const String taxCreate = 'TAX_CREATE';
  static const String taxRead = 'TAX_READ';
  static const String taxUpdate = 'TAX_UPDATE';
  static const String taxDelete = 'TAX_DELETE';
  static const String taxList = 'TAX_LIST';
  static const String taxManageGroups = 'TAX_MANAGE_GROUPS';

  // ── 11. Reports (5) ───────────────────────────────────────────────────────
  static const String reportView = 'REPORT_VIEW';
  static const String reportViewSales = 'REPORT_VIEW_SALES';
  static const String reportViewFinancial = 'REPORT_VIEW_FINANCIAL';
  static const String reportViewUserActivity = 'REPORT_VIEW_USER_ACTIVITY';
  static const String reportExport = 'REPORT_EXPORT';

  // ── 12. Dashboard (2) ─────────────────────────────────────────────────────
  static const String dashboardView = 'DASHBOARD_VIEW';
  static const String dashboardExport = 'DASHBOARD_EXPORT';

  // ── 13. System Maintenance & Settings (4) ─────────────────────────────────
  static const String systemViewLogs = 'SYSTEM_VIEW_LOGS';
  static const String systemManageConfig = 'SYSTEM_MANAGE_CONFIG';
  static const String systemBackup = 'SYSTEM_BACKUP';
  static const String systemMaintenance = 'SYSTEM_MAINTENANCE';

  // ── 14. Plan & Subscription (2) ───────────────────────────────────────────
  static const String planRead = 'PLAN_READ';
  static const String subscriptionRead = 'SUBSCRIPTION_READ';

  /// Complete list of 72 operational permissions for the POS application.
  static const List<String> posPermissions = [
    // Orders & POS (8)
    orderCreate,
    orderRead,
    orderUpdate,
    orderDelete,
    orderList,
    orderCancel,
    orderRefund,
    orderReprint,
    // Payments & Cash Register (7)
    paymentProcess,
    refundProcess,
    paymentView,
    paymentRefund,
    paymentViewReports,
    paymentCancel,
    drawerOpenManual,
    // Inventory (9)
    inventoryCreate,
    inventoryRead,
    inventoryUpdate,
    inventoryDelete,
    barcodeScan,
    weightBasedPricing,
    bulkItemImport,
    stockAdjust,
    expiryManage,
    // Pricing & POS Security (3)
    discountApply,
    discountOverride,
    priceOverride,
    // Customers (5)
    customerCreate,
    customerRead,
    customerUpdate,
    customerDelete,
    customerList,
    // Suppliers (5)
    supplierCreate,
    supplierRead,
    supplierUpdate,
    supplierDelete,
    supplierList,
    // Purchases (6)
    purchaseCreate,
    purchaseRead,
    purchaseUpdate,
    purchaseDelete,
    purchaseList,
    purchaseReceive,
    // Expenses (5)
    expenseCreate,
    expenseRead,
    expenseUpdate,
    expenseDelete,
    expenseApprove,
    // Accounts (5)
    accountCreate,
    accountRead,
    accountUpdate,
    accountDelete,
    accountManage,
    // Taxes (6)
    taxCreate,
    taxRead,
    taxUpdate,
    taxDelete,
    taxList,
    taxManageGroups,
    // Reports (5)
    reportView,
    reportViewSales,
    reportViewFinancial,
    reportViewUserActivity,
    reportExport,
    // Dashboard (2)
    dashboardView,
    dashboardExport,
    // System Maintenance & Hardware (5)
    systemViewLogs,
    systemManageConfig,
    systemBackup,
    systemMaintenance,
    deviceManage,
    // Plan & Subscription (2)
    planRead,
    subscriptionRead,
  ];

  // ──────────────────────────────────────────────────────────────────────────
  // Store Administration / Web Portal Permissions (Excluded from POS client)
  // These are managed in the central web management portal, not in POS client.
  // ──────────────────────────────────────────────────────────────────────────
  static const String userCreate = 'USER_CREATE';
  static const String userRead = 'USER_READ';
  static const String userUpdate = 'USER_UPDATE';
  static const String userDelete = 'USER_DELETE';
  static const String userList = 'USER_LIST';
  static const String userManageRoles = 'USER_MANAGE_ROLES';

  static const String branchCreate = 'BRANCH_CREATE';
  static const String branchRead = 'BRANCH_READ';
  static const String branchUpdate = 'BRANCH_UPDATE';
  static const String branchDelete = 'BRANCH_DELETE';

  static const String brandCreate = 'BRAND_CREATE';
  static const String brandRead = 'BRAND_READ';
  static const String brandUpdate = 'BRAND_UPDATE';
  static const String brandDelete = 'BRAND_DELETE';
  static const String brandList = 'BRAND_LIST';

  static const String apiUserCreate = 'API_USER_CREATE';
  static const String apiUserRead = 'API_USER_READ';
  static const String apiUserUpdate = 'API_USER_UPDATE';
  static const String apiUserDelete = 'API_USER_DELETE';
  static const String apiUserList = 'API_USER_LIST';

  static const String deviceManage = 'DEVICE_MANAGE';
}
