class ApiEndpoints {
  // Base URL - Change this to your server URL
  static const String baseUrl = 'http://localhost:8080';

  // Auth endpoints
  static const String login = '/api/auth/login';
  static const String profile = '/api/auth/profile';
  static const String register = '/api/auth/register';

  // User management endpoints
  static const String users = '/api/users';
  static const String changePassword = '/api/users/change-password';
  static String resetPassword(int userId) =>
      '/api/users/$userId/reset-password';

  // Vehicle endpoints
  static const String vehicles = '/api/vehicles';
  static const String availableVehicles = '/api/vehicles/available';
  static const String vehicleBrands = '/api/vehicles/brands';
  static const String vehicleModels = '/api/vehicles/models';
  static String vehicleModelsByBrand(String brand) =>
      '/api/vehicles/brands/$brand/models';
  static String vehicleById(int id) => '/api/vehicles/$id';
  static String setVehicleSellingPrice(int id) =>
      '/api/vehicles/$id/selling-price';

  // Vehicle Type endpoints
  static const String vehicleTypes = '/api/vehicle-types';
  static String vehicleTypeById(int id) => '/api/vehicle-types/$id';

  // Customer endpoints
  static const String customers = '/api/customers';
  static String customerById(int id) => '/api/customers/$id';
  static String customerByPhone(String phone) => '/api/customers/phone/$phone';
  static String customerByEmail(String email) => '/api/customers/email/$email';

  // Transaction endpoints
  static const String purchaseTransactions = '/api/transactions/purchase';
  static const String salesTransactions = '/api/transactions/sales';
  static const String sales = '/api/sales';
  static String purchaseTransactionById(int id) =>
      '/api/transactions/purchase/$id';
  static String salesTransactionById(int id) => '/api/transactions/sales/$id';
  static String saleById(int id) => '/api/sales/$id';
  static String updatePurchasePayment(int id) =>
      '/api/transactions/purchase/$id/payment';
  static String updateSalesPayment(int id) =>
      '/api/transactions/sales/$id/payment';
  static String generateInvoice(int saleId) => '/api/sales/$saleId/invoice';
  static String printInvoice(int saleId) => '/api/sales/$saleId/print';

  // Spare parts endpoints
  static const String spareParts = '/api/spare-parts';
  static const String sparePartCategories = '/api/spare-parts/categories';
  static const String lowStockSpareParts = '/api/spare-parts/low-stock';
  static const String bulkStockUpdate = '/api/spare-parts/bulk-stock-update';
  static String sparePartById(int id) => '/api/spare-parts/$id';
  static String sparePartByCode(String code) => '/api/spare-parts/code/$code';
  static String updateSparePartStock(int id) => '/api/spare-parts/$id/stock';
  static String checkSparePartStock(int id) =>
      '/api/spare-parts/$id/stock-check';

  // Repair endpoints
  static const String repairs = '/api/repairs';
  static const String repairOrders = '/api/repair-orders';
  static const String repairStats = '/api/repairs/stats';
  static const String mechanicWorkload = '/api/repairs/mechanic-workload';
  static String repairById(int id) => '/api/repairs/$id';
  static String repairDetail(int id) => '/api/repairs/$id';
  static String repairByCode(String code) => '/api/repairs/code/$code';
  static String updateRepairProgress(int id) => '/api/repairs/$id/progress';
  static String repairOrderProgress(int id) =>
      '/api/repair-orders/$id/progress';
  static String repairOrderComplete(int id) =>
      '/api/repair-orders/$id/complete';
  static String repairSpareParts(int id) => '/api/repairs/$id/spare-parts';
  static String removeRepairSparePart(int id, int sparePartId) =>
      '/api/repairs/$id/spare-parts/$sparePartId';
  static String repairItems(int repairId) =>
      '/api/repairs/$repairId/spare-parts';
  static String repairItem(int repairId, int itemId) =>
      '/api/repairs/$repairId/spare-parts/$itemId';
  static String startRepair(int repairId) => '/api/repairs/$repairId/start';
  static String completeRepair(int repairId) =>
      '/api/repairs/$repairId/complete';

  // Supplier endpoints
  static const String suppliers = '/api/suppliers';
  static String supplierById(int id) => '/api/suppliers/$id';
  static String supplierByPhone(String phone) => '/api/suppliers/phone/$phone';
  static String supplierByEmail(String email) => '/api/suppliers/email/$email';

  // Dashboard endpoints
  static const String dashboard = '/api/dashboard';
  static const String adminDashboard = '/api/dashboard/admin';
  static const String cashierDashboard = '/api/dashboard/cashier';
  static const String mechanicDashboard = '/api/dashboard/mechanic';
  static const String dailyClosing = '/api/dashboard/daily-closing';

  // Health check
  static const String health = '/health';
}
