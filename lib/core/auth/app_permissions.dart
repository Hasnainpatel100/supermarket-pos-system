/// Centralized catalog of all RBAC permissions managed by the backend.
/// Using string constants ensures type-safety, IDE autocomplete, and prevents typos.
class AppPermissions {
  // ── Users ─────────────────────────────────────────────────────────────────
  static const String userCreate = 'USER_CREATE';
  static const String userRead = 'USER_READ';
  static const String userUpdate = 'USER_UPDATE';
  static const String userDelete = 'USER_DELETE';
  static const String userList = 'USER_LIST';
  static const String userManageRoles = 'USER_MANAGE_ROLES';

  // ── Branches & Brands ─────────────────────────────────────────────────────
  static const String branchCreate = 'BRANCH_CREATE';
  static const String branchRead = 'BRANCH_READ';
  static const String branchUpdate = 'BRANCH_UPDATE';
  static const String branchDelete = 'BRANCH_DELETE';

  static const String brandCreate = 'BRAND_CREATE';
  static const String brandRead = 'BRAND_READ';
  static const String brandUpdate = 'BRAND_UPDATE';
  static const String brandDelete = 'BRAND_DELETE';
  static const String brandList = 'BRAND_LIST';

  // ── Device & System Maintenance ───────────────────────────────────────────
  static const String deviceManage = 'DEVICE_MANAGE';
  static const String systemViewLogs = 'SYSTEM_VIEW_LOGS';
  static const String systemManageConfig = 'SYSTEM_MANAGE_CONFIG';
  static const String systemBackup = 'SYSTEM_BACKUP';
  static const String systemMaintenance = 'SYSTEM_MAINTENANCE';

  // ── Plan & Subscription ───────────────────────────────────────────────────
  static const String planRead = 'PLAN_READ';
  static const String subscriptionRead = 'SUBSCRIPTION_READ';

  // ── Orders & Point of Sale (POS) ──────────────────────────────────────────
  static const String orderCreate = 'ORDER_CREATE';
  static const String orderRead = 'ORDER_READ';
  static const String orderUpdate = 'ORDER_UPDATE';
  static const String orderDelete = 'ORDER_DELETE';
  static const String orderList = 'ORDER_LIST';
  static const String orderCancel = 'ORDER_CANCEL';
  static const String orderRefund = 'ORDER_REFUND';
  static const String orderReprint = 'ORDER_REPRINT';

  // ── Payments & Register ───────────────────────────────────────────────────
  static const String paymentProcess = 'PAYMENT_PROCESS';
  static const String refundProcess = 'REFUND_PROCESS';
  static const String paymentView = 'PAYMENT_VIEW';
  static const String paymentRefund = 'PAYMENT_REFUND';
  static const String paymentViewReports = 'PAYMENT_VIEW_REPORTS';
  static const String paymentCancel = 'PAYMENT_CANCEL';
  static const String drawerOpenManual = 'DRAWER_OPEN_MANUAL';

  // ── Taxes ─────────────────────────────────────────────────────────────────
  static const String taxCreate = 'TAX_CREATE';
  static const String taxRead = 'TAX_READ';
  static const String taxUpdate = 'TAX_UPDATE';
  static const String taxDelete = 'TAX_DELETE';
  static const String taxList = 'TAX_LIST';
  static const String taxManageGroups = 'TAX_MANAGE_GROUPS';

  // ── Reports ───────────────────────────────────────────────────────────────
  static const String reportView = 'REPORT_VIEW';
  static const String reportViewSales = 'REPORT_VIEW_SALES';
  static const String reportViewFinancial = 'REPORT_VIEW_FINANCIAL';
  static const String reportViewUserActivity = 'REPORT_VIEW_USER_ACTIVITY';
  static const String reportExport = 'REPORT_EXPORT';

  // ── Dashboard ─────────────────────────────────────────────────────────────
  static const String dashboardView = 'DASHBOARD_VIEW';
  static const String dashboardExport = 'DASHBOARD_EXPORT';

  // ── Expenses ──────────────────────────────────────────────────────────────
  static const String expenseCreate = 'EXPENSE_CREATE';
  static const String expenseRead = 'EXPENSE_READ';
  static const String expenseUpdate = 'EXPENSE_UPDATE';
  static const String expenseDelete = 'EXPENSE_DELETE';
  static const String expenseApprove = 'EXPENSE_APPROVE';

  // ── Accounts & Cash Drawer Movements ──────────────────────────────────────
  static const String accountCreate = 'ACCOUNT_CREATE';
  static const String accountRead = 'ACCOUNT_READ';
  static const String accountUpdate = 'ACCOUNT_UPDATE';
  static const String accountDelete = 'ACCOUNT_DELETE';
  static const String accountManage = 'ACCOUNT_MANAGE';

  // ── Inventory, Catalog & Scanning ─────────────────────────────────────────
  static const String inventoryCreate = 'INVENTORY_CREATE';
  static const String inventoryRead = 'INVENTORY_READ';
  static const String inventoryUpdate = 'INVENTORY_UPDATE';
  static const String inventoryDelete = 'INVENTORY_DELETE';
  static const String barcodeScan = 'BARCODE_SCAN';
  static const String weightBasedPricing = 'WEIGHT_BASED_PRICING';
  static const String bulkItemImport = 'BULK_ITEM_IMPORT';
  static const String stockAdjust = 'STOCK_ADJUST';
  static const String expiryManage = 'EXPIRY_MANAGE';

  // ── Pricing & POS Security ────────────────────────────────────────────────
  static const String discountApply = 'DISCOUNT_APPLY';
  static const String discountOverride = 'DISCOUNT_OVERRIDE';
  static const String priceOverride = 'PRICE_OVERRIDE';

  // ── Customers ─────────────────────────────────────────────────────────────
  static const String customerCreate = 'CUSTOMER_CREATE';
  static const String customerRead = 'CUSTOMER_READ';
  static const String customerUpdate = 'CUSTOMER_UPDATE';
  static const String customerDelete = 'CUSTOMER_DELETE';
  static const String customerList = 'CUSTOMER_LIST';

  // ── Suppliers ─────────────────────────────────────────────────────────────
  static const String supplierCreate = 'SUPPLIER_CREATE';
  static const String supplierRead = 'SUPPLIER_READ';
  static const String supplierUpdate = 'SUPPLIER_UPDATE';
  static const String supplierDelete = 'SUPPLIER_DELETE';
  static const String supplierList = 'SUPPLIER_LIST';

  // ── Purchases ─────────────────────────────────────────────────────────────
  static const String purchaseCreate = 'PURCHASE_CREATE';
  static const String purchaseRead = 'PURCHASE_READ';
  static const String purchaseUpdate = 'PURCHASE_UPDATE';
  static const String purchaseDelete = 'PURCHASE_DELETE';
  static const String purchaseList = 'PURCHASE_LIST';
  static const String purchaseReceive = 'PURCHASE_RECEIVE';

  // ── API Users ─────────────────────────────────────────────────────────────
  static const String apiUserCreate = 'API_USER_CREATE';
  static const String apiUserRead = 'API_USER_READ';
  static const String apiUserUpdate = 'API_USER_UPDATE';
  static const String apiUserDelete = 'API_USER_DELETE';
  static const String apiUserList = 'API_USER_LIST';
}
